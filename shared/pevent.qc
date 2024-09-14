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

#include "common.h"
#include "protocol.h"
#include "weapons.h"

#define PE_TYPE_SOUND		1
#define PE_TYPE_PROJECTILE	2

// LIST
class predevent_c;
#ifdef CSQC
predevent_c predeventlist;
#endif
#ifdef SSQC
.predevent_c predeventlist;
#endif

// CLASS DEFINITION
class predevent_c {
	float field1;
	float field2;
	float field3;

	entity partner;

	float movesequence;
	predevent_c _next;

	#ifdef CSQC
	float verified;
	#endif

	virtual void() predevent_c {
		if (!this.owner)
		{
			remove(this);
			return;
		}
		
		this.effects = EF_NOPVSCULL;
		if (!this.movesequence)
		{
			this.movesequence = this.owner.framenumber;
			#ifdef CSQC
			this.movesequence++;
			#endif
		}
		this.effects = EF_NODEPTHTEST;

		// macro hell
		#ifdef CSQC
		if (predeventlist)
		{
			predevent_c hld;
			for(predevent_c lst = predeventlist; lst; hld = lst, lst = lst._next)
		#else
		if (this.owner.predeventlist)
		{
			predevent_c hld;
			for(predevent_c lst = this.owner.predeventlist; lst; hld = lst, lst = lst._next)
		#endif
			{
				if (lst.field1 != this.field1 || lst.field2 != this.field2 || lst.field3 != this.field3 || lst.movesequence != this.movesequence) // make sure our entry is unique
					continue;
				remove(this);
				return;
			}
			hld._next = this;
		}
		else
		{
		#ifdef CSQC
			predeventlist = this;
		#else
			this.owner.predeventlist = this;
		#endif
		}
	};
};

#ifdef SSQC
float(entity to, float sendflags) PEvent_SendEntity {
	predevent_c pe = (predevent_c)self;
	if (to != pe.owner)
		return FALSE;

	sendflags = 0;
	if (pe.field1)
		sendflags |= 0x01;
	if (pe.field2)
		sendflags |= 0x02;
	if (pe.field3)
		sendflags |= 0x04;

	WriteByte(MSG_ENTITY, NENT::PredEvent);
	WriteByte(MSG_ENTITY, sendflags);

	if (sendflags & 0x01)
		WriteLong(MSG_ENTITY, pe.field1);
	if (sendflags & 0x02)
		WriteLong(MSG_ENTITY, pe.field2);
	if (sendflags & 0x04)
		WriteLong(MSG_ENTITY, pe.field3);
	
	WriteLong(MSG_ENTITY, pe.movesequence);
	return TRUE;
};
#endif
#ifdef CSQC
predevent_c PEvent_Create(entity who, float f1, float f2, float f3, optional float sequence);
float PEvent_AttemptToVerify(predevent_c pe);
void EntUpdate_PEvent(float is_new)
{
	predevent_c pe = (predevent_c)self;
	float sendflags = ReadByte();
	if (sendflags & 0x01)
		pe.field1 = ReadLong();
	if (sendflags & 0x02)
		pe.field2 = ReadLong();
	if (sendflags & 0x04)
		pe.field3 = ReadLong();
	pe.movesequence = ReadLong();

	if (pe.classname != "predevent")
		is_new = TRUE;
	
	if (is_new)
	{
		pe.classname = "predevent";
		float succ = PEvent_AttemptToVerify(pe);
		if (!succ)
		{
			PEvent_Create(world, pe.field1, pe.field2, pe.field3, pe.movesequence);
		}
	}
}
#endif

// HELPER FUNCTIONS
predevent_c PEvent_Create(entity who, float f1, float f2, float f3, optional float sequence)
{
#ifdef CSQC
	if (!is_effectframe)
		return world;
#endif
	predevent_c pe = spawn(predevent_c, owner: who, field1: f1, field2: f2, field3: f3, movesequence: sequence);
	if (wasfreed(pe))
		return world;
#ifdef SSQC
	pe.SendEntity = PEvent_SendEntity;
	pe.effects = EF_NODEPTHTEST;
	setmodel(pe, "models/misc/null.md3");
#endif
	return pe;
}

void PEvent_Sound(entity who, float channel, string sample, float volume, float attenuation)
{
#ifdef CSQC
	if (!is_effectframe)
		return;
#endif
	// FIXME: this should use PEvent_ but I'm too lazy right now
	float chan = CHAN_PREDICT + channel;
	if (channel == CHAN_AUTO)
		chan = CHAN_PREDICT_AUTO + (who.framenumber % (CHAN_PREDICT_END - CHAN_PREDICT_AUTO));
	#ifdef SSQC
	sound(who, chan, sample, volume, attenuation);
	#endif
	#ifdef CSQC
	sound(world, chan, sample, volume, 0);
	#endif
#if 0
	float soundindex = 4; // fix this
	float f1 = (PE_TYPE_SOUND & 0x00000F) | ((soundindex << 4) & 0x0FFFF0) | ((channel << 20) & 0xF00000);
	float f2 = ((attenuation * 64) & 0x000FFF) | (((volume * 255) << 12) & 0x0FF000);
	float f3 = 0;
	predevent_c pe = PEvent_Create(who, f1, f2, f3);

	float chan = CHAN_PREDICT + channel;
	if (channel == CHAN_AUTO)
		chan = CHAN_PREDICT_AUTO + (pe.movesequence % (CHAN_PREDICT_END - CHAN_PREDICT_AUTO));
	#ifdef SSQC
	sound(who, chan, sample, volume, attenuation);
	#endif
	#ifdef CSQC
	sound(world, chan, sample, volume, 0);
	#endif
#endif
}

float PEvent_Projectile(entity who, __out projectile_c prj)
{
#ifdef CSQC
	if (!is_effectframe)
		return FALSE;
	return FALSE; // FIXME
#endif
	float soundindex = 4; // FIXME
	float f1 = (PE_TYPE_PROJECTILE & 0x00000F);
	float f2 = 0;
	float f3 = 0;
	predevent_c pe = PEvent_Create(who, f1, f2, f3);
	if (!pe)
		return FALSE;
	prj = Projectile_Prediction();
	pe.partner = (entity)prj;

	return TRUE;
}

#ifdef CSQC
float predevent_movesequence;
void PEvent_Cleanup()
{
	predevent_movesequence = max(predevent_movesequence, servercommandframe - 4);
	predevent_c hld;
	for(predevent_c lst = predeventlist; lst; hld = lst, lst = lst._next)
	{
		if (lst.movesequence >= predevent_movesequence) // make sure predevent is old
			continue;
		if (predeventlist == lst)
			predeventlist = lst._next;
		else
			hld._next = lst._next;
		
		float type = lst.field1 & 0xF;
		if (type == PE_TYPE_PROJECTILE)
		{
			if (lst.partner)
			{
				((projectile_c)lst.partner).RemoveEntity();
			}
		}
		else if (type == PE_TYPE_SOUND)
		{
			if (!lst.verified)
			{
				print("Cleaning up PE_TYPE_SOUND\n");
				float channel = (lst.field1 & 0xF00000) >> 20;
				float chan = CHAN_PREDICT + channel;
				if (channel == CHAN_AUTO)
					chan = CHAN_PREDICT_AUTO + (lst.movesequence % (CHAN_PREDICT_END - CHAN_PREDICT_AUTO));

				sound(world, chan, "misc/null.wav", 1, 0);
			}
		}

		remove(lst);
	}
}
float PEvent_AttemptToVerify(predevent_c pe)
{
	predevent_movesequence = max(predevent_movesequence, pe.movesequence);
	predevent_c hld;
	for(predevent_c lst = predeventlist; lst; hld = lst, lst = lst._next)
	{
		if (lst.verified)
			continue;
		if (lst.field1 != pe.field1 || lst.field2 != pe.field2 || lst.field3 != pe.field3 || lst.movesequence != pe.movesequence)
			continue;
		lst.verified = TRUE;
		return TRUE;
	}
	return FALSE;
}
#endif
#ifdef SSQC
void PEvent_Cleanup(entity pl)
{
	predevent_c hld;
	for(predevent_c lst = pl.predeventlist; lst; hld = lst, lst = lst._next)
	{
		if (lst.movesequence >= pl.framenumber - 10) // make sure our entry is unique
			continue;
		if (pl.predeventlist == lst)
			pl.predeventlist = lst._next;
		else
			hld._next = lst._next;
		remove(lst);
	}
}
#endif


