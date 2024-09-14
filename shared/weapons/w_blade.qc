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

#ifdef CSQC
#include "client.h"

static float blade_glow;
void W_Blade_Render()
{
	setmodel(viewmodel, "models/weapons/melee/v_gauntlet.md3");
	viewmodel.origin += (v_right * 7);
	viewmodel.origin += (v_up * -7);
	viewmodel.origin += (v_forward * 4);

	float old_frametime = viewmodel.frame1time;
	float old_frame = viewmodel.frame;
	float wep_frame = viewmodel.weapon_mode & 0x0FF0 >> 4;
	viewmodel.frame = wep_frame;

	/*
	if (old_clientframe != SEC_TO_FRAMES(self.clienttime))
		viewmodel.lerpfrac = 0;

	if (old_animfinish < self.weapon_animfinish)
	{
		viewmodel.frame1time = time;
	}
	
	if (old_weapon != self.weapon)
	{
		viewmodel.lerpfrac = 0;
		viewmodel.frame2 = viewmodel.frame;
		viewmodel.frame2time = viewmodel.frame1time;
	}
	else if (old_frame != wep_frame || old_animfinish < self.weapon_animfinish)
	{
		viewmodel.lerpfrac = 1;
		viewmodel.frame2 = old_frame;
		viewmodel.frame2time = old_frametime;
	}

	if (viewmodel.lerpfrac > 0)
	{
		float frac = self.clienttime / FRAMETIME;
		frac -= floor(frac);
		frac = 1 - frac;
		viewmodel.lerpfrac = frac;
	}
	*/

	addentity(viewmodel);

	float tag_blade = gettagindex(viewmodel, "tag_blade");

	setmodel(viewmodel2, "models/weapons/melee/v_blade.md3");
	setorigin(viewmodel2, gettaginfo(viewmodel, tag_blade));
	viewmodel2.angles = vectoangles2(v_forward, v_up);
	
	// blade glow
	if (wep_frame >= 5 && wep_frame <= 25)
		blade_glow = min(1, blade_glow + (frametime * 0.8));
	else
		blade_glow = max(0, blade_glow - (frametime * 1.6));
	viewmodel2.glowmod = (vector)max(0.01, round(blade_glow * 8) / 8);
	addentity(viewmodel2);
	viewmodel2.glowmod = 0;
	//

	// blade blood
	if (self.weapon_mode & 0x2000)
	{
		setmodel(viewmodel2, "models/weapons/melee/v_blade_blood.md3");
		addentity(viewmodel2);
	}
	//
}
#endif

void W_Blade_Boost()
{
	makevectors(input_angles);
	self.attack_frames += SEC_TO_FRAMES(1);

	#ifdef SSQC // send blade dash effect
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TEMPENT::BLADEDASH);
	WriteShort(MSG_BROADCAST, num_for_edict(self));
	#endif
	
	float jboost;
	if (self.flags & FL_ONGROUND)
		jboost = 96;
	else
		jboost = 120;
	
	vector old_velocity = self.velocity;
	if (input_angles[0] < 45)
	{
		float vcfactor = 1;
		vcfactor = 1 - fabs(input_angles[0] / 90);

		vector currspeed = [self.velocity[0], self.velocity[1], 0];
		vector wishspeed;
		wishspeed = v_forward * 430 * vcfactor;
		wishspeed[2] *= 2;
		
		//currspeed = (v_forward * currspeed) * v_forward;
		float target_spd = 512;
		if (self.flags & FL_ONGROUND)
			target_spd = 768;

		currspeed += wishspeed;
		currspeed = v_forward * bound(target_spd, v_forward * currspeed, 1024);

		self.velocity[0] = currspeed[0];
		self.velocity[1] = currspeed[1];
		self.velocity[2] = bound((self.flags & FL_ONGROUND) ? 0: -120, wishspeed[2] * 0.6, 200);
	}
	else
	{
		local float vrange;
		vrange = 90 / input_angles[0]; 
		self.velocity = v_forward;
		self.velocity = self.velocity * 500 * vrange;
	}

	self.velocity[2] += jboost;
	if (self.velocity[2] > 0)
		self.flags &= ~FL_ONGROUND;

	// we shouldn't be able to SLOW down
	if (vlen([old_velocity[0], old_velocity[1], 0]) > vlen([self.velocity[0], self.velocity[1], 0]))
	{
		vector new_vec = normalize(self.velocity) * vlen(old_velocity);
		self.velocity[0] = new_vec[0];
		self.velocity[1] = new_vec[1];
	}
}

#define BLADE_MODE_IDLE			0x0
#define BLADE_MODE_CHARGE 		0x1
#define BLADE_MODE_STAB 		0x2
#define BLADE_MODE_SWING 		0x4
#define BLADE_MODE_DRAW 		0x8

void W_Blade_Putaway()
{
	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	wep_frame = 50;
	wep_phase = BLADE_MODE_DRAW;
	self.busy_frames = 5;
	self.attack_frames = 5;

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Blade_Draw()
{
	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	wep_frame = 45;
	wep_phase = BLADE_MODE_DRAW;
	self.weapon_animfinish = 5;
	self.busy_frames = 3;
	self.attack_frames = 2;

	PEvent_Sound(self, CHAN_AUTO, sprintf("weapons/melee/select%g.ogg", floor(random() * 2) + 1), 1, ATTN_STATIC);
	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Blade_Frame()
{
	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xC000 >> 12;

	if (!self.attack_frames)
	{
		if (input_buttons & BUTTON_ALTFIRE)
		{
			wep_phase = BLADE_MODE_CHARGE;
			wep_frame = 5;
			self.busy_frames = 3;
			self.attack_frames = 2;
		}
		else if (input_buttons & BUTTON_FIRE)
		{	
			wep_frame = 1 + (SEC_TO_FRAMES(self.clienttime * 983) % 4);
			wep_phase = BLADE_MODE_SWING;
			self.busy_frames = 9;
			self.attack_frames = 12;
			self.weapon_animfinish = 19;
			PEvent_Sound(self, CHAN_AUTO, sprintf("weapons/melee/attack%g.ogg", floor(random() * 4) + 1), 1, ATTN_GUN);

			makevectors(input_angles);
			W_FireHitscan2(v_forward, 0, 35, 230, 72);
		}
	}

	switch (wep_phase)
	{
		case BLADE_MODE_CHARGE:
			wep_frame = min(wep_frame + 1, 25);

			self.attack_frames = max(self.attack_frames, 2);
			if (wep_frame >= 7)
			{
				if !(input_buttons & BUTTON_ALTFIRE)
				{
					W_Blade_Boost();
					wep_phase = BLADE_MODE_STAB;
					wep_frame = 25;
					self.attack_frames = 15;
					self.busy_frames = 6;
					PEvent_Sound(self, CHAN_AUTO, sprintf("weapons/melee/attack%g.ogg", floor(random() * 8) + 1), 1, ATTN_GUN);
				}
			}
		break;
		case BLADE_MODE_STAB:
			wep_frame++;
			if (wep_frame < 35)
			{
				makevectors(input_angles);
				if (self.velocity * v_forward > -10)
				{
					W_FireHitscan2(v_forward, 0, 15, 120, 96);
				}
			}
			if (wep_frame > 45)
			{
				wep_frame = 0;
				wep_phase = BLADE_MODE_IDLE;
			}
		break;
		case BLADE_MODE_DRAW:
			wep_frame++;
			if (!self.busy_frames && !self.weapon_animfinish)
			{
				wep_frame = 0;
				wep_phase = BLADE_MODE_IDLE;
			}
		break;
		default:
			if (!self.weapon_animfinish)
			{
				wep_frame = 0;
				wep_phase = BLADE_MODE_IDLE;
			}
		break;
	}

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Blade_Init()
{
	weapon_t blade;
	precache_sound("weapons/melee/select1.ogg");
	precache_sound("weapons/melee/select2.ogg");
	for(float i = 1; i <= 8; i++)
		precache_sound(sprintf("weapons/melee/attack%g.ogg", i));

	#ifdef CSQC
	precache_model("models/weapons/melee/v_gauntlet.md3");
	precache_model("models/weapons/melee/v_blade.md3");
	precache_model("models/weapons/melee/v_blade_blood.md3");

	setmodel(viewmodel, "models/weapons/melee/v_gauntlet.md3");

	blade.render = W_Blade_Render;
	#endif
	blade.frame = W_Blade_Frame;
	blade.putaway = W_Blade_Putaway;
	blade.takeout = W_Blade_Draw;
	
	blade.it_flag = ITEM::BLADE;
	weaponlist[WEAPON::BLADE] = blade;
}
