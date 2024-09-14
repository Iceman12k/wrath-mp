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

#include "protocol.h"

.float globalstats[STAT::GLOBALFIELDS_END - STAT::GLOBALFIELDS];

void worldspawn()
{
	Precache_Player();
	for(float i = 0; i < globalstats.length; i++)
	{
		addstat(STAT::GLOBALFIELDS + i, AS_FLOAT, globalstats[i]);
	}

	addstat(STAT::PING, AS_FLOAT, ping);
	addstat(STAT::HITBEEP_DATA, AS_FLOAT, hitbeep_data);

	// null assets
	precache_model("models/misc/null.md3");
	precache_sound("misc/null.wav");
	// item assets
	for(float i = 1; i <= 5; i++)
		precache_sound(sprintf("fx/tele%g.ogg", i));
	// player asset
	precache_model("models/alpha/head.md3");
	precache_model("models/alpha/upper.md3");
	precache_model("models/alpha/lower.md3");
	for(float i = 1; i <= 5; i++)
		precache_sound(sprintf("player/jumps/jump%g.ogg", i));
	// init structures
	W_Init();
	IT_Init();

	float timelimit = cvar("timelimit");
	if (timelimit)
	{
		gametime_start = time + 10;
		gametime_end = gametime_start + (timelimit * 60);
	}
}


void main()
{
	
	
	
}

void StartFrame()
{
	PM_UpdateMovementStats();
}

void PL_MapGlobalsStatsToFields() {
	typedef struct fieldmap_t
	{
		float value;
		float stat;
	};

	fieldmap_t fieldmap[] = {
		{sv_maxspeed, STAT::PM_MAXSPEED},
		{sv_friction, STAT::PM_FRICTION},
		{sv_accelerate, STAT::PM_ACCELERATE},
		{sv_stopspeed, STAT::PM_STOPSPEED},
		{sv_edgefriction, STAT::PM_EDGEFRICTION},
		{sv_gravity, STAT::PM_GRAVITY},
		{sv_stepheight, STAT::PM_STEPHEIGHT},
		{sv_ticrate, STAT::SV_TICRATE},
		{sv_framenum, STAT::SV_FRAMENUM},
		{gametime_start, STAT::GAMETIME_START},
		{gametime_end, STAT::GAMETIME_END},
	};
	
	for(entity lst = findflags(world, flags, FL_CLIENT); lst; lst = findflags(lst, flags, FL_CLIENT))
	{
		for(float i = 0; i < fieldmap.length; i++)
		{
			lst.globalstats[fieldmap[i].stat - STAT::GLOBALFIELDS] = fieldmap[i].value;
		}
	}
}

void EndFrame()
{
	// hacked together .customphysics replacement
	for(entity edict = nextent(world); edict; edict = nextent(edict))
	{
		if (!edict.cphysics)
			continue;
		
		self = edict;
		edict.cphysics();
	}
	//
	
	PL_MapGlobalsStatsToFields();

	for(entity edict = nextent(world); edict; edict = nextent(edict))
	{
		if (edict.flags & FL_CLIENT && edict.simulatedthisframe)
		{
			edict.simulatedthisframe = FALSE;
			PL_NetCheck(edict, net_lastsent);
		}

		if (!edict.NetDelta)
			continue;
		
		self = edict;
		edict.NetDelta(edict, netg_lastsent);
	}

	static float match_ended = 0;
	if (!match_ended)
	{
		if (gametime_end && time >= gametime_end)
		{
			match_ended = time + 5;

			float is_tied = FALSE;
			float most_frags = -999;
			entity most_edict = world;
			for(entity edict = nextent(world); edict; edict = nextent(edict))
			{
				if !(edict.flags & FL_CLIENT)
					continue;

				if (edict.frags > most_frags)
				{
					most_frags = edict.frags;
					most_edict = edict;
					is_tied = FALSE;
				}
				else if (edict.frags == most_frags)
				{
					is_tied = TRUE;
				}
			}

			if (most_edict)
			{
				if (is_tied)
				{
					match_ended = 0;
					gametime_end = time + 120;
					centerprint_all("^3Match tied\n\n^32 Minute Overtime!");
				}
				else
				{
					string str = sprintf("^1Match over\n\n^7%s wins with %.0f frags!", most_edict.netname, most_frags);
					centerprint_all(str);
				}
			}
		}
	}
	else if (time > match_ended)
	{
		match_ended = time + 9999;
		changelevel(mapname);
	}

	Scoreboard_Update();
}






