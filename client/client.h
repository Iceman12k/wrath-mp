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

const float MASK_ENGINE = 0x01;
const float MASK_VIEWMODEL = 0x02;
const float MASK_PLAYER	= 0x04;

const float	EF_BRIGHTFIELD	= 1;
const float	EF_MUZZLEFLASH 	= 2;
const float	EF_BRIGHTLIGHT 	= 4;
const float	EF_DIMLIGHT 	= 8;

float vid_width;
float vid_height;
float vid_rwidth;
float vid_rheight;

float servertime;
float cltime;
vector view_origin;
float xframe_lasttime;
float clframetime;

float r_healthhaze;
float r_saturation;

float r_crosshairhighlight_time;

entity view_subject;
.float renderflags;
.float scale;
.float alpha;
.vector colormod;
.vector glowmod;
.float oldmodelindex;

.void() RemoveEntity;