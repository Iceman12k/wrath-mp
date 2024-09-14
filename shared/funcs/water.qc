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

.string cshift;
.float fakewatertype;

void() liquid_touch {
	if (other.classname != "player")
		return;

	float test;
	test = other.origin_z + other.mins_z + 1;
	if (test <= self.absmax_z && test >= self.absmin_z)
	{
		other.fakewatertype = self.fakewatertype;
		other.waterlevel = 1;

		// Test Torso
		test = other.origin_z + (other.mins_z + other.maxs_z) * 0.5;
		if (test <= self.absmax_z)
		{
			other.waterlevel = 2;
		}

		// Test Eyes
		test = other.origin_z + other.view_ofs_z;
		if ((test <= self.absmax_z))
		{
			other.waterlevel = 3;
		}
	}
}

void() func_water = 
{ 
	if (self.noise != string_null)
		precache_sound(self.noise);
	if (self.noise1 != string_null)
		precache_sound(self.noise1);
	if (self.noise2 != string_null)
		precache_sound(self.noise2);
		
	if(!self.watertype)	
		self.watertype = -3;
	
	//self.clipgroup = 2;
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NOCLIP;
	setmodel(self, self.model);
	setsize(self, self.mins, self.maxs);
	setorigin(self, self.origin);
	//self.rel_origin = self.origin;
	self.touch = liquid_touch;

	if ((self.watertype < CONTENT_LAVA || self.watertype > CONTENT_WATER))
		self.watertype = CONTENT_WATER;
	//if (self.watertype == CONTENT_LAVA)
	//spawn_lava_sounds(self);

	self.fakewatertype = self.watertype;
	if (self.fakewatertype == CONTENT_WATER)
		self.dphitcontentsmask = DPCONTENTS_WATER;
	if (self.fakewatertype == CONTENT_SLIME)
		self.dphitcontentsmask = DPCONTENTS_SLIME;
	if (self.fakewatertype == CONTENT_LAVA)
		self.dphitcontentsmask = DPCONTENTS_LAVA; 
	if (self.cshift == "")
	{
		if (self.fakewatertype == CONTENT_WATER)
		{
			self.cshift = "130 80 50 128";
		}
		else if (self.fakewatertype == CONTENT_SLIME)
			self.cshift = "0 25 5 150";
		else if (self.fakewatertype == CONTENT_LAVA)
			self.cshift = "255 80 0 150";
	}

	/*
	if (self.targetname)
		self.movetype = MOVETYPE_PUSH;
	
	SetMovedir();
	if (!self.lip)
		self.lip = 8;
	if (!self.speed)
		self.speed = 100;

	self.pos1 = self.origin;
	self.pos2 = self.pos1 + self.movedir *(fabs(self.movedir *self.size) - self.lip);

	if (self.spawnflags &1)
	{
		// start moved
		setorigin(self, self.pos2);
		self.water_movflag = 1;
	}

	if(self.height_water1)
		self.pos3 = self.pos1 + self.movedir *(self.height_water1);
	if(self.height_water2)
		self.pos4 = self.pos1 + self.movedir *(self.height_water2);
	if(self.height_water3)
		self.pos5 = self.pos1 + self.movedir *(self.height_water3);
	self.use = func_water_use;

	// Cap drag force
	if (self.drag > 100) self.drag = 100;
	if (self.drag < 0) self.drag = 0;

	if (self.mangle != '0 0 0')
		self.mangle = self.mangle * 50;
	*/
};