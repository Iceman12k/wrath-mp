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

enumflags SCOREBOARDFLAG:float {
	NULL = 0,
	INUSE,
};

enumflags SCOREBOARDU:float {
	NULL = 0,
	INDEX,
	NAME,
	COLUMN1,
	COLUMN2,
	COLUMN3,
	COLUMN4
};

enum SCOREBOARDCOLUMN:float {
	FRAGS,
	DEATHS,
	UNUSED,
	PING,
};

class scoreboard_entry_c;
scoreboard_entry_c scoreboard_plates;


#ifdef SSQC
.scoreboard_entry_c sb_entry;

void Scoreboard_AllocateEntry(entity pl);
void Scoreboard_CleanupEntry(entity pl);
float SendEntity_ScoreboardEntry(entity to, float sendflags);
#elif defined(CSQC)
void EntUpdate_ScoreboardEntry(float is_new);

float scoreboard_visible;
#endif

class scoreboard_entry_c
{
	float index;
	float flags;
	string name;
	string column[4];
	var vector color[4];

	scoreboard_entry_c _next;
	scoreboard_entry_c chain;

	virtual void() RemoveEntity {
		strunzone(this.name);
		for(float i = 0; i < scoreboard_entry_c::column.length; i++)
			 strunzone(this.column[i]);

		scoreboard_entry_c hld;
		for(scoreboard_entry_c lst = scoreboard_plates; lst; hld = lst, lst = lst._next)
		{
			if (lst != this)
				continue;
			if (scoreboard_plates == lst)
			scoreboard_plates = lst._next;
			else
				hld._next = lst._next;
			break;
		}
		remove(this);
	};

	nonvirtual void() scoreboard_entry_c;
};