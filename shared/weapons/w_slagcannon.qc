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

#define SLAG_FLAG_MUZZLE	0x1
#define SLAG_FLAG_MUZZLE2	0x2

#ifdef CSQC
#include "client.h"

static float gunglow;
void W_Slag_Render()
{
	setmodel(viewmodel, "models/weapons/cannon/v_cannon.md3");
	viewmodel.origin += (v_right * 9);
	viewmodel.origin += (v_up * -9);
	viewmodel.origin += (v_forward * 17);

	float old_frametime = viewmodel.frame1time;
	float old_frame = viewmodel.frame;
	float wep_frame = viewmodel.weapon_mode & 0x0FF0 >> 4;
	float wep_flags = viewmodel.weapon_mode & 0x3000 >> 12;
	viewmodel.frame = wep_frame;
	
	if (wep_flags)
	{
		viewmodel.effects |= EF_MUZZLEFLASH;
		if (wep_flags & SLAG_FLAG_MUZZLE2)
			gunglow = 1.7;
		else
			gunglow = min(gunglow + (frametime * 6), 1.2);
	}
	else
		gunglow -= frametime * 0.9;
	gunglow = max(0.01, gunglow);

	
	float stime = round(time * 5) / 5;
	stime = prandom(stime);
	float v_glow = min(gunglow + (0.6 + stime * 0.2), 1);
	viewmodel.glowmod = [v_glow, v_glow, v_glow];


	addentity(viewmodel);


	float tag_pipes = gettagindex(viewmodel, "tag_pipes");
	setmodel(viewmodel2, "models/weapons/cannon/v_pipes.md3");
	setorigin(viewmodel2, gettaginfo(viewmodel, tag_pipes));
	viewmodel2.angles = vectoangles2(v_forward, v_up);

	float p_glow = min(gunglow, 1);
	viewmodel2.glowmod = [p_glow, p_glow, p_glow];

	addentity(viewmodel2);
}
#endif

#define SLAG_MODE_IDLE		0x0
#define SLAG_MODE_FIRE1 	0x1
#define SLAG_MODE_FIRE2		0x2
#define SLAG_MODE_DRAW 		0x4

void W_Slag_Putaway()
{
	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	wep_frame = 50;
	wep_phase = SLAG_MODE_DRAW;
	self.busy_frames = 6;
	self.attack_frames = 6;

	PEvent_Sound(self, CHAN_AUTO, "weapons/cannon/lower.ogg", 1, ATTN_STATIC);

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Slag_Draw()
{
	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	wep_frame = 42;
	wep_phase = SLAG_MODE_DRAW;
	self.busy_frames = 7;
	self.attack_frames = 5;

	PEvent_Sound(self, CHAN_AUTO, "weapons/cannon/raise.ogg", 1, ATTN_STATIC);

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

#define SLAGBALL_RADIUS 120
#define SLAGBALL_KNOCKBACK 240
#define SLAGBALL_DAMAGE 40
void W_Slagball_Touch()
{
	projectile_c prj = (projectile_c)self;
	entity dealer = prj.owner;
	prj.owner = world;

	self.cmovetype = MOVETYPE_NONE;

	if (other.takedamage)
	{
		vector l_org = (other.absmin + other.absmax) / 2;
		vector diff = (l_org - prj.origin);
		PL_TakeDamage(normalize(diff) * SLAGBALL_KNOCKBACK, SLAGBALL_DAMAGE, 0, dealer, other);
	}

	entity lst = findradius(prj.origin, SLAGBALL_RADIUS + 32);
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
		float points = 1 - (vlen(diff) / SLAGBALL_RADIUS);
		if (points < 0)
			continue;
		points = bound(0.15, points, 0.95);

		PL_TakeDamage(normalize(diff_mid) * SLAGBALL_KNOCKBACK * points, SLAGBALL_DAMAGE * points, 0, dealer, lst);
	}
#ifdef SSQC
	soundwrath(prj, CHAN_AUTO, sprintf("impact/projectiles/slag1_explo%g.ogg", (floor(random() *3) + 1)), 1, ATTN_EXPLODE, 100 + (crandom() * 5), 0, 0);
	pointparticles(particleeffectnum("slag"), prj.origin, trace_plane_normal * (-550), 1);

	remove(prj);
#endif
}

#define SLAGROCKET_RADIUS 256
#define SLAGROCKET_KNOCKBACK 700
#define SLAGROCKET_DAMAGE 90
void W_Slagrocket_Touch()
{
	projectile_c prj = (projectile_c)self;
	entity dealer = prj.owner;
	prj.owner = world;

	self.cmovetype = MOVETYPE_NONE;

	if (other.takedamage)
	{
		vector l_org = (other.absmin + other.absmax) / 2;
		vector diff = (l_org - prj.origin);
		PL_TakeDamage(normalize(diff) * SLAGROCKET_KNOCKBACK, SLAGROCKET_DAMAGE, 0, dealer, other);
	}

	entity lst = findradius(prj.origin, SLAGROCKET_RADIUS + 32);
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
		float points = 1 - (vlen(diff) / SLAGROCKET_RADIUS);
		if (points < 0)
			continue;
		points = bound(0.15, points, 0.95);

		PL_TakeDamage(normalize(diff_mid) * SLAGROCKET_KNOCKBACK * points, SLAGROCKET_DAMAGE * points, 0, dealer, lst);
	}
#ifdef SSQC
	soundwrath(prj, CHAN_AUTO, sprintf("impact/projectiles/slag2_explo%g.ogg", (floor(random() *3) + 1)), 1, ATTN_EXPLODE_BIG, 0, 0, 0);
	pointparticles(particleeffectnum("slag2"), prj.origin, trace_plane_normal * (-550), 1);

	remove(prj);
#endif
}

void W_Slag_FireProjectile()
{
	if (self.ammo_ore <= 0)
		return;

	self.ammo_ore--;

	makevectors(input_angles + self.punchangle);

	self.punchangle[0] -= 1;
	PEvent_Sound(self, CHAN_WEAPON, sprintf("weapons/cannon/fire1_%g.ogg", floor(random() * 5) + 1), 1, ATTN_GUN);

	projectile_c prj;// = spawn(projectile_c);
	if (PEvent_Projectile(self, prj))
	{
		setmodel(prj, "models/projectiles/proj_slag1.md3");
		prj.owner = self;
		prj.angles = input_angles;
		prj.angles[0] *= -1;

		prj.touch = W_Slagball_Touch;
		
		vector barrel_pos = self.origin + self.view_ofs + [0, 0, self.sview_height];
		barrel_pos += v_forward * 4;
		setorigin(prj, barrel_pos);
		setsize(prj, '0 0 0', '0 0 0');
		prj.solid = SOLID_BBOX;

		prj.velocity = 1800 * v_forward;

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

void W_Slag_FireRocket()
{
	makevectors(input_angles + self.punchangle);

	self.punchangle[0] -= 5;
	PEvent_Sound(self, CHAN_WEAPON, sprintf("weapons/cannon/fire2_%g.ogg", floor(random() * 5) + 1), 1, ATTN_GUN);

	projectile_c prj;// = spawn(projectile_c);
	if (PEvent_Projectile(self, prj))
	{
		setmodel(prj, "models/projectiles/proj_slag2.md3");
		prj.owner = self;
		prj.angles = input_angles;
		prj.angles[0] *= -1;

		prj.touch = W_Slagrocket_Touch;
		
		vector barrel_pos = self.origin + self.view_ofs + [0, 0, self.sview_height];
		barrel_pos += v_forward * 4;
		setorigin(prj, barrel_pos);
		setsize(prj, '-2 -2 -2', '2 2 2');
		prj.solid = SOLID_BBOX;

		prj.velocity = 1440 * v_forward;

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


void W_Slag_ClientFrame()
{
	if (self.attack_frames)
		return;

	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	if (self.ammo_ore <= 0)
	{
		if ((input_buttons & BUTTON_ALTFIRE) || (input_buttons & BUTTON_FIRE))
			self.weapon_wanted = PL_BestWeapon();
		return;
	}

	if (input_buttons & BUTTON_ALTFIRE)
	{
		self.weapon_mode |= WEAPON_FLAG_FIRED;
		wep_frame = 20;
		wep_phase = SLAG_MODE_FIRE2;

		self.ammo_ore = max(0, self.ammo_ore - 3);

		self.effects |= EF_MUZZLEFLASH;
		wep_flags |= SLAG_FLAG_MUZZLE2;

		W_Slag_FireRocket();

		self.weapon_animfinish = 21;
		self.attack_frames = 17;
		self.busy_frames = 5;
	}
	else if (input_buttons & BUTTON_FIRE)
	{
		self.weapon_mode |= WEAPON_FLAG_FIRED;
		wep_frame = 2;
		wep_phase = SLAG_MODE_FIRE1;

		self.effects |= EF_MUZZLEFLASH;
		wep_flags |= SLAG_FLAG_MUZZLE;

		W_Slag_FireProjectile();
		
		self.weapon_animfinish = 6;
		self.attack_frames = 9;
		self.busy_frames = 5;
	}

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Slag_Frame()
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
		case SLAG_MODE_FIRE1:
			wep_frame++;
			if ((wep_frame == 6 || (wep_frame == 8 && input_buttons & BUTTON_FIRE)))
			{
				if (self.ammo_ore <= 0)
				{
					wep_frame = 0;
					wep_phase = SLAG_MODE_IDLE;
					break;
				}

				if (wep_frame == 8)
				{
					self.weapon_animfinish = 6;
					self.attack_frames = 9;
					self.busy_frames = 5;
					wep_frame = 2;
				}

				wep_flags |= SLAG_FLAG_MUZZLE;
				self.effects |= EF_MUZZLEFLASH;
				W_Slag_FireProjectile();
			}

			if (!self.weapon_animfinish)
			{
				wep_frame = 0;
				wep_phase = SLAG_MODE_IDLE;
			}
		break;
		case SLAG_MODE_FIRE2:
			wep_frame++;
			if (!self.weapon_animfinish)
			{
				wep_frame = 0;
				wep_phase = SLAG_MODE_IDLE;
			}
		break;
		case SLAG_MODE_DRAW:
			wep_frame++;
			if (!self.busy_frames)
			{
				wep_frame = 0;
				wep_phase = SLAG_MODE_IDLE;
			}
		break;
		default:
			if (!self.weapon_animfinish)
			{
				wep_frame = 0;
				wep_phase = SLAG_MODE_IDLE;
			}
		break;
	}

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Slag_Init()
{
	weapon_t slagcannon;
	#ifdef CSQC
	precache_model("models/weapons/cannon/w_cannon.md3");
	precache_model("models/weapons/cannon/v_cannon.md3");
	precache_model("models/weapons/cannon/v_pipes.md3");
	slagcannon.render = W_Slag_Render;
	slagcannon.hmodel = "models/weapons/cannon/w_cannon.md3";
	#endif
	precache_model("models/projectiles/proj_slag1.md3");
	precache_model("models/projectiles/proj_slag2.md3");
	precache_sound("impact/projectiles/slag1_explo1.ogg");
	precache_sound("impact/projectiles/slag1_explo2.ogg");
	precache_sound("impact/projectiles/slag1_explo3.ogg");
	precache_sound("impact/projectiles/slag2_explo1.ogg");
	precache_sound("impact/projectiles/slag2_explo2.ogg");
	precache_sound("impact/projectiles/slag2_explo3.ogg");
	precache_sound("weapons/cannon/raise.ogg");
	precache_sound("weapons/cannon/lower.ogg");
	for(float i = 1; i <= 5; i++)
		precache_sound(sprintf("weapons/cannon/fire1_%g.ogg", i));
	for(float i = 1; i <= 5; i++)
		precache_sound(sprintf("weapons/cannon/fire2_%g.ogg", i));

	slagcannon.clientframe = W_Slag_ClientFrame;
	slagcannon.frame = W_Slag_Frame;
	slagcannon.putaway = W_Slag_Putaway;
	slagcannon.takeout = W_Slag_Draw;
	
	slagcannon.it_flag = ITEM::SLAGCANNON;
	weaponlist[WEAPON::SLAGCANNON] = slagcannon;
}
