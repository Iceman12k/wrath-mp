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

#pragma once
#define WEAPON_FLAG_PUTAWAY		0x040000
#define WEAPON_FLAG_FIRED		0x080000
#define WEAPON_FLAG_LOWFPS		0x100000
#define WEAPON_FLAG_RESERVED	0xFC0000
#include "physics.h"

.float deaths;
.float frags;

enum WEAPON:float {
	NULL,
	BLADE,
	COACHGUN,
	SHOTGUN,
	SPITTER,
	RETCHER,
	SLAGCANNON,
	LANCE,
	CRYSTAL,
	MACE,
	MAX
};

enumflags ITEM:float {
	BLADE,
	COACHGUN,
	SHOTGUN,
	SPITTER,
	RETCHER,
	SLAGCANNON,
	CRYSTAL,
	LANCE,
};

typedef struct {
	#ifdef CSQC
	void() render;
	string hmodel;
	#endif
	void() clientframe;
	void() frame;
	void() takeout;
	void() putaway;

	float it_flag;
} weapon_t;

weapon_t weaponlist[WEAPON::MAX];

class projectile_c;
projectile_c projectile_list;

class projectile_c
{
	nonvirtual void(entity edict, .genericnet_t net_storage) structtoedict = {
		projectile_c ent = (projectile_c)edict;
		ent.origin = ent.net_storage.origin;
		ent.angles = ent.net_storage.angles;
		ent.velocity = ent.net_storage.velocity;
		ent.cmovetype = ent.net_storage.cmovetype;
		ent.owner = ent.net_storage.owner;
	};

	nonvirtual void(entity edict, .genericnet_t net_storage) edicttostruct = {
		projectile_c ent = (projectile_c)edict;
		ent.net_storage.origin = ent.origin;
		ent.net_storage.angles = ent.angles;
		ent.net_storage.velocity = ent.velocity;
		ent.net_storage.cmovetype = ent.cmovetype;
		ent.net_storage.owner = ent.owner;
	};

	nonvirtual void(entity edict, .genericnet_t from, .genericnet_t to) structtostruct = {
		projectile_c ent = (projectile_c)edict;
		ent.to = ent.from;
	};

	float framenumber;
	float xerp;
#ifdef CSQC
	vector start_origin;
	vector start_velocity;
	float start_time;
	float collision_frame;

	projectile_c _next;

	virtual void() RemoveEntity {
		projectile_c hld;
		for(projectile_c lst = projectile_list; lst; hld = lst, lst = lst._next)
		{
			if (lst != this)
				continue;
			if (projectile_list == lst)
				projectile_list = lst._next;
			else
				hld._next = lst._next;
			break;
		}
		remove(this);
	};

	virtual void() projectile_c {
		this._next = projectile_list;
		projectile_list = this;
	};
#endif
};

float wep_phase;
float wep_frame;
float wep_flags;

float old_animfinish;
float old_clientframe;
float old_weapon;

#ifdef SSQC
.float damage_given;
.float damage_taken;
.float hitbeep_flags;
.float hitbeep_data; // the data we sync to the client via a stat
#endif
enumflags HITBEEP:float {
	NULL = 0,
	FRIENDLYFIRE,
};

#ifdef CSQC
class viewmodel_c {

};
viewmodel_c viewmodel;
viewmodel_c viewmodel2;

void W_Render();
#endif

float PL_BestWeapon();
void Projectile_Physics();
projectile_c Projectile_Prediction();
void W_FireHitscan2(vector dir, float dflag, float damage, float knockback, float range);
void W_FireHitscan(vector dir, float dflag, float damage, float knockback);
#ifdef SSQC
float SendEntity_Projectile(entity to, float sendflags);
#endif

#define INCREMENT_FRAME 																	\
	if (!(self.weapon_mode & WEAPON_FLAG_LOWFPS) || (SEC_TO_FRAMES(self.clienttime) % 2)) 	\
	{																						\
		wep_frame++;																		\
	}																						\

void W_Init();
void ClientServerFrame();

