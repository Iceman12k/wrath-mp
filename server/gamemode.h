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

// define universal game cvars
var float autocvar_g_weaponstay = 0; // weapons can only be picked up once per life, and do not disappear
var float autocvar_g_respawn_health = 35; // respawn time of all health
var float autocvar_g_respawn_armor = 25; // respawn time of normal armors
var float autocvar_g_respawn_darkarmor = 25; // respawn time of dark armors
var float autocvar_g_respawn_weapon = 5; // respawn time of weapons
var float autocvar_g_respawn_ammo = 15; // respawn time of ammo boxes

var float gametime_start;
var float gametime_end;

