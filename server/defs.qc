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


.float(entity to, float sendflags) SendEntity;
.float SendFlags;
.entity watching;

float servercommandframe;

void centerprint_all(string str)
{
	for(entity ent = findflags(world, flags, FL_CLIENT); ent; ent = findflags(ent, flags, FL_CLIENT))
	{
		centerprint(ent, str);
	}
}




