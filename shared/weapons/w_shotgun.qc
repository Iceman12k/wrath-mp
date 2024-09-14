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

#define SHOTGUN_FLAG_MUZZLE		0x1

#ifdef CSQC
#include "client.h"

static float gunglow;
void W_Shotgun_Render()
{
	setmodel(viewmodel, "models/weapons/shotgun/v_shotgun.md3");
	viewmodel.origin += (v_right * 7);
	viewmodel.origin += (v_up * -9.5);
	viewmodel.origin += (v_forward * 10.5);

	float old_frametime = viewmodel.frame1time;
	float old_frame = viewmodel.frame;
	float wep_frame = viewmodel.weapon_mode & 0x0FF8 >> 3;
	float wep_flags = viewmodel.weapon_mode & 0x3000 >> 12;
	viewmodel.frame = wep_frame;
	
	if (wep_flags & SHOTGUN_FLAG_MUZZLE)
		gunglow = 1.7;
	else if (wep_frame >= 82 && wep_frame <= 101)
		gunglow = (1 - ((101 - wep_frame) / 20)) * 1.2;
	else
		gunglow -= frametime * 1.6;
	gunglow = max(0.01, gunglow);
	float v_glow = min(gunglow, 1);
	viewmodel.glowmod = [v_glow, v_glow, v_glow];


	addentity(viewmodel);

	if (wep_flags & SHOTGUN_FLAG_MUZZLE)
	{
		viewmodel.effects |= EF_MUZZLEFLASH;
		float tag_muzzle = gettagindex(viewmodel, "tag_muzzle");
		setmodel(viewmodel2, "models/weapons/shotgun/flash_small.md3");
		setorigin(viewmodel2, gettaginfo(viewmodel, tag_muzzle));
		viewmodel2.angles = vectoangles2(v_forward, v_up);
		addentity(viewmodel2);
	}
}
#endif

#define SHOTROCKET_RADIUS 400
#define SHOTROCKET_KNOCKBACK 250
#define SHOTROCKET_DAMAGE 25
void W_Shotgunbomb_Touch()
{
	projectile_c prj = (projectile_c)self;
	entity dealer = prj.owner;
	prj.owner = world;

	self.cmovetype = MOVETYPE_NONE;

	if (other.takedamage)
	{
		vector l_org = (other.absmin + other.absmax) / 2;
		vector diff = (l_org - prj.origin);
		PL_TakeDamage(normalize(diff) * SHOTROCKET_KNOCKBACK, SHOTROCKET_DAMAGE, 0, dealer, other);
	}

	entity lst = findradius(prj.origin, SHOTROCKET_RADIUS + 32);
	for(;lst;lst = lst.chain)
	{
		if (lst == other) // we handle this separately
			continue;
		if !(lst.flags & FL_CLIENT && lst.deadflag == DEAD_NO && lst.takedamage)
			continue;
		// capsule hit radius
		vector l_org = (lst.absmin + lst.absmax) / 2;
		vector diff_mid = (l_org - prj.origin);
		l_org[2] = bound(lst.absmin[2] + 16, prj.origin[2], lst.absmax[2] - 16);
		l_org += 16 * normalize(l_org - prj.origin);
		//
		vector diff = (l_org - prj.origin);
		float points = 1 - (vlen(diff) / SHOTROCKET_RADIUS);
		if (points < 0)
			continue;
		points = bound(0.15, points, 0.95);

		PL_TakeDamage(normalize(diff_mid) * SHOTROCKET_KNOCKBACK * points, SHOTROCKET_DAMAGE * points, 0, dealer, lst);
	}
#ifdef SSQC
	soundwrath(prj, CHAN_AUTO, "impact/projectiles/shotgun_explo1.ogg", 1, ATTN_VOICE, 0, 0, 0);
	pointparticles(particleeffectnum("shotgun_explo"), prj.origin, '0 0 0', 1);

	remove(prj);
#endif
}

void W_Shotgun_FireProjectile(float offs)
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

		prj.touch = W_Shotgunbomb_Touch;
		prj.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY;
		
		vector barrel_pos = self.origin + self.view_ofs + [0, 0, self.sview_height];
		barrel_pos += v_forward * 4;
		barrel_pos += v_right * offs;

		setorigin(prj, barrel_pos);
		setsize(prj, '0 0 0', '0 0 0');
		prj.solid = SOLID_BBOX;

		prj.velocity = 1600 * v_forward;
		prj.velocity += random(7, 30) * offs * v_right;
		prj.velocity += random(-30, 30) * v_up;
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

#define SHOTGUN_MODE_IDLE		0x0
#define SHOTGUN_MODE_FIRE1 		0x1
#define SHOTGUN_MODE_FIRE1EMPTY	0x2
#define SHOTGUN_MODE_FIRE2		0x3
#define SHOTGUN_MODE_DRAW 		0x4
#define SHOTGUN_MODE_CHARGE		0x5

void W_Shotgun_Putaway()
{
	wep_phase = self.weapon_mode & 0x0007;
	wep_frame = self.weapon_mode & 0x0FF8 >> 3;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	wep_frame = 106;
	wep_phase = SHOTGUN_MODE_DRAW;
	self.busy_frames = 5;
	self.attack_frames = 5;

	PEvent_Sound(self, CHAN_AUTO, "weapons/shotgun/lower.ogg", 1, ATTN_STATIC);

	self.weapon_mode = wep_phase | (wep_frame << 3) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Shotgun_Draw()
{
	wep_phase = self.weapon_mode & 0x0007;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	wep_frame = 101;
	wep_phase = SHOTGUN_MODE_DRAW;
	self.busy_frames = 5;
	self.attack_frames = 5;

	PEvent_Sound(self, CHAN_AUTO, "weapons/shotgun/raise.ogg", 1, ATTN_STATIC);

	self.weapon_mode = wep_phase | (wep_frame << 3) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

#define SHOTGUN_PELLETS 	19
#define SHOTGUN_DAMAGE		6
#define SHOTGUN_KNOCKBACK 	80
#define SHOTGUN_WIDTH		0.009

void W_Shotgun_ClientFrame() // do shooting on inter-frames to respect aim more
{
	wep_phase = self.weapon_mode & 0x0007;
	wep_frame = self.weapon_mode & 0x0FF8 >> 3;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	if (self.ammo_shells < 2)
	{
		if ((input_buttons & BUTTON_ALTFIRE) || (input_buttons & BUTTON_FIRE))
			self.weapon_wanted = PL_BestWeapon();
		return;
	}

	if (!self.attack_frames)
	{
		if (input_buttons & BUTTON_FIRE)
		{
			wep_flags |= SHOTGUN_FLAG_MUZZLE;
			self.effects |= EF_MUZZLEFLASH;
			self.weapon_mode |= WEAPON_FLAG_FIRED;
			PEvent_Sound(self, CHAN_WEAPON, sprintf("weapons/shotgun/fire1_%g.ogg", floor(random() * 2) + 1), 1, ATTN_GUN);
			self.punchangle[0] -= 6;
			
			makevectors(input_angles);
			#ifdef SSQC
			for(float i = 0; i < 18; i++)
			{
				vector dir = v_forward + (((v_right * crandom() * 0.1) + (v_up * crandom() * 0.66)) * (1/12)); // 1 unit spread per 16 units
				dir += (v_right * (i - (SHOTGUN_PELLETS/2))) * SHOTGUN_WIDTH;
				W_FireHitscan(dir, 0, SHOTGUN_DAMAGE, SHOTGUN_KNOCKBACK);
			}
			#endif

			if (self.ammo_shells > 2)
			{
				wep_frame = 2;
				wep_phase = SHOTGUN_MODE_FIRE1;
				self.weapon_animfinish = 39;
				self.attack_frames = 32;
				self.busy_frames = 5;
			}
			else
			{
				wep_frame = 114;
				wep_phase = SHOTGUN_MODE_FIRE1EMPTY;
				self.weapon_mode |= WEAPON_FLAG_LOWFPS;
				self.weapon_animfinish = 37;
				self.attack_frames = 17;
				self.busy_frames = 6;
			}
			self.ammo_shells -= 2;
		}
		else if (input_buttons & BUTTON_ALTFIRE)
		{
			wep_frame = 82;
			wep_phase = SHOTGUN_MODE_CHARGE;
			self.attack_frames = 2;
			self.busy_frames = 3;
			self.weapon_animfinish = 19;

			PEvent_Sound(self, CHAN_WEAPON, "weapons/shotgun/charge.ogg", 1, ATTN_STATIC);
		}
	}

	self.weapon_mode = wep_phase | (wep_frame << 3) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Shotgun_Frame()
{
	wep_phase = self.weapon_mode & 0x0007;
	wep_frame = self.weapon_mode & 0x0FF8 >> 3;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	if !(self.weapon_mode & WEAPON_FLAG_FIRED)
	{
		wep_flags = 0;
		self.effects &= ~EF_MUZZLEFLASH;
	}

	self.weapon_mode &= ~WEAPON_FLAG_LOWFPS;
	switch (wep_phase)
	{
		case SHOTGUN_MODE_FIRE1EMPTY:
			self.weapon_mode |= WEAPON_FLAG_LOWFPS;
			INCREMENT_FRAME
			if (!self.weapon_animfinish)
			{
				wep_frame = 0;
				wep_phase = SHOTGUN_MODE_IDLE;
			}
		break;
		case SHOTGUN_MODE_FIRE1:
			INCREMENT_FRAME
			if (!self.weapon_animfinish)
			{
				wep_frame = 0;
				wep_phase = SHOTGUN_MODE_IDLE;
			}
		break;
		case SHOTGUN_MODE_FIRE2:
			INCREMENT_FRAME
			if (!self.weapon_animfinish)
			{
				wep_frame = 0;
				wep_phase = SHOTGUN_MODE_IDLE;
			}
		break;
		case SHOTGUN_MODE_DRAW:
			INCREMENT_FRAME
			if (!self.busy_frames)
			{
				wep_frame = 0;
				wep_phase = SHOTGUN_MODE_IDLE;
			}
		break;
		case SHOTGUN_MODE_CHARGE:
			if (wep_frame < 92)
				self.weapon_mode |= WEAPON_FLAG_LOWFPS;
			
			INCREMENT_FRAME
			self.attack_frames = 3;
			self.busy_frames = 3;
			if (wep_frame >= 100)// || !(input_buttons & BUTTON_ALTFIRE))
			{
				PEvent_Sound(self, CHAN_WEAPON, sprintf("weapons/shotgun/fire2_%g.ogg", floor(random() * 2) + 1), 1, ATTN_GUN);
				W_Shotgun_FireProjectile(-2);
				W_Shotgun_FireProjectile(2);
				self.punchangle[0] -= 8;

				self.ammo_shells -= 2;
				wep_flags |= SHOTGUN_FLAG_MUZZLE;
				self.effects |= EF_MUZZLEFLASH;
				wep_frame = 42;
				wep_phase = SHOTGUN_MODE_FIRE2;
				self.weapon_animfinish = 35;
				self.attack_frames = 32;
				self.busy_frames = 17;
			}
			else if (!(input_buttons & BUTTON_ALTFIRE))
			{
				wep_frame = 0;
				wep_phase = SHOTGUN_MODE_IDLE;
				PEvent_Sound(self, CHAN_WEAPON, "misc/null.wav", 1, ATTN_GUN);
			}
		break;
		default:
			if (!self.weapon_animfinish)
			{
				wep_frame = 0;
				wep_phase = SHOTGUN_MODE_IDLE;
			}
		break;
	}

	self.weapon_mode = wep_phase | (wep_frame << 3) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Shotgun_Init()
{
	weapon_t shotgun;
	#ifdef CSQC
	precache_model("models/weapons/shotgun/v_shotgun.md3");
	precache_model("models/weapons/shotgun/flash_small.md3");
	shotgun.render = W_Shotgun_Render;
	shotgun.hmodel = "models/weapons/shotgun/w_shotgun.md3";
	#endif
	precache_sound("weapons/shotgun/lower.ogg");
	precache_sound("weapons/shotgun/raise.ogg");
	for(float i = 1; i <= 2; i++)
		precache_sound(sprintf("weapons/shotgun/fire1_%g.ogg", i));
	for(float i = 1; i <= 2; i++)
		precache_sound(sprintf("weapons/shotgun/fire2_%g.ogg", i));

	shotgun.frame = W_Shotgun_Frame;
	shotgun.clientframe = W_Shotgun_ClientFrame;
	shotgun.putaway = W_Shotgun_Putaway;
	shotgun.takeout = W_Shotgun_Draw;
	
	shotgun.it_flag = ITEM::SHOTGUN;
	weaponlist[WEAPON::SHOTGUN] = shotgun;
}
