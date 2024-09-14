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

float sv_maxspeed;
float sv_friction;
float sv_accelerate;
float sv_stopspeed;
float sv_edgefriction;
float sv_gravity;
float sv_stepheight;
float sv_ticrate;
float sv_framenum;
float framenum;
#ifdef CSQC
float cl_framenum;
float pl_framenum;
#endif

#define MAXTOUCH 5
#define MIN_STEP_NORMAL 0.7f

// custom physics
.void() cphysics;
.float cmovetype;
void Entity_ForcePhysicsFrame(entity edict, float dt);
//

.entity groundentity;
.vector groundplane;
.float stuck_in_air;
.float gravity;
.float bouncefactor;
.float bouncestop;
.float teleport_time;
.float numtouch;
.entity touchents[MAXTOUCH];

void PMove(entity ent);
void PL_Acceleration(void);
void PM_UpdateMovementStats(void);
void PL_Footstep(entity e);
void PL_LandingSound(entity e, float isheavy);