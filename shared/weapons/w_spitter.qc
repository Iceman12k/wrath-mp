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

#include "common.h"
#include "weapons.h"

#define SPITTER_FLAG_MUZZLE		0x1
#define SPITTER_FLAG_MUZZLE2	0x2

#ifdef CSQC
#include "client.h"

static float fang_spin_lerpfrac;
static float fang_spin_oldframe;
static float fang_spin;
void W_Spitter_Render()
{
	setmodel(viewmodel, "models/weapons/spitter/v_spitter.md3");
	viewmodel.origin += (v_right * 5);
	viewmodel.origin += (v_up * -7);
	viewmodel.origin += (v_forward * 12);

	float old_frametime = viewmodel.frame1time;
	float old_frame = viewmodel.frame;
	float wep_frame = viewmodel.weapon_mode & 0x0FF0 >> 4;
	float wep_flags = viewmodel.weapon_mode & 0x3000 >> 12;
	viewmodel.frame = wep_frame;
	viewmodel.glowmod = 0;


	addentity(viewmodel);

	if (wep_flags)
	{
		if (fang_spin_oldframe != wep_frame)
		{
			if (wep_flags & SPITTER_FLAG_MUZZLE)
				fang_spin += 1;
			fang_spin_oldframe = wep_frame;
			fang_spin = fang_spin % 15;
			fang_spin_lerpfrac = 1;
		}
	}

	if (fang_spin_lerpfrac > 0)
	{
		fang_spin_lerpfrac = max(0, fang_spin_lerpfrac - frametime * 20);
	}

	float tag_body = gettagindex(viewmodel, "tag_body");
	setmodel(viewmodel2, "models/weapons/spitter/v_fangs.md3");
	setorigin(viewmodel2, gettaginfo(viewmodel, tag_body));
	viewmodel2.angles = vectoangles2(v_forward, v_up);
	viewmodel2.frame = fang_spin;
	viewmodel2.frame2 = (fang_spin - 1) % 15;
	viewmodel2.lerpfrac = fang_spin_lerpfrac;
	viewmodel2.skin = bound(0, view_subject.ammo_fangs, 8);

	addentity(viewmodel2);
}
#endif

#define SPITTER_MODE_IDLE		0x0
#define SPITTER_MODE_FIRE1 		0x1
#define SPITTER_MODE_FIRE2		0x2
#define SPITTER_MODE_RECOVER 	0x3
#define SPITTER_MODE_DRAW 		0x4

void W_Spitter_Putaway()
{
	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	wep_frame = 44;
	wep_phase = SPITTER_MODE_DRAW;
	self.busy_frames = 5;
	self.attack_frames = 5;

	PEvent_Sound(self, CHAN_AUTO, "weapons/spitter/lower.ogg", 1, ATTN_STATIC);

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Spitter_Draw()
{
	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	wep_frame = 41;
	wep_phase = SPITTER_MODE_DRAW;
	self.busy_frames = 4;
	self.attack_frames = 4;

	PEvent_Sound(self, CHAN_AUTO, "weapons/spitter/raise.ogg", 1, ATTN_STATIC);

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

#define FANG_DAMAGE 15
#define FANG_KNOCKBACK 120
void W_Fang_Touch()
{
	projectile_c prj = (projectile_c)self;
	entity dealer = prj.owner;
	prj.owner = world;

	self.cmovetype = MOVETYPE_NONE;

	if (other.takedamage)
	{
		vector l_org = (other.absmin + other.absmax) / 2;
		vector diff = (l_org - prj.origin);
		PL_TakeDamage(normalize(diff) * FANG_KNOCKBACK, FANG_DAMAGE, 0, dealer, other);
	}

#ifdef SSQC
	pointparticles(particleeffectnum("fang"), prj.origin, trace_plane_normal * (-550), 1);

	remove(prj);
#endif
}

void W_Spitter_FireProjectile(float type, float offs)
{
	if (self.ammo_fangs <= 0)
		return;

	self.ammo_fangs--;

	makevectors(input_angles + self.punchangle);
	PEvent_Sound(self, CHAN_WEAPON, sprintf("weapons/spitter/fire1_%g.ogg", floor(random() * 5) + 1), 1, ATTN_GUN);

	vector barrel_pos = self.origin + self.view_ofs + [0, 0, self.sview_height];
	barrel_pos += v_forward * 2;
	barrel_pos += v_right * offs;

	// view kick
	if (type == 1)
	{
		if (SEC_TO_FRAMES(self.clienttime) % 2)
		{
			self.punchangle[0] = max(-6, self.punchangle[0] - 2);
			self.sview_height += ((prandom(self.clienttime) * 1.5) - 0.5) * 4;
		}
	}
	else
	{
		self.punchangle[0] = max(-5, self.punchangle[0] - 1);
	}
	//
	
	projectile_c prj;// = spawn(projectile_c);
	if (PEvent_Projectile(self, prj))
	{
		setmodel(prj, "models/projectiles/proj_fang1.md3");
		prj.owner = self;
		prj.touch = W_Fang_Touch;
		
		setorigin(prj, barrel_pos);
		setsize(prj, '-0.25 -0.25 -0.25', '0.25 0.25 0.25');
		prj.solid = SOLID_TRIGGER;
		prj.effects 
		|= EF_FULLBRIGHT;

		prj.velocity = 2048 * v_forward;
		if (type == 1)
		{
			prj.velocity += v_right * ((prandom(self.clienttime + 7) * 2) - 1) * 32;
			prj.velocity += v_up * ((prandom(self.clienttime + 2) * 2) - 0.5) * 64;
		}

		prj.angles = vectoangles(prj.velocity);
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
		prj.nextthink = time + 5;

		prj.SendEntity = SendEntity_Projectile;
		//Entity_ForcePhysicsFrame(prj, 0.025);
	#endif
	}
}

void W_Spitter_ClientFrame()
{
	if (self.attack_frames)
		return;

	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	if (self.ammo_fangs <= 0)
	{
		if ((input_buttons & BUTTON_ALTFIRE) || (input_buttons & BUTTON_FIRE))
			self.weapon_wanted = PL_BestWeapon();
		return;
	}

	if (self.weapon_wanted)
		return;

	if (input_buttons & BUTTON_ALTFIRE)
	{
		self.weapon_mode |= WEAPON_FLAG_FIRED;
		wep_frame = 1;
		wep_phase = SPITTER_MODE_FIRE2;

		//self.effects |= EF_MUZZLEFLASH;
		wep_flags |= SPITTER_FLAG_MUZZLE;

		W_Spitter_FireProjectile(0, 1);
		
		self.attack_frames = 2;
		self.busy_frames = 5;
	}
	else if (input_buttons & BUTTON_FIRE)
	{
		self.weapon_mode |= WEAPON_FLAG_FIRED;
		wep_frame = 2;
		wep_phase = SPITTER_MODE_FIRE1;

		//self.effects |= EF_MUZZLEFLASH;
		wep_flags |= SPITTER_FLAG_MUZZLE;

		W_Spitter_FireProjectile(0, 1);
		
		self.attack_frames = 2;
		self.busy_frames = 5;
	}

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Spitter_Frame()
{
	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	if !(self.weapon_mode & WEAPON_FLAG_FIRED)
	{
		wep_flags = 0;
		//self.effects &= ~EF_MUZZLEFLASH;
	}

	self.weapon_mode &= ~WEAPON_FLAG_LOWFPS;
	switch (wep_phase)
	{
		case SPITTER_MODE_FIRE1:
			self.weapon_mode |= WEAPON_FLAG_LOWFPS;
			INCREMENT_FRAME
			if (self.attack_frames)
				break;

			if (!(input_buttons & BUTTON_FIRE) || (self.weapon_wanted))
			{
				wep_frame = 21;
				wep_phase = SPITTER_MODE_RECOVER;
				self.weapon_animfinish = 9;
				self.busy_frames = 2;
				PEvent_Sound(self, CHAN_AUTO, "weapons/spitter/fire1_release.wav", 1, ATTN_GUN);
				break;
			}

			self.attack_frames = 2;
			self.busy_frames = 5;
			float fireframe = 1;//(wep_frame % 2) == 1;
			if (fireframe)
			{
				if (self.ammo_fangs <= 0)
				{
					wep_frame = 21;
					wep_phase = SPITTER_MODE_RECOVER;
					self.weapon_animfinish = 9;
					self.busy_frames = 4;
					break;
				}

				wep_flags |= SPITTER_FLAG_MUZZLE;
				//self.effects |= EF_MUZZLEFLASH;
				float offset = ((((wep_frame % 2) == 1) * 2) - 1) * 3;
				offset *= 0.8 + (prandom(self.clienttime) * 0.2);
				offset += 4;
				W_Spitter_FireProjectile(0, offset);
			}

			if (wep_frame >= 20)
			{
				wep_frame = 2;
			}
		break;
		case SPITTER_MODE_FIRE2:
			if (!(input_buttons & BUTTON_ALTFIRE) || (self.weapon_wanted))
			{
				wep_frame = 21;
				wep_phase = SPITTER_MODE_RECOVER;
				self.weapon_animfinish = 9;
				self.busy_frames = 4;
				PEvent_Sound(self, CHAN_AUTO, "weapons/spitter/fire2_release.wav", 1, ATTN_GUN);
				break;
			}

			wep_frame++;
			self.attack_frames = 2;
			self.busy_frames = 5;
			float fireframe = 1;//(wep_frame % 2) == 1;
			if (fireframe)
			{
				if (self.ammo_fangs <= 0)
				{
					wep_frame = 21;
					wep_phase = SPITTER_MODE_RECOVER;
					self.weapon_animfinish = 9;
					self.busy_frames = 2;
					break;
				}

				wep_flags |= SPITTER_FLAG_MUZZLE;
				//self.effects |= EF_MUZZLEFLASH;
				float offset = ((((wep_frame % 2) == 1) * 2) - 1) * 3;
				offset *= 0.7 + (prandom(self.clienttime) * 0.5);
				offset += 4;
				W_Spitter_FireProjectile(1, offset);
			}

			if (wep_frame >= 20)
			{
				wep_frame = 2;
			}
		break;
		case SPITTER_MODE_DRAW:
			wep_frame++;
			if (!self.busy_frames)
			{
				wep_frame = 0;
				wep_phase = SPITTER_MODE_IDLE;
			}
		break;
		case SPITTER_MODE_RECOVER:
			wep_frame++;
		default:
			if (!self.weapon_animfinish)
			{
				wep_frame = 0;
				wep_phase = SPITTER_MODE_IDLE;
			}
		break;
	}

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Spitter_Init()
{
	weapon_t spitter;
	#ifdef CSQC
	precache_model("models/weapons/spitter/w_spitter.md3");
	precache_model("models/weapons/spitter/v_spitter.md3");
	precache_model("models/weapons/spitter/v_fangs.md3");
	spitter.render = W_Spitter_Render;
	spitter.hmodel = "models/weapons/spitter/w_spitter.md3";
	#endif
	precache_sound("weapons/spitter/fire1_release.wav");
	precache_sound("weapons/spitter/fire2_release.wav");
	precache_sound("impact/projectiles/slag1_explo2.ogg");
	precache_sound("weapons/spitter/raise.ogg");
	precache_sound("weapons/spitter/lower.ogg");
	for(float i = 1; i <= 5; i++)
		precache_sound(sprintf("weapons/spitter/fire1_%g.ogg", i));

	spitter.clientframe = W_Spitter_ClientFrame;
	spitter.frame = W_Spitter_Frame;
	spitter.putaway = W_Spitter_Putaway;
	spitter.takeout = W_Spitter_Draw;
	
	spitter.it_flag = ITEM::SPITTER;
	weaponlist[WEAPON::SPITTER] = spitter;
}
