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
#define THINKFPS	20
#define FRAMETIME 	(1 / THINKFPS)
#define SEC_TO_FRAMES(s) (ceil(s/FRAMETIME))
#define FRAME_TO_SECS(f) (f*FRAMETIME)

enum NENT:float {
	NULL,
	Player,
	ItemPickup,
	Projectile,
	PredEvent,
	ScoreboardEntry,
};

enum STAT:float {
	// hacked in global fields
	GLOBALFIELDS = 100,
	PM_MAXSPEED,
	PM_FRICTION,
	PM_ACCELERATE,
	PM_STOPSPEED,
	PM_EDGEFRICTION,
	PM_GRAVITY,
	PM_STEPHEIGHT,
	SV_TICRATE,
	SV_FRAMENUM,
	GAMETIME_START,
	GAMETIME_END,
	GLOBALFIELDS_END,

	// normal local stats
	LOCALFIELDS = 150,
	PING,
	SATURATION,
	HEALTHHAZE,
	ZOOM,
	HITBEEP_DATA,
};

enum TEMPENT:float {
	CUSTOMSTART = 100,
	NOTIFICATION,
	KILLFEED,
	BLADEDASH,
	LANCEBEAM,
	FIXANGLE,
};

enumflags NOTIFICATIONFLAG:float {
	TIMESTAMP,
};

enumflags U:float {
	ORIGIN, 		// 0x00000001
	VELOCITY,		// 0x00000002
	ANGLES,			// 0x00000004
	MOVETYPE,		// 0x00000008
	FLAGS,			// 0x00000010
	WEAPON,			// 0x00000020
	CFRAME,			// 0x00000040
	MOREBYTES16,	// 0x00000080
	MODEL,			// 0x00000100
	FRAME,			// 0x00000200
	HEALTH,			// 0x00000400
	WEAPON2,		// 0x00000800
	ITEMS,			// 0x00001000
	AMMO1,			// 0x00002000
	AMMO2,			// 0x00004000
	MOREBYTES24,	// 0x00008000
	HEALTH2,		// 0x00010000
	MOVETYPE2,		// 0x00020000
	RES13,			// 0x00040000
	RES14,			// 0x00080000
	RES15,			// 0x00100000
	RES16,			// 0x00200000
	RES17,			// 0x00400000
	MOREBYTES32,	// 0x00800000
	RES18,			// 0x01000000
	RES19,			// 0x02000000
	RES20,			// 0x04000000
	RES21,			// 0x08000000
	RES22,			// 0x10000000
	RES23,			// 0x20000000
	RES24,			// 0x40000000
	RES25,			// 0x80000000
};

enumflags LF:float {
	LOCAL,
	SPECTATOR,
	REMOTE,
};

typedef struct {
	vector origin;
	vector angles;
	vector velocity;
	float status;
	float cmovetype;
	entity owner;
} genericnet_t;

#define BUTTON_FIRE		0x0001
#define BUTTON_JUMP		0x0002
#define BUTTON_ALTFIRE	0x0004
#define BUTTON_CROUCH	0x0008
#define BUTTON_WALK		0x0040

#ifdef SSQC
#define INIT_NETFUNCS(ed)						\
	ed.NetEdictToStruct = ed.edicttostruct;		\
	ed.NetStructToEdict = ed.structtoedict;		\
	ed.NetStructToStruct = ed.structtostruct;	\
	ed.NetDelta = ed.delta;						
#else
#define INIT_NETFUNCS(ed)						\
	ed.NetEdictToStruct = ed.edicttostruct;		\
	ed.NetStructToEdict = ed.structtoedict;		\
	ed.NetStructToStruct = ed.structtostruct;	
#endif

.void(entity ent, .genericnet_t net_storage) NetStructToEdict;
.void(entity ent, .genericnet_t net_storage) NetEdictToStruct;
.void(entity ent, .genericnet_t from, .genericnet_t to) NetStructToStruct;
.float clienttime;
.float framenumber;
#ifdef CSQC
float effectframe;
float is_effectframe;
.genericnet_t netg_server;
.genericnet_t netg_oldserver;
.genericnet_t netg_pureserver;
.genericnet_t netg_predicted;
#else
.genericnet_t netg_lastsent;
const float is_effect_frame = 1;
.void(entity ent, .genericnet_t net_storage) NetDelta;
#endif
