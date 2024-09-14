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
#include "protocol.h"
#include "weapons.h"

void Actor_AddToList(entity add)
{
	if (add.is_actor)
		return;
	add.is_actor = TRUE;
	
	entity hld = world;
	for(entity actor = actorList; actor; hld = actor, actor = actor.actorNext)
	{
		if (actor == add) // no duplicates pls
			return;
	}
	if (hld == world) // if we're the first, we ARE the list
	{
		actorList = add;
		return;
	}
	hld.actorNext = add;
}

void Actor_RemoveFromList(entity rem)
{
	if !(rem.is_actor)
		return;
	rem.is_actor = FALSE;

	if (rem == actorList)
	{
		actorList = rem.actorNext;
		return;
	}

	entity hld;
	for(entity actor = actorList; actor; hld = actor, actor = actor.actorNext)
	{
		if (actor != rem) // no duplicates pls
			continue;
		hld.actorNext = rem.actorNext;
		return;
	}
}

void Predict_SimulateAllActors(void)
{
	if (frametime <= 0.005) // super tiny frames we can ignore
		return;
	
	entity o_self = self;
	for(entity actor = actorList; actor; actor = actor.actorNext)
	{
		if (actor == o_self) // ignore "self" since it's our player
			continue;
		if (!actor.cphysics)
			continue;
		self = actor;
		actor.cphysics();
	}
	self = o_self;
}

void Predict_RunAllActors(void)
{
	entity o_self = self;
	for(entity actor = actorList; actor; actor = actor.actorNext)
	{
		if (actor.was_updated)
		{
			actor.was_updated = FALSE;
			continue;
		}
		if (actor == o_self) // ignore "self" since it's our player
			continue;
		if (!actor.cphysics)
			continue;
		self = actor;
		actor.cphysics();
	}
	self = o_self;
}

void Predict_RewindAllActors(.genericnet_t state)
{
	entity o_self = self;
	for(entity actor = actorList; actor; actor = actor.actorNext)
	{
		if (actor == o_self) // ignore "self" since it's our player
			continue;
		if !(actor.NetStructToEdict)
			continue;
		actor.NetStructToEdict(actor, state);
	}
	self = o_self;
}

void Predict_SaveAllActors(.genericnet_t state)
{
	entity o_self = self;
	for(entity actor = actorList; actor; actor = actor.actorNext)
	{
		if (actor == o_self) // ignore "self" since it's our player
			continue;
		if !(actor.NetEdictToStruct)
			continue;
		actor.NetEdictToStruct(actor, state);
	}
	self = o_self;
}

// self should equal local player
void Predict_GameState(float do_effects, .playernet_t state)
{
	entity o_self = self;
	// state comparison
	if (state == net_server) // werid??? some janky fteqcc shit happening here
	{
		NetField_StructToEntity(self, net_server);
		Predict_RewindAllActors(netg_server);
	}
	else if (state == net_oldserver)
	{
		NetField_StructToEntity(self, net_oldserver);
		Predict_RewindAllActors(netg_oldserver);
	}
	else if (state == net_predicted)
	{
		NetField_StructToEntity(self, net_predicted);
		Predict_RewindAllActors(netg_predicted);
	}
	//

	//Predict_RewindAllActors(gstate);
	//NetField_StructToEntity(self, state);
	float o_frametime = frametime;
	float cl_commandframe = min(clientcommandframe, servercommandframe + 100);
	self.framenumber = max(servercommandframe - 50, self.framenumber);

	framenum = sv_framenum;
	is_effectframe = FALSE;
	for(self.framenumber; self.framenumber < cl_commandframe; self.framenumber++)
	{
		self = o_self;
		getinputstate(self.framenumber);
		
		frametime = input_timelength;
		framenum += (input_timelength / sv_ticrate);
		if (do_effects && self.framenumber > effectframe)
		{
			is_effectframe = TRUE;
			effectframe = self.framenumber;
		}

		Predict_SimulateAllActors();
		PL_RunPhysics(o_self);
	}

	frametime = o_frametime;
}

#ifdef CSQC
void touchtriggers(entity ent)
{
	entity o_self = self;
	entity o_other = other;
	for(entity actor = actorList; actor; actor = actor.actorNext)
	{
		if (actor.solid != SOLID_TRIGGER)
			continue;
		if (ent == actor)
			continue;
		if (boxesoverlap(actor.absmin, actor.absmax, ent.absmin, ent.absmax))
		{
			/*
			if (ent.touch)
			{
				self = ent;
				other = actor;
				ent.touch();
			}
			*/
	
			if (actor.touch)
			{
				self = actor;
				other = ent;
				actor.touch();
			}
		}
	}
	self = o_self;
	other = o_other;
}
#endif