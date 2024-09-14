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

#include "protocol.h"
#include "physics.h"
#include "weapons.h"
#ifdef CSQC
#include "client.h"
#endif
#ifdef SSQC
#include "gamemode.h"
.float pain_finished;
#endif

#define NETFIELDS 								\
	NF_VEC(origin, 		U::ORIGIN)				\
	NF_PMVEC(velocity, 	U::VELOCITY)			\
	NF_ANGVEC(angles, 	U::ANGLES)				\
	NF_COORDVEC(view_ofs, U::ORIGIN)			\
	NF_FLOAT(sview_height, U::ORIGIN)			\
	NF_FLOAT(sview_bob, U::ORIGIN)				\
	NF_COORDVEC(mins, U::MOVETYPE)				\
	NF_COORDVEC(maxs, U::MOVETYPE)				\
	NF_BYTE(movetype, U::MOVETYPE)				\
	NF_BYTE(solid, U::MOVETYPE)					\
	NF_SHORT(disableweapon, U::MOVETYPE2)		\
	NF_SHORT(disablemove, U::MOVETYPE2)			\
	NF_BYTE(jumppadtimer, U::MOVETYPE2)			\
	NF_BYTE(liquiddamagetimer, U::MOVETYPE2)	\
	NF_PMVEC(punchangle, U::MOVETYPE2)			\
	NF_FLOAT(flags, U::FLAGS)					\
	NF_BYTE(watertype, U::FLAGS)				\
	NF_BYTE(waterlevel, U::FLAGS)				\
	NF_SHORT(effects, U::FLAGS)					\
	NF_SHORT(health, U::HEALTH)					\
	NF_BYTE(armorvalue, U::HEALTH)				\
	NF_BYTE(darmorvalue, U::HEALTH)				\
	NF_SHORT(max_health, U::HEALTH2)			\
	NF_BYTE(deadflag, U::HEALTH)				\
	NF_BYTE(damageboost, U::HEALTH)				\
	NF_BYTE(frame, U::FRAME)					\
	NF_FLOAT(framenumber, U::CFRAME)			\
	NF_FLOAT(clienttime, U::CFRAME)				\
	NF_BYTE(attack_frames, U::WEAPON)			\
	NF_BYTE(busy_frames, U::WEAPON)				\
	NF_BYTE(impulse, U::WEAPON)					\
	NF_BYTE(weapon_wanted, U::WEAPON)			\
	NF_BYTE(weapon, U::WEAPON)					\
	NF_BITFIELD(weapon_mode, U::WEAPON)			\
	NF_SHORT(weapon_cooldown, U::WEAPON2)		\
	NF_SHORT(weapon_animfinish, U::WEAPON2) 	\
	NF_SHORT(weapon_last, U::WEAPON2) 			\
	NF_FLOAT(items, U::ITEMS)					\
	NF_BYTE(ammo_slugs, U::AMMO1)				\
	NF_BYTE(ammo_shells, U::AMMO1)				\
	NF_BYTE(ammo_ore, U::AMMO1)					\
	NF_BYTE(ammo_lances, U::AMMO1)				\
	NF_BYTE(ammo_cysts, U::AMMO2)				\
	NF_SHORT(ammo_fangs, U::AMMO2)				\
	NF_BYTE(ammo_souls, U::AMMO2)				\
	NF_SHORT(ammo_crystals, U::AMMO2)			\

.vector oldin_movevalues;
.float oldin_buttons;
.vector clin_movevalues;
.float clin_buttons;
.float oldclienttime;


#define NF_VEC(field, fl)		vector #field;
#define NF_SHORTVEC(field, fl)	vector #field;
#define NF_PMVEC(field, fl)		vector #field;
#define NF_COORDVEC(field, fl)	vector #field;
#define NF_ANGVEC(field, fl)	vector #field;
#define NF_FLOAT(field, fl)		float #field;
#define NF_BITFIELD(field, fl)	float #field;
#define NF_SHORT(field, fl)		float #field;
#define NF_BYTE(field, fl)		float #field;
#define NF_EDICT(field, fl)		float #field;
typedef struct {
#ifdef CSQC
	float status;
#endif
	NETFIELDS
} playernet_t;
#undef NF_VEC
#undef NF_SHORTVEC
#undef NF_PMVEC
#undef NF_COORDVEC
#undef NF_ANGVEC
#undef NF_FLOAT
#undef NF_BITFIELD
#undef NF_SHORT
#undef NF_BYTE
#undef NF_EDICT

#define NF_VEC(field, fl)		.vector field;
#define NF_SHORTVEC(field, fl)	.vector field;
#define NF_PMVEC(field, fl)		.vector field;
#define NF_COORDVEC(field, fl)	.vector field;
#define NF_ANGVEC(field, fl)	.vector field;
#define NF_FLOAT(field, fl)		.float field;
#define NF_BITFIELD(field, fl)	.float field;
#define NF_SHORT(field, fl)		.float field;
#define NF_BYTE(field, fl)		.float field;
#ifdef SSQC
#define NF_EDICT(field, fl)		.entity field;
#else
#define NF_EDICT(field, fl)		.float field;
#endif
NETFIELDS
#undef NF_VEC
#undef NF_SHORTVEC
#undef NF_PMVEC
#undef NF_COORDVEC
#undef NF_ANGVEC
#undef NF_FLOAT
#undef NF_BITFIELD
#undef NF_SHORT
#undef NF_BYTE
#undef NF_EDICT

#ifdef CSQC // ew hack
#include "prediction.h"
#endif

void NetField_EntityToStruct(entity ent, .playernet_t netstorage)
{
	#define NF_VEC(field, fl)		ent.netstorage.field = ent.field;
	#define NF_SHORTVEC(field, fl)	ent.netstorage.field = ent.field;
	#define NF_PMVEC(field, fl)		ent.netstorage.field = ent.field;
	#define NF_COORDVEC(field, fl)	ent.netstorage.field = ent.field;
	#define NF_ANGVEC(field, fl)	ent.netstorage.field = ent.field;
	#define NF_FLOAT(field, fl)		ent.netstorage.field = ent.field;
	#define NF_BITFIELD(field, fl)	ent.netstorage.field = ent.field;
	#define NF_SHORT(field, fl)		ent.netstorage.field = ent.field;
	#define NF_BYTE(field, fl)		ent.netstorage.field = ent.field;
	#ifdef SSQC
	#define NF_EDICT(field, fl)		ent.netstorage.field = num_for_edict(ent.netstorage.field);
	#else
	#define NF_EDICT(field, fl)		ent.netstorage.field = ent.netstorage.field;
	#endif
	NETFIELDS
	#undef NF_VEC
	#undef NF_SHORTVEC
	#undef NF_PMVEC
	#undef NF_COORDVEC
	#undef NF_ANGVEC
	#undef NF_FLOAT
	#undef NF_BITFIELD
	#undef NF_SHORT
	#undef NF_BYTE
	#undef NF_EDICT
}

void NetField_StructToEntity(entity ent, .playernet_t netstorage)
{
	#define NF_VEC(field, fl)		ent.field = ent.netstorage.field;
	#define NF_SHORTVEC(field, fl)	ent.field = ent.netstorage.field;
	#define NF_PMVEC(field, fl)		ent.field = ent.netstorage.field;
	#define NF_COORDVEC(field, fl)	ent.field = ent.netstorage.field;
	#define NF_ANGVEC(field, fl)	ent.field = ent.netstorage.field;
	#define NF_FLOAT(field, fl)		ent.field = ent.netstorage.field;
	#define NF_BITFIELD(field, fl)	ent.field = ent.netstorage.field;
	#define NF_SHORT(field, fl)		ent.field = ent.netstorage.field;
	#define NF_BYTE(field, fl)		ent.field = ent.netstorage.field;
	#ifdef SSQC
	#define NF_EDICT(field, fl)		ent.field = edict_num(ent.netstorage.field);
	#else
	#define NF_EDICT(field, fl)		ent.field = ent.netstorage.field;
	#endif
	NETFIELDS
	#undef NF_VEC
	#undef NF_SHORTVEC
	#undef NF_PMVEC
	#undef NF_COORDVEC
	#undef NF_ANGVEC
	#undef NF_FLOAT
	#undef NF_BITFIELD
	#undef NF_SHORT
	#undef NF_BYTE
	#undef NF_EDICT

	setsize(ent, ent.mins, ent.maxs);
	setorigin(ent, ent.origin);
}

void NetField_StructToStruct(entity ent, .playernet_t from, .playernet_t to)
{
	#define NF_VEC(field, fl)		ent.to.field = ent.from.field;
	#define NF_SHORTVEC(field, fl)	ent.to.field = ent.from.field;
	#define NF_PMVEC(field, fl)		ent.to.field = ent.from.field;
	#define NF_COORDVEC(field, fl)	ent.to.field = ent.from.field;
	#define NF_ANGVEC(field, fl)	ent.to.field = ent.from.field;
	#define NF_FLOAT(field, fl)		ent.to.field = ent.from.field;
	#define NF_BITFIELD(field, fl)	ent.to.field = ent.from.field;
	#define NF_SHORT(field, fl)		ent.to.field = ent.from.field;
	#define NF_BYTE(field, fl)		ent.to.field = ent.from.field;
	#define NF_EDICT(field, fl)		ent.to.field = ent.from.field;
	NETFIELDS
	#undef NF_VEC
	#undef NF_SHORTVEC
	#undef NF_PMVEC
	#undef NF_COORDVEC
	#undef NF_ANGVEC
	#undef NF_FLOAT
	#undef NF_BITFIELD
	#undef NF_SHORT
	#undef NF_BYTE
	#undef NF_EDICT
}

#ifdef CSQC
.playernet_t net_oldserver;
.playernet_t net_server;
.playernet_t net_predicted;

void(entity edict, .genericnet_t gstruct) PL_GEntToStruct
{
	if (gstruct == netg_server)
		NetField_EntityToStruct(edict, net_server);
	else if (gstruct == netg_oldserver)
		NetField_EntityToStruct(edict, net_oldserver);
	else if (gstruct == netg_predicted)
		NetField_EntityToStruct(edict, net_predicted);
}

void(entity edict, .genericnet_t gstruct) PL_GStructToEnt
{
	if (gstruct == netg_server)
		NetField_StructToEntity(edict, net_server);
	else if (gstruct == netg_oldserver)
		NetField_StructToEntity(edict, net_oldserver);
	else if (gstruct == netg_predicted)
		NetField_StructToEntity(edict, net_predicted);
}

void(entity edict, .genericnet_t g1, .genericnet_t g2) PL_GStructToStruct
{
	.playernet_t f1;
	.playernet_t f2;

	if (g1 == netg_server)
		f1 = net_server;
	if (g1 == netg_oldserver)
		f1 = net_oldserver;
	if (g1 == netg_predicted)
		f1 = net_predicted;

	if (g2 == netg_server)
		f2 = net_server;
	if (g2 == netg_oldserver)
		f2 = net_oldserver;
	if (g2 == netg_predicted)
		f2 = net_predicted;

	NetField_StructToStruct(edict, f1, f2);
}
#endif
#ifdef SSQC
.playernet_t net_lastsent;

void PL_NetCheck(entity ent, .playernet_t netstorage)
{
	#define NF_VEC(field, fl)		if (ent.field != ent.netstorage.field) { ent.netstorage.field = ent.field; ent.SendFlags |= fl; };
	#define NF_SHORTVEC(field, fl)	if (ent.field != ent.netstorage.field) { ent.netstorage.field = ent.field; ent.SendFlags |= fl; };
	#define NF_PMVEC(field, fl)		if (ent.field != ent.netstorage.field) { ent.netstorage.field = ent.field; ent.SendFlags |= fl; };
	#define NF_COORDVEC(field, fl)	if (ent.field != ent.netstorage.field) { ent.netstorage.field = ent.field; ent.SendFlags |= fl; };
	#define NF_ANGVEC(field, fl)	if (ent.field != ent.netstorage.field) { ent.netstorage.field = ent.field; ent.SendFlags |= fl; };
	#define NF_FLOAT(field, fl)		if (ent.field != ent.netstorage.field) { ent.netstorage.field = ent.field; ent.SendFlags |= fl; };
	#define NF_BITFIELD(field, fl)	if (ent.field != ent.netstorage.field) { ent.netstorage.field = ent.field; ent.SendFlags |= fl; };
	#define NF_SHORT(field, fl)		if (ent.field != ent.netstorage.field) { ent.netstorage.field = ent.field; ent.SendFlags |= fl; };
	#define NF_BYTE(field, fl)		if (ent.field != ent.netstorage.field) { ent.netstorage.field = ent.field; ent.SendFlags |= fl; };
	#define NF_EDICT(field, fl)		if (num_for_edict(ent.field) != ent.netstorage) { ent.netstorage.field = num_for_edict(ent.field); ent.SendFlags |= fl; };
	NETFIELDS
	#undef NF_VEC
	#undef NF_SHORTVEC
	#undef NF_PMVEC
	#undef NF_COORDVEC
	#undef NF_ANGVEC
	#undef NF_FLOAT
	#undef NF_BITFIELD
	#undef NF_SHORT
	#undef NF_BYTE
	#undef NF_EDICT

	#if 1
	if (ent.SendFlags > U::MOREBYTES16)
	{
		ent.SendFlags |= U::MOREBYTES16;
		if (ent.SendFlags > U::MOREBYTES24)
		{
			ent.SendFlags |= U::MOREBYTES24;
			if (ent.SendFlags > U::MOREBYTES32)
				ent.SendFlags |= U::MOREBYTES32;
		}
	}
	#endif
}
#endif

.float health;
.float waterlevel;
.float watertype;
.float teleport_time;
.float oldflags;
.vector oldvelocity;

#ifdef SSQC
void PL_PainSound(entity pl)
{
	if (time < pl.pain_finished)
		return;

	pl.pain_finished = time + 0.5;
	sound(pl, CHAN_VOICE, sprintf("player/hurt%g.ogg", floor(random() * 5) + 1), 1, ATTN_VOICE);
}

void PL_DeathSound(entity pl)
{
	sound(pl, CHAN_VOICE, sprintf("player/die%g.ogg", floor(random() * 5) + 1), 1, ATTN_SCREAM);
}
#endif

void PL_Death(entity pl)
{
	pl.deadflag = DEAD_DEAD;
	pl.takedamage = DAMAGE_NO;
	pl.movetype = MOVETYPE_STEP;
	pl.health = 0;
	pl.weapon = WEAPON::NULL;
	pl.weapon_mode = 0;
	pl.effects = 0;
	pl.busy_frames = 60;
	pl.solid = SOLID_CORPSE;

	#ifdef SSQC
	pl.deaths++;
	PL_DeathSound(pl);
	#endif
}

#define DARKARMOR_SAVE		1
#define DARKARMOR_TAKE		0.8
#define ARMOR_SAVE			0.6
#define ARMOR_TAKE			0.6
void Hud_SendKillfeed(entity ownr, string icon, entity p1, entity p2, float fl);
void PL_TakeDamage(vector knockback, float damage, float fl, entity dealer, entity victim)
{
	#ifdef SSQC
	if (time < gametime_start)
		return;
	#endif

	if (victim.takedamage == DAMAGE_NO)
	{
		victim.velocity += knockback;
		return;
	}

	if (dealer == victim)
		damage *= 0.5;
	
	if (victim.darmorvalue > 0)
	{
		float take;
		float save;
		float amt = ceil(min(damage * DARKARMOR_TAKE, victim.darmorvalue));
		take = amt;
		save = (amt / DARKARMOR_TAKE) * DARKARMOR_SAVE;
		
		victim.darmorvalue -= take;
		damage -= save;
	}

	if (victim.armorvalue > 0)
	{
		float take;
		float save;
		float amt = ceil(min(damage * ARMOR_TAKE, victim.armorvalue));
		take = amt;
		save = (amt / ARMOR_TAKE) * ARMOR_SAVE;
		
		victim.armorvalue -= take;
		damage -= save;
	}

	damage = max(0, floor(damage));

	if (vlen(knockback) > 20)
		victim.damageboost = 120;
	victim.velocity += knockback;
	victim.health -= damage;
	if (victim.velocity[2] > 0)
		victim.flags &= ~FL_ONGROUND;
	
	#ifdef SSQC
	if (dealer != victim)
	{
		if (dealer)
			dealer.damage_given += damage;
		victim.damage_taken += damage;
	}

	if (victim.health <= 0)
	{
		PL_Death(victim);

		if (victim != dealer && dealer)
		{
			Hud_SendKillfeed(world, "full", dealer, victim, NOTIFICATIONFLAG::TIMESTAMP);
			dealer.frags++;
		}
		else
		{
			Hud_SendKillfeed(world, "full", 0, victim, NOTIFICATIONFLAG::TIMESTAMP);
			victim.frags--;
		}
	}
	else
	{
		if (damage > 3)
			PL_PainSound(victim);
	}
	#endif
}

void PL_Friction(float dt)
{
	vector wishvel, wishdir, v;
	float wishspeed, f;

	if (self.velocity_x || self.velocity_y)
	{
		v = self.velocity;
		v_z = 0;
		f = vlen(v);

		// if the leading edge is over a dropoff, increase friction
		v = self.origin + normalize(v) *16 + '0 0 1' *self.mins_z;

		traceline(v, v + '0 0 -34', TRUE, self);

		// apply friction
		if (trace_fraction == 1.0)
		{
			if (f < sv_stopspeed)
				f = 1 - dt * (sv_stopspeed / f) * sv_friction * sv_edgefriction;
			else
				f = 1 - dt * sv_friction * sv_edgefriction;
		}
		else
		{
			if (f < sv_stopspeed)
				f = 1 - dt * (sv_stopspeed / f) * sv_friction;
			else
				f = 1 - dt * sv_friction;
		}

		if (f < 0)
			self.velocity = '0 0 0';
		else
			self.velocity = self.velocity * f;
	}
}

void PL_NetRounding(entity ent)
{
	//ent.sview_bob = ceil(ent.sview_bob * 0x1FFF);

	#define NF_VEC(field, fl)		ent.field = ent.field;
	#define NF_SHORTVEC(field, fl)	ent.field[0] = floor(ent.field[0] & 0xFFFF); ent.field[1] = floor(ent.field[1] & 0xFFFF); ent.field[2] = floor(ent.field[2] & 0xFFFF);
	#define NF_PMVEC(field, fl)		ent.field[0] = round(ent.field[0] * 8) / 8; ent.field[1] = round(ent.field[1] * 8) / 8; ent.field[2] = round(ent.field[2] * 8) / 8;
	#define NF_COORDVEC(field, fl)	ent.field = ent.field;
	#define NF_ANGVEC(field, fl)	ent.field = ent.field;
	#define NF_FLOAT(field, fl)		ent.field = ent.field;
	#define NF_BITFIELD(field, fl)	ent.field = floor(ent.field & 0xFFFFFF);
	#define NF_SHORT(field, fl)		ent.field = floor(ent.field & 0xFFFF);
	#define NF_BYTE(field, fl)		ent.field = floor(ent.field & 0xFF);
	#define NF_EDICT(field, fl)		ent.field = ent.field;
	NETFIELDS
	#undef NF_VEC
	#undef NF_SHORTVEC
	#undef NF_COORDVEC
	#undef NF_ANGVEC
	#undef NF_FLOAT
	#undef NF_BITFIELD
	#undef NF_SHORT
	#undef NF_BYTE
	#undef NF_EDICT
}

#ifdef SSQC
void PL_Respawn();
#endif
void PL_DeadThink()
{
	//if (self.flags & FL_ONGROUND)
	//{
	self.sview_height = max(-30, self.sview_height - (input_timelength * 110));
	//}
	ClientServerFrame();
	#ifdef SSQC
	if (self.busy_frames <= 0 || (self.busy_frames <= 50 && input_buttons & BUTTON_FIRE))
	{
		PL_Respawn();
	}
	#endif
}

void PL_PreThink()
{
	self.oldflags = self.flags;
	self.oldvelocity = self.velocity;

	#ifdef SSQC
	if (time < gametime_start)
	{
		self.disablemove = (gametime_start - time) * 1000;
		self.disableweapon = (gametime_start - time) * 1000;
	}
	#endif

	if (self.deadflag != DEAD_NO)
	{
		self.angles[0] = 0;
		self.angles[2] = 0;
		PL_DeadThink();
		return;
	}

	//self.sview_bob /= 0x1FFF;
	self.angles = input_angles;

	// hacky quick boost system
	if (self.flags & FL_QUICKBOOST)
	{
		if (self.weapon != WEAPON::BLADE)
		{
			input_buttons &= ~(BUTTON_ALTFIRE | BUTTON_FIRE);
			self.weapon_wanted = WEAPON::BLADE;
		}
		else
		{
			wep_phase = self.weapon_mode & 0x000F;
			if (wep_phase == 0x2 && !self.busy_frames && !(input_buttons & BUTTON_CROUCH))
			{
				self.flags &= ~FL_QUICKBOOST;
				self.weapon_wanted = self.weapon_last;
			}
			else if (wep_phase != 0x1)
			{
				input_buttons |= BUTTON_ALTFIRE;
			}
			else if !(input_buttons & BUTTON_CROUCH)
			{
				input_buttons &= ~(BUTTON_ALTFIRE | BUTTON_FIRE);
			}
			else
			{
				input_buttons |= BUTTON_ALTFIRE;
			}
		}
	}
	else
	{
		if (input_buttons & BUTTON_CROUCH)
		{
			if (self.weapon != WEAPON::BLADE)
			{
				self.flags |= FL_QUICKBOOST;
			}
			else
			{
				input_buttons |= BUTTON_ALTFIRE;
			}
		}
	}
}

void PL_Jump()
{
	if ((input_buttons & BUTTON_JUMP) && (self.disablemove <= 0)) // jumping physics
	{
		if (self.waterlevel >= 2)
		{
			if (self.watertype == CONTENT_WATER)
				self.velocity_z = 100;
			else if (self.watertype == CONTENT_SLIME)
				self.velocity_z = 80;
			else
				self.velocity_z = 100;
		}
		else if (self.flags & FL_JUMPRELEASED)
		{
			if (self.flags & FL_ONGROUND)
			{
				if (!(self.oldflags & FL_ONGROUND) && (self.velocity[2] >= 0))
					PL_Friction(0.014);
				
				PEvent_Sound(self, CHAN_VOICE, sprintf("player/jumps/jump%g.ogg", floor(random() * 4) + 1), 1, ATTN_VOICE);
				
				//self.flags &= ~FL_JUMPRELEASED;
				self.flags &= ~FL_ONGROUND;
				if (self.velocity[2] < 0)
				{
					self.velocity += (self.groundplane * 200);
					self.velocity[2] += 70;
				}
				else
				{
					self.velocity[2] += 270;
				}
			}
		}
	}
	else
	{
		self.flags |= FL_JUMPRELEASED;
	}
}

void PL_PostThink()
{
	if (self.deadflag != DEAD_NO)
		return;

	if (!boxesoverlap(self.absmin, self.absmax, world.absmin, world.absmax)) // uhh.. we're out of the world
	{
		PL_TakeDamage(0, 999, 0, world, self);
		return;
	}

/* #region fall damage logic */
	if (self.flags & FL_ONGROUND)
	{
		float diff = (self.velocity[2] - self.oldvelocity[2]);
		if (diff > 250)
		{
			if (diff > 650)
			{
				PL_LandingSound(self, 1);
			}
			else
			{
				PL_LandingSound(self, 0);
			}
		}
	}
/* #endregion */

	PL_Jump();

	// stair smooth view
	float sview_spd = 120;
	if (fabs(self.sview_height) > 4)
		sview_spd = 160;
	if (self.sview_height < 0)
		self.sview_height = min(0, self.sview_height + input_timelength * sview_spd);
	else if (self.sview_height > 0)
		self.sview_height = max(0, self.sview_height - input_timelength * sview_spd);
	self.sview_height = bound(-16, self.sview_height, 16);
	// move viewbob
	if (self.flags & FL_ONGROUND)
	{
		float vel = vlen([self.velocity[0], self.velocity[1], 0]);
		if (vel > 10)
		{
			float old_bob = self.sview_bob;
			self.sview_bob += 2 * input_timelength;
			self.sview_bob += (vel / 55) * input_timelength;

			float modif = -M_PI/2;
			float scaler = 1/M_PI;
			if ((floor((self.sview_bob - modif) * scaler) - floor((old_bob - modif) * scaler)) >= 1)
			{
				#ifdef SSQC
				PL_Footstep(self);
				#endif
			}
		}
	}
	else
	{
		self.sview_bob += 1.8 * input_timelength;
	}
	#ifdef CSQC
	viewmodel.sview_bob = self.sview_bob;
	viewmodel.velocity = self.velocity;
	#endif
	//

	ClientServerFrame();

	PL_NetRounding(self);
	self.oldflags = self.flags;
}

void PL_RunPhysics(entity ent)
{
	entity o_self = self;
	self = ent;

	if (input_impulse)
		ent.impulse = input_impulse;
	
		
	//#ifdef SSQC
	PL_PreThink();
	PMove(ent);
	touchtriggers(ent);
	//PL_Acceleration();
	//runstandardplayerphysics(ent);
	PL_PostThink();
	//#endif

	setorigin(ent, ent.origin);
	self = o_self;
}


#ifdef SSQC
float SendEntity_Player(entity to, float sendflags)
{
	WriteByte(MSG_ENTITY, NENT::Player);

	float localflags;
	if (to == self)
	{
		localflags |= LF::LOCAL;
	}
	else
	{
		if (to.watching == self)
			localflags |= LF::SPECTATOR;
		localflags |= LF::REMOTE;
	}

	#if 0
	if (sendflags > U::MOREBYTES16)
	{
		sendflags |= U::MOREBYTES16;
		if (sendflags > U::MOREBYTES24)
		{
			sendflags |= U::MOREBYTES24;
			if (sendflags > U::MOREBYTES32)
				sendflags |= U::MOREBYTES32;
		}
	}
	#endif

	WriteByte(MSG_ENTITY, localflags);
	WriteByte(MSG_ENTITY, sendflags & 0x000000FF);
	if (sendflags & U::MOREBYTES16)
	{
		WriteByte(MSG_ENTITY, (sendflags & 0x0000FF00) >> 8);
		if (sendflags & U::MOREBYTES24)
		{
			WriteByte(MSG_ENTITY, (sendflags & 0x00FF0000) >> 16);
			if (sendflags & U::MOREBYTES32)
			{
				WriteByte(MSG_ENTITY, (sendflags & 0xFF000000) >> 24);
			}
		}
	}

	if ((localflags & LF::LOCAL) || (localflags & LF::SPECTATOR)) // sync prediction values
	{
		#define NF_VEC(field, fl)		if (sendflags & fl) { WriteVectorF(MSG_ENTITY, self.net_lastsent.field); };
		#define NF_SHORTVEC(field, fl)	if (sendflags & fl) { WriteVectorS(MSG_ENTITY, self.net_lastsent.field); };
		#define NF_PMVEC(field, fl)		if (sendflags & fl) { WriteVectorS(MSG_ENTITY, self.net_lastsent.field * 8); };
		#define NF_COORDVEC(field, fl)	if (sendflags & fl) { WriteVectorL(MSG_ENTITY, self.net_lastsent.field); };
		#define NF_ANGVEC(field, fl)	if (sendflags & fl) { WriteVectorA(MSG_ENTITY, self.net_lastsent.field); };
		#define NF_FLOAT(field, fl)		if (sendflags & fl) { WriteFloat(MSG_ENTITY, self.net_lastsent.field); };
		#define NF_BITFIELD(field, fl)	if (sendflags & fl) { WriteShort(MSG_ENTITY, self.net_lastsent.field & 0x00FFFF); WriteByte(MSG_ENTITY, (self.net_lastsent.field & 0xFF0000) >> 16); };
		#define NF_SHORT(field, fl)		if (sendflags & fl) { WriteShort(MSG_ENTITY, self.net_lastsent.field); };
		#define NF_BYTE(field, fl)		if (sendflags & fl) { WriteByte(MSG_ENTITY, self.net_lastsent.field); };
		#define NF_EDICT(field, fl)		if (sendflags & fl) { WriteShort(MSG_ENTITY, self.net_lastsent.field); };
		NETFIELDS
		#undef NF_VEC
		#undef NF_SHORTVEC
		#undef NF_PMVEC
		#undef NF_COORDVEC
		#undef NF_FLOAT
		#undef NF_BITFIELD
		#undef NF_SHORT
		#undef NF_BYTE
		#undef NF_EDICT
	}
	else if (localflags & LF::REMOTE)
	{
		WriteVectorB(MSG_ENTITY, self.clin_movevalues / 640);
		WriteByte(MSG_ENTITY, self.clin_buttons);

		if (sendflags & U::ORIGIN)
		{
			WriteVectorL(MSG_ENTITY, self.net_lastsent.origin);
		}

		if (sendflags & U::VELOCITY)
		{
			WriteVectorS(MSG_ENTITY, self.net_lastsent.velocity);
		}

		if (sendflags & U::ANGLES)
		{
			WriteVectorA(MSG_ENTITY, self.angles);
		}

		if (sendflags & U::MOVETYPE)
		{
			WriteVectorS(MSG_ENTITY, self.net_lastsent.mins);
			WriteVectorS(MSG_ENTITY, self.net_lastsent.maxs);
			WriteByte(MSG_ENTITY, self.net_lastsent.solid);
			WriteByte(MSG_ENTITY, self.net_lastsent.movetype);
		}

		if (sendflags & U::WEAPON)
		{
			WriteByte(MSG_ENTITY, self.net_lastsent.weapon);
			WriteByte(MSG_ENTITY, self.net_lastsent.weapon_mode >> 16);
		}

		if (sendflags & U::FLAGS)
		{
			WriteLong(MSG_ENTITY, self.net_lastsent.flags);
			WriteShort(MSG_ENTITY, self.net_lastsent.effects);
		}

		if (sendflags & U::HEALTH)
		{
			WriteByte(MSG_ENTITY, self.net_lastsent.deadflag);
		}
	}

	if (sendflags & U::MODEL)
	{
		//WriteShort(MSG_ENTITY, self.modelindex);
	}

	return TRUE;
}
#endif
#ifdef CSQC
float autocvar_cl_movement;
float autocvar_cl_rollangle;
float autocvar_cl_rollspeed;
.vector origin_errorcorrection;
.entity m_head;
.entity m_torso;
.entity m_legs;
.entity wepent;
void Player_LocalPredraw(void)
{
	if (autocvar_cl_movement && clientcommandframe)
	{
		if (self.net_server.status == 1)
		{
			self.net_server.status = 0;

			Predict_GameState(TRUE, net_oldserver);
			vector rough_origin = self.origin;

			Predict_GameState(FALSE, net_server);

			NetField_EntityToStruct(self, net_predicted);
			Predict_SaveAllActors(netg_predicted);

			self.origin_errorcorrection = (self.origin + self.origin_errorcorrection) - rough_origin;

			/*
			NetField_StructToEntity(self, net_predicted);
			self.framenumber = max(servercommandframe - 50, self.framenumber);
			//slagball.velocity = slagball.start_velocity;
			framenum = sv_framenum;
			for(self.framenumber; self.framenumber < clientcommandframe; self.framenumber++)
			{
				getinputstate(self.framenumber);
				framenum += (input_timelength / sv_ticrate);

				PL_RunPhysics(self);
			}
			vector rough_origin = self.origin;


			NetField_StructToEntity(self, net_oldserver);
			self.framenumber = max(servercommandframe - 50, self.framenumber);
			// current frame
			//slagball.velocity = slagball.start_velocity;
			framenum = sv_framenum;
			is_effectframe = FALSE;
			for(self.framenumber; self.framenumber < clientcommandframe; self.framenumber++)
			{
				getinputstate(self.framenumber);
				if (self.framenumber > effectframe)
				{
					is_effectframe = TRUE;
					effectframe = self.framenumber;
				}

				framenum += (input_timelength / sv_ticrate);
				PL_RunPhysics(self);
			}
			is_effectframe = FALSE;

			NetField_EntityToStruct(self, net_predicted);
			self.framenumber = max(servercommandframe - 50, self.framenumber);
			self.origin_errorcorrection = (self.origin + self.origin_errorcorrection) - rough_origin;
			//float diff = vlen(self.origin - rough_origin);
			//if (diff > 0.1)
			//	print("ORIGIN DESYNC: ", ftos(diff), "\n");
			*/
		}

		Predict_GameState(FALSE, net_predicted);

		// xerp frame
		float o_frametime = frametime;
		getinputstate(clientcommandframe);
		frametime = input_timelength;
		Predict_SimulateAllActors();
		PL_RunPhysics(self);
		frametime = o_frametime;


		/*
		NetField_StructToEntity(self, net_predicted);

		// current frame
		//slagball.velocity = slagball.start_velocity;
		framenum = sv_framenum;
		for(self.framenumber; self.framenumber < clientcommandframe; self.framenumber++)
		{
			getinputstate(self.framenumber);
			framenum += (input_timelength / sv_ticrate);

			PL_RunPhysics(self);
		}

		// xerp frame
		getinputstate(clientcommandframe);
		PL_RunPhysics(self);
		//
		*/

		float err = vlen(self.origin_errorcorrection);
		vector norm = normalize(self.origin_errorcorrection);

		float spd = 10;
		if (err > 128)
			err = 0;
		else if (err > 96)
			spd = 600;
		else if (err > 64)
			spd = 400;
		else if (err > 32)
			spd = 250;
		else if (err > 12)
			spd = 200;
		else if (err > 4)
			spd = 90;
		err = max(0, err - clframetime * spd);
		self.origin_errorcorrection = err * norm;
	}
	else
	{
		self.origin_errorcorrection = 0;
		NetField_StructToEntity(self, net_server);

		float frac = cl_framenum - sv_framenum;
		self.origin = lerpVector(self.net_oldserver.origin, self.net_server.origin, frac);
		setorigin(self, self.origin);
		self.angles = view_angles;

		viewmodel.effects = self.effects;
		viewmodel.weapon_mode = self.weapon_mode;
		viewmodel.weapon = self.weapon;
		viewmodel.weapon_animfinish = self.weapon_animfinish;
		viewmodel.clienttime = self.clienttime;
		viewmodel.sview_bob = self.sview_bob;
		viewmodel.velocity = self.velocity;
	}

	//print(vtos(self.origin), "\n");
	view_origin = self.origin - self.origin_errorcorrection;
	view_origin += self.view_ofs;
	view_origin[2] += self.sview_height;

	if (autocvar_cl_rollangle)
	{
		makevectors(view_angles);
		
		static float sideroll;
		float roll_wanted = (v_right * self.velocity) / autocvar_cl_rollspeed;
		float ft = min(1, frametime * 22);
		sideroll = lerp(sideroll, roll_wanted, ft);

		view_angles[2] = bound(-autocvar_cl_rollangle, sideroll * autocvar_cl_rollangle, autocvar_cl_rollangle);
	}

	if (self.deadflag == DEAD_DEAD)
	{
		float frac = max(0, -self.sview_height / 30);
		view_angles[2] += 20 * frac;
	}

	view_angles += self.punchangle;
	
	vector h_org = self.origin;
	NetField_StructToEntity(self, net_predicted);
	self.origin = h_org;

	self.framenumber = max(servercommandframe - 50, self.framenumber);
	W_Render();

	if ((viewmodel.effects) & EF_MUZZLEFLASH)
	{
		makevectors(view_angles);
		adddynamiclight2(self.origin + (v_up * 8) + (v_forward * 16), 150, '1 0.8 0.6', 0, "", 3);
	}

	// hit beeps
	static float hitbeep_framenum;
	float hitbeep_data = getstatf(STAT::HITBEEP_DATA);
	float fnum = hitbeep_data & 0xFF;
	if (fnum > hitbeep_framenum || (hitbeep_framenum - fnum) > 64)
	{
		float dmg_given = (hitbeep_data >> 8) & 0xFF;
		float dmg_taken = ((hitbeep_data >> 16) & 0xF) * 10;
		float hitflags = (hitbeep_data >> 20) & 0xF;
		hitbeep_framenum = fnum;

		if (dmg_given > 0)
		{
			string noise;
			if (dmg_given <= 20)
				noise = "misc/hit20.wav";
			else if (dmg_given <= 40)
				noise = "misc/hit40.wav";
			else if (dmg_given <= 60)
				noise = "misc/hit60.wav";
			else
				noise = "misc/hit80.wav";
			sound(world, CHAN_AUTO, noise, 1, ATTN_NONE);
			r_crosshairhighlight_time = cltime + 0.15;
		}
	}
	//
}

void Player_CPhysics(void)
{
	if (vlen([self.velocity[0], self.velocity[1], 0]) < 120) // reign in A/D spam a little bit
		input_movevalues = '0 0 0';
	float o_timelength = input_timelength;
	float tleft = frametime;
	while(tleft > 0)
	{
		float tamt = min(tleft, 0.05);
		input_timelength = tamt;
		PMove(self);
		tleft -= tamt;
	}
	input_timelength = o_timelength;

	//self.velocity[2] -= sv_gravity * frametime * 0.5;
	//self.origin += self.velocity * frametime;
	//self.velocity[2] -= sv_gravity * frametime * 0.5;
}

.float legang;
.float legang_wanted;
.vector old_velocity;
.float animcheck_time;
#define PLAYER_ANIM_TIC	0.1
void Player_AnimationCheck(void)
{
	entity head = self.m_head;
	entity torso = self.m_torso;
	entity legs = self.m_legs;

	float legframe = legs.frame;
	float torsoframe = torso.frame;
	float headframe = head.frame;

	legs.old_velocity = legs.velocity;
	legs.velocity = self.velocity;
	legs.deadflag = self.deadflag;

	if (self.deadflag == DEAD_NO)
	{
		// legs
		legframe = 13;
		vector vel_angs = vectoangles([self.velocity[0], self.velocity[1], 0]);
		float vel_len = vlen(self.velocity);
		if (vel_len > 30)
		{
			if (vel_len > 240)
			{
				makevectors([0, legs.legang, 0]);
				if (self.velocity * v_forward > 0)
					legframe = 8;
				else
					legframe = 9;
			}
			else
				legframe = 7;
		}

		if !(self.flags & FL_ONGROUND)
		{
			legframe = legs.frame;
			if (self.velocity[2] < -160)
				legframe = 12;
			else if (self.velocity[2] < -60)
			{
				tracebox(self.origin, self.mins, self.maxs, self.origin + '0 0 -32', MOVE_NORMAL, self);
				if (trace_fraction >= 1)
					legframe = 12;
			}
			else if (self.velocity[2] > 20)
				legframe = 11;
		}
		//

		if (self.weapon_mode & WEAPON_FLAG_PUTAWAY)
		{
			torsoframe = 22;
		}
		else
		{
			if (self.weapon == WEAPON::COACHGUN)
				torsoframe = 23;
			else if (self.weapon == WEAPON::BLADE)
				torsoframe = 21;
			else
				torsoframe = 25;
			if (self.effects & EF_MUZZLEFLASH)
				torsoframe -= 10;
		}
	}
	else
	{
		headframe = 0;
		torsoframe = 0;
		legframe = 0;
	}

	head.frame2 = 0;
	torso.frame2 = 0;
	legs.frame2 = 0;
	if (head.frame != headframe)
	{
		head.frame2 = head.frame;
		head.frame2time = head.frame1time;
		head.frame = headframe;
		head.frame1time = self.animcheck_time;
	}
	if (torso.frame != torsoframe)
	{
		torso.frame2 = torso.frame;
		torso.frame2time = torso.frame1time;
		torso.frame = torsoframe;
		torso.frame1time = self.animcheck_time;
	}
	if (legs.frame != legframe)
	{
		legs.frame2 = legs.frame;
		legs.frame2time = legs.frame1time;
		legs.frame = legframe;
		legs.frame1time = self.animcheck_time;
	}
}

void Player_RenderModel(void)
{
	entity head = self.m_head;
	entity torso = self.m_torso;
	entity legs = self.m_legs;
	entity wmodel = self.wepent;
	wmodel.renderflags = legs.renderflags = torso.renderflags = head.renderflags = self.renderflags;

	legs.origin = self.origin + '0 0 -8';
	legs.angles = self.angles;

	/*
	makevectors([0, view_angles[1], 0]);
	legs.origin = view_origin;
	legs.origin += v_forward * 64;
	*/

	torso.skin = 1;
	legs.skin = 1;
	if (self.deadflag != DEAD_NO)
	{
		torso.skin = 0;
		legs.skin = 0;
	}
	
	if (time > self.animcheck_time || self.deadflag != legs.deadflag)
	{
		Player_AnimationCheck();
		self.animcheck_time = max(time - PLAYER_ANIM_TIC, self.animcheck_time + PLAYER_ANIM_TIC);
	}
	float frac = bound(0, (self.animcheck_time - time) / PLAYER_ANIM_TIC, 1);
	head.lerpfrac = 0;
	if (head.frame2)
		head.lerpfrac = frac;
	torso.lerpfrac = 0;
	if (torso.frame2)
		torso.lerpfrac = frac;
	legs.lerpfrac = 0;
	if (legs.frame2)
		legs.lerpfrac = frac;
	vector vel_to_use = lerpVector(legs.velocity, legs.old_velocity, frac);


	// leg dir
	if (vlen([self.velocity[0], self.velocity[1], 0]) > 30)
	{
		legs.legang_wanted = legs.legang;
		vector vel_angs = vectoangles([self.velocity[0], self.velocity[1], 0]);
		legs.legang_wanted = vel_angs[1];
	}

	float angdiff = angle_difference(self.angles[1], legs.legang_wanted);
	if (angdiff > 120 || angdiff < -120 )
	{
		legs.legang_wanted = vel_angs[1] + 180;
	}
	else if (angdiff > 110)
	{
		legs.legang_wanted = self.angles[1] + 45;
	}
	else if (angdiff > 45)
	{
		if (vlen(self.velocity) > 30)
			legs.legang_wanted = self.angles[1] - 45;
		else
			legs.legang_wanted = self.angles[1] - 15;
	}
	else if (angdiff < -110)
	{
		legs.legang_wanted = self.angles[1] - 45;
	}
	else if (angdiff < -45)
	{
		if (vlen(self.velocity) > 30)
			legs.legang_wanted = self.angles[1] + 45;
		else
			legs.legang_wanted = self.angles[1] - 15;
	}
	// leg dir end
	

	float angdiff = angle_difference(legs.legang, legs.legang_wanted);
	float absdiff = fabs(angdiff);
	float spd = 150;
	if (absdiff > 40)
		spd = 900;
	else if (absdiff > 20)
		spd = 500;
	else if (absdiff > 5)
		spd = 300;
	spd = min(spd * clframetime, fabs(angdiff));
	if (angdiff < 0)
		legs.legang = legs.legang + spd;
	else if (angdiff > 0)
		legs.legang = legs.legang - spd;

	float angdiff = angle_difference(self.angles[1], legs.legang);
	if (angdiff > 60)
		legs.legang = self.angles[1] - 60;
	else if (angdiff < -60)
		legs.legang = self.angles[1] + 60;
	
	
	float lean_scale = (self.net_server.flags & FL_ONGROUND) ? 1 : 2.5;
	makevectors([0, self.angles[1], 0]);
	legs.angles[0] = bound(-90, vel_to_use * v_forward * -0.025 * lean_scale, 90);
	legs.angles[2] = bound(-45, vel_to_use * v_right * 0.03 * lean_scale, 45);
	legs.angles[1] = legs.legang;
	addentity(legs);

	torso.origin = gettaginfo(legs, gettagindex(legs, "tag_torso"));
	torso.angles[0] = (legs.angles[0] * 0.1) - (self.angles[0] * 0.4);
	torso.angles[1] = self.angles[1];
	torso.angles[2] = legs.angles[2] * 0.6;
	addentity(torso);


	wmodel.origin = gettaginfo(torso, gettagindex(torso, "tag_weapon"));
	wmodel.angles = vectoangles2(v_forward, v_up);
	wmodel.angles[0] -= (self.angles[0] * 0.1);
	wmodel.scale = 0.5;
	weapon_t wep = weaponlist[self.weapon];

	if (wep.hmodel)
	{
		setmodel(wmodel, wep.hmodel);
		addentity(wmodel);
	}


	head.origin = gettaginfo(torso, gettagindex(torso, "tag_head"));
	if (self.deadflag == DEAD_NO)
	{
		head.angles[0] = -self.angles[0]*0.7;
		head.angles[1] = self.angles[1];
		head.angles[2] = 0;
	}
	else
	{
		head.angles = vectoangles2(v_forward, v_up);
	}
	addentity(head);
}

void Player_Predraw(void)
{
	self.renderflags = 0;
	if (self.entnum == player_localentnum)
	{
		if (self.deadflag != DEAD_DEAD)
			self.renderflags = RF_EXTERNALMODEL;
		view_subject = self;
		Player_LocalPredraw();
	}
	else
	{
		float o_frametime = frametime;
		float dt = bound(0.01, getstatf(STAT::PING) / 1000, 0.1) + sv_ticrate;

		///*
		if (self.net_server.status == 1)
		{
			self.net_server.status = 0;
			
			NetField_StructToEntity(self, net_oldserver);
			
			frametime = dt + (time - self.old_updated);
			input_buttons = self.oldin_buttons;
			input_movevalues = self.oldin_movevalues;
			input_angles = self.angles;
			Player_CPhysics();
			vector rough_origin = self.origin;

			NetField_StructToEntity(self, net_server);
			frametime = dt + (time - self.was_updated);
			input_buttons = self.clin_buttons;
			input_movevalues = self.clin_movevalues;
			input_angles = self.angles;
			Player_CPhysics();

			self.origin_errorcorrection = (self.origin + self.origin_errorcorrection) - rough_origin;
		}

		NetField_StructToEntity(self, net_server);
		frametime = dt + (time - self.was_updated);
		input_buttons = self.clin_buttons;
		input_movevalues = self.clin_movevalues;
		input_angles = self.angles;
		Player_CPhysics();
		frametime = o_frametime;


		// Error correction
		float err = vlen(self.origin_errorcorrection);
		vector norm = normalize(self.origin_errorcorrection);

		float spd;
		if (err > 256)
			err = 0;
		else if (err > 96)
			spd = 500;
		else if (err > 64)
			spd = 400;
		else if (err > 32)
			spd = 280;
		else if (err > 16)
			spd = 220;
		else
			spd = 90;
		err = max(0, err - (clframetime * spd));
		self.origin_errorcorrection = err * norm;
		//
		self.origin -= self.origin_errorcorrection;

		//float frac = cl_framenum - sv_framenum;
		//self.origin = lerpVector(self.net_oldserver.origin, self.net_server.origin, frac);

		if (self.effects & EF_MUZZLEFLASH)
		{
			makevectors(self.angles);
			adddynamiclight2(self.origin + (v_up * 8) + (v_forward * 16), 150, '1 0.8 0.6', 0, "", 3);
		}
	}

	Player_RenderModel();
}

void Player_RemoveEntity()
{
	if (self.m_legs)
		remove(self.m_legs);
	if (self.m_torso)
		remove(self.m_torso);
	if (self.m_head)
		remove(self.m_head);
	if (self.wepent)
		remove(self.wepent);
	remove(self);
}

void EntUpdate_Player(float is_new)
{
	float localflags = ReadByte();
	float sendflags = ReadByte();
	if (sendflags & U::MOREBYTES16)
		sendflags |= (ReadByte() << 8);
	if (sendflags & U::MOREBYTES24)
		sendflags |= (ReadByte() << 16);
	if (sendflags & U::MOREBYTES32)
		sendflags |= (ReadByte() << 24);
	
	NetField_StructToStruct(self, net_server, net_oldserver);
	self.net_server.status = 1;
	
	if ((localflags & LF::LOCAL) || (localflags & LF::SPECTATOR)) // sync prediction values
	{
		#define NF_VEC(field, fl)		if (sendflags & fl) { self.net_server.field = ReadVectorF();};
		#define NF_SHORTVEC(field, fl)	if (sendflags & fl) { self.net_server.field = ReadVectorS();};
		#define NF_PMVEC(field, fl)		if (sendflags & fl) { self.net_server.field = ReadVectorS() / 8;};
		#define NF_COORDVEC(field, fl)	if (sendflags & fl) { self.net_server.field = ReadVectorL();};
		#define NF_ANGVEC(field, fl)	if (sendflags & fl) { self.net_server.field = ReadVectorA();};
		#define NF_FLOAT(field, fl)		if (sendflags & fl) { self.net_server.field = ReadFloat();};
		#define NF_BITFIELD(field, fl)	if (sendflags & fl) { self.net_server.field = (ReadShort() | (ReadByte() << 16));};
		#define NF_SHORT(field, fl)		if (sendflags & fl) { self.net_server.field = ReadShort();};
		#define NF_BYTE(field, fl)		if (sendflags & fl) { self.net_server.field = ReadByte();};
		#define NF_EDICT(field, fl)		if (sendflags & fl) { self.net_server.field = ReadShort();};
		NETFIELDS
		#undef NF_VEC
		#undef NF_SHORTVEC
		#undef NF_PMVEC
		#undef NF_COORDVEC
		#undef NF_FLOAT
		#undef NF_BITFIELD
		#undef NF_SHORT
		#undef NF_BYTE
		#undef NF_EDICT
	}
	else if (localflags & LF::REMOTE)
	{
		// get player input
		self.oldin_movevalues = self.clin_movevalues;
		self.oldin_buttons = self.clin_buttons;
		self.clin_movevalues = ReadVectorB() * 640;
		self.clin_buttons = ReadByte();
		//

		if (sendflags & U::ORIGIN)
		{
			self.net_server.origin = ReadVectorL();
		}

		if (sendflags & U::VELOCITY)
		{
			self.net_server.velocity = ReadVectorS();
		}

		if (sendflags & U::ANGLES)
		{
			self.net_server.angles = ReadVectorA();
		}

		if (sendflags & U::MOVETYPE)
		{
			self.net_server.mins = ReadVectorS();
			self.net_server.maxs = ReadVectorS();
			self.net_server.solid = ReadByte();
			self.net_server.movetype = ReadByte();
		}

		if (sendflags & U::WEAPON)
		{
			self.net_server.weapon = ReadByte();
			self.net_server.weapon_mode = ReadByte() << 16;
		}

		if (sendflags & U::FLAGS)
		{
			self.net_server.flags = ReadLong();
			self.net_server.effects = ReadShort();
		}

		if (sendflags & U::HEALTH)
		{
			self.net_server.deadflag = ReadByte();
		}

		NetField_StructToEntity(self, net_server);
	}

	if (sendflags & U::MODEL)
	{
		//setmodelindex(self, ReadShort());
	}
	
	self.old_updated = self.was_updated;
	self.was_updated = time;
	setsize(self, self.net_server.mins, self.net_server.maxs);
	setorigin(self, self.net_server.origin);

	if (self.classname != "player")
		is_new = TRUE;
	
	if (is_new)
	{
		self.old_updated = time;
		self.classname = "player";
		self.drawmask = MASK_PLAYER;
		self.predraw = Player_Predraw;
		self.takedamage = DAMAGE_YES;
		self.RemoveEntity = Player_RemoveEntity;
		self.flags = FL_CLIENT;
		
		self.m_head = spawn(); self.m_head.scale = 1.15;
		setmodel(self.m_head, "models/alpha/head.md3");
		self.m_head.skin = 1;

		self.m_torso = spawn(); self.m_torso.scale = 1.15;
		setmodel(self.m_torso, "models/alpha/upper.md3");
		self.m_torso.skin = 1;

		self.m_legs = spawn(); self.m_legs.scale = 1.15;
		setmodel(self.m_legs, "models/alpha/lower.md3");
		self.m_legs.skin = 1;

		self.wepent = spawn();

		self.cphysics = Player_CPhysics;
		
		//Actor_AddToList(self);
		self.NetEdictToStruct = PL_GEntToStruct;
		self.NetStructToEdict = PL_GStructToEnt;
		self.NetStructToStruct = PL_GStructToStruct;	
	}
}

void PlayerGhost_Predraw(void)
{
	self.alpha -= 2 * frametime;
	if (self.alpha < 0.01)
	{
		remove(self.m_head);
		remove(self.m_torso);
		remove(self.m_legs);
		remove(self);
		return;
	}

	// pause timers
	self.m_head.frame1time += frametime;
	self.m_head.frame2time += frametime;
	self.m_torso.frame1time += frametime;
	self.m_torso.frame2time += frametime;
	self.m_legs.frame1time += frametime;
	self.m_legs.frame2time += frametime;
	//

	self.m_legs.alpha =
	self.m_torso.alpha =
	self.m_head.alpha = self.alpha;

	self.m_legs.colormod =
	self.m_torso.colormod =
	self.m_head.colormod = self.colormod;

	self.m_legs.renderflags =
	self.m_torso.renderflags =
	self.m_head.renderflags = self.renderflags;

	addentity(self.m_head);
	addentity(self.m_torso);
	addentity(self.m_legs);
}

void PlayerGhost_Spawn(entity player)
{
	if (!player.m_head || !player.m_torso || !player.m_head)
		return;
	
	entity ghost = spawn();
	ghost.m_head = spawn();
	ghost.m_torso = spawn();
	ghost.m_legs = spawn();

	ghost.drawmask = MASK_ENGINE;
	ghost.predraw = PlayerGhost_Predraw;
	ghost.alpha = 0.6;
	ghost.colormod = '0.6 0.04 0.1';
	ghost.renderflags = player.renderflags | RF_ADDITIVE;
	
	// head
	ghost.m_head.origin = player.m_head.origin;
	ghost.m_head.angles = player.m_head.angles;
	ghost.m_head.modelindex = player.m_head.modelindex;
	ghost.m_head.skin = player.m_head.skin;
	ghost.m_head.frame = player.m_head.frame;
	ghost.m_head.frame1time = player.m_head.frame1time;
	ghost.m_head.frame2 = player.m_head.frame2;
	ghost.m_head.frame2time = player.m_head.frame2time;
	ghost.m_head.lerpfrac = player.m_head.lerpfrac;
	// torso
	ghost.m_torso.origin = player.m_torso.origin;
	ghost.m_torso.angles = player.m_torso.angles;
	ghost.m_torso.modelindex = player.m_torso.modelindex;
	ghost.m_torso.skin = player.m_torso.skin;
	ghost.m_torso.frame = player.m_torso.frame;
	ghost.m_torso.frame1time = player.m_torso.frame1time;
	ghost.m_torso.frame2 = player.m_torso.frame2;
	ghost.m_torso.frame2time = player.m_torso.frame2time;
	ghost.m_torso.lerpfrac = player.m_torso.lerpfrac;
	// legs
	ghost.m_legs.origin = player.m_legs.origin;
	ghost.m_legs.angles = player.m_legs.angles;
	ghost.m_legs.modelindex = player.m_legs.modelindex;
	ghost.m_legs.skin = player.m_legs.skin;
	ghost.m_legs.frame = player.m_legs.frame;
	ghost.m_legs.frame1time = player.m_legs.frame1time;
	ghost.m_legs.frame2 = player.m_legs.frame2;
	ghost.m_legs.frame2time = player.m_legs.frame2time;
	ghost.m_legs.lerpfrac = player.m_legs.lerpfrac;
}

void BladeDash_Predraw(void)
{
	if (self.health <= 0 || wasfreed(self.owner))
	{
		remove(self);
		return;
	}

	if (time > self.clienttime)
	{
		self.health--;
		PlayerGhost_Spawn(self.owner);
		self.clienttime = time + 0.08;
	}
}

void BladeDash_Spawn(entity player)
{
	entity bdash = spawn();
	bdash.drawmask = MASK_ENGINE;
	bdash.predraw = BladeDash_Predraw;
	bdash.clienttime = time + 0.05;
	bdash.health = 5;
	bdash.owner = player;
}
#endif


