/*
WRATH: Aeon of Ruin Deathmatch Codebase
Copyright (C) 2023 - 2024  Samuel "Reki" Piper

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#include "weapons.h"

#define REVOLVER_FLAG_MUZZLE1	0x1
#define REVOLVER_FLAG_MUZZLE2	0x2

#ifdef CSQC
#include "client.h"

static float gunglow;
void W_Coachgun_Render()
{
	setmodel(viewmodel, "models/weapons/revolver/v_revolver.md3");
	viewmodel.origin += (v_right * 6);
	viewmodel.origin += (v_up * -9.5);
	viewmodel.origin += (v_forward * 13.5);

	float old_frametime = viewmodel.frame1time;
	float old_frame = viewmodel.frame;
	float wep_frame = viewmodel.weapon_mode & 0x0FF0 >> 4;
	float wep_flags = viewmodel.weapon_mode & 0x3000 >> 12;
	viewmodel.frame = wep_frame;
	
	if (wep_flags)
	{
		viewmodel.effects |= EF_MUZZLEFLASH;
		if (wep_flags & REVOLVER_FLAG_MUZZLE2)
			gunglow = 1.7;
		else
			gunglow = 1.3;
	}
	else
		gunglow -= frametime * 1.4;
	gunglow = max(0.01, gunglow);
	float v_glow = min(gunglow, 1);
	viewmodel.glowmod = [v_glow, v_glow, v_glow];


	addentity(viewmodel);

	if (wep_flags)
	{
		float tag_muzzle = gettagindex(viewmodel, "tag_muzzle");

		if (wep_flags & REVOLVER_FLAG_MUZZLE1)
		{
			setmodel(viewmodel2, "models/weapons/revolver/flash_small.md3");
			setorigin(viewmodel2, gettaginfo(viewmodel, tag_muzzle));
			viewmodel2.angles = vectoangles2(v_forward, v_up);
			addentity(viewmodel2);
		}
		if (wep_flags & REVOLVER_FLAG_MUZZLE2)
		{
			setmodel(viewmodel2, "models/weapons/revolver/flash_big.md3");
			setorigin(viewmodel2, gettaginfo(viewmodel, tag_muzzle));
			viewmodel2.angles = vectoangles2(v_forward, v_up);
			addentity(viewmodel2);
		}
	}
}
#endif

#define REVOLVER_MODE_IDLE		0x0
#define REVOLVER_MODE_FIRE1 	0x1
#define REVOLVER_MODE_FIRE2		0x2
#define REVOLVER_MODE_DRAW 		0x4

void W_Coachgun_Putaway()
{
	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	wep_frame = 47;
	wep_phase = REVOLVER_MODE_DRAW;
	self.busy_frames = 3;
	self.attack_frames = 3;

	PEvent_Sound(self, CHAN_AUTO, "weapons/revolver/lower.ogg", 1, ATTN_STATIC);

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Coachgun_Draw()
{
	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	wep_frame = 43;
	wep_phase = REVOLVER_MODE_DRAW;
	self.busy_frames = 3;
	self.attack_frames = 3;

	PEvent_Sound(self, CHAN_AUTO, "weapons/revolver/raise.ogg", 1, ATTN_STATIC);

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_CoachgunProjectile_Touch()
{
	projectile_c prj = (projectile_c)self;
	entity dealer = prj.partner;
	prj.owner = world;

	if (other.takedamage && other.solid == SOLID_SLIDEBOX)
	{
		#ifdef SSQC
		PL_TakeDamage(normalize(self.velocity) * 110, 20, 0, dealer, other);
		#endif
		self.owner = other;
		self.health = -1;
	}
	else
	{
		float backoff = -(self.velocity * trace_plane_normal);
		self.velocity += trace_plane_normal * backoff * 1.9;
		self.health--;
		self.owner = world;

		#ifdef SSQC
		soundwrath(self, CHAN_AUTO, sprintf("impact/projectiles/rico%g.ogg", floor(random() * 15) + 1), 1, ATTN_IDLE, 100 + (crandom() * 5), 0, 0.2);
		#endif
	}

	self.cmovetype = MOVETYPE_FLYMISSILE;

	#ifdef SSQC
	self.SendFlags |= 0x41;
	if (self.health < 0)
		remove(self);
	#endif
	#ifdef CSQC
	if (self.health < 0)
		self.cmovetype = MOVETYPE_NONE;
	#endif
}


void W_Coachgun_FireProjectile()
{
	#ifdef CSQC
	return;
	#endif
	makevectors(input_angles);
	projectile_c prj = spawn(projectile_c);
	//if (PEvent_Projectile(self, prj))
	{
		setmodel(prj, "models/projectiles/proj_shrapnel.md3");
		prj.owner = self;
		prj.partner = self;
		prj.angles = input_angles;
		prj.angles[0] *= -1;

		prj.touch = W_CoachgunProjectile_Touch;
		prj.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY;
		
		vector barrel_pos = self.origin + self.view_ofs + [0, 0, self.sview_height];
		barrel_pos += v_forward * 4;
		barrel_pos += (crandom() * v_up) * 2;
		barrel_pos += (crandom() * v_right) * 2;

		setorigin(prj, barrel_pos);
		setsize(prj, '0 0 0', '0 0 0');
		prj.solid = SOLID_BBOX;

		prj.velocity = 1800 * v_forward;
		prj.velocity += random(-25, 25) * v_right;
		prj.velocity += random(-20, 20) * v_up;
		prj.health = 4;

		newmis = prj;
	#ifdef CSQC
		prj.origin += prj.velocity * 0.025;

		prj.start_velocity = prj.velocity;
		prj.start_origin = prj.origin;
		//prj.framenumber = framenum;
		//prj.framenumber -= 0.025 / sv_ticrate;
	#endif
	#ifdef SSQC
		prj.cmovetype = MOVETYPE_FLYMISSILE;
		prj.cphysics = Projectile_Physics;
		
		prj.framenumber = sv_framenum;

		prj.think = SUB_Remove;
		prj.nextthink = time + 2;

		prj.SendEntity = SendEntity_Projectile;
		//Entity_ForcePhysicsFrame(prj, 0.025);
	#endif
	}
}

void W_Coachgun_ClientFrame()
{
	if (self.attack_frames)
		return;
	
	if (self.ammo_slugs <= 0)
	{
		if ((input_buttons & BUTTON_ALTFIRE) || (input_buttons & BUTTON_FIRE))
			self.weapon_wanted = PL_BestWeapon();
		return;
	}

	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	if (input_buttons & BUTTON_FIRE)
	{
		self.weapon_mode |= WEAPON_FLAG_FIRED;
		wep_flags |= REVOLVER_FLAG_MUZZLE1;
		self.effects |= EF_MUZZLEFLASH;
		wep_frame = 2;
		wep_phase = REVOLVER_MODE_FIRE1;

		self.punchangle[0] -= 2;
		PEvent_Sound(self, CHAN_WEAPON, sprintf("weapons/revolver/fire1_%g.ogg", floor(random() * 3) + 1), 1, ATTN_GUN);
		
		makevectors(input_angles);
		W_FireHitscan(v_forward, 0, 14, 240);
		
		self.weapon_animfinish = 14;
		self.attack_frames = 8;
		self.busy_frames = 1;
		self.ammo_slugs--;
	}
	else if (input_buttons & BUTTON_ALTFIRE)
	{
		self.weapon_mode |= WEAPON_FLAG_FIRED;
		wep_flags |= REVOLVER_FLAG_MUZZLE2;
		self.effects |= EF_MUZZLEFLASH;
		wep_frame = 18;
		wep_phase = REVOLVER_MODE_FIRE2;

		self.punchangle[0] -= 3;
		PEvent_Sound(self, CHAN_WEAPON, sprintf("weapons/revolver/fire2_%g.ogg", floor(random() * 2) + 1), 1, ATTN_GUN);
		for(float i = min(3, self.ammo_slugs); i > 0; i--)
		{
			self.ammo_slugs--;
			W_Coachgun_FireProjectile();
		}

		self.weapon_animfinish = 18;
		self.attack_frames = 17;
		self.busy_frames = 4;
	}

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Coachgun_Frame()
{
	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	if !(self.weapon_mode & WEAPON_FLAG_FIRED)
	{
		wep_flags = 0;
		self.effects &= ~EF_MUZZLEFLASH;
	}

	switch (wep_phase)
	{
		case REVOLVER_MODE_FIRE1:
			wep_frame = min(wep_frame + 1, 18);
			if (!self.weapon_animfinish)
			{
				wep_frame = 1;
				wep_phase = REVOLVER_MODE_IDLE;
			}
		break;
		case REVOLVER_MODE_FIRE2:
			wep_frame++;
			if (!self.weapon_animfinish)
			{
				wep_frame = 1;
				wep_phase = REVOLVER_MODE_IDLE;
			}
		break;
		case REVOLVER_MODE_DRAW:
			wep_frame++;
			if (!self.busy_frames)
			{
				wep_frame = 1;
				wep_phase = REVOLVER_MODE_IDLE;
			}
		break;
		default:
			if (!self.weapon_animfinish)
			{
				wep_frame = 1;
				wep_phase = REVOLVER_MODE_IDLE;
			}
		break;
	}

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Coachgun_Init()
{
	weapon_t coachgun;
	#ifdef CSQC
	precache_model("models/weapons/revolver/v_revolver.md3");
	precache_model("models/weapons/revolver/flash_small.md3");
	precache_model("models/weapons/revolver/flash_big.md3");
	precache_model("models/projectiles/proj_shrapnel.md3");

	coachgun.render = W_Coachgun_Render;
	coachgun.hmodel = "models/weapons/revolver/w_revolver.md3";
	#endif
	precache_sound("weapons/revolver/lower.ogg");
	precache_sound("weapons/revolver/raise.ogg");
	for(float i = 1; i <= 3; i++)
		precache_sound(sprintf("weapons/revolver/fire1_%g.ogg", i));
	for(float i = 1; i <= 2; i++)
		precache_sound(sprintf("weapons/revolver/fire2_%g.ogg", i));

	coachgun.clientframe = W_Coachgun_ClientFrame;
	coachgun.frame = W_Coachgun_Frame;
	coachgun.putaway = W_Coachgun_Putaway;
	coachgun.takeout = W_Coachgun_Draw;
	
	coachgun.it_flag = ITEM::COACHGUN;
	weaponlist[WEAPON::COACHGUN] = coachgun;
}
