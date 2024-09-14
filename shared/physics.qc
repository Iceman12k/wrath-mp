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

void PM_UpdateMovementStats()
{
	#if defined(SSQC)
	sv_maxspeed = cvar("sv_maxspeed");
	sv_friction = cvar("sv_friction");
	sv_accelerate = cvar("sv_accelerate");
	sv_stopspeed = cvar("sv_stopspeed");
	sv_edgefriction = cvar("sv_edgefriction");
	sv_gravity = cvar("sv_gravity");
	sv_stepheight = cvar("sv_stepheight");
	sv_ticrate = cvar("sys_ticrate");
	framenum += (frametime / sv_ticrate);
	sv_framenum = floor(framenum);
	#elif defined(CSQC)
	sv_maxspeed = getstatf(STAT::PM_MAXSPEED);
	sv_friction = getstatf(STAT::PM_FRICTION);
	sv_accelerate = getstatf(STAT::PM_ACCELERATE);
	sv_stopspeed = getstatf(STAT::PM_STOPSPEED);
	sv_edgefriction = getstatf(STAT::PM_EDGEFRICTION);
	sv_gravity = getstatf(STAT::PM_GRAVITY);
	sv_stepheight = getstatf(STAT::PM_STEPHEIGHT);
	sv_ticrate = bound(0.001, getstatf(STAT::SV_TICRATE), 0.5);
	sv_framenum = getstatf(STAT::SV_FRAMENUM);
	#endif
}

void Entity_ForcePhysicsFrame(entity edict, float dt)
{
	if (!edict.cphysics)
		return;

	float o_frametime = frametime;
	entity o_self = self;
	
	frametime = dt;
	self = edict;
	edict.cphysics();

	self = o_self;
	frametime = o_frametime;
}

// Reki:
// Adapted from xonotic
void _Movetype_Impact(entity oth) // SV_Impact
{
	entity oldother, oldself;

	oldself = self;
	oldother = other;

	if(self.touch)
	{
		other = oth;

		self.touch();

		other = oldother;
	}

	if(oth.touch)
	{
		other = self;
		self = oth;

		self.touch();

		self = oldself;
		other = oldother;
	}
}

#define MAX_CLIP_PLANES 5
vector _Movetype_ClipVelocity(vector vel, vector norm, float f) // SV_ClipVelocity
{
	vel = vel - ((vel * norm) * norm) * f;

	if(vel_x > -0.1 && vel_x < 0.1) vel_x = 0;
	if(vel_y > -0.1 && vel_y < 0.1) vel_y = 0;
	if(vel_z > -0.1 && vel_z < 0.1) vel_z = 0;

	return vel;
}

void _Movetype_PushEntityTrace(vector push)
{
	vector end;
	float type;

	end = self.origin + push;

	 if(self.movetype == MOVETYPE_FLYMISSILE)
		type = MOVE_MISSILE;
	else if(self.solid == SOLID_TRIGGER || self.solid == SOLID_NOT)
		type = MOVE_NOMONSTERS;
	else
		type = MOVE_NORMAL;
	
	#ifdef CSQC
		type = MOVE_WORLDONLY;
	#endif

	tracebox(self.origin, self.mins, self.maxs, end, type, self);
}

float _Movetype_PushEntity(vector push, float failonstartsolid) // SV_PushEntity
{
	_Movetype_PushEntityTrace(push);

	if(trace_startsolid && failonstartsolid)
		return trace_fraction;

	self.origin = trace_endpos;

	if(trace_fraction < 1)
		if(self.solid >= SOLID_TRIGGER && (!(self.flags & FL_ONGROUND) || (self.groundentity != trace_ent)))
			_Movetype_Impact(trace_ent);

	return trace_fraction;
}

void Physics_Bounce(float dt) // SV_Physics_Toss
{
	float gravity_value = sv_gravity;
	
	if(self.flags & FL_ONGROUND)
	{
		if(self.velocity_z >= 1/32)
			self.flags &~= FL_ONGROUND;
		else if(!self.groundentity)
			return;
		else if(self.stuck_in_air && wasfreed(self.groundentity))
		{
			self.groundentity = world;
			return;
		}
	}

	self.stuck_in_air = FALSE;
	
	if(self.gravity)
		self.velocity_z -= 0.5 * dt * self.gravity * gravity_value;
	else
		self.velocity_z -= 0.5 * dt * gravity_value;

	self.angles = self.angles + self.avelocity * dt;

	float movetime, bump;
	movetime = dt;
	for(bump = 0; bump < MAX_CLIP_PLANES && movetime > 0; ++bump)
	{
		vector move;
		move = self.velocity * movetime;
		_Movetype_PushEntity(move, TRUE);
		if(wasfreed(self))
			return;
		
		/*
		if(trace_startsolid)
		{
			_Movetype_UnstickEntity();
			_Movetype_PushEntity(move, FALSE);
			if(wasfreed(self))
				return;
		}
		*/

		if(trace_fraction == 1)
			break;

		movetime *= 1 - min(1, trace_fraction);
		
		
		//if(self.move_movetype == MOVETYPE_BOUNCE)
		//{
			float d, bouncefac, bouncestp;

			bouncefac = self.bouncefactor;     if(!bouncefac)  bouncefac = 0.5;
			bouncestp = self.bouncestop; if(!bouncestp) bouncestp = 60 / 800;
			if(self.gravity)
				bouncestp *= self.gravity * gravity_value;
			else
				bouncestp *= gravity_value;

			self.velocity = _Movetype_ClipVelocity(self.velocity, trace_plane_normal, 1 + bouncefac);

			d = trace_plane_normal * self.velocity;
			if(trace_plane_normal_z > 0.7 && d < bouncestp && d > -bouncestp)
			{
				self.flags |= FL_ONGROUND;
				self.groundentity = trace_ent;
				self.velocity = '0 0 0';
				self.avelocity = '0 0 0';
			}
			else
				self.flags &~= FL_ONGROUND;
		//}

		// DP revision 8918 (WHY...)
		if(self.flags & FL_ONGROUND)
			break;
	}
	
	if(!(self.flags & FL_ONGROUND))
	{
		if(self.gravity)
			self.velocity_z -= 0.5 * dt * self.gravity * gravity_value;
		else
			self.velocity_z -= 0.5 * dt * gravity_value;
	}

	//_Movetype_CheckWaterTransition();
}




void LinkEdict_TouchAreaGrid() // SV_LinkEdict_TouchAreaGrid
{
	// From xonotic
	entity e, oldself, oldother;

	oldself = self;
	oldother = other;

	for(e = findradius(0.5 * (self.absmin + self.absmax), 0.5 * vlen(self.absmax - self.absmin)); e; e = e.chain)
	{
		if(e.touch)
		if(boxesoverlap(e.absmin, e.absmax, oldself.absmin, oldself.absmax))
		{
			self = e;
			other = oldself;

			/*
			trace_allsolid = FALSE;
			trace_startsolid = FALSE;
			trace_fraction = 1;
			trace_inwater = FALSE;
			trace_inopen = TRUE;
			trace_endpos = e.origin;
			trace_plane_normal = '0 0 1';
			trace_plane_dist = 0;
			trace_ent = oldself;
			*/

			e.touch();
		}
	}

	other = oldother;
	self = oldself;
}


// Reki:
// Port of the ssqc jump behavior, tweaked to work with prediction
void PL_CheckWaterJump()
{
    local vector start, end;

// check for a jump-out-of-water
    makevectors (input_angles);
    start = self.origin;
    start_z = start_z + 8;
    v_forward_z = 0;
    normalize(v_forward);
    end = start + v_forward*24;
    traceline (start, end, TRUE, self);

    if (trace_fraction < 1)
    {   // solid at waist
        start_z = start_z + self.maxs_z - 8;
        end = start + v_forward*24;
        traceline (start, end, TRUE, self);

        if (trace_fraction == 1)
        {   // open at eye level
            self.flags = self.flags | FL_WATERJUMP;
            self.velocity_z = 225;
            self.flags -= (self.flags & FL_JUMPRELEASED);
			
			//self.pmove_flags |= PMF_JUMP_HELD;
			//self.pmove_jump |= PMF_JUMP_HELD;
            self.teleport_time = time + 2;  // safety net
            return;
        }
    }
}

// Reki:
// Waterlevel check code from frikbots
float() SV_CheckWater =
{
	local vector point;
	local float cont;
	
	point_x = self.origin_x;
	point_y = self.origin_y;
	self.waterlevel = 0;
	self.watertype = CONTENT_EMPTY;
	point_z = self.origin_z + self.mins_z + 1;
	cont = pointcontents(point);
	if (cont <= CONTENT_WATER)
	{
		self.watertype = cont;
		self.waterlevel = 1;
		point_z = self.origin_z + (self.mins_z + self.maxs_z) * 0.5;
		cont = pointcontents(point);
		if (cont <= CONTENT_WATER)
		{
			self.waterlevel = 2;
			point_z = self.origin_z + 22;
			cont = pointcontents(point);
			if (cont <= CONTENT_WATER)
				self.waterlevel = 3;
		}
	}
	
	return (self.waterlevel > 1);
};

// FTE's CSQC TEST CODE
.entity groundentity;
void(vector surfnorm) PMove_Rebound =
{
	float v;
	v = self.velocity*surfnorm;
	self.velocity = self.velocity - surfnorm*(v);

	if (surfnorm_z > 0.7)
	{	//if we hit a ground plane then we're now on the ground.
		self.flags |= FL_ONGROUND;
		self.groundentity = trace_ent;
	}
};

/*
==================
ClipVelocity

Slide off of the impacting object
returns the blocked flags (1 = floor, 2 = step / wall)
==================
*/
#define STOP_EPSILON 0.1
void ClipVelocity (vector in, vector normal, __out vector out, float overbounce)
{
	float i;
	float backoff;
	
	local vector oldout = in;
	
	backoff = -(in * normal) * overbounce;
	VectorMA(in, backoff, normal, out);
	//out = VectorMA(in, backoff, normal, out);
	//out = in + (normal * backoff);
	
	/*
	for (i = 0;i < 3;i++)
		if (out[i] > -STOP_EPSILON && out[i] < STOP_EPSILON)
			out[i] = 0;
	*/
	
	///*
	if (out_x > -STOP_EPSILON && out_x < STOP_EPSILON)
		out_x = 0;
	if (out_y > -STOP_EPSILON && out_y < STOP_EPSILON)
		out_y = 0;
	if (out_z > -STOP_EPSILON && out_z < STOP_EPSILON)
		out_z = 0;
	//*/
}

/*
============
PMove_PushEntity

Does not change the entities velocity at all
The trace globals are filled with the trace that has been done.
Returns true if the push did not result in the entity being teleported by QC code.
============
*/
float PMove_PushEntity (entity ent, vector push)
{
	float type;
	vector start;
	vector end;

	start = ent.origin;
	end = start + push;

	type = MOVE_NORMAL;
	//if (ent.gvelocity)
	//	type = MOVE_WORLDONLY;
	
	tracebox(start, ent.mins, ent.maxs, end, type, ent);
	
	
	// fail the move if stuck in world
	if (trace_startsolid)
		return FALSE;
	
	setorigin(ent, trace_endpos);
	//ent.origin = trace_endpos;
	//VectorCopy(trace_endpos, ent.origin);
	
	LinkEdict_TouchAreaGrid();
	
	return TRUE;
}

#define MAX_CLIP_PLANES 5
float PM_StepSlideMove_(entity ent, float move_time)
{
    float       bumpcount, numbumps;
    vector      dir;
    float       d;
    float         numplanes;
    vector      planes[MAX_CLIP_PLANES];
    vector      primal_velocity;
    float       i, j;
    vector      endv;
    float       time_left;

    numbumps = 4;
	
	primal_velocity = ent.velocity;
    numplanes = 0;

    time_left = move_time;
		


	float blocked;
	
    for (bumpcount = 0; bumpcount < numbumps; bumpcount++) {
        //for (i = 0; i < 3; i++)
        endv[0] = ent.origin[0] + time_left * ent.velocity[0];
		endv[1] = ent.origin[1] + time_left * ent.velocity[1];
		endv[2] = ent.origin[2] + time_left * ent.velocity[2];
			
		tracebox(ent.origin, ent.mins, ent.maxs, endv, MOVE_NORMAL, ent);
		
        if (trace_allsolid) {
            // entity is trapped in another solid
            ent.velocity[2] = 0;    // don't build up falling damage
            return 3;
        }

        if (trace_fraction > 0) {
            // actually covered some distance
			ent.origin = trace_endpos;
            numplanes = 0;
        }

        if (trace_fraction >= 1)
            break;     // moved the entire distance
		
		if (trace_plane_normal[2])
		{
			if (trace_plane_normal[2] > 0.7)
			{
				// floor
				blocked |= 1;

				//ent.flags |= FL_ONGROUND;
				ent.groundplane = trace_plane_normal;
				ent.flags |= FL_ONGROUND;
				ent.groundentity = trace_ent;
			}
		}


        // save entity for contact
        if (ent.numtouch < MAXTOUCH && trace_ent) {
            ent.touchents[ent.numtouch] = trace_ent;
            ent.numtouch++;
        }

        time_left -= time_left * trace_fraction;

        // slide along this plane
        if (numplanes >= MAX_CLIP_PLANES) {
            // this shouldn't really happen
			ent.velocity = 0;
            break;
        }
		
		planes[numplanes] = trace_plane_normal;
        numplanes++;

//
// modify original_velocity so it parallels all of the clip planes
//
        for (i = 0; i < numplanes; i++) {
            ClipVelocity(ent.velocity, planes[i], ent.velocity, 1.01);
            for (j = 0; j < numplanes; j++)
                if (j != i) {
                    if (ent.velocity * planes[j] < 0)
                        break;  // not ok
                }
            if (j == numplanes)
                break;
        }

        if (i != numplanes) {
            // go along this plane
        } else {
            // go along the crease
            if (numplanes != 2) {
				ent.velocity = 0;
                break;
            }
			dir = normalize(CrossProduct(planes[0], planes[1]));
            d = ent.velocity * dir;
            ent.velocity = dir * d;
        }

        //
        // if velocity is against the original velocity, stop dead
        // to avoid tiny occilations in sloping corners
        //
        if (ent.velocity * primal_velocity <= 0) {
            ent.velocity = 0;
            break;
        }
    }

	return blocked;
}

void PM_StepSlideMove(entity ent, float move_time)
{
    vector      start_o, start_v;
    vector      down_o, down_v;
    float       down_dist, up_dist;
    vector      up, down;

	ent.flags &= ~FL_ONGROUND;

	start_o = ent.origin;
	start_v = ent.velocity;

    PM_StepSlideMove_(ent, move_time);
	
	down_o = ent.origin;
	down_v = ent.velocity;
	
	up = start_o;
    up[2] += sv_stepheight;
	
	tracebox(up, ent.mins, ent.maxs, up, MOVE_NORMAL, ent);
    if (trace_allsolid)
        return;     // can't step up

    // try sliding above
	ent.origin = up;
	ent.velocity = start_v;

    PM_StepSlideMove_(ent, move_time);

    // push down the final amount
    down = ent.origin;
    down[2] -= sv_stepheight;
	
	tracebox(ent.origin, ent.mins, ent.maxs, down, MOVE_NORMAL, ent);
    if (!trace_allsolid)
        ent.origin = trace_endpos;
	
	if (trace_plane_normal[2] > 0.95)
	{
		float diff = (start_o[2] - ent.origin[2]);
		//if (diff < -4)
		//	ent.sview_height += min(diff, 0);
		//ent.sview_height += diff;
		ent.sview_height += diff;
	}
	
	up = ent.origin;

    // decide which one went farther
    down_dist = (down_o[0] - start_o[0]) * (down_o[0] - start_o[0])
                + (down_o[1] - start_o[1]) * (down_o[1] - start_o[1]);
    up_dist = (up[0] - start_o[0]) * (up[0] - start_o[0])
              + (up[1] - start_o[1]) * (up[1] - start_o[1]);

    if (down_dist > up_dist || trace_plane_normal[2] < MIN_STEP_NORMAL)
	{
		ent.origin = down_o;
		ent.velocity = down_v;
		//ent.velocity[2] = down_v[2];
        return;
    }
    //!! Special case
    // if we were walking along a plane, then we need to copy the Z over
    ent.velocity[2] = down_v[2];
}



void() PMove_ApplyFriction =
{
	float newspeed, oldspeed;
	oldspeed = vlen(self.velocity);
	if (oldspeed < 1)
	{
		self.velocity = '0 0 0';
		return;
	}
	
	//calculate what their new speed should be
	newspeed = oldspeed - oldspeed*sv_friction*input_timelength;

	//and slow them
	if (newspeed < 0)
		newspeed = 0;
	self.velocity = self.velocity * (newspeed/oldspeed);
};

void(vector wishdir, float wishspeed, float accel) PMove_Accelerate =
{
	float addspeed, accelspeed;
	float d;
	d = self.velocity*wishdir;
	addspeed = wishspeed - (d);
	if (addspeed <= 0)
		return;
	accelspeed = accel*input_timelength*wishspeed;
	if (accelspeed > addspeed)
		accelspeed = addspeed;

	self.velocity = self.velocity + accelspeed*wishdir;
};

void() PMove_NoclipAccelerate =
{
	vector desireddir;
	float desiredspeed;

	desireddir = v_forward*input_movevalues_x + v_right*input_movevalues_y+v_up*input_movevalues_z;
	desiredspeed = vlen(desireddir);
	desireddir = normalize(desireddir);

	PMove_ApplyFriction();
	PMove_Accelerate(desireddir, desiredspeed, sv_accelerate);
};

void() PMove_Categorise =
{
	tracebox(self.origin, self.mins, self.maxs, self.origin-'0 0 1', FALSE, self);
	if ((trace_fraction == 1 || trace_plane_normal_z < 0.7))
	{
		self.flags &= ~FL_ONGROUND;
	}
	else
	{
		self.flags |= FL_ONGROUND;
		self.groundentity = trace_ent;
	}
};



float roundcoordf(float f)
{	//round this coord like the networking will... ish...
	//coord rounding is often client-specific. which makes life fun.
	return rint(f*8)/8;
}
vector roundcoordv(vector v)
{
	return [
		roundcoordf(v_x),
		roundcoordf(v_y),
		roundcoordf(v_z)
	];
}
vector truncv(vector v)
{
	return v & v;
}
static void Pmove_Nudge(void)
{
	self.velocity = (self.velocity);
	vector test, org = (self.origin);

	static float offsets[] = {0, -1./8, 1./8, -2./8, 2./8};
	for (float z = 0; z < offsets.length; z++)	
	{
		test.z = org.z + offsets[z];
		for (float y = 0; y < offsets.length; y++)	
		{
			test.y = org.y + offsets[y];
			for (float x = 0; x < offsets.length; x++)	
			{
				test.x = org.x + offsets[x];
				tracebox(test, self.mins, self.maxs, test, FALSE, self);
				if (!trace_startsolid)
				{	//okay, that'll do
					self.origin = test;
					return;
				}
			}
		}
	}
	self.origin = org;
};


void PL_Acceleration()
{
	local vector wishvel, wishdir, v;
	local float wishspeed, f;

	if (self.movetype == MOVETYPE_NONE)
		return;

	if (self.punchangle != '0 0 0')
	{
		f = vlen(self.punchangle) - 20 * input_timelength;
		if (f > 0)
			self.punchangle = normalize(self.punchangle) *f;
		else
			self.punchangle = '0 0 0';
	}

	makevectors(input_angles);

	// if dead, behave differently
	if (self.deadflag != DEAD_NO)
		return;

	if (self.disablemove > 0)
		return;

	sv_maxspeed = cvar("sv_maxspeed");
	sv_friction = cvar("sv_friction");
	sv_accelerate = cvar("sv_accelerate");
	sv_stopspeed = cvar("sv_stopspeed");
	sv_edgefriction = cvar("edgefriction");

	float maxspeed = sv_maxspeed;
	if (input_buttons & BUTTON_WALK)
		maxspeed = sv_maxspeed * 0.5;

	if (self.flags & FL_WATERJUMP)
	{
		self.velocity[0] = v_forward[0] * 10;
		self.velocity[1] = v_forward[1] * 10;
		if (time > self.teleport_time || self.waterlevel == 0)
		{
			self.flags &= ~FL_WATERJUMP;
			self.teleport_time = 0;
		}
		return;
	}

	makevectors(input_angles);

	// swim
	if (self.waterlevel >= 2)
		if (self.movetype != MOVETYPE_NOCLIP)
		{
			self.flags &= ~FL_ONGROUND;

			if (input_movevalues == '0 0 0')
				wishvel = '0 0 -60';	// drift towards bottom
			else
				wishvel = (v_forward * input_movevalues[0]) + (v_right * input_movevalues[1]) + ('0 0 1' * input_movevalues[2]);

			wishspeed = vlen(wishvel);
			if (wishspeed > maxspeed)
				wishspeed = maxspeed;

			wishspeed = wishspeed *0.7;

			// water friction
			if (self.velocity != '0 0 0')
			{
				f = vlen(self.velocity) *(1 - input_timelength *sv_friction);
				if (f > 0)
					self.velocity = normalize(self.velocity) *f;
				else
					self.velocity = '0 0 0';
			}
			else
				f = 0;

			// water acceleration
			if (wishspeed <= f)
				return;

			f = min(wishspeed - f, sv_accelerate *wishspeed * input_timelength);
			self.velocity = self.velocity + normalize(wishvel) *f;
			return;
		}

	// hack to not let you back into teleporter
	if (time < self.teleport_time && input_movevalues[0] < 0)
		wishvel = v_right * input_movevalues[1];
	else
	{
		// LordHavoc: this NOCLIP check is a fix for the 'not moving while looking straight up/down when noclipping' bug in Quake
		if ((self.flags & FL_ONGROUND) || (self.movetype == MOVETYPE_NOCLIP))
			makevectors(input_angles[1] * '0 1 0');

		wishvel = (v_forward * input_movevalues[0]) + (v_right * input_movevalues[1]);
	}

	if (self.movetype != MOVETYPE_WALK)
		wishvel_z = input_movevalues[2];
	else
		wishvel_z = 0;

	wishdir = normalize(wishvel);
	wishspeed = vlen(wishvel);
	if (wishspeed > maxspeed)
		wishspeed = maxspeed;

	if (self.movetype == MOVETYPE_NOCLIP)	// noclip
	{
		self.flags &= ~FL_ONGROUND;
		self.velocity = wishdir * wishspeed * 5;
	}
	else if (self.flags & FL_ONGROUND)	// walking
	{
		// friction
		float amt = input_timelength;
		if (self.damageboost)
			amt *= 0.2;
		PL_Friction(amt);

		// acceleration
		float amt = input_timelength;
		if (self.damageboost)
			amt *= 0.6;
		f = wishspeed - (self.velocity * wishdir);
		if (f > 0)
			self.velocity = self.velocity + wishdir * min(f, sv_accelerate * amt * wishspeed);
	}
	else	// airborn
	{
		if (wishspeed < 30)
			f = wishspeed - (self.velocity * wishdir);
		else
			f = 30 - (self.velocity * wishdir);
		if (f > 0)
			self.velocity = self.velocity + wishdir *(min(f, sv_accelerate * 0.5) * wishspeed * input_timelength);
	}
}

void(entity ent) PMove =
{
	self = ent;
	makevectors(input_angles);

	//Pmove_Nudge();
	
	//if (!(input_buttons & PMF_JUMP_HELD))
	//	self.pmove_flags &= ~PMF_JUMP_HELD;

	SV_CheckWater();
	
	self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BODY;
	
	//PMove_Categorise();
	self.oldorigin = self.origin;
	if (input_timelength >= 0)
	{
		//touchtriggers(ent);
		switch(self.movetype)
		{
			case MOVETYPE_STEP:
				float applygravity = (self.waterlevel < 2);
				self.velocity_z -= sv_gravity * input_timelength;

				if (self.flags & FL_ONGROUND)
					PL_Friction(input_timelength * 0.6);
				
				PM_StepSlideMove(self, input_timelength);

				break;
			case MOVETYPE_WALK:
				
				PL_Acceleration();
				//PL_PlayerJump();
				//PMove_WalkMove(self);
				float applygravity = (self.waterlevel < 2);
				
				if (applygravity)
					self.velocity_z -= sv_gravity * 0.5 * input_timelength;

				PM_StepSlideMove(self, input_timelength);

				if (applygravity && !(self.flags & FL_ONGROUND))
					self.velocity_z -= sv_gravity * 0.5 * input_timelength;
				
				break;
			case MOVETYPE_FLY:
				PMove_NoclipAccelerate();
				PM_StepSlideMove(self, input_timelength);
				break;
			case MOVETYPE_NOCLIP:
				PMove_NoclipAccelerate();
				self.origin += self.velocity * input_timelength;
				break;
			case MOVETYPE_NONE:
				break;
		}
	}


	entity oself = self;
	for(float i = 0; i < self.numtouch && i < MAXTOUCH; i++)
	{
		self = self.touchents[i];
		if (self.touch)
		{
			other = oself;
			self.touch();
		}
		
		if (oself.touch)
		{
			other = self;
			self = oself;
			self.touch();
		}
	}
	self = oself;
	self.numtouch = 0;
}

