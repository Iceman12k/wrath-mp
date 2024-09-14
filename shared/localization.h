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

#define LOCSTR 								\
	LC_STR(NOTIFY_FULL)						\
	LC_STR(NOTIFY_HEALTH_VIAL)				\
	LC_STR(NOTIFY_HEALTH_BEAKER)			\
	LC_STR(NOTIFY_HEALTH_CHALICE)			\
	LC_STR(NOTIFY_ARMOR_SHARD)				\
	LC_STR(NOTIFY_ARMOR_HELM)				\
	LC_STR(NOTIFY_ARMOR)					\
	LC_STR(NOTIFY_DARKARMOR_SHARD)			\
	LC_STR(NOTIFY_DARKARMOR_HELM)			\
	LC_STR(NOTIFY_DARKARMOR)				\
	LC_STR(NOTIFY_WEP_REVOLVER)				\
	LC_STR(NOTIFY_WEP_SHOTGUN)				\
	LC_STR(NOTIFY_WEP_SPITTER)				\
	LC_STR(NOTIFY_WEP_RETCHER)				\
	LC_STR(NOTIFY_WEP_SLAGCANNON)			\
	LC_STR(NOTIFY_WEP_LANCE)				\
	LC_STR(NOTIFY_WEP_BOILER)				\
	LC_STR(NOTIFY_WEP_MACE)					\
	LC_STR(NOTIFY_AMMO_REVOLVER)			\
	LC_STR(NOTIFY_AMMO_SHOTGUN)				\
	LC_STR(NOTIFY_AMMO_SPITTER)				\
	LC_STR(NOTIFY_AMMO_RETCHER)				\
	LC_STR(NOTIFY_AMMO_SLAGCANNON)			\
	LC_STR(NOTIFY_AMMO_LANCE)				\
	LC_STR(NOTIFY_AMMO_CRYSTAL)				\

#define LC_STR(S)	S,
enum LOCALIZATION:float {
	LOCSTR
	MAX,
};
#undef LC_STR

#ifdef CSQC
#define LC_STR(S)	_(#S),
string localization_str[] = {
	LOCSTR
};
#undef LC_STR
#endif




