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

#ifdef SSQC

void te_lance(entity who, vector trail_start, vector trail_end)
{
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TEMPENT::LANCEBEAM);
	WriteShort(MSG_BROADCAST, num_for_edict(who));
	WriteVectorL(MSG_BROADCAST, trail_start);
	WriteVectorL(MSG_BROADCAST, trail_end);
}

#endif
#ifdef CSQC
#include "client.h"

.vector start;
.vector end;
void te_lance_predraw(void)
{
	entity bez = self;

	if (time > bez.health)
	{
		bez.alpha -= frametime;
		if (bez.alpha < 0)
		{
			remove(bez);
			return;
		}
	}


	float segment_length = 32;
    float segments_needed = ceil(vlen(bez.start - bez.end) / segment_length);
    vector curr_org = bez.start;
    vector last_org = curr_org;
    vector diff = normalize(bez.end - bez.start); // this might be flipped, I always get it mixed up
    vector angs = vectoangles(diff);
	setmodel(bez, "models/projectiles/proj_railb.md3");

    for(float i = 0; i < segments_needed; i++)
    {
        curr_org = last_org + (normalize(diff) * segment_length);
        bez.angles = angs;
        bez.origin = last_org;
        addentity(bez);
        last_org = curr_org;
    }

	setmodel(bez, "models/projectiles/proj_raila.md3");
	bez.origin = last_org;
	addentity(bez);

	bez.modelindex = 0;
}

void te_lance(vector trail_start, vector trail_end)
{
	entity te = spawn();
	te.start = trail_start;
	te.end = trail_end;

	te.predraw = te_lance_predraw;
	te.drawmask = MASK_ENGINE;
	te.health = time + 0.5;
	te.alpha = 0.8;
}

void TempEnt_LanceBeam(void)
{
	float own = ReadShort();
	vector st = ReadVectorL();
	vector ed = ReadVectorL();
	te_lance(st, ed);
}

static float fang_spin_lerpfrac;
static float fang_spin_oldframe;
static float fang_spin;
void W_Lance_Render()
{
	setmodel(viewmodel, "models/weapons/lance/v_lance.md3");
	viewmodel.origin += (v_right * 6);
	viewmodel.origin += (v_up * -6);
	viewmodel.origin += (v_forward * 12);

	float old_frametime = viewmodel.frame1time;
	float old_frame = viewmodel.frame;
	float wep_frame = viewmodel.weapon_mode & 0x0FF0 >> 4;
	float wep_flags = viewmodel.weapon_mode & 0x3000 >> 12;
	viewmodel.frame = wep_frame;
	viewmodel.glowmod = 0;


	addentity(viewmodel);
}
#endif

#define LANCE_MODE_IDLE			0x0
#define LANCE_MODE_FIRE1 		0x1
#define LANCE_MODE_FIRE2		0x2
#define LANCE_MODE_RECOVER 		0x3
#define LANCE_MODE_DRAW 		0x4

void W_Lance_Putaway()
{
	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	wep_frame = 8;
	wep_phase = LANCE_MODE_DRAW;
	self.busy_frames = 2;
	self.attack_frames = 2;

	PEvent_Sound(self, CHAN_AUTO, sprintf("weapons/lance/lance_deselect%.0f.ogg", floor(random() * 3) + 1), 1, ATTN_STATIC);

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Lance_Draw()
{
	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	wep_frame = 3;
	wep_phase = SPITTER_MODE_DRAW;
	self.busy_frames = 4;
	self.attack_frames = 4;

	PEvent_Sound(self, CHAN_AUTO, sprintf("weapons/lance/lance_select%.0f.ogg", floor(random() * 3) + 1), 1, ATTN_STATIC);

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Lance_FireProjectile(void)
{
	if (self.ammo_lances <= 0)
		return;

	self.ammo_lances--;

	makevectors(input_angles + self.punchangle);
	PEvent_Sound(self, CHAN_WEAPON, sprintf("weapons/lance/fire%.0f.ogg", floor(random() * 3) + 1), 1, ATTN_GUN);

	vector view_pos = self.origin + self.view_ofs + [0, 0, self.sview_height];
	vector barrel_pos = view_pos;
	barrel_pos += v_forward * 32;
	barrel_pos += v_right * 6;
	barrel_pos += v_up * -6;

	W_FireHitscan(v_forward, 0, 100, 800);
	#ifdef SSQC
	traceline(barrel_pos, view_pos + v_forward * 4096, MOVE_NOMONSTERS, self);
	te_lance(self, barrel_pos, trace_endpos);
	#endif
	#ifdef CSQC
	//traceline(barrel_pos, view_pos + v_forward * 4096, MOVE_NOMONSTERS, self);
	//te_lance(barrel_pos, trace_endpos);
	#endif

	// view kick
	self.punchangle[0] = max(-5, self.punchangle[0] - 1);
	//
}

void W_Lance_ClientFrame()
{
	if (self.attack_frames)
		return;

	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	if (self.ammo_lances <= 0)
	{
		if ((input_buttons & BUTTON_ALTFIRE) || (input_buttons & BUTTON_FIRE))
			self.weapon_wanted = PL_BestWeapon();
		return;
	}

	if (self.weapon_wanted)
		return;

	if (input_buttons & BUTTON_FIRE)
	{
		self.weapon_mode |= WEAPON_FLAG_FIRED;
		wep_frame = 2;
		wep_phase = LANCE_MODE_FIRE1;

		self.effects |= EF_MUZZLEFLASH;

		W_Lance_FireProjectile();
		
		self.attack_frames = 40;
		self.busy_frames = 34;
		self.weapon_animfinish = 40;
	}

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Lance_Frame()
{
	wep_phase = self.weapon_mode & 0x000F;
	wep_frame = self.weapon_mode & 0x0FF0 >> 4;
	wep_flags = self.weapon_mode & 0xF000 >> 12;

	if !(self.weapon_mode & WEAPON_FLAG_FIRED)
	{
		wep_flags = 0;
		self.effects &= ~EF_MUZZLEFLASH;
	}

	self.weapon_mode &= ~WEAPON_FLAG_LOWFPS;
	switch (wep_phase)
	{
		case LANCE_MODE_DRAW:
			wep_frame++;
			if (!self.busy_frames)
			{
				wep_frame = 0;
				wep_phase = SPITTER_MODE_IDLE;
			}
		break;
		default:
			if (!self.weapon_animfinish)
			{
				wep_frame = 0;
				wep_phase = LANCE_MODE_IDLE;
			}
		break;
	}

	self.weapon_mode = wep_phase | (wep_frame << 4) | (wep_flags << 12) | (self.weapon_mode & WEAPON_FLAG_RESERVED);
}

void W_Lance_Init()
{
	weapon_t lance;
	#ifdef CSQC
	precache_model("models/projectiles/proj_raila.md3");
	precache_model("models/projectiles/proj_railb.md3");
	precache_model("models/weapons/lance/w_lance.md3");
	precache_model("models/weapons/lance/v_lance.md3");
	lance.render = W_Lance_Render;
	lance.hmodel = "models/weapons/lance/w_lance.md3";
	#endif
	for(float i = 1; i <= 3; i++)
		precache_sound(sprintf("weapons/lance/fire%g.ogg", i));
	for(float i = 1; i <= 3; i++)
		precache_sound(sprintf("weapons/lance/lance_select%g.ogg", i));
	for(float i = 1; i <= 3; i++)
		precache_sound(sprintf("weapons/lance/lance_deselect%g.ogg", i));

	lance.clientframe = W_Lance_ClientFrame;
	lance.frame = W_Lance_Frame;
	lance.putaway = W_Lance_Putaway;
	lance.takeout = W_Lance_Draw;
	
	lance.it_flag = ITEM::LANCE;
	weaponlist[WEAPON::LANCE] = lance;
}
