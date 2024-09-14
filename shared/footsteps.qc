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

#include "physics.h"

.float landsoundtime;

float	MAT_GENERIC = 0;
float	MAT_GRASS = 32768;
float	MAT_DIRT = 65536;
float	MAT_GRAVEL = 98304; // 32768 + 65536
float	MAT_GRATE = 131072; // *2
float	MAT_ICE = 163840;//131072 + 32768
float	MAT_METAL = 196608 ;//131072 + 65536
float	MAT_MUD = 229376; // 131072 + 32768 + 65536
float	MAT_PUDDLE = 262144;// *2
float	MAT_SNOW = 294912; //262144 + 32768
float	MAT_SOFT = 327680; // 262144 + 65536
float	MAT_STONE = 360448; // 262144 + 32768 +65536
float	MAT_WOOD = 393216; // 262144 + 131072
float	MAT_BFLESH= 425984; // 262144 + 131072+ 32768;
float	MAT_MASK = 491520 ; //  262144 + 131072+ 32768 +65536

float GetFootMaterial(entity e)
{ 
	traceline(e.origin, e.origin - '0 0 64', TRUE, e);

	if(trace_dphittexturename == "e1m2/e1m2_grt1_2")
		return MAT_GRATE;

	if(trace_dphittexturename == "textures/e1m2/e1m2_grt1_2")
		return MAT_GRATE;

	if(trace_dphitq3surfaceflags == 64)
		return MAT_BFLESH;

	if(trace_dphitq3surfaceflags & 8192)
		return -1;

	if(trace_dphitq3surfaceflags & 4096)
		return MAT_GRATE;

	float matflags = trace_dphitq3surfaceflags & MAT_MASK;
		return matflags;
};

void PL_LandingSound(entity e, float isheavy)
{
	string landingsound;
	if (isheavy > 0)
	{
		string r = sprintf("%.0f", floor(random() * 3) + 1);
		landingsound = strcat("player/landings/heavy_land", r, ".ogg");
	}
	else
	{
		if (e.landsoundtime > e.clienttime)
			return;
		
		e.landsoundtime = e.clienttime + 1;
		float material = GetFootMaterial(e);
		string r = sprintf("%.0f", floor(random() * 5) + 1);

		if(material == -1)
			return;	

		if (material == MAT_GENERIC)
		{
			landingsound = strcat("player/landings/land_stone", r, ".ogg");
		}
		else if (material == MAT_DIRT)
		{
			landingsound = strcat("player/landings/land_dirt", r, ".ogg");
		}
		else if (material == MAT_GRATE)
		{
			landingsound = strcat("player/landings/land_grate", r, ".ogg");
		}
		else if (material == MAT_GRAVEL)
		{
			landingsound = strcat("player/landings/land_gravel", r, ".ogg");
		}
		else if (material == MAT_GRASS)
		{
			landingsound = strcat("player/landings/land_grass", r, ".ogg");
		}
		else if (material == MAT_ICE)
		{
			landingsound = strcat("player/landings/land_ice", r, ".ogg");
		}
		else if (material == MAT_METAL)
		{
			landingsound = strcat("player/landings/land_metal", r, ".ogg");
		}
		else if (material == MAT_MUD)
		{
			landingsound = strcat("player/landings/land_dirt", r, ".ogg");
		}
		else if (material == MAT_SNOW)
		{
			landingsound = strcat("player/landings/land_snow", r, ".ogg");
		}
		else if (material == MAT_SOFT)
		{
			landingsound = strcat("player/landings/land_stone", r, ".ogg");
		}
		else if (material == MAT_STONE)
		{
			landingsound = strcat("player/landings/land_stone", r, ".ogg");
		}
		else if (material == MAT_WOOD)
		{
			landingsound = strcat("player/landings/land_wood", r, ".ogg");
		}
		else if (material == MAT_GRASS)
		{
			landingsound = strcat("player/landings/land_grass", r, ".ogg");
		}
		else if (material == MAT_BFLESH)
		{
			landingsound = strcat("player/landings/land_flesh", r, ".ogg");
		}
	}

	#ifdef SSQC
	soundwrath(e, CHAN_AUTO, landingsound, 1, ATTN_STEP, 80 + random() * 30, 0, TRAP_STEP);
	#endif
}

void PL_Footstep(entity e)
{
	string footstepsound;
	float footstepvol;
	float footstepcrouchvol;
	float material;

	material = GetFootMaterial(e);

	string r = sprintf("%.0f", floor(random() * 5) + 1);
	if (e.watertype >= 1)
	{
		footstepvol = 1;
		footstepcrouchvol = 0.7;
		footstepsound = strcat("player/footsteps/puddle", r, ".ogg");
	}
	else
	{
		if (material == MAT_DIRT)
		{
			footstepvol = 1;
			footstepcrouchvol = 0.7;
			footstepsound = strcat("player/footsteps/dirt", r, ".ogg");
		}
		else if (material == MAT_GRAVEL)
		{
			footstepvol = 0.7;
			footstepcrouchvol = 0.5;
			footstepsound = strcat("player/footsteps/gravel", r, ".ogg");
		}
		else if (material == MAT_GRASS)
		{
			footstepvol = 0.5;
			footstepcrouchvol = 0.2;
			footstepsound = strcat("player/footsteps/grass", r, ".ogg");
		}
		else if (material == MAT_GRATE)
		{
			footstepvol = 0.7;
			footstepcrouchvol = 0.5;
			footstepsound = strcat("player/footsteps/grate", r, ".ogg");
		}
		else if (material == MAT_ICE)
		{
			footstepvol = 0.5;
			footstepcrouchvol = 0.2;
			footstepsound = strcat("player/footsteps/ice", r, ".ogg");
		}
		else if (material == MAT_METAL)
		{
			footstepvol = 1;
			footstepcrouchvol = 0.7;
			footstepsound = strcat("player/footsteps/metal", r, ".ogg");
		}
		else if (material == MAT_MUD)
		{
			footstepvol = 1;
			footstepcrouchvol = 0.7;
			footstepsound = strcat("player/footsteps/mud", r, ".ogg");
		}
		else if (material == MAT_SNOW)
		{
			footstepvol = 0.7;
			footstepcrouchvol = 0.4;
			footstepsound = strcat("player/footsteps/snow", r, ".ogg");
		}
		else if (material == MAT_PUDDLE)
		{
			footstepvol = 0.7;
			footstepcrouchvol = 0.2;
			footstepsound = strcat("player/footsteps/puddle", r, ".ogg");
		}
		else if (material == MAT_SOFT)
		{
			footstepvol = 1;
			footstepcrouchvol = 0.7;
			footstepsound = strcat("player/footsteps/stone", r, ".ogg");
		}
		else if (material == MAT_STONE)
		{
			footstepvol = 0.8;
			footstepcrouchvol = 0.7;
			footstepsound = strcat("player/footsteps/stone", r, ".ogg");
		}
		else if (material == MAT_WOOD)
		{
			footstepvol = 0.7;
			footstepcrouchvol = 0.4;
			footstepsound = strcat("player/footsteps/wood", r, ".ogg");
		}
		else if (material == MAT_BFLESH)
		{
			footstepvol = 0.7;
			footstepcrouchvol = 0.4;
			footstepsound = strcat("player/footsteps/flesh", r, ".ogg");
		}
		else //if (material == MAT_GENERIC)
		{
			footstepvol = 0.7;
			footstepcrouchvol = 0.3;
			footstepsound = strcat("player/footsteps/dirt", r, ".ogg");
		}

		float pvol = footstepvol;
		if (vlen([e.velocity[0], e.velocity[1], 0]) < 240)
			pvol = footstepcrouchvol;

		#ifdef SSQC
		soundwrath(e, CHAN_AUTO, footstepsound, pvol, ATTN_STEP, 80 + random() * 30, 0, TRAP_STEP);
		#endif
	}
}