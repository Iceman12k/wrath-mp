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

void Projectile_Physics()
{
	if (self.cmovetype != MOVETYPE_FLYMISSILE)
		return;
	
	entity o_self = self;
	entity o_other;
	//tracebox(self.origin, self.mins, self.maxs, self.origin + (self.velocity * frametime), MOVE_NORMAL, self);
	traceline(self.origin, self.origin + (self.velocity * frametime), MOVE_NORMAL, self);
	setorigin(self, trace_endpos);

	if (trace_fraction < 1)
	{
		o_other = trace_ent;

		if (o_self.touch)
		{
			self = o_self;
			other = o_other;
			o_self.touch();
		}

		if (o_other.touch)
		{
			self = o_other;
			other = o_self;
			o_other.touch();
		}
	}
}

#ifdef SSQC
float SendEntity_Projectile(entity to, float sendflags)
{
	projectile_c prj = (projectile_c)self;

	WriteByte(MSG_ENTITY, NENT::Projectile);
	WriteByte(MSG_ENTITY, sendflags);

	if (sendflags & 1)
	{
		WriteVectorL(MSG_ENTITY, prj.origin);
		WriteVectorS(MSG_ENTITY, prj.velocity);
	}

	if (sendflags & 4)
	{
		WriteVectorA(MSG_ENTITY, prj.angles);
	}

	if (sendflags & 8)
	{
		WriteVectorB(MSG_ENTITY, prj.mins * 4);
		WriteVectorB(MSG_ENTITY, prj.maxs * 4);
	}

	if (sendflags & 16)
	{
		WriteShort(MSG_ENTITY, prj.modelindex);
		WriteShort(MSG_ENTITY, prj.effects);
	}

	if (sendflags & 32)
	{
		float tindx = 0;
		if (prj.touch == W_CoachgunProjectile_Touch)
			tindx = 1;
		WriteByte(MSG_ENTITY, tindx);
	}

	if (sendflags & 64)
	{
		WriteShort(MSG_ENTITY, num_for_edict(prj.owner));
	}
	
	return TRUE;
}
#endif
#ifdef CSQC
void Projectile_RemoveEntity()
{
	projectile_c prj = (projectile_c)self;
	remove(prj);
}

void Projectile_Predraw()
{
	projectile_c prj = (projectile_c)self;

	if (prj.modelindex)
		prj.oldmodelindex = prj.modelindex;
	prj.modelindex = prj.oldmodelindex;
	if (prj.cmovetype == MOVETYPE_NONE)
	{
		prj.oldmodelindex = prj.modelindex;
		prj.modelindex = 0;
		return;
	}

	#if 0
	float frac = cl_framenum - sv_framenum;
	self.origin = lerpVector(self.netg_oldserver.origin, self.netg_server.origin, frac);
	setorigin(self, self.origin);
	#endif
}

void EntUpdate_Projectile(float is_new)
{
	projectile_c prj = (projectile_c)self;
	float sendflags = ReadByte();
	prj.netg_server = prj.netg_pureserver;
	prj.netg_oldserver = prj.netg_server;

	if (prj.classname != "nent_projectile")
		is_new = TRUE;
	
	if (sendflags & 1)
	{
		prj.netg_server.origin = ReadVectorL();
		prj.netg_server.velocity = ReadVectorS();
		prj.netg_server.cmovetype = MOVETYPE_FLYMISSILE;
		prj.was_updated = TRUE;
	}

	if (sendflags & 4)
	{
		prj.netg_server.angles = ReadVectorA();
	}

	if (sendflags & 8)
	{
		prj.mins = ReadVectorB() / 4;
		prj.maxs = ReadVectorB() / 4;
		setsize(prj, prj.mins, prj.maxs);
	}

	if (sendflags & 16)
	{
		setmodelindex(prj, ReadShort());
		prj.effects = ReadShort();
	}

	if (sendflags & 32)
	{
		float tindx = ReadByte();
		switch (tindx)
		{
			case 1:
				prj.touch = W_CoachgunProjectile_Touch;
			break;
			default:
				prj.touch = __NULL__;
			break;
		}
	}

	if (sendflags & 64)
	{
		prj.owner = findfloat(world, entnum, ReadShort());
	}
	
	if (is_new)
	{
		prj.netg_oldserver = prj.netg_server;
		prj.classname = "nent_projectile";
		prj.predraw = Projectile_Predraw;
		prj.drawmask = MASK_ENGINE;
		prj.solid = SOLID_TRIGGER;
		prj.dphitcontentsmask = DPCONTENTS_SOLID;// | DPCONTENTS_BODY;
		prj.cphysics = Projectile_Physics;
		prj.cmovetype = MOVETYPE_FLYMISSILE;

		INIT_NETFUNCS(prj)
		Actor_AddToList(prj);
	}
	prj.netg_pureserver = prj.netg_server;
}
#endif

projectile_c Projectile_Prediction()
{
	projectile_c prj = spawn(projectile_c);
	#ifdef SSQC
	prj.framenumber = sv_framenum;
	prj.xerp = min(self.ping / 1000, ANTILAG_MAXREWIND);
	#else
	prj.framenumber = cl_framenum;
	prj.flags = FL_CLIENT;
	prj.predraw = Projectile_Predraw;
	prj.drawmask = MASK_ENGINE;
	#endif
	prj.classname = "pred_projectile";

	return prj;
}

void W_FireHitscan2(vector dir, float dflag, float damage, float knockback, float range)
{
	float o_content = self.dphitcontentsmask;
	self.dphitcontentsmask = DPCONTENTSMASK_WEAPON;
	#ifdef SSQC
	vector barrel_org = self.origin + self.view_ofs + [0, 0, self.sview_height];
	traceline(barrel_org, barrel_org + (dir * range), MOVE_NORMAL, self);

	if (trace_fraction >= 1 && !trace_startsolid)
	{
		self.dphitcontentsmask = o_content;
		return;
	}
	if (!trace_ent.takedamage)
	{
		vector part_org = (trace_endpos + trace_plane_normal) - dir;
		if (random() < 0.5)
			pointparticles(particleeffectnum("TE_GUNSHOT"), part_org, trace_plane_normal, 1);
		pointparticles(particleeffectnum("TE_GUNSHOT2"), part_org, trace_plane_normal, 1);
	}
	else if (trace_ent.classname == "player")
	{
		vector diff = normalize(trace_ent.net_lastsent.origin - self.origin);
		PL_TakeDamage(knockback * diff, damage, dflag, self, trace_ent);

		pointparticles(particleeffectnum("NORMAL_BLOOD"), trace_endpos, trace_plane_normal, 1);
	}
	#endif
	self.dphitcontentsmask = o_content;
}

void W_FireHitscan(vector dir, float dflag, float damage, float knockback)
{
	W_FireHitscan2(dir, dflag, damage, knockback, 4096);
}

void W_Init()
{
	W_Blade_Init();
	W_Coachgun_Init();
	W_Shotgun_Init();
	W_Slag_Init();
	W_Spitter_Init();
	W_Lance_Init();

	precache_sound("misc/hit20.wav");
	precache_sound("misc/hit40.wav");
	precache_sound("misc/hit60.wav");
	precache_sound("misc/hit80.wav");

	#ifdef CSQC
	viewmodel = spawn(viewmodel_c, renderflags: RF_DEPTHHACK | RF_NOSHADOW);
	viewmodel2 = spawn(viewmodel_c, renderflags: RF_DEPTHHACK | RF_NOSHADOW);
	#endif
}

#ifdef CSQC
vector vm_draworg;
float autocvar_cl_bob;
void W_Render()
{
	weapon_t wep = weaponlist[viewmodel.weapon];

	vector vm_org = view_origin;
	vector vm_ang = [-view_angles[0], view_angles[1], 0];
	
	float intensity = min(vlen([viewmodel.velocity[0], viewmodel.velocity[1], 0]) / 400, 3);
	makevectors(view_angles);
	vm_org[0] = sin(viewmodel.sview_bob) * 0.2 * intensity;
	vm_org[1] = sin(viewmodel.sview_bob * 2) * 0.42 * intensity;
	vm_org[2] = sin(viewmodel.sview_bob / 2) * 0.1 * intensity;

	vm_org[1] -= bound(-120, viewmodel.velocity[2] * (v_up * '0 0 1'), 300) / 200;

	float ft = min(1, frametime * 6);
	vm_draworg[0] = lerp(vm_draworg[0], vm_org[0], ft);
	vm_draworg[1] = lerp(vm_draworg[1], vm_org[1], ft);
	vm_draworg[2] = lerp(vm_draworg[2], vm_org[2], ft);

	if (autocvar_cl_bob)
	{
		view_origin -= v_right * vm_draworg[0] * 4;
		view_origin -= v_up * vm_draworg[1] * 6;
		view_origin -= v_forward * vm_draworg[2] * 4;
	}

	vm_org = view_origin;
	vm_org += v_right * vm_draworg[0];
	vm_org += v_up * vm_draworg[1];
	vm_org += v_forward * vm_draworg[2];
	setorigin(viewmodel, vm_org);

	viewmodel.angles = vm_ang;
	viewmodel2.angles = viewmodel.angles;

	// INTERPOLATION
	static float old_viewmodel_frame;
	if (old_viewmodel_frame != viewmodel.frame)
	//if (old_animfinish < viewmodel.weapon_animfinish)
	{
		///*
		//viewmodel.lerpfrac = 1;
		//viewmodel.frame2 = viewmodel.frame;
		//viewmodel.frame2time = viewmodel.frame1time;
		viewmodel.frame1time = time;
		//*/

		old_viewmodel_frame = viewmodel.frame;
	}

	if (viewmodel.weapon_mode & WEAPON_FLAG_LOWFPS)
	{
		if (old_clientframe != SEC_TO_FRAMES(viewmodel.clienttime) && (SEC_TO_FRAMES(viewmodel.clienttime) % 2))
		{
			viewmodel.lerpfrac = 1;
			viewmodel.frame2 = viewmodel.frame;
			viewmodel.frame2time = viewmodel.frame1time;
		}
	}
	else
	{
		if (old_clientframe != SEC_TO_FRAMES(viewmodel.clienttime))
		{
			viewmodel.lerpfrac = 1;
			viewmodel.frame2 = viewmodel.frame;
			viewmodel.frame2time = viewmodel.frame1time;
		}
	}

	if (viewmodel.weapon != old_weapon)
	{
		viewmodel.lerpfrac = 0;
		viewmodel.frame2 = viewmodel.frame;
		viewmodel.frame2time = viewmodel.frame1time;
		viewmodel.frame1time = time;

		viewmodel.skin = 0;
		viewmodel2.skin = 0;
		viewmodel2.frame = 0;
	}

	float dt = THINKFPS;
	if (viewmodel.weapon_mode & WEAPON_FLAG_LOWFPS)
		dt /= 2;
	viewmodel.lerpfrac = max(0, viewmodel.lerpfrac - (frametime * dt));
	//

	if (wep.render)
		wep.render();
	
	old_weapon = viewmodel.weapon;
	old_animfinish = viewmodel.weapon_animfinish;
	old_clientframe = SEC_TO_FRAMES(viewmodel.clienttime);
}
#endif

void W_ClientFrame(float wep_ind)
{
	if (self.weapon_mode & WEAPON_FLAG_FIRED)
		return;

	weapon_t wep = weaponlist[wep_ind];

	if (wep.clientframe)
		wep.clientframe();
}

void W_Frame(float wep_ind)
{
	self.busy_frames = max(0, self.busy_frames - 1);
	self.attack_frames = max(0, self.attack_frames - 1);
	self.weapon_animfinish = max(0, self.weapon_animfinish - 1);

	weapon_t wep = weaponlist[wep_ind];

	if (self.weapon_wanted && !self.busy_frames)
	{
		if (self.weapon_mode & WEAPON_FLAG_PUTAWAY)
		{
			self.weapon_mode &= ~WEAPON_FLAG_PUTAWAY;
			self.weapon_last = self.weapon;
			self.weapon = self.weapon_wanted;
			self.weapon_wanted = 0;
			weapon_t wep = weaponlist[self.weapon];
			
			self.busy_frames = 1;
			if (wep.takeout)
				wep.takeout();
		}
		else
		{
			self.weapon_mode |= WEAPON_FLAG_PUTAWAY;
			if (wep.putaway)
				wep.putaway();
		}
	}

	if (wep.frame)
		wep.frame();

	self.weapon_mode &= ~WEAPON_FLAG_FIRED;
	#ifdef CSQC
	viewmodel.weapon_mode = self.weapon_mode;
	viewmodel.weapon = self.weapon;
	viewmodel.weapon_animfinish = self.weapon_animfinish;
	viewmodel.clienttime = self.clienttime;
	viewmodel.effects = self.effects;
	#endif
}

float PL_BestWeapon()
{
	if (self.items & ITEM::CRYSTAL && self.ammo_crystals > 0)
		return WEAPON::CRYSTAL;

	if (self.items & ITEM::LANCE && self.ammo_lances > 0)
		return WEAPON::LANCE;

	if (self.items & ITEM::SPITTER && self.ammo_fangs > 5)
		return WEAPON::SPITTER;

	if (self.items & ITEM::SHOTGUN && self.ammo_shells > 2)
		return WEAPON::SHOTGUN;

	if (self.items & ITEM::SLAGCANNON && self.ammo_ore > 2)
		return WEAPON::SLAGCANNON;

	if (self.items & ITEM::RETCHER && self.ammo_cysts > 2)
		return WEAPON::RETCHER;

	if (self.items & ITEM::COACHGUN && self.ammo_slugs > 0)
		return WEAPON::COACHGUN;

	if (self.items & ITEM::BLADE)
		return WEAPON::BLADE;

	return 0;
}

float PL_HandleImpulses()
{
	if (!self.impulse)
		return FALSE;
	
	if (self.impulse >= 1 && self.impulse < WEAPON::MAX) // direct weapon swap
	{
		if (!(self.items & weaponlist[self.impulse].it_flag) || (self.weapon == self.impulse && !self.weapon_wanted))
			return FALSE;
		
		self.weapon_wanted = self.impulse;
		return TRUE;
	}
	else if (self.impulse == 57) // last weapon
	{
		if (!(self.items & weaponlist[self.weapon_last].it_flag) || (self.weapon == self.weapon_last && !self.weapon_wanted))
			return FALSE;
		
		self.weapon_wanted = self.weapon_last;
		return TRUE;
	}
	else if (self.impulse == 55) // next weapon
	{
		float old_wep = self.weapon;
		float i = old_wep;
		do {
			if (!(self.items & weaponlist[i].it_flag) || (i == old_wep))
			{
				i++;
				if (i >= WEAPON::MAX)
					i = 0;
				continue;
			}

			//if (self.weapon != i)
				self.weapon_wanted = i;
			return TRUE;
		} while (i != old_wep);
	}
	else if (self.impulse == 56) // previous weapon
	{
		float old_wep = self.weapon;
		float i = old_wep;
		do {
			if (!(self.items & weaponlist[i].it_flag) || (i == old_wep))
			{
				i--;
				if (i < 0)
					i = WEAPON::MAX - 1;
				continue;
			}

			//if (self.weapon != i)
				self.weapon_wanted = i;
			return TRUE;
		} while (i != old_wep);
	}

	return FALSE;
}

void ClientServerFrame()
{
	self.oldclienttime = self.clienttime;
	self.clienttime += input_timelength;

	#ifdef SSQC
	// update hitbeep data
	if (self.damage_given || self.damage_taken)
	{
		float fnum = self.hitbeep_data & 0xFF; fnum++;
		if (fnum > 0xFF) // loop back around after 255 frames
			fnum = 0;
		self.hitbeep_data = fnum;
		self.hitbeep_data |= (bound(0, ceil(self.damage_given), 0xFF) << 8);
		self.hitbeep_data |= (bound(0, ceil(self.damage_taken / 10), 0xF) << 16);
		self.hitbeep_data |= (bound(0, self.hitbeep_flags, 0xF) << 20);

		self.damage_given = 0;
		self.damage_taken = 0;
		self.hitbeep_flags = 0;
	}
	//
	#endif

	float msec = floor(input_timelength * 1000);
	self.disableweapon = max(0, self.disableweapon - msec);
	self.disablemove = max(0, self.disablemove - msec);
	self.jumppadtimer = max(0, self.jumppadtimer - msec);
	self.liquiddamagetimer = max(0, self.liquiddamagetimer - msec);

/* #region liquid logic */
	if (self.waterlevel > 0)
	{
		float content_type = self.watertype;
		if (content_type == CONTENT_EMPTY)
			content_type = self.fakewatertype;
		if (content_type == CONTENT_LAVA)
		{
			if (self.liquiddamagetimer <= 0)
			{
				self.liquiddamagetimer = 100;
				PL_TakeDamage(0, 10, 0, world, self);
			}
		}
		else if (content_type == CONTENT_SLIME)
		{
			if (self.liquiddamagetimer <= 0)
			{
				self.liquiddamagetimer = 100;
				PL_TakeDamage(0, 5, 0, world, self);
			}
		}
	}
/* #endregion */

	if (self.deadflag == DEAD_NO)
	{
		if (self.disableweapon <= 0)
		{
			if (SEC_TO_FRAMES(self.oldclienttime) < SEC_TO_FRAMES(self.clienttime)) // execute frame
			{
				if (PL_HandleImpulses())
				{
					self.impulse = 0;
				}

				if (SEC_TO_FRAMES(self.clienttime) % THINKFPS == 0) // 1hz
				{
					if (self.health > self.max_health)
					{
						self.health--;
					}
				}

				W_Frame(self.weapon);
			}

			self.damageboost = max(0, self.damageboost - msec);
			W_ClientFrame(self.weapon);
		}
		else
		{
			self.flags &= ~FL_QUICKBOOST;
		}
	}
	else
	{
		self.damageboost = 0;
		if (SEC_TO_FRAMES(self.oldclienttime) < SEC_TO_FRAMES(self.clienttime))
		{
			self.busy_frames = max(0, self.busy_frames - 1);

			#ifdef CSQC
			viewmodel.weapon_mode = self.weapon_mode;
			viewmodel.weapon = self.weapon;
			viewmodel.weapon_animfinish = self.weapon_animfinish;
			viewmodel.clienttime = self.clienttime;
			viewmodel.effects = self.effects;
			#endif
		}
	}
}
