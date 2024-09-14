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

#define ANTILAG_MAXREWIND 		0.12

const float M_PI = 3.14159265358979323846;

const float	FL_QUICKBOOST		= 0x800000;

const float CHAN_AUTO			= 0;
const float CHAN_WEAPON			= 1;
const float CHAN_VOICE			= 2;
const float CHAN_ITEM			= 3;
const float CHAN_BODY			= 4;
const float CHAN_PREDICT		= 32;
const float CHAN_PREDICT_AUTO	= 38;
const float CHAN_PREDICT_END	= 50;

const float ATTN_NONE			= 0;
const float ATTN_NORM			= 0.5;
const float ATTN_IDLE			= 1;
const float ATTN_STATIC			= 1.5;
const float ATTN_VOICE			= 0.45;
const float ATTN_SCREAM			= 0.4;
const float ATTN_GUN			= 0.35;
const float ATTN_EXPLODE		= 0.3;
const float ATTN_EXPLODE_BIG	= 0.25;
const float ATTN_PICKUP			= 0.35;
const float ATTN_STEP			= 0.5;

const float TRAP_STEP			= 0.2;
const float TRAP_PICKUP			= 0.7;

const float EF_ADDITIVE		= 32;
const float EF_BLUE			= 64;
const float EF_FLAME		= 1024;
const float EF_FULLBRIGHT	= 512;
const float EF_NODEPTHTEST	= 8192;
const float EF_NODRAW		= 16;
const float EF_NOSHADOW		= 4096;
const float EF_RED			= 128;
const float EF_STARDUST		= 2048;
const float EF_SELECTABLE 	= 16384;
const float EF_NOPVSCULL 	= 8192;

const float GEOMTYPE_NONE = -1;       // entity will be entirely skipped by ODE
const float GEOMTYPE_SOLID = 0;       // geometry type will be set based on .solid field
const float GEOMTYPE_BOX = 1;         // entity bound box
const float GEOMTYPE_SPHERE = 2;      // sphere with radius picked from x axis of entity bound box
const float GEOMTYPE_CAPSULE = 3;     // with leading axis automatically determined from longest one, radius is picked as minimal of the rest 2 axes
const float GEOMTYPE_TRIMESH = 4;     // triangle mesh
const float GEOMTYPE_CYLINDER = 5;    // like capsule but not capped
                                      // note that ODE's builtin cylinder support is experimental, somewhat bugged and unfinished (no cylinder-cylinder collision)
									  // to use properly working cylinder should build ODE with LIBCCD extension
const float GEOMTYPE_CAPSULE_X = 6;   // capsule with fixed leading axis
const float GEOMTYPE_CAPSULE_Y = 7;
const float GEOMTYPE_CAPSULE_Z = 8;
const float GEOMTYPE_CYLINDER_X	= 9;  // cylinder with fixed leading axis
const float GEOMTYPE_CYLINDER_Y	= 10;
const float GEOMTYPE_CYLINDER_Z	= 11;
.float geomtype;

// dp contents
float DPCONTENTS_SOLID = 1; // hit a bmodel, not a bounding box
float DPCONTENTS_WATER = 2;
float DPCONTENTS_SLIME = 4;
float DPCONTENTS_LAVA = 8;
float DPCONTENTS = 16;
float DPCONTENTS_BODY = 32; // hit a bounding box, not a bmodel
float DPCONTENTS_CORPSE = 64; // hit a SOLID_CORPSE entity
float DPCONTENTS_NODROP = 128; // an area where backpacks should not spawn
float DPCONTENTS_PLAYERCLIP = 256; // blocks player movement
float DPCONTENTS_MONSTERCLIP = 512; // blocks monster movement
float DPCONTENTS_DONOTENTER = 1024; // AI hint brush
float DPCONTENTS_LIQUIDSMASK = 14; // WATER | SLIME | LAVA
float DPCONTENTS_BOTCLIP = 2048; // AI hint brush
float DPCONTENTS_OPAQUE = 4096; // only fully opaque brushes get this (may be useful for line of sight checks)
float DPCONTENTS_INTERACTCLIP 	= 0x00002000;
float DPCONTENTS_WEAPONCLIP 	= 0x00004000;
float DPCONTENTS_BOSSCLIP 		= 0x00008000;
float DPCONTENTS_WRATHUNUSED3 	= 0x00010000;
float DPCONTENTS_WRATHUNUSED4 	= 0x00020000;
float DPCONTENTSMASK_WEAPON		= DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_WEAPONCLIP;

// deadflag values
float	DEAD_NO					= 0;
float	DEAD_DYING				= 1;
float	DEAD_DEAD				= 2;
float	DEAD_RESPAWNABLE		= 3;
float	DEAD_RESPAWNING			= 4; // dead, waiting for buttons to be released
.float 	deadflag;

// takedamage values
float	DAMAGE_NO				= 0;
float	DAMAGE_YES				= 1;
float	DAMAGE_AIM				= 2;
.float 	takedamage;

// modelflag values
float EF_NOMODELFLAGS = 8388608; // ignore any effects in a model file and substitute your own
float MF_ROCKET  =   1; // leave a trail
float MF_GRENADE =   2; // leave a trail
float MF_GIB     =   4; // leave a trail
float MF_ROTATE  =   8; // rotate (bonus items)
float MF_TRACER  =  16; // green split trail
float MF_ZOMGIB  =  32; // small blood trail
float MF_TRACER2 =  64; // orange split trail
float MF_TRACER3 = 128; // purple trail
.float modelflags;

entity newmis;
.entity owner;
.string target;
.string targetname;
.entity partner;
.vector movedir;
.vector mangle;
.float spawnflags;
.float using;
.float speed;
.float lip;
.string noise;
.string noise1;
.string noise2;
.string noise3;
.string noise4;
string string_null;

typedef struct lightparams_t
{
	float radius;
	float pflags;
	vector color;
	float lstyle;
};

.float light_lev;
.float pflags;
.vector color;
.float style;

#ifdef CSQC
void DynamicLight_Generic()
{
	adddynamiclight2(self.origin, self.light_lev, self.color, 0, "", self.pflags);
}
#endif

#define SET_DYNAMIC_LIGHT_PROPERTIES(e, dl) \
	e.light_lev = dl.radius; 				\
	e.pflags = dl.pflags;					\
	e.color = dl.color;						\
	e.style = dl.lstyle;

const lightparams_t dl_null = {
	0,
	0,
	'0 0 0',
	0
};

const lightparams_t dl_hpvial = {
	15,
	PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW | PFLAGS_LODFADE,
	'3 0 0',
	0
};

const lightparams_t dl_hpbeaker = {
	25,
	PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW | PFLAGS_LODFADE,
	'3 0 0',
	0
};

const lightparams_t dl_hpchalice = {
	32,
	PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW | PFLAGS_LODFADE,
	'3 0 0',
	0
};

const lightparams_t dl_readable = {
	32,
	PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW | PFLAGS_LODFADE,
	'1 1 0.5',
	0
};

const lightparams_t dl_cofferkey = {
	48,
	PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW | PFLAGS_LODFADE,
	'1 1 1',
	0
};

const lightparams_t dl_redkey = {
	48,
	PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW | PFLAGS_LODFADE,
	'1 0 0',
	0
};

const lightparams_t dl_bluekey = {
	48,
	PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW | PFLAGS_LODFADE,
	'0 0.2 1',
	0
};

const lightparams_t dl_yellowkey = {
	48,
	PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW | PFLAGS_LODFADE,
	'1 1 0',
	0
};

const lightparams_t dl_armor_shard = {
	20,
	PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW | PFLAGS_LODFADE,
	'0.9 0.9 1',
	0
};

const lightparams_t dl_armor_helm = {
	25,
	PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW | PFLAGS_LODFADE,
	'0.9 0.9 1',
	0
};

const lightparams_t dl_armor = {
	32,
	PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW | PFLAGS_LODFADE,
	'0.9 0.9 1',
	0
};

const lightparams_t dl_darkarmor_shard = {
	20,
	PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW | PFLAGS_LODFADE,
	'0.7 0.7 1',
	0
};

const lightparams_t dl_darkarmor_helm = {
	25,
	PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW | PFLAGS_LODFADE,
	'0.7 0.7 1',
	0
};

const lightparams_t dl_darkarmor = {
	32,
	PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW | PFLAGS_LODFADE,
	'0.7 0.7 1',
	0
};

