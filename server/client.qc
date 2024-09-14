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

#include "weapons.h"
#include "scoreboard.h"

.float simulatedthisframe;

void spawnfunc_info_player_start()
{
	//self.classname = "spawn_location";
}

void spawnfunc_info_player_deathmatch()
{
	self.classname = "spawn_location";

	setsize(self, '-16 -16 -24', '16 16 32');
}

void Precache_Player()
{
	precache_model("models/players/outlander/player.md3");

	precache_sound ("player/hurt1.ogg");
	precache_sound ("player/hurt2.ogg");
	precache_sound ("player/hurt3.ogg");
	precache_sound ("player/hurt4.ogg");
	precache_sound ("player/hurt5.ogg");

	precache_sound ("player/die1.ogg");
	precache_sound ("player/die2.ogg");
	precache_sound ("player/die3.ogg");
	precache_sound ("player/die4.ogg");
	precache_sound ("player/die5.ogg");

	precache_sound ("player/footsteps/dirt1.ogg");
	precache_sound ("player/footsteps/dirt2.ogg");
	precache_sound ("player/footsteps/dirt3.ogg");
	precache_sound ("player/footsteps/dirt4.ogg");
	precache_sound ("player/footsteps/dirt5.ogg");
	precache_sound ("player/footsteps/grass1.ogg");
	precache_sound ("player/footsteps/grass2.ogg");
	precache_sound ("player/footsteps/grass3.ogg");
	precache_sound ("player/footsteps/grass4.ogg");
	precache_sound ("player/footsteps/grass5.ogg");
	precache_sound ("player/footsteps/grate1.ogg");
	precache_sound ("player/footsteps/grate2.ogg");
	precache_sound ("player/footsteps/grate3.ogg");
	precache_sound ("player/footsteps/grate4.ogg");
	precache_sound ("player/footsteps/grate5.ogg");
	precache_sound ("player/footsteps/gravel1.ogg");
	precache_sound ("player/footsteps/gravel2.ogg");
	precache_sound ("player/footsteps/gravel3.ogg");
	precache_sound ("player/footsteps/gravel4.ogg");
	precache_sound ("player/footsteps/gravel5.ogg");
	precache_sound ("player/footsteps/ice1.ogg");
	precache_sound ("player/footsteps/ice2.ogg");
	precache_sound ("player/footsteps/ice3.ogg");
	precache_sound ("player/footsteps/ice4.ogg");
	precache_sound ("player/footsteps/ice5.ogg");
	precache_sound ("player/footsteps/mud1.ogg");
	precache_sound ("player/footsteps/mud2.ogg");
	precache_sound ("player/footsteps/mud3.ogg");
	precache_sound ("player/footsteps/mud4.ogg");
	precache_sound ("player/footsteps/mud5.ogg");
	precache_sound ("player/footsteps/puddle1.ogg");
	precache_sound ("player/footsteps/puddle2.ogg");
	precache_sound ("player/footsteps/puddle3.ogg");
	precache_sound ("player/footsteps/puddle4.ogg");
	precache_sound ("player/footsteps/puddle5.ogg");
	precache_sound ("player/footsteps/snow1.ogg");
	precache_sound ("player/footsteps/snow2.ogg");
	precache_sound ("player/footsteps/snow3.ogg");
	precache_sound ("player/footsteps/snow4.ogg");
	precache_sound ("player/footsteps/snow5.ogg");
	precache_sound ("player/footsteps/stone1.ogg");
	precache_sound ("player/footsteps/stone2.ogg");
	precache_sound ("player/footsteps/stone3.ogg");
	precache_sound ("player/footsteps/stone4.ogg");
	precache_sound ("player/footsteps/stone5.ogg");
	precache_sound ("player/footsteps/wood1.ogg");
	precache_sound ("player/footsteps/wood2.ogg");
	precache_sound ("player/footsteps/wood3.ogg");
	precache_sound ("player/footsteps/wood4.ogg");
	precache_sound ("player/footsteps/wood5.ogg");
	precache_sound ("player/hurt_underwater1.ogg");
	precache_sound ("player/hurt_underwater2.ogg");
	precache_sound ("player/hurt_underwater3.ogg");
	precache_sound ("player/jumps/jump1.ogg");
	precache_sound ("player/jumps/jump2.ogg");
	precache_sound ("player/jumps/jump3.ogg");
	precache_sound ("player/jumps/jump4.ogg");
	precache_sound ("player/jumps/jump5.ogg");
	precache_sound ("player/landings/heavy_land1.ogg");
	precache_sound ("player/landings/heavy_land2.ogg");
	precache_sound ("player/landings/heavy_land3.ogg");
	precache_sound ("player/landings/land_dirt1.ogg");
	precache_sound ("player/landings/land_dirt2.ogg");
	precache_sound ("player/landings/land_dirt3.ogg");
	precache_sound ("player/landings/land_dirt4.ogg");
	precache_sound ("player/landings/land_dirt5.ogg");
	precache_sound ("player/landings/land_grass1.ogg");
	precache_sound ("player/landings/land_grass2.ogg");
	precache_sound ("player/landings/land_grass3.ogg");
	precache_sound ("player/landings/land_grass4.ogg");
	precache_sound ("player/landings/land_grass5.ogg");
	precache_sound ("player/landings/land_grass5.ogg");
	precache_sound ("player/landings/land_grate1.ogg");
	precache_sound ("player/landings/land_grate2.ogg");
	precache_sound ("player/landings/land_grate3.ogg");
	precache_sound ("player/landings/land_grate4.ogg");
	precache_sound ("player/landings/land_ice1.ogg");
	precache_sound ("player/landings/land_ice2.ogg");
	precache_sound ("player/landings/land_ice3.ogg");
	precache_sound ("player/landings/land_ice4.ogg");
	precache_sound ("player/landings/land_puddle1.ogg");
	precache_sound ("player/landings/land_puddle2.ogg");
	precache_sound ("player/landings/land_puddle3.ogg");
	precache_sound ("player/landings/land_puddle4.ogg");
	precache_sound ("player/landings/land_snow1.ogg");
	precache_sound ("player/landings/land_snow2.ogg");
	precache_sound ("player/landings/land_snow3.ogg");
	precache_sound ("player/landings/land_snow4.ogg");
	precache_sound ("player/landings/land_snow5.ogg");
	precache_sound ("player/landings/land_stone1.ogg");
	precache_sound ("player/landings/land_stone2.ogg");
	precache_sound ("player/landings/land_stone3.ogg");
	precache_sound ("player/landings/land_stone4.ogg");
	precache_sound ("player/landings/land_stone5.ogg");
	precache_sound ("player/landings/land_wood1.ogg");
	precache_sound ("player/landings/land_wood2.ogg");
	precache_sound ("player/landings/land_wood3.ogg");
	precache_sound ("player/landings/land_wood4.ogg");
	precache_sound ("player/landings/land_wood5.ogg");
}

void SetNewParms()
{
	
}


void SetChangeParms()
{
	
}


void PL_SetFirstWeapon()
{
	self.weapon = 0;
	for(float i = WEAPON::MAX-1; i >= 0; i--)
	{
		weapon_t wep = weaponlist[i];
		if !(self.items & wep.it_flag)
			continue;
		
		self.weapon_wanted = i;
		break;
	}
}

entity PL_FindSpawnpoint()
{
	entity list = findchain(classname, "spawn_location");
	float list_size = 0;
	
	entity hld;
	for(entity lp = list; lp; hld = lp, lp = lp.chain)
	{
		tracebox(lp.origin, '-16 -16 -24', '16 16 32', lp.origin + '0 0 1', MOVE_NORMAL, world);
		if (trace_fraction >= 1 && !trace_startsolid && !trace_allsolid)
		{
			list_size++;
			continue;
		}
		if (lp == list)
			list = lp.chain;
		else
			hld.chain = lp.chain;
	}
	if (list_size == 0)
		return find(world, classname, "spawn_location");
	
	list_size = floor(random(list_size));
	
	for(; list_size > 0; list = list.chain, list_size--);
	return list;
}

void PL_Respawn()
{
	entity spawnpoint = PL_FindSpawnpoint();
	setorigin(self, spawnpoint.origin);
	self.angles = self.v_angle = spawnpoint.angles;
	//self.fixangle = TRUE;

	msg_entity = self;
	WriteByte(MSG_ONE, SVC_TEMPENTITY);
	WriteByte(MSG_ONE, TEMPENT::FIXANGLE);
	WriteVectorL(MSG_ONE, spawnpoint.angles);

	self.velocity = '0 0 0';
	self.flags |= FL_ONGROUND;

	self.classname = "player";
	setmodel(self, "models/enemies/fallen/fallen1.md3");
	soundwrath(self, CHAN_AUTO, "fx/tele4.ogg", 1, ATTN_PICKUP, 110 + random() * 30, 0, TRAP_PICKUP);


	self.max_health = 100;
	self.health = self.max_health;
	self.weapon = 0;
	self.weapon_mode = 0;
	self.attack_frames = 0;
	self.busy_frames = 0;
	// clear ammo
	self.ammo_slugs = self.ammo_shells =
	self.ammo_fangs = self.ammo_cysts =
	self.ammo_ore = self.ammo_lances =
	self.ammo_crystals = self.ammo_souls = 0;
	//

	self.items = ITEM::BLADE | ITEM::COACHGUN;
	self.ammo_slugs = 30;
	PL_SetFirstWeapon();
	
	self.disablemove = 0;
	self.jumppadtimer = 0;
	self.damageboost = 0;
	self.deadflag = DEAD_NO;
	self.takedamage = DAMAGE_YES;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.view_ofs = '0 0 22';
	setsize(self, '-16 -16 -32', '16 16 32');
	self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BODY;

	self.SendEntity = SendEntity_Player;
	self.SendFlags |= 0xFFFFFF;
}

void PutClientInServer()
{
	string str = sprintf("%s connected to the server!", self.netname);
	bprint(str, "\n");
	centerprint_all(str);

	stuffcmd(self, "cl_movement 1\n");

	PL_Respawn();
	Scoreboard_AllocateEntry(self);
}


void ClientConnect()
{
	self.flags |= FL_CLIENT;
}


void ClientDisconnect()
{
	Scoreboard_CleanupEntry(self);
}


void ClientKill()
{
	if (self.health > 0)
	{
		PL_TakeDamage('0 0 400', 999, 0, self, self);
	}
}


void PlayerPreThink()
{
	
}


void PlayerPostThink()
{
	
}


void SV_RunClientCommand()
{
	self.framenumber = servercommandframe + 1;
	self.simulatedthisframe = TRUE;

	self.clin_movevalues = input_movevalues;
	self.clin_buttons = input_buttons;
	
	PL_RunPhysics(self);
	PEvent_Cleanup(self);

	//self.framenumber = servercommandframe++;
	//self.angles = [input_angles[0] * -0.2, input_angles[1], 0];
	//self.frame = (self.frame + 1) % 20;
	//PL_NetCheck(self, net_lastsent);

	if (newmis)
	{
		Entity_ForcePhysicsFrame(newmis, 0.025);
		newmis = world;
	}
}

