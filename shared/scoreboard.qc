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
#include "scoreboard.h"

void() scoreboard_entry_c::scoreboard_entry_c {
	// allocate empty strings
	this.name = strzone(" ");
	for(float i = 0; i < scoreboard_entry_c::column.length; i++)
		this.column[i] = strzone(" ");
	this.index = 255;
	
	// add to list
	this._next = scoreboard_plates;
	scoreboard_plates = this;

	// make sure we're networkin'
	#ifdef SSQC
	((entity)this).SendEntity = SendEntity_ScoreboardEntry;
	((entity)this).effects = EF_NOPVSCULL;
	setmodel((entity)this, "models/misc/null.md3");
	#endif
};

#ifdef SSQC
vector Scoreboard_PingColor(float msec)
{
	if (msec < 40)
		return '0.19 0.96 0.20';
	else if (msec < 75)
		return '0.63 0.96 0.19';
	else if (msec < 100)
		return '0.92 0.96 0.19';
	else if (msec < 140)
		return '0.96 0.87 0.19';
	else if (msec < 190)
		return '0.96 0.51 0.19';
	else
		return '0.96 0.20 0.19';
}

void Scoreboard_SetName(scoreboard_entry_c sb, string tempname)
{
	if (!strcmp(sb.name, tempname))
		return;

	if (sb.name)
		strunzone(sb.name);

	sb.name = strzone(tempname);
	sb.SendFlags |= SCOREBOARDU::NAME;
}

void Scoreboard_SetColumn(scoreboard_entry_c sb, float index, string tempstr, vector col)
{	
	if (sb.color[index] == col && !strcmp(sb.column[index], tempstr))
		return;

	if (sb.column[index])
		strunzone(sb.column[index]);
	
	sb.column[index] = strzone(tempstr);
	//(vector)(sb.color[index]) = col;

	sb.SendFlags |= SCOREBOARDU::COLUMN1 << index;

}

//void Scoreboard_Update

void Scoreboard_AllocateEntry(entity pl)
{
	if (pl.sb_entry)
		pl.sb_entry.RemoveEntity();
	pl.sb_entry = spawn(scoreboard_entry_c, owner: pl);

	Scoreboard_SetName(pl.sb_entry, pl.netname);
	Scoreboard_SetColumn(pl.sb_entry, SCOREBOARDCOLUMN::FRAGS, "0", '-1 -1 -1');
	Scoreboard_SetColumn(pl.sb_entry, SCOREBOARDCOLUMN::DEATHS, "0", '-1 -1 -1');
	Scoreboard_SetColumn(pl.sb_entry, SCOREBOARDCOLUMN::PING, sprintf("%.0fms", pl.ping), Scoreboard_PingColor(pl.ping));
}

void Scoreboard_CleanupEntry(entity pl)
{
	if (pl.sb_entry)
		pl.sb_entry.RemoveEntity();
	pl.sb_entry = 0;
}

void Scoreboard_Reorder(void)
{
	scoreboard_entry_c ordered;
	for(scoreboard_entry_c lst = scoreboard_plates; lst; lst = lst._next)
	{
		if (!ordered)
		{
			ordered = lst;
			lst.chain = 0;
			continue;
		}

		if (ordered.owner.frags < lst.owner.frags)
		{
			lst.chain = ordered;
			ordered = lst;
			continue;
		}

		scoreboard_entry_c hld = ordered;
		scoreboard_entry_c or = ordered.chain;
		while(or)
		{
			if (or.owner.frags < lst.owner.frags)
				break;
			hld = or;
			or = or.chain;
		}
		hld.chain = lst;
		lst.chain = or;
	}

	#if 1
	for(float i = 0, scoreboard_entry_c lst = ordered; lst; i++, lst = lst.chain)
	{
		if (lst.index == i)
			continue;
		lst.index = i;
		lst.SendFlags |= SCOREBOARDU::INDEX;
	}
	#endif
}

void Scoreboard_Update()
{
	static float scoreboard_updatetime = 0;
	if (time < scoreboard_updatetime)
		return;

	scoreboard_updatetime = time + 1;
	for(scoreboard_entry_c lst = scoreboard_plates; lst; lst = lst._next)
	{
		if (!lst.owner)
			continue;

		Scoreboard_SetName(lst, lst.owner.netname);
		Scoreboard_SetColumn(lst, SCOREBOARDCOLUMN::FRAGS, ftos(lst.owner.frags), '-1 -1 -1');
		Scoreboard_SetColumn(lst, SCOREBOARDCOLUMN::DEATHS, ftos(lst.owner.deaths), '-1 -1 -1');
		Scoreboard_SetColumn(lst, SCOREBOARDCOLUMN::PING, sprintf("%.0fms", lst.owner.ping), Scoreboard_PingColor(lst.owner.ping));
	}

	Scoreboard_Reorder();
}

float SendEntity_ScoreboardEntry(entity to, float sendflags)
{
	scoreboard_entry_c entry = (scoreboard_entry_c)self;
	WriteByte(MSG_ENTITY, NENT::ScoreboardEntry);
	WriteByte(MSG_ENTITY, sendflags);

	if (sendflags & SCOREBOARDU::INDEX)
	{
		WriteByte(MSG_ENTITY, entry.index);
	}

	if (sendflags & SCOREBOARDU::NAME)
	{
		WriteString(MSG_ENTITY, entry.name);
	}

	// loop to write all 4 columns
	for(float i = 0; i < 4; i++)
	{
		const static float byte = SCOREBOARDU::COLUMN1; // fteqcc is a buggy fuckin mess
		if (sendflags & (byte << i))
		{
			WriteString(MSG_ENTITY, entry.column[i]);
			WriteColor(MSG_ENTITY, entry.color[i]);
		}
	}

	return TRUE;
}
#endif
#ifdef CSQC
void EntUpdate_ScoreboardEntry(float is_new)
{
	if (is_new)
	{
		spawnfunc_scoreboard_entry_c();
	}

	scoreboard_entry_c entry = (scoreboard_entry_c)self;
	float sendflags = ReadByte();

	if (sendflags & SCOREBOARDU::INDEX)
	{
		entry.index = ReadByte();
	}

	if (sendflags & SCOREBOARDU::NAME)
	{
		strunzone(entry.name);
		entry.name = strzone(ReadString());
	}

	// loop to read all 4 columns
	for(float i = 0; i < 4; i++)
	{
		const static float byte = SCOREBOARDU::COLUMN1; // fteqcc is a buggy fuckin mess
		if (sendflags & (byte << i))
		{
			strunzone(entry.column[i]);
			entry.column[i] = strzone(ReadString());
			entry.color[i] = ReadColor();
		}
	}
}
#endif










