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
#include "localization.h"
#ifdef SSQC
#include "gamemode.h"
#endif

.float notify_fulltime;

enum PICKUP:float {
	HEALTH_VIAL = 1,
	HEALTH_BEAKER,
	HEALTH_CHALICE,
	ARMOR_SHARD,
	ARMOR_HELM,
	ARMOR_VEST,
	DARKARMOR_SHARD,
	DARKARMOR_HELM,
	DARKARMOR_VEST,
	AMMO_SLUGS,
	AMMO_SHELLS,
	AMMO_FANGS,
	AMMO_CYSTS,
	AMMO_ORE,
	AMMO_LANCES,
	AMMO_CRYSTALS,
	AMMO_SOULS,
	WEAPON_BEGIN,
	WEAPON_COACHGUN,
	WEAPON_SHOTGUN,
	WEAPON_SPITTER,
	WEAPON_RETCHER,
	WEAPON_SLAGCANNON,
	WEAPON_LANCE,
	WEAPON_END,
	MAX
};

enum PICKUPSTATUS:float {
	Spawned,
	WeaponStay,
	PickedUp,
};

typedef struct {
	void() touch;
	string model;
	string sound;
	vector mins;
	vector maxs;
	lightparams_t dlight;
	float mflags;
} pickup_t;

pickup_t pickup_defs[PICKUP::MAX];

class itemPickup_c {
	float status;
	float type;
	string noise;
	
	nonvirtual void(entity edict, .genericnet_t net_storage) structtoedict = {
		itemPickup_c ent = (itemPickup_c)edict;
		setorigin(ent, ent.net_storage.origin);
		ent.angles = ent.net_storage.angles;
		ent.status = ent.net_storage.status;

		if (ent.status != PICKUPSTATUS::PickedUp)
			ent.solid = SOLID_TRIGGER;
		else
			ent.solid = SOLID_NOT;
	};

	nonvirtual void(entity edict, .genericnet_t net_storage) edicttostruct = {
		itemPickup_c ent = (itemPickup_c)edict;
		ent.net_storage.origin = ent.origin;
		ent.net_storage.angles = ent.angles;
		ent.net_storage.status = ent.status;
	};

	nonvirtual void(entity edict, .genericnet_t from, .genericnet_t to) structtostruct = {
		itemPickup_c ent = (itemPickup_c)edict;
		ent.to = ent.from;
	};

#ifdef SSQC
	nonvirtual void(entity edict, .genericnet_t net_storage) delta = {
		itemPickup_c ent = (itemPickup_c)edict;

		if (ent.origin != ent.net_storage.origin) { ent.net_storage.origin = ent.origin; ent.SendFlags |= 0x01; };
		if (ent.angles != ent.net_storage.angles) { ent.net_storage.angles = ent.angles; ent.SendFlags |= 0x01; };
		if (ent.status != ent.net_storage.status) { ent.net_storage.status = ent.status; ent.SendFlags |= 0x04; };
	};
#endif
};

void Hud_SendNotification(entity ownr, string icon, float msg, float fl)
{
	#ifdef SSQC
	msg_entity = ownr;
	WriteByte(MSG_ONE, SVC_TEMPENTITY);
	WriteByte(MSG_ONE, TEMPENT::NOTIFICATION);
	WriteString(MSG_ONE, icon);
	WriteShort(MSG_ONE, msg);
	WriteByte(MSG_ONE, fl);
	#endif
};

void Hud_SendNotification_Full(entity ownr)
{
	#ifdef SSQC
	if (time > ownr.notify_fulltime)
	{
		ownr.notify_fulltime = time + 3.5;
		Hud_SendNotification(ownr, "full", LOCALIZATION::NOTIFY_FULL, 0);
	}
	#endif
};

void Hud_SendKillfeed(entity ownr, string icon, entity p1, entity p2, float fl)
{
	#ifdef SSQC
	float msg_type = MSG_ONE;
	if (!ownr)
		msg_type = MSG_ALL;

	msg_entity = ownr;
	WriteByte(msg_type, SVC_TEMPENTITY);
	WriteByte(msg_type, TEMPENT::KILLFEED);
	WriteString(msg_type, icon);
	WriteShort(msg_type, num_for_edict(p1));
	WriteShort(msg_type, num_for_edict(p2));
	WriteByte(msg_type, fl);
	#endif
};

void Item_Respawn()
{
	itemPickup_c it = (itemPickup_c)self;
	it.status = PICKUPSTATUS::Spawned;
	it.solid = SOLID_TRIGGER;
	soundwrath(it, CHAN_VOICE, sprintf("fx/tele%g.ogg", (floor(random() * 5) + 1)), 1, ATTN_IDLE, 100 + (crandom() * 5), 0, 0);
}

void Item_SetToRespawn(float rtime)
{
	if (rtime <= 0)
		return;

	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
	{
		it.nextthink = time + rtime;
		it.think = Item_Respawn;
	}
}

// health pickups
void HPVial_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	if (other.health >= other.max_health)
	{	
		Hud_SendNotification_Full(other);
		return;
	}
	it.status = PICKUPSTATUS::PickedUp;
	it.solid = SOLID_NOT;
	other.health = min(other.health + 10, other.max_health);
	Hud_SendNotification(other, "lifeblood_vial", LOCALIZATION::NOTIFY_HEALTH_VIAL, NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_health);

	// pickup sound
	string noise;
	float r = random() * 3;
	if (r < 1)
		noise = "items/lifeblood_vial1.ogg";
	else if (r < 2)
		noise = "items/lifeblood_vial2.ogg";
	else
		noise = "items/lifeblood_vial3.ogg";
	soundwrath(it, CHAN_VOICE, noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	sound(other, CHAN_ITEM, "player/gain_health.ogg", 1, ATTN_NORM);
	//
	#endif
}
void HPBeaker_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	if (other.health >= other.max_health)
	{	
		Hud_SendNotification_Full(other);
		return;
	}
	it.status = PICKUPSTATUS::PickedUp;
	it.solid = SOLID_NOT;
	other.health = min(other.health + 30, other.max_health);
	Hud_SendNotification(other, "lifeblood_beaker", LOCALIZATION::NOTIFY_HEALTH_BEAKER, NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_health);

	// pickup sound
	string noise;
	float r = random() * 3;
	if (r < 1)
		noise = "items/lifeblood_beaker1.ogg";
	else if (r < 2)
		noise = "items/lifeblood_beaker2.ogg";
	else
		noise = "items/lifeblood_beaker3.ogg";
	soundwrath(it, CHAN_VOICE, noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	sound(other, CHAN_ITEM, "player/gain_health.ogg", 1, ATTN_NORM);
	//
	#endif
}
void HPChalice_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	it.status = PICKUPSTATUS::PickedUp;
	it.solid = SOLID_NOT;
	other.health += 100;
	Hud_SendNotification(other, "lifeblood_chalice", LOCALIZATION::NOTIFY_HEALTH_CHALICE, NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_health);

	// pickup sound
	string noise;
	noise = "items/lifeblood_vial1.ogg";
	soundwrath(it, CHAN_VOICE, noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	sound(other, CHAN_AUTO, "player/gain_health.ogg", 1, ATTN_NORM);
	//
	#endif
}
// Armor Pickups
void ArmorShard_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	if (other.armorvalue >= 100)
	{	
		Hud_SendNotification_Full(other);
		return;
	}
	it.status = PICKUPSTATUS::PickedUp;
	it.solid = SOLID_NOT;
	other.armorvalue = min(other.armorvalue + 5, 100);
	Hud_SendNotification(other, "shard", LOCALIZATION::NOTIFY_ARMOR_SHARD, NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_armor);

	string noise;
	float r = random() * 3;
	if (r < 1)
		noise = "items/armor_shard1.ogg";
	else if (r < 2)
		noise = "items/armor_shard2.ogg";
	else
		noise = "items/armor_shard3.ogg";
	soundwrath(it, CHAN_VOICE, noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
void ArmorHelm_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	if (other.armorvalue >= 100)
	{	
		Hud_SendNotification_Full(other);
		return;
	}
	it.status = PICKUPSTATUS::PickedUp;
	it.solid = SOLID_NOT;
	other.armorvalue = min(other.armorvalue + 25, 100);
	Hud_SendNotification(other, "helm", LOCALIZATION::NOTIFY_ARMOR_HELM, NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_armor);
	soundwrath(it, CHAN_VOICE, it.noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
void ArmorVest_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	if (other.armorvalue >= 100)
	{	
		Hud_SendNotification_Full(other);
		return;
	}
	it.status = PICKUPSTATUS::PickedUp;
	it.solid = SOLID_NOT;
	other.armorvalue = min(other.armorvalue + 50, 100);
	Hud_SendNotification(other, "armor", LOCALIZATION::NOTIFY_ARMOR, NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_armor);
	soundwrath(it, CHAN_VOICE, it.noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
void DArmorShard_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	if (other.darmorvalue >= 100)
	{	
		Hud_SendNotification_Full(other);
		return;
	}
	it.status = PICKUPSTATUS::PickedUp;
	it.solid = SOLID_NOT;
	other.darmorvalue = min(other.darmorvalue + 5, 100);
	Hud_SendNotification(other, "dark_shard", LOCALIZATION::NOTIFY_DARKARMOR_SHARD, NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_darkarmor);

	string noise;
	float r = random() * 3;
	if (r < 1)
		noise = "items/armor_shard_dark1.ogg";
	else if (r < 2)
		noise = "items/armor_shard_dark2.ogg";
	else
		noise = "items/armor_shard_dark3.ogg";
	soundwrath(it, CHAN_VOICE, noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
void DArmorHelm_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	if (other.darmorvalue >= 100)
	{	
		Hud_SendNotification_Full(other);
		return;
	}
	it.status = PICKUPSTATUS::PickedUp;
	it.solid = SOLID_NOT;
	other.darmorvalue = min(other.darmorvalue + 25, 100);
	Hud_SendNotification(other, "dark_helm", LOCALIZATION::NOTIFY_DARKARMOR_HELM, NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_darkarmor);
	soundwrath(it, CHAN_VOICE, it.noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
void DArmorVest_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	if (other.darmorvalue >= 100)
	{	
		Hud_SendNotification_Full(other);
		return;
	}
	it.status = PICKUPSTATUS::PickedUp;
	it.solid = SOLID_NOT;
	other.darmorvalue = min(other.darmorvalue + 50, 100);
	Hud_SendNotification(other, "dark_armor", LOCALIZATION::NOTIFY_DARKARMOR, NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_darkarmor);
	soundwrath(it, CHAN_VOICE, it.noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
// Ammo Pickups
void AmmoSlugs_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	it.status = PICKUPSTATUS::PickedUp;
	it.solid = SOLID_NOT;
	other.ammo_slugs = min(100, other.ammo_slugs + 24);
	Hud_SendNotification(other, "slugs", LOCALIZATION::NOTIFY_AMMO_REVOLVER, NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_ammo);
	soundwrath(it, CHAN_VOICE, it.noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
void AmmoShells_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	it.status = PICKUPSTATUS::PickedUp;
	it.solid = SOLID_NOT;
	other.ammo_shells = min(50, other.ammo_shells + 12);
	Hud_SendNotification(other, "shells", LOCALIZATION::NOTIFY_AMMO_SHOTGUN, NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_ammo);
	soundwrath(it, CHAN_VOICE, it.noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
void AmmoOre_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	it.status = PICKUPSTATUS::PickedUp;
	it.solid = SOLID_NOT;
	other.ammo_ore = min(60, other.ammo_ore + 18);
	Hud_SendNotification(other, "ore", LOCALIZATION::NOTIFY_AMMO_SLAGCANNON, NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_ammo);
	soundwrath(it, CHAN_VOICE, it.noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
void AmmoFangs_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	it.status = PICKUPSTATUS::PickedUp;
	it.solid = SOLID_NOT;
	other.ammo_fangs = min(200, other.ammo_fangs + 40);
	Hud_SendNotification(other, "fangs", LOCALIZATION::NOTIFY_AMMO_SLAGCANNON, NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_ammo);
	soundwrath(it, CHAN_VOICE, it.noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
void AmmoLances_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	it.status = PICKUPSTATUS::PickedUp;
	it.solid = SOLID_NOT;
	other.ammo_lances = min(15, other.ammo_lances + 6);
	Hud_SendNotification(other, "lances", LOCALIZATION::NOTIFY_AMMO_SLAGCANNON, NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_ammo);
	soundwrath(it, CHAN_VOICE, it.noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
// Weapon Pickups
void WeaponCoachgun_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	if (it.status == PICKUPSTATUS::WeaponStay && other.items & ITEM::COACHGUN)
	{	
		Hud_SendNotification_Full(other);
		return;
	}
	if (it.status == PICKUPSTATUS::Spawned)
	{
		it.status = PICKUPSTATUS::PickedUp;
		it.solid = SOLID_NOT;
	}
	other.notify_fulltime = time + 2;
	other.items |= ITEM::COACHGUN;
	other.ammo_slugs = min(100, other.ammo_slugs + 24);
	Hud_SendNotification(other, "revolver", LOCALIZATION::NOTIFY_WEP_REVOLVER, (it.status == PICKUPSTATUS::WeaponStay) ? 0 : NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_weapon);
	soundwrath(it, CHAN_VOICE, it.noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
void WeaponShotgun_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	if (it.status == PICKUPSTATUS::WeaponStay && other.items & ITEM::SHOTGUN)
	{	
		Hud_SendNotification_Full(other);
		return;
	}
	if (it.status == PICKUPSTATUS::Spawned)
	{
		it.status = PICKUPSTATUS::PickedUp;
		it.solid = SOLID_NOT;
	}
	other.notify_fulltime = time + 2;
	other.items |= ITEM::SHOTGUN;
	other.ammo_shells = min(50, other.ammo_shells + 16);
	Hud_SendNotification(other, "shotgun", LOCALIZATION::NOTIFY_WEP_SHOTGUN, (it.status == PICKUPSTATUS::WeaponStay) ? 0 : NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_weapon);
	soundwrath(it, CHAN_VOICE, it.noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
void WeaponSlagCannon_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	if (it.status == PICKUPSTATUS::WeaponStay && other.items & ITEM::SLAGCANNON)
	{	
		Hud_SendNotification_Full(other);
		return;
	}
	if (it.status == PICKUPSTATUS::Spawned)
	{
		it.status = PICKUPSTATUS::PickedUp;
		it.solid = SOLID_NOT;
	}
	other.notify_fulltime = time + 2;
	other.items |= ITEM::SLAGCANNON;
	other.ammo_ore = min(60, other.ammo_ore + 18);
	Hud_SendNotification(other, "cannon", LOCALIZATION::NOTIFY_WEP_SLAGCANNON, (it.status == PICKUPSTATUS::WeaponStay) ? 0 : NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_weapon);
	soundwrath(it, CHAN_VOICE, it.noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
void WeaponSpitter_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	if (it.status == PICKUPSTATUS::WeaponStay && other.items & ITEM::SPITTER)
	{	
		Hud_SendNotification_Full(other);
		return;
	}
	if (it.status == PICKUPSTATUS::Spawned)
	{
		it.status = PICKUPSTATUS::PickedUp;
		it.solid = SOLID_NOT;
	}
	other.notify_fulltime = time + 2;
	other.items |= ITEM::SPITTER;
	other.ammo_fangs = min(200, other.ammo_fangs + 40);
	Hud_SendNotification(other, "spitter", LOCALIZATION::NOTIFY_WEP_SPITTER, (it.status == PICKUPSTATUS::WeaponStay) ? 0 : NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_weapon);
	soundwrath(it, CHAN_VOICE, it.noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
void WeaponLance_Pickup()
{
	itemPickup_c it = (itemPickup_c)self;
	if (it.status == PICKUPSTATUS::PickedUp)
		return;
	if (!(other.flags & FL_CLIENT) || other.deadflag != DEAD_NO)
		return;
	if (it.status == PICKUPSTATUS::WeaponStay && other.items & ITEM::LANCE)
	{	
		Hud_SendNotification_Full(other);
		return;
	}
	if (it.status == PICKUPSTATUS::Spawned)
	{
		it.status = PICKUPSTATUS::PickedUp;
		it.solid = SOLID_NOT;
	}
	other.notify_fulltime = time + 2;
	other.items |= ITEM::LANCE;
	other.ammo_lances = min(15, other.ammo_lances + 3);
	Hud_SendNotification(other, "lance", LOCALIZATION::NOTIFY_WEP_LANCE, (it.status == PICKUPSTATUS::WeaponStay) ? 0 : NOTIFICATIONFLAG::TIMESTAMP);
	#ifdef SSQC
	Item_SetToRespawn(autocvar_g_respawn_weapon);
	soundwrath(it, CHAN_VOICE, it.noise, 1, ATTN_PICKUP, 100 + (crandom() * 5), 0, TRAP_PICKUP);
	#endif
}
//

void IT_Init()
{
	pickup_t pickup; // silly workaround for FTEQCC

	precache_sound("items/lifeblood_vial1.ogg");
	precache_sound("items/lifeblood_vial2.ogg");
	precache_sound("items/lifeblood_vial3.ogg");
	precache_sound("items/lifeblood_beaker1.ogg");
	precache_sound("items/lifeblood_beaker2.ogg");
	precache_sound("items/lifeblood_beaker3.ogg");
	precache_sound("player/gain_health.ogg");

	precache_sound("items/armor_shard1.ogg");
	precache_sound("items/armor_shard2.ogg");
	precache_sound("items/armor_shard3.ogg");
	precache_sound("items/armor_shard_dark1.ogg");
	precache_sound("items/armor_shard_dark2.ogg");
	precache_sound("items/armor_shard_dark3.ogg");

	//hp
	pickup_t pickup = {
		HPVial_Pickup,
		"models/items/lifeblood_vial.md3",
		"",
		'-16 -16 -8', '16 16 28',
		dl_hpvial,
		0
	}; pickup_defs[HEALTH_VIAL] = pickup;

	pickup_t pickup = {
		HPBeaker_Pickup,
		"models/items/lifeblood_beaker.md3",
		"",
		'-16 -16 -8', '16 16 28',
		dl_hpbeaker,
		0
	}; pickup_defs[HEALTH_BEAKER] = pickup;

	pickup_t pickup = {
		HPChalice_Pickup,
		"models/items/lifeblood_chalice.md3",
		"",
		'-24 -24 -8', '24 24 28',
		dl_hpchalice,
		0
	}; pickup_defs[HEALTH_CHALICE] = pickup;

	// armor
	pickup_t pickup = {
		ArmorShard_Pickup,
		"models/items/armor_shard.md3",
		"",
		'-16 -16 -8', '16 16 28',
		dl_armor_shard,
		0
	}; pickup_defs[ARMOR_SHARD] = pickup;

	pickup_t pickup = {
		ArmorHelm_Pickup,
		"models/items/helm.md3",
		"items/helm1.ogg",
		'-16 -16 -8', '16 16 28',
		dl_armor_helm,
		0
	}; pickup_defs[ARMOR_HELM] = pickup;

	pickup_t pickup = {
		ArmorVest_Pickup,
		"models/items/armor.md3",
		"items/armor1.ogg",
		'-24 -24 -8', '24 24 28',
		dl_armor,
		0
	}; pickup_defs[ARMOR_VEST] = pickup;

	pickup_t pickup = {
		DArmorShard_Pickup,
		"models/items/armor_shard_dark.md3",
		"",
		'-16 -16 -8', '16 16 28',
		dl_darkarmor_shard,
		0
	}; pickup_defs[DARKARMOR_SHARD] = pickup;

	pickup_t pickup = {
		DArmorHelm_Pickup,
		"models/items/helm_dark.md3",
		"items/helm_dark1.ogg",
		'-16 -16 -8', '16 16 28',
		dl_darkarmor_helm,
		0
	}; pickup_defs[DARKARMOR_HELM] = pickup;

	pickup_t pickup = {
		DArmorVest_Pickup,
		"models/items/armor_dark.md3",
		"items/armor_dark1.ogg",
		'-24 -24 -8', '24 24 28',
		dl_darkarmor,
		0
	}; pickup_defs[DARKARMOR_VEST] = pickup;

	// ammo
	pickup_t pickup = {
		AmmoSlugs_Pickup,
		"models/items/ammo_revolver.md3",
		"items/ammo_revolver.ogg",
		'-16 -16 -8', '16 16 28',
		dl_null,
		0
	}; pickup_defs[AMMO_SLUGS] = pickup;

	pickup_t pickup = {
		AmmoShells_Pickup,
		"models/items/ammo_shotgun.md3",
		"items/ammo_shotgun.ogg",
		'-16 -16 -8', '16 16 28',
		dl_null,
		0
	}; pickup_defs[AMMO_SHELLS] = pickup;

	pickup_t pickup = {
		AmmoOre_Pickup,
		"models/items/ammo_cannon.md3",
		"items/ammo_cannon.ogg",
		'-16 -16 -8', '16 16 28',
		dl_null,
		0
	}; pickup_defs[AMMO_ORE] = pickup;

	pickup_t pickup = {
		AmmoFangs_Pickup,
		"models/items/ammo_spitter.md3",
		"items/ammo_spitter.ogg",
		'-16 -16 -8', '16 16 28',
		dl_null,
		0
	}; pickup_defs[AMMO_FANGS] = pickup;

	pickup_t pickup = {
		AmmoLances_Pickup,
		"models/items/ammo_lance.md3",
		"items/ammo_lance.ogg",
		'-16 -16 -8', '16 16 28',
		dl_null,
		0
	}; pickup_defs[AMMO_LANCES] = pickup;

	// weapons
	pickup_t pickup = {
		WeaponCoachgun_Pickup,
		"models/weapons/revolver/w_revolver.md3",
		"weapons/shotgun/raise.ogg",
		'-32 -32 -8', '32 32 36',
		dl_null,
		MF_ROTATE
	}; pickup_defs[WEAPON_COACHGUN] = pickup;

	pickup_t pickup = {
		WeaponShotgun_Pickup,
		"models/weapons/shotgun/w_shotgun.md3",
		"weapons/shotgun/raise.ogg",
		'-32 -32 -8', '32 32 36',
		dl_null,
		MF_ROTATE
	}; pickup_defs[WEAPON_SHOTGUN] = pickup;

	pickup_t pickup = {
		WeaponSlagCannon_Pickup,
		"models/weapons/cannon/w_cannon.md3",
		"weapons/shotgun/raise.ogg",
		'-32 -32 -8', '32 32 36',
		dl_null,
		MF_ROTATE
	}; pickup_defs[WEAPON_SLAGCANNON] = pickup;

	pickup_t pickup = {
		WeaponSpitter_Pickup,
		"models/weapons/spitter/w_spitter.md3",
		"weapons/shotgun/raise.ogg",
		'-32 -32 -8', '32 32 36',
		dl_null,
		MF_ROTATE
	}; pickup_defs[WEAPON_SPITTER] = pickup;

	pickup_t pickup = {
		WeaponLance_Pickup,
		"models/weapons/lance/w_lance.md3",
		"weapons/shotgun/raise.ogg",
		'-32 -32 -8', '32 32 36',
		dl_null,
		MF_ROTATE
	}; pickup_defs[WEAPON_LANCE] = pickup;

	// precache assets
	for(float i = 0; i < pickup_defs.length; i++)
	{
		pickup_t pickup = pickup_defs[i];
		if (pickup.model)
			precache_model(pickup.model);
		if (pickup.sound)
			precache_sound(pickup.sound);
	}
}

#ifdef CSQC
void ItemPickup_Predraw()
{
	itemPickup_c it = (itemPickup_c)self;
	pickup_t p = pickup_defs[it.type];

	if (it.status == PICKUPSTATUS::PickedUp)
	{
		it.modelindex = 0;
		it.model = "";
		return;
	}
	else if (!it.modelindex)
	{
		setmodel(it, p.model);
	}

	if (p.mflags & MF_ROTATE)
	{
		it.modelflags = 0;
		it.angles[1] = time * 90;
		it.origin[2] = it.netg_server.origin[2];
		it.origin[2] += 16 + (sin(time * 2) * 4);
	}

	if (it.health > 0)
	{
		it.health = max(0, it.health - (clframetime * 5));
		it.colormod = '1 1 1' + ('1 1 1' * it.health * 10);
		adddynamiclight2(self.origin, 90, '1 1 1' * it.health, 0, "", PFLAGS_LODFADE | PFLAGS_NOSHADOW | PFLAGS_FULLDYNAMIC);
	}

	//it.NetStructToEdict(it, netg_server);
	//float frac = cl_framenum - sv_framenum;
	//it.origin = lerpVector(it.netg_oldserver.origin, it.netg_server.origin, frac);

	DynamicLight_Generic();
}

void EntUpdate_ItemPickup(float is_new)
{
	itemPickup_c it = (itemPickup_c)self;
	it.netg_server = it.netg_pureserver;
	it.netg_oldserver = it.netg_server;

	// read data
	float sendflags = ReadByte();

	if (sendflags & 0x01)
	{
		it.netg_server.origin = ReadVectorL();
		it.netg_server.angles = ReadVectorA();
	}

	is_new = FALSE;
	if (sendflags & 0x02)
	{
		it.type = ReadShort();
		is_new = TRUE;
	}

	if (sendflags & 0x04)
	{
		it.netg_server.status = ReadByte();
		if (it.netg_server.status == PICKUPSTATUS::Spawned && it.status != it.netg_server.status) // we just respawned!
		{
			it.health = 1; // overglow
		}
	}
	
	if (is_new)
	{
		it.netg_oldserver = it.netg_server;
		it.classname = "itempickup";
		it.predraw = ItemPickup_Predraw;
		it.drawmask = MASK_ENGINE;
		INIT_NETFUNCS(it)

		pickup_t p = pickup_defs[it.type];

		it.noise = p.sound;
		it.touch = p.touch;
		setmodel(it, p.model);
		setsize(it, p.mins, p.maxs);
		SET_DYNAMIC_LIGHT_PROPERTIES(it, p.dlight)
		it.modelflags = p.mflags;

		Actor_AddToList(it);
	}
	it.netg_pureserver = it.netg_server;
}
#endif
#ifdef SSQC
float SendEntity_ItemPickup(entity to, float sendflags)
{
	itemPickup_c it = (itemPickup_c)self;

	WriteByte(MSG_ENTITY, NENT::ItemPickup);
	WriteByte(MSG_ENTITY, sendflags);

	// origin
	if (sendflags & 0x01)
	{
		WriteVectorL(MSG_ENTITY, it.origin);
		WriteVectorA(MSG_ENTITY, it.angles);
	}

	// type
	if (sendflags & 0x02)
	{
		WriteShort(MSG_ENTITY, it.type);
	}

	// status
	if (sendflags & 0x04)
	{
		WriteByte(MSG_ENTITY, it.status);
	}

	return TRUE;
}

void Initialize_Pickup(itemPickup_c it, float ittype)
{
	pickup_t p = pickup_defs[ittype];
	it.type = ittype;
	setmodel(it, p.model);
	setsize(it, p.mins, p.maxs);
	it.solid = SOLID_TRIGGER;
	it.noise = p.sound;
	it.touch = p.touch;
	it.modelflags = p.mflags;
	it.SendEntity = SendEntity_ItemPickup;
	it.status = PICKUPSTATUS::Spawned;
	INIT_NETFUNCS(it)

	if (autocvar_g_weaponstay && ittype > PICKUP::WEAPON_BEGIN && ittype < PICKUP::WEAPON_END)
		it.status = PICKUPSTATUS::WeaponStay;

	entity o_self = self;
	self = it;
	droptofloor();
	self = o_self;
	SET_DYNAMIC_LIGHT_PROPERTIES(it, p.dlight)
}

void spawnfunc_health_life_vial() { Initialize_Pickup((itemPickup_c)self, PICKUP::HEALTH_VIAL); }
void spawnfunc_health_life_beaker() { Initialize_Pickup((itemPickup_c)self, PICKUP::HEALTH_BEAKER); }
void spawnfunc_health_life_chalice() { Initialize_Pickup((itemPickup_c)self, PICKUP::HEALTH_CHALICE); }
void spawnfunc_armor_shard() { Initialize_Pickup((itemPickup_c)self, PICKUP::ARMOR_SHARD); }
void spawnfunc_armor_helm() { Initialize_Pickup((itemPickup_c)self, PICKUP::ARMOR_HELM); }
void spawnfunc_armor_armor() { Initialize_Pickup((itemPickup_c)self, PICKUP::ARMOR_VEST); }
void spawnfunc_armor_shard_dark() { Initialize_Pickup((itemPickup_c)self, PICKUP::DARKARMOR_SHARD); }
void spawnfunc_armor_helm_dark() { Initialize_Pickup((itemPickup_c)self, PICKUP::DARKARMOR_HELM); }
void spawnfunc_armor_armor_dark() { Initialize_Pickup((itemPickup_c)self, PICKUP::DARKARMOR_VEST); }
void spawnfunc_ammo_slugs() { Initialize_Pickup((itemPickup_c)self, PICKUP::AMMO_SLUGS); }
void spawnfunc_ammo_shells() { Initialize_Pickup((itemPickup_c)self, PICKUP::AMMO_SHELLS); }
void spawnfunc_ammo_ore() { Initialize_Pickup((itemPickup_c)self, PICKUP::AMMO_ORE); }
void spawnfunc_ammo_fangs() { Initialize_Pickup((itemPickup_c)self, PICKUP::AMMO_FANGS); }
void spawnfunc_ammo_lance() { Initialize_Pickup((itemPickup_c)self, PICKUP::AMMO_LANCES); }
void spawnfunc_weapon_coachgun() { Initialize_Pickup((itemPickup_c)self, PICKUP::WEAPON_COACHGUN); }
void spawnfunc_weapon_shotgun() { Initialize_Pickup((itemPickup_c)self, PICKUP::WEAPON_SHOTGUN); }
void spawnfunc_weapon_cannon() { Initialize_Pickup((itemPickup_c)self, PICKUP::WEAPON_SLAGCANNON); }
void spawnfunc_weapon_spitter() { Initialize_Pickup((itemPickup_c)self, PICKUP::WEAPON_SPITTER); }
void spawnfunc_weapon_lance() { Initialize_Pickup((itemPickup_c)self, PICKUP::WEAPON_LANCE); }
#endif


