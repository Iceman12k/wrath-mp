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

float PUSH_ONCE = 1;
float PUSH_SILENT = 2;
.vector oldvelocity;
.float pushltime;
.float monsterjump;
.vector movedir;
void() trigger_jumpad_touch = {
	float flighttime, dist, grav;

	if (self.using != 1)
		return;

	if (!self.target)
	{
		other.velocity = self.movedir;
		other.flags &= ~FL_ONGROUND;
		return;
	}

	if ((other.flags & FL_CLIENT) && (other.jumppadtimer > 0))
		return;

	vector org = other.origin;
	other.disablemove = max(other.disablemove, 500);
	other.jumppadtimer = max(other.jumppadtimer, 200);

	#ifdef SSQC
	sound(self, CHAN_AUTO, "fx/tele1.ogg", 1, ATTN_NORM);

	// send blade dash effect
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TEMPENT::BLADEDASH);
	WriteShort(MSG_BROADCAST, num_for_edict(other));
	#endif

	//if (other.classname == "player")
	//	sound(other, CHAN_AUTO, "jump.ogg", 1, ATTN_NORM);

	// figure out how long it will take to hit the point considering gravity
	grav = sv_gravity;
	flighttime = sqrt((self.enemy.origin_z - org_z) / (0.5 *grav));
	if (!flighttime)
		return;

	// how far in X and Y to move
	self.movedir = (self.enemy.origin - org);
	self.movedir_z = 0;
	dist = vlen(self.movedir);

	// finally calculate the velocity
	self.movedir = normalize(self.movedir) *(dist / flighttime);
	self.movedir_z = flighttime * grav;

	other.flags = other.flags - (other.flags &FL_ONGROUND);
	// reset tracking of oldvelocity for impact damage (sudden velocity changes)
	other.oldvelocity = other.velocity = self.movedir;
	// reset tracking of who pushed you into a hazard (for kill credit)
	other.pushltime = 0;

	if (other.classname == "missile")
		other.angles = vectoangles(other.velocity);

	if (self.spawnflags & PUSH_ONCE)
	{
		self.touch = SUB_Null;
		self.think = SUB_Remove;
		self.nextthink = time;
	}
};

void() trigger_jumpad_findtarget = {	// find the target
	self.enemy = find(world, targetname, self.target);
	if (!self.enemy)
	{
		objerror("trigger_push: target not found\n");
		remove(self);
	}
};

void() trigger_jumppad = {
	if (self.angles != '0 0 0')
		SetMovedir();

	precache_sound("fx/tele1.ogg");

	self.solid = SOLID_TRIGGER;
	setmodel(self, self.model);
	self.movetype = MOVETYPE_NONE;
	self.use = toggle_use;
	if (!self.using)
		self.using = 1;

	self.touch = trigger_jumpad_touch;

	// check if this is a jump pad
	if (self.target)
	{
		self.think = trigger_jumpad_findtarget;
		self.nextthink = time + 0.2;
	}
	else
	{
		// normal push setup
		if (!self.speed)
			self.speed = 1000;
		self.movedir = self.movedir *self.speed * 10;
	}
};

void() target_push = {};
void() target_position = {}