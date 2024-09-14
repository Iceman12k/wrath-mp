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

#include "uielement.h"


float appparatus_flash;
float appparatus_using;
float pulsehealth_icon;
float pulsearmor_icon;
float pulsedarmor_icon;
float pulseammo_icon;
float phicon;
float arphicon;
float drphicon;
float ammphicon;
void() pulse_health = 
{
	phicon = 0;
	pulsehealth_icon = 1;
};

void GameTime_GetStamp(__out float minutes, __out float seconds)
{
	float tleft = getstatf(GAMETIME_END);
	tleft = fabs(time - tleft);

	minutes = floor(tleft / 60);
	seconds = floor(tleft % 60);
}

static float playerinfo_alpha;
static float playerinfo_active;
static float playerinfo_cooldown;
static float playerinfo_trace(vector start, vector end, entity ent)
{
	vector beams[] = {
		'0 0',
		'-64 0',
		'64 0',
		'0 64',
		'0 64'
	};

	makevectors(vectoangles(end - start));
	for(float i = 0; i < beams.length; i++) // check each beam
	{
		vector offs = beams[i];
		vector s = start + (offs[0] * v_right * 0.25) + (offs[1] * v_up * 0.25);
		vector e = end + (offs[0] * v_right) + (offs[1] * v_up);
		traceline(s, e, MOVE_NORMAL, ent);

		if (trace_fraction < 1 && trace_ent.flags & FL_CLIENT)
		{
			playerinfo_cooldown = time + 1;
			return trace_ent.entnum;
		}
	}

	playerinfo_cooldown = time + 0.1;
	return FALSE;
}

/* #region scoreboard */
uielement_c hud_scoreboardentries[10];

void HUD_InitializeScoreboard(void)
{
	float(uielement_c this) scoreboard_condition = { return scoreboard_visible; };
	void(uielement_c this, __inout vector position) scoreboard_preloop = {
		for(float i = 0; i < hud_scoreboardentries.length; i++)
		{
			uielement_c container = hud_scoreboardentries[i];
			uitext_c uiname = (uitext_c)container.partner;
			uitext_c uikills = (uitext_c)container.partner2;
			uitext_c uideaths = (uitext_c)container.partner3;
			uitext_c uiping = (uitext_c)container.partner4;
			container.flags |= UIFLAG::HIDE;

			for(scoreboard_entry_c lst = scoreboard_plates; lst; lst = lst._next)
			{
				if (lst.index != i)
					continue;

				container.flags &= ~UIFLAG::HIDE;
				uiname.text = lst.name;
				uikills.text = lst.column[SCOREBOARDCOLUMN::FRAGS]; uikills.color = CONVERT_TO_DP_SHITTY_COLOR(lst.color[SCOREBOARDCOLUMN::FRAGS]);
				uideaths.text = lst.column[SCOREBOARDCOLUMN::DEATHS]; uideaths.color = CONVERT_TO_DP_SHITTY_COLOR(lst.color[SCOREBOARDCOLUMN::DEATHS]);
				uiping.text = lst.column[SCOREBOARDCOLUMN::PING]; uiping.color = CONVERT_TO_DP_SHITTY_COLOR(lst.color[SCOREBOARDCOLUMN::PING]);
			}
		}
	};

	uielement_c scoreboard = spawn(uielement_c, owner: ui_hud, flags: UIFLAG::STRETCH);
		scoreboard.active_condition = scoreboard_condition;
		scoreboard.preloop = scoreboard_preloop;

	uipicture_c journal = spawn(uipicture_c, owner: scoreboard, image: "gfx/journal/journal.tga", size: '512 400', anchor: '0.5 0.5', justify: '0.5 0.5');
	
	// player slots
	float offs = 64;
	for(float i = 0; i < hud_scoreboardentries.length; i++, offs += 25)
	{
		uielement_c container = spawn(uielement_c, owner: journal, size: '512 24', origin: [0, offs]);
			container.partner = (uielement_c)spawn(uitext_c, owner: container, origin: '146 0', justify: '0.5 0.5', color: '1 1 1', font: FONT_USER7, size: '18 18', text: "TestName");
			container.partner2 = (uielement_c)spawn(uitext_c, owner: container, origin: '310 0', justify: '0.5 0.5', color: '-0.8 -0.8 -0.8', font: FONT_USER7, size: '16 16', text: "0");
			container.partner3 = (uielement_c)spawn(uitext_c, owner: container, origin: '370 0', justify: '0.5 0.5', color: '-0.8 -0.8 -0.8', font: FONT_USER7, size: '16 16', text: "0");
			container.partner4 = (uielement_c)spawn(uitext_c, owner: container, origin: '450 0', justify: '1 0.5', color: '-0.8 -0.8 -0.8', font: FONT_USER7, size: '16 16', text: "30ms");
		hud_scoreboardentries[i] = container;
	}

	// labels at the top
	uielement_c container = spawn(uielement_c, owner: journal, size: '512 24', origin: [0, 30]);
	(uielement_c)spawn(uitext_c, owner: container, origin: '146 0', justify: '0.5 0', color: '-0.6 -0.6 -0.6', font: FONT_USER7, size: '18 18', text: "NAME");
	(uielement_c)spawn(uitext_c, owner: container, origin: '310 0', justify: '0.5 0', color: '-0.6 -0.6 -0.6', font: FONT_USER7, size: '18 18', text: "FRAGS");
	(uielement_c)spawn(uitext_c, owner: container, origin: '370 0', justify: '0.5 0', color: '-0.6 -0.6 -0.6', font: FONT_USER7, size: '18 18', text: "DEATHS");
	(uielement_c)spawn(uitext_c, owner: container, origin: '450 0', justify: '1 0', color: '-0.6 -0.6 -0.6', font: FONT_USER7, size: '18 18', text: "PING");
}
/* #endregion */

float ui_oldweaponselected;
float ui_ammoslide;
void HUD_InitializeUI(void)
{
	// healthhaze fill
	float(uielement_c this) condtional = { if (r_healthhaze > 0) return TRUE; return FALSE; };
	void(uifill_c this, __inout vector color_to_render, __inout float alpha_to_render) healthhaze_prerender = { alpha_to_render *= r_healthhaze; };
	uifill_c healthhaze_fill = spawn(uifill_c, flags: UIFLAG::STRETCH, color: '0.7 -1 -1', alpha: 0.5);
		healthhaze_fill.active_condition = condtional;
		healthhaze_fill.prerender = healthhaze_prerender;

	// Match timer
	void(uielement_c this, __inout vector position) timer_preloop = {
		uitext_c minl, secl;
		float min, sec;
		minl = this.partner;
		secl = this.partner2;

		GameTime_GetStamp(min, sec);
		minl.text = sprintf("%02.0f", min);
		secl.text = sprintf("%02.0f", sec);
	};
	uitext_c timer = spawn(uitext_c, owner: ui_hud,  origin: '0 12', size: '32 32', anchor: '0.5 0', justify: '0.5 0', text: ":");
	timer.preloop = timer_preloop;
	timer.partner = spawn(uitext_c, owner: timer,  origin: '-6 4', size: '32 32', anchor: '0.5 0', justify: '1 0', text: "00");
	timer.partner2 = spawn(uitext_c, owner: timer,  origin: '6 4', size: '32 32', anchor: '0.5 0', justify: '0 0', text: "00");

	// Player name
	void(uitext_c this, __inout string txt_to_render, __inout vector color_to_render, __inout float alpha_to_render) name_prerender = {
		if (playerinfo_active)
			playerinfo_alpha = min(1, playerinfo_alpha + (10 * frametime));
		else
			playerinfo_alpha = max(0, playerinfo_alpha - (5 * frametime));

		alpha_to_render = playerinfo_alpha * this.alpha;
	};
	void(uielement_c this, __inout vector position) name_preloop = {
		uitext_c nameplate = (uitext_c)this;
		
		if (time < playerinfo_cooldown)
			return;
		
		// do trace
		makevectors(view_angles);
		float pid = playerinfo_trace(view_origin, view_origin + (v_forward * 2048), view_subject);
		if (pid <= 0)
		{
			playerinfo_active = FALSE;
			return;
		}

		strunzone(nameplate.text);
		nameplate.text = strzone(getplayerkeyvalue(pid - 1, INFOKEY_P_NAME));
		playerinfo_active = TRUE;
	};
	uitext_c nameplate = spawn(uitext_c, owner: ui_hud,  origin: '0 120', size: '24 24', anchor: '0.5 0.5', justify: '0.5 1', text: strzone(" "), alpha: 0.7);
		nameplate.preloop = name_preloop;
		nameplate.prerender = name_prerender;
	
	// Health Numbers
	void(uielement_c this, __inout vector position) hp_preloop = {
		float hp = view_subject.health;
		if (pulsehealth_icon == 1)
		{
			if (floor(phicon) >= 10)
			{
				pulsehealth_icon = 0;
			}
		}

		((uispritesheet_c)this.partner).sprite[1] = phicon;
		((uispritesheet_c)this.partner2).sprite[1] = phicon; 
		((uispritesheet_c)this.partner3).sprite[1] = phicon;

		this.partner.flags &= ~UIFLAG::HIDE;
		this.partner2.flags &= ~UIFLAG::HIDE;
		this.partner3.flags &= ~UIFLAG::HIDE;
		if (hp < 100)
		{
			this.partner3.flags |= UIFLAG::HIDE;
			if (hp < 10)
			{
				this.partner2.flags |= UIFLAG::HIDE;
				if (hp <= 0)
				{
					this.partner.flags |= UIFLAG::HIDE;
				}
				else
				{
					((uispritesheet_c)this.partner).sprite[0] = hp % 10;
				}
			}
			else
			{
				((uispritesheet_c)this.partner).sprite[0] = floor((hp % 100) / 10);
				((uispritesheet_c)this.partner2).sprite[0] = hp % 10;
			}
		}
		else
		{
			((uispritesheet_c)this.partner).sprite[0] = floor(hp / 100);
			((uispritesheet_c)this.partner2).sprite[0] = floor((hp % 100) / 10);
			((uispritesheet_c)this.partner3).sprite[0] = hp % 10;
		}
	}
	uielement_c hpbox = spawn(uielement_c, owner: ui_hud,  origin: '24 -18', size: '84 36', anchor: '0 1', justify: '0 1');
		hpbox.preloop = hp_preloop;
	hpbox.partner = spawn(uispritesheet_c, owner: hpbox, origin: '0 0', size: '28 36', image: "gfx/hud/health_sheet.tga", sheet_size: '10 10', sprite: '0 0');
	hpbox.partner2 = spawn(uispritesheet_c, owner: hpbox, origin: '30 0', size: '28 36', image: "gfx/hud/health_sheet.tga", sheet_size: '10 10', sprite: '0 0');
	hpbox.partner3 = spawn(uispritesheet_c, owner: hpbox, origin: '60 0', size: '28 36', image: "gfx/hud/health_sheet.tga", sheet_size: '10 10', sprite: '0 0');
	//

	// Armor Numbers
	void(uielement_c this, __inout vector position) ap_preloop = {
		float armorv = view_subject.armorvalue;
		if (pulsearmor_icon == 1)
		{
			if (floor(arphicon) >= 10)
			{
				pulsearmor_icon = 0;
			}
		}

		((uispritesheet_c)this.partner).sprite[1] = arphicon;
		((uispritesheet_c)this.partner2).sprite[1] = arphicon; 
		((uispritesheet_c)this.partner3).sprite[1] = arphicon;

		this.partner.flags &= ~UIFLAG::HIDE;
		this.partner2.flags &= ~UIFLAG::HIDE;
		this.partner3.flags &= ~UIFLAG::HIDE;
		if (armorv < 100)
		{
			this.partner3.flags |= UIFLAG::HIDE;
			if (armorv < 10)
			{
				this.partner2.flags |= UIFLAG::HIDE;
				if (armorv <= 0)
				{
					this.partner.flags |= UIFLAG::HIDE;
				}
				else
				{
					((uispritesheet_c)this.partner).sprite[0] = armorv % 10;
				}
			}
			else
			{
				((uispritesheet_c)this.partner).sprite[0] = floor((armorv % 100) / 10);
				((uispritesheet_c)this.partner2).sprite[0] = armorv % 10;
			}
		}
		else
		{
			((uispritesheet_c)this.partner).sprite[0] = floor(armorv / 100);
			((uispritesheet_c)this.partner2).sprite[0] = floor((armorv % 100) / 10);
			((uispritesheet_c)this.partner3).sprite[0] = armorv % 10;
		}
	}
	uielement_c apbox = spawn(uielement_c, owner: ui_hud, origin: '120 -18', size: '48 18', anchor: '0 1', justify: '0 1');
	apbox.preloop = ap_preloop;
	apbox.partner = spawn(uispritesheet_c, owner: apbox, origin: '0 0', size: '14 18', image: "gfx/hud/armor_sheet.tga", sheet_size: '10 10', sprite: '0 0');
	apbox.partner2 = spawn(uispritesheet_c, owner: apbox, origin: '14 0', size: '14 18', image: "gfx/hud/armor_sheet.tga", sheet_size: '10 10', sprite: '0 0');
	apbox.partner3 = spawn(uispritesheet_c, owner: apbox, origin: '28 0', size: '14 18', image: "gfx/hud/armor_sheet.tga", sheet_size: '10 10', sprite: '0 0');
	//

	// Dark Armor Numbers
	void(uielement_c this, __inout vector position) dap_preloop = {
		float armorv = view_subject.darmorvalue;
		if (pulsedarmor_icon == 1)
		{
			if (floor(drphicon) >= 10)
			{
				pulsedarmor_icon = 0;
			}
		}

		((uispritesheet_c)this.partner).sprite[1] = drphicon;
		((uispritesheet_c)this.partner2).sprite[1] = drphicon; 
		((uispritesheet_c)this.partner3).sprite[1] = drphicon;

		this.partner.flags &= ~UIFLAG::HIDE;
		this.partner2.flags &= ~UIFLAG::HIDE;
		this.partner3.flags &= ~UIFLAG::HIDE;
		if (armorv < 100)
		{
			this.partner3.flags |= UIFLAG::HIDE;
			if (armorv < 10)
			{
				this.partner2.flags |= UIFLAG::HIDE;
				if (armorv <= 0)
				{
					this.partner.flags |= UIFLAG::HIDE;
				}
				else
				{
					((uispritesheet_c)this.partner).sprite[0] = armorv % 10;
				}
			}
			else
			{
				((uispritesheet_c)this.partner).sprite[0] = floor((armorv % 100) / 10);
				((uispritesheet_c)this.partner2).sprite[0] = armorv % 10;
			}
		}
		else
		{
			((uispritesheet_c)this.partner).sprite[0] = floor(armorv / 100);
			((uispritesheet_c)this.partner2).sprite[0] = floor((armorv % 100) / 10);
			((uispritesheet_c)this.partner3).sprite[0] = armorv % 10;
		}
	}
	uielement_c apbox = spawn(uielement_c, owner: ui_hud, origin: '120 -36', size: '48 18', anchor: '0 1', justify: '0 1');
	apbox.preloop = dap_preloop;
	apbox.partner = spawn(uispritesheet_c, owner: apbox, origin: '0 0', size: '14 18', image: "gfx/hud/darmor_sheet.tga", sheet_size: '10 10', sprite: '0 0');
	apbox.partner2 = spawn(uispritesheet_c, owner: apbox, origin: '14 0', size: '14 18', image: "gfx/hud/darmor_sheet.tga", sheet_size: '10 10', sprite: '0 0');
	apbox.partner3 = spawn(uispritesheet_c, owner: apbox, origin: '28 0', size: '14 18', image: "gfx/hud/darmor_sheet.tga", sheet_size: '10 10', sprite: '0 0');
	//

	//Ammo Counter
	static void(float c_w, __out string sheet, __out float ammo) ammo_getdetails
	{
		ammo = -1;
		sheet = "gfx/hud/slugs_sheet.tga";
		if (c_w == WEAPON::COACHGUN)
		{
			sheet = "gfx/hud/slugs_sheet.tga";
			ammo = view_subject.ammo_slugs;
		}
		if (c_w == WEAPON::SHOTGUN)
		{
			sheet = "gfx/hud/shells_sheet.tga";
			ammo = view_subject.ammo_shells;
		}
		else if (c_w == WEAPON::SLAGCANNON)
		{
			sheet = "gfx/hud/ore_sheet.tga";
			ammo = view_subject.ammo_ore;
		}
		else if (c_w == WEAPON::SPITTER)
		{
			sheet = "gfx/hud/fangs_sheet.tga";
			ammo = view_subject.ammo_fangs;
		}
		else if (c_w == WEAPON::RETCHER)
		{
			sheet = "gfx/hud/cysts_sheet.tga";
			ammo = view_subject.ammo_cysts;
		}
		else if (c_w == WEAPON::LANCE)
		{
			sheet = "gfx/hud/lances_sheet.tga";
			ammo = view_subject.ammo_lances;
		}
		else if (c_w == WEAPON::MACE)
		{
			sheet = "gfx/hud/mace_sheet.tga";
			ammo = view_subject.ammo_souls;
		}
		else if (c_w == WEAPON::CRYSTAL)
		{
			sheet = "gfx/hud/crystal_sheet.tga";
			ammo = view_subject.ammo_crystals;
		}
	}

	void(uielement_c this, __inout vector position) ammo_preloop = {
		float ammov;
		string picofnammo;
		if (pulseammo_icon == 1)
		{
			if (floor(ammphicon) >= 10)
			{
				pulseammo_icon = 0;
			}
		}

		((uispritesheet_c)this.partner).sprite[1] = ammphicon;
		((uispritesheet_c)this.partner2).sprite[1] = ammphicon; 
		((uispritesheet_c)this.partner3).sprite[1] = ammphicon;

		ammo_getdetails(view_subject.weapon, picofnammo, ammov);

		float slide_max = 128;
		if (ui_renderframe) // hack so we animate only on render frames
		{
			if (view_subject.weapon_mode & WEAPON_FLAG_PUTAWAY || ammov < 0)
			{
				ui_ammoslide = min(slide_max, ui_ammoslide + (1200 * clframetime));
			}
			else if (ui_ammoslide > 0)
			{
				ui_ammoslide = max(0, ui_ammoslide - (1200 * clframetime));
			}
		}
		
		float alph = 1 - (ui_ammoslide / slide_max);
		this.partner.alpha = this.partner2.alpha = this.partner3.alpha = alph;
		position[0] += ui_ammoslide * ui_scale[0];

		((uispritesheet_c)this.partner).image = picofnammo;
		((uispritesheet_c)this.partner2).image = picofnammo; 
		((uispritesheet_c)this.partner3).image = picofnammo;

		this.partner.flags &= ~UIFLAG::HIDE;
		this.partner2.flags &= ~UIFLAG::HIDE;
		this.partner3.flags &= ~UIFLAG::HIDE;
		if (ammov < 100)
		{
			this.partner3.flags |= UIFLAG::HIDE;
			if (ammov < 10)
			{
				this.partner2.flags |= UIFLAG::HIDE;
				if (ammov < 0)
					this.partner.flags |= UIFLAG::HIDE;
				else
					((uispritesheet_c)this.partner).sprite[0] = ammov % 10;
			}
			else
			{
				((uispritesheet_c)this.partner).sprite[0] = floor((ammov % 100) / 10);
				((uispritesheet_c)this.partner2).sprite[0] = ammov % 10;
			}
		}
		else
		{
			((uispritesheet_c)this.partner).sprite[0] = floor(ammov / 100);
			((uispritesheet_c)this.partner2).sprite[0] = floor((ammov % 100) / 10);
			((uispritesheet_c)this.partner3).sprite[0] = ammov % 10;
		}
	}

	uielement_c ammobox = spawn(uielement_c, owner: ui_hud, origin: '-28 -18', size: '84 36', anchor: '1 1', justify: '1 1');
	ammobox.preloop = ammo_preloop;
	ammobox.partner = spawn(uispritesheet_c, owner: ammobox, origin: '0 0', size: '28 36', sheet_size: '10 10', sprite: '0 0');
	ammobox.partner2 = spawn(uispritesheet_c, owner: ammobox, origin: '30 0', size: '28 36', sheet_size: '10 10', sprite: '0 0');
	ammobox.partner3 = spawn(uispritesheet_c, owner: ammobox, origin: '60 0', size: '28 36', sheet_size: '10 10', sprite: '0 0');



	//weapon bar
	void(uielement_c this, __inout vector position) weapon_preloop = {
		float ammov;
		string picofnammo;
		if (pulseammo_icon == 1)
		{
			if (floor(ammphicon) >= 10)
			{
				pulseammo_icon = 0;
			}
		}

		((uispritesheet_c)this.partner).sprite[1] = ammphicon;
		((uispritesheet_c)this.partner2).sprite[1] = ammphicon; 
		((uispritesheet_c)this.partner3).sprite[1] = ammphicon;

		ammo_getdetails(this.skin, picofnammo, ammov);
		
		/*
		float slide_max = 128;
		if (ui_renderframe) // hack so we animate only on render frames
		{
			if (view_subject.weapon != this.skin)
			{
				this.health = min(slide_max, this.health + (1200 * clframetime));
			}
			else if (this.health > 0)
			{
				this.health = max(0, this.health - (1200 * clframetime));
			}
		}
		
		float alph = 1 - (this.health / slide_max);
		this.partner.alpha = this.partner2.alpha = this.partner3.alpha = alph;
		position[0] += this.health * ui_scale[0];
		*/

		((uispritesheet_c)this.partner).image = picofnammo;
		((uispritesheet_c)this.partner2).image = picofnammo; 
		((uispritesheet_c)this.partner3).image = picofnammo;

		this.partner.flags &= ~UIFLAG::HIDE;
		this.partner2.flags &= ~UIFLAG::HIDE;
		this.partner3.flags &= ~UIFLAG::HIDE;
		if (ammov < 100)
		{
			this.partner.flags |= UIFLAG::HIDE;
			if (ammov < 10)
			{
				this.partner2.flags |= UIFLAG::HIDE;
				if (ammov < 0)
					this.partner3.flags |= UIFLAG::HIDE;
				else
					((uispritesheet_c)this.partner3).sprite[0] = ammov % 10;
			}
			else
			{
				((uispritesheet_c)this.partner2).sprite[0] = floor((ammov % 100) / 10);
				((uispritesheet_c)this.partner3).sprite[0] = ammov % 10;
			}
		}
		else
		{
			((uispritesheet_c)this.partner).sprite[0] = floor(ammov / 100);
			((uispritesheet_c)this.partner2).sprite[0] = floor((ammov % 100) / 10);
			((uispritesheet_c)this.partner3).sprite[0] = ammov % 10;
		}
	}

	float(uielement_c this) weapon_active = {
		weapon_t wep = weaponlist[this.skin];
		if (view_subject.items & wep.it_flag)
			return TRUE;
		return FALSE;
	}

	string wep_icons[] = {
		"gfx/hud/messages/icons/msgicon_slugs.tga",
		"gfx/hud/messages/icons/msgicon_slugs.tga",
		"gfx/hud/messages/icons/msgicon_slugs.tga",
		"gfx/hud/messages/icons/msgicon_shells.tga",
		"gfx/hud/messages/icons/msgicon_fangs.tga",
		"gfx/hud/messages/icons/msgicon_cysts.tga",
		"gfx/hud/messages/icons/msgicon_ore.tga",
		"gfx/hud/messages/icons/msgicon_lances.tga",
		"gfx/hud/messages/icons/msgicon_crystals.tga",
		"gfx/hud/messages/icons/msgicon_souls.tga",
		"gfx/hud/messages/icons/msgicon_slugs.tga"
	};

	uilist_c weaponbar = spawn(uilist_c, owner: ui_hud, origin: '-18 0', size: [84, (8) * 21], anchor: '1 0.5', justify: '1 0.5', separation: '0 21');
	for(float i = WEAPON::BLADE+1; i < WEAPON::MAX; i++)
	{
		uielement_c ammobox = spawn(uielement_c, owner: weaponbar, origin: '-12 0', size: '42 21', anchor: '1 0', justify: '1 0', skin: i);
		ammobox.preloop = weapon_preloop;
		ammobox.active_condition = weapon_active;
		ammobox.partner = spawn(uispritesheet_c, owner: ammobox, origin: '0 0', size: '14 18', sheet_size: '10 10', sprite: '0 0');
		ammobox.partner2 = spawn(uispritesheet_c, owner: ammobox, origin: '15 0', size: '14 18', sheet_size: '10 10', sprite: '0 0');
		ammobox.partner3 = spawn(uispritesheet_c, owner: ammobox, origin: '30 0', size: '14 18', sheet_size: '10 10', sprite: '0 0');
		spawn(uipicture_c, owner: ammobox, origin: '8 0', anchor: '1 0.5', justify: '0 0.5', size: '16 16', image: wep_icons[i]);
	}

	HUD_InitializeScoreboard();
}

#define HUD_NOTIFY_LINES	8
#define HUD_NOTIFY_OVERFLOW	4
#define HUD_NOTIFY_TIME		4
#define HUD_NOTIFY_FADETIME	0.3
#define HUD_NOTIFY_FADEIN	0.1
uielement_c ui_notify_lines[HUD_NOTIFY_LINES];
void HUD_ShuffleNotificationsUp(void);
void HUD_InitializeNotifications(void)
{
	void(uielement_c this, __inout vector position) notify_preloop = {
		uielement_c line = ui_notify_lines[0];

		if (line.skin && time >= line.skin)
			HUD_ShuffleNotificationsUp();
		
		// do positioning and alpha fadeout
		uielement_c line;
		uipicture_c icon;
		uitext_c msg;
		uipicture_c msgimg;
		uitext_c timestamp;
		float i;
		for(i = 0; i < HUD_NOTIFY_LINES; i++)
		{
			line = ui_notify_lines[i];
			icon = (uipicture_c)line.partner;
			msg = (uitext_c)line.partner2;
			msgimg = (uipicture_c)line.partner3;
			timestamp = (uitext_c)line.partner4;
			
			if (!line.skin)
				break;

			float tfrom = time - line.colormap;
			float tleft = line.skin - time;
			if (tleft <= 0)
			{
				line.flags |= UIFLAG::HIDE;
				continue;
			}
			
			line.flags &= ~UIFLAG::HIDE;
			icon.alpha = 1;
			msg.alpha = 1;
			msgimg.alpha = 1;
			timestamp.alpha = 1;
			if (tleft < HUD_NOTIFY_FADETIME)
			{
				float frac = tleft/HUD_NOTIFY_FADETIME;

				float alph = slerp(0, 1, frac);
				icon.alpha = alph;
				msg.alpha = alph;
				msgimg.alpha = alph;
				timestamp.alpha = alph;

				vector moveup = ((uilist_c)this).separation * (1 - frac);
				moveup = [moveup[0] * ui_scale[0], moveup[1] * ui_scale[1]];
				position -= moveup;
			}
			else if (tfrom < HUD_NOTIFY_FADEIN)
			{
				float frac = (tfrom / HUD_NOTIFY_FADEIN);
				float alph = slerp(0, 1, frac);
				icon.alpha = alph;
				msg.alpha = alph;
				msgimg.alpha = alph;
				timestamp.alpha = alph;
			}
		}

		if (i > HUD_NOTIFY_OVERFLOW) // if we're over the overflow, hurry it up slowpoke
			ui_notify_lines[0].skin = min(ui_notify_lines[0].skin, time + HUD_NOTIFY_FADETIME);
		//
	}
	float(uielement_c this) notify_active = {
		uipicture_c icon = (uipicture_c)this.partner;
		uitext_c msg = (uitext_c)this.partner2;
		uipicture_c msgimg = (uipicture_c)this.partner3;
		uitext_c timestamp = (uitext_c)this.partner4;
		
		if (!this.skin)
			return FALSE;
		
		if (!icon.image && !msg.text && !msgimg.image && !timestamp.text)
			return FALSE;

		return TRUE;
	} 

	uilist_c notifybox = spawn(uilist_c, owner: ui_hud, origin: '8 8', separation: '0 40');
	notifybox.preloop = notify_preloop;
	for(float i = 0; i < HUD_NOTIFY_LINES; i++)
	{
		uielement_c line = ui_notify_lines[i] = spawn(uielement_c, owner: notifybox, size: '256 32');
		line.active_condition = notify_active;

		uipicture_c icon = spawn(uipicture_c, owner: line, anchor: '0 0.5', size: '32 32', justify: '0 0.5', image: __NULL__);
		uitext_c text = spawn(uitext_c, owner: line, origin: '38 0', anchor: '0 0.5', justify: '0 0.5', size: '24 24', color: '-0.2 -0.21 -0.215', font: FONT_USER7); text.text = __NULL__;
		uipicture_c textimg = spawn(uipicture_c, owner: line, origin: '38 0', anchor: '0 0.5', justify: '0 0.5', size: '32 32', color: '1 1 1', image: __NULL__);
		uitext_c timestamp = spawn(uitext_c, owner: line, origin: '38 0', anchor: '0 1', justify: '0 0', size: '12 12', color: '0.3 0.3 0.34', font: FONT_USER7); timestamp.text = __NULL__;

		line.partner = icon;
		line.partner2 = text;
		line.partner3 = textimg;
		line.partner4 = timestamp;
	}
	
};

void HUD_ShuffleNotificationsUp(void)
{
	uielement_c line;
	uipicture_c icon;
	uitext_c msg;
	uipicture_c msgimg;
	uitext_c timestamp;

	// get string offs we're bumping
	line = ui_notify_lines[0];
	icon = (uipicture_c)line.partner;
	msg = (uitext_c)line.partner2;
	msgimg = (uipicture_c)line.partner3;
	timestamp = (uitext_c)line.partner4;
	string stroffs_icon = icon.image;
	string stroffs_text = msg.text;
	string stroffs_textimg = msgimg.image;
	string stroffs_timestamp = timestamp.text;
	//

	for(float i = 0; i < HUD_NOTIFY_LINES - 1; i++)
	{
		// the line we're moving to
		line = ui_notify_lines[i];
		icon = (uipicture_c)line.partner;
		msg = (uitext_c)line.partner2;
		msgimg = (uipicture_c)line.partner3;
		timestamp = (uitext_c)line.partner4;
		// the line we're copying from
		uielement_c line2 = ui_notify_lines[i + 1];
		uipicture_c icon2 = (uipicture_c)line2.partner;
		uitext_c msg2 = (uitext_c)line2.partner2;
		uipicture_c msgimg2 = (uipicture_c)line2.partner3;
		uitext_c timestamp2 = (uitext_c)line2.partner4;

		// copy data we want
		line.skin = line2.skin;
		line.colormap = line2.colormap;
		icon.image = icon2.image;
		icon.size = icon2.size;
		msg.text = msg2.text;
		msg.origin = msg2.origin;
		msgimg.image = msgimg2.image;
		msgimg.origin = msgimg2.origin;
		msgimg.size = msgimg2.size;
		timestamp.text = timestamp2.text;
		timestamp.origin = timestamp2.origin;

		icon.flags = icon2.flags;
		msg.flags = msg2.flags;
		msgimg.flags = msgimg2.flags;
		timestamp.flags = timestamp2.flags;
	}
	
	line = ui_notify_lines[HUD_NOTIFY_LINES - 1];
	line.skin = 0;

	if (stroffs_icon)
		strunzone(stroffs_icon);
	if (stroffs_text)
		strunzone(stroffs_text);
	if (stroffs_textimg)
		strunzone(stroffs_textimg);
	if (stroffs_timestamp)
		strunzone(stroffs_timestamp);
}

uielement_c HUD_AllocateLine(void)
{
	float time_prev = 0;
	for(float i = 0; i < HUD_NOTIFY_LINES; i++)
	{
		uielement_c line = ui_notify_lines[i];
		if (line.skin)
		{
			time_prev = line.skin;
			continue;
		}
		
		line.skin = bound(time + HUD_NOTIFY_TIME, time_prev + 0.34, time + (HUD_NOTIFY_TIME * 2));
		line.colormap = time;
		return line;
	}

	//HUD_ShuffleNotificationsUp();
	// go into overflow line
	HUD_ShuffleNotificationsUp();

	uielement_c line = ui_notify_lines[HUD_NOTIFY_LINES - 1];
	line.skin = bound(time + HUD_NOTIFY_TIME, time_prev + 0.34, time + (HUD_NOTIFY_TIME * 2));
	line.colormap = time;
	return line;
}

/* #region killfeed */
#define KILLFEED_NOTIFY_LINES	10
#define KILLFEED_NOTIFY_OVERFLOW	6
#define KILLFEED_NOTIFY_TIME		15
#define KILLFEED_NOTIFY_FADETIME	0.3
#define KILLFEED_NOTIFY_FADEIN	0.1
uielement_c ui_killfeed_lines[KILLFEED_NOTIFY_LINES];

void Killfeed_ShuffleNotificationsUp(void);
void Killfeed_InitializeNotifications(void)
{
	void(uielement_c this, __inout vector position) notify_preloop = {
		uielement_c line = ui_killfeed_lines[0];

		if (line.skin && time >= line.skin)
			Killfeed_ShuffleNotificationsUp();
		
		// do positioning and alpha fadeout
		uielement_c line;
		uipicture_c icon;
		uitext_c msg;
		uipicture_c msg2;
		uitext_c timestamp;
		float i;
		for(i = 0; i < KILLFEED_NOTIFY_LINES; i++)
		{
			line = ui_killfeed_lines[i];
			icon = (uipicture_c)line.partner;
			msg = (uitext_c)line.partner2;
			msg2 = (uitext_c)line.partner3;
			timestamp = (uitext_c)line.partner4;
			
			if (!line.skin)
				break;

			float tfrom = time - line.colormap;
			float tleft = line.skin - time;
			if (tleft <= 0)
			{
				line.flags |= UIFLAG::HIDE;
				continue;
			}
			
			line.flags &= ~UIFLAG::HIDE;
			icon.alpha = 1;
			msg.alpha = 1;
			msg2.alpha = 1;
			timestamp.alpha = 1;
			if (tleft < KILLFEED_NOTIFY_FADETIME)
			{
				float frac = tleft/KILLFEED_NOTIFY_FADETIME;

				float alph = slerp(0, 1, frac);
				icon.alpha = alph;
				msg.alpha = alph;
				msg2.alpha = alph;
				timestamp.alpha = alph;

				vector moveup = ((uilist_c)this).separation * (1 - frac);
				moveup = [moveup[0] * ui_scale[0], moveup[1] * ui_scale[1]];
				position -= moveup;
			}
			else if (tfrom < KILLFEED_NOTIFY_FADEIN)
			{
				float frac = (tfrom / KILLFEED_NOTIFY_FADEIN);
				float alph = slerp(0, 1, frac);
				icon.alpha = alph;
				msg.alpha = alph;
				msg2.alpha = alph;
				timestamp.alpha = alph;
			}
		}

		if (i > KILLFEED_NOTIFY_OVERFLOW) // if we're over the overflow, hurry it up slowpoke
			ui_killfeed_lines[0].skin = min(ui_killfeed_lines[0].skin, time + KILLFEED_NOTIFY_FADETIME);
		//
	}
	float(uielement_c this) notify_active = {
		uipicture_c icon = (uipicture_c)this.partner;
		uitext_c msg = (uitext_c)this.partner2;
		uitext_c msg2 = (uipicture_c)this.partner3;
		uitext_c timestamp = (uitext_c)this.partner4;
		
		if (!this.skin)
			return FALSE;
		
		if (!icon.image && !msg.text && !msg2.text && !timestamp.text)
			return FALSE;

		return TRUE;
	} 

	uilist_c notifybox = spawn(uilist_c, owner: ui_hud, origin: '-8 8', anchor: '1 0', separation: '0 36');
	notifybox.preloop = notify_preloop;
	for(float i = 0; i < KILLFEED_NOTIFY_LINES; i++)
	{
		uielement_c line = ui_killfeed_lines[i] = spawn(uielement_c, owner: notifybox, size: '256 32', justify: '1 0');
		line.active_condition = notify_active;

		uipicture_c icon = spawn(uipicture_c, owner: line, anchor: '1 0.5', size: '32 32', justify: '1 0.5', image: __NULL__);
		uitext_c text = spawn(uitext_c, owner: line, origin: '38 0', anchor: '1 0.5', justify: '1 0.5', size: '24 24', font: FONT_USER7); text.text = __NULL__;
		uitext_c text2 = spawn(uitext_c, owner: line, origin: '38 0', anchor: '1 0.5', justify: '1 0.5', size: '24 24', font: FONT_USER7); text.text = __NULL__;
		uitext_c timestamp = spawn(uitext_c, owner: line, origin: '38 0', anchor: '1 1', justify: '1 0', size: '12 12', color: '0.3 0.3 0.34', font: FONT_USER7); timestamp.text = __NULL__;

		line.partner = icon;
		line.partner2 = text;
		line.partner3 = text2;
		line.partner4 = timestamp;
	}
	
};

void Killfeed_ShuffleNotificationsUp(void)
{
	uielement_c line;
	uipicture_c icon;
	uitext_c msg;
	uitext_c msgk;
	uitext_c timestamp;

	// get string offs we're bumping
	line = ui_killfeed_lines[0];
	icon = (uipicture_c)line.partner;
	msg = (uitext_c)line.partner2;
	msgk = (uitext_c)line.partner3;
	timestamp = (uitext_c)line.partner4;
	string stroffs_icon = icon.image;
	string stroffs_text = msg.text;
	string stroffs_textimg = msgk.text;
	string stroffs_timestamp = timestamp.text;
	//

	for(float i = 0; i < KILLFEED_NOTIFY_LINES - 1; i++)
	{
		// the line we're moving to
		line = ui_killfeed_lines[i];
		icon = (uipicture_c)line.partner;
		msg = (uitext_c)line.partner2;
		msgk = (uitext_c)line.partner3;
		timestamp = (uitext_c)line.partner4;
		// the line we're copying from
		uielement_c line2 = ui_killfeed_lines[i + 1];
		uipicture_c icon2 = (uipicture_c)line2.partner;
		uitext_c msg2 = (uitext_c)line2.partner2;
		uitext_c msgk2 = (uitext_c)line2.partner3;
		uitext_c timestamp2 = (uitext_c)line2.partner4;

		// copy data we want
		line.skin = line2.skin;
		line.colormap = line2.colormap;
		icon.image = icon2.image;
		icon.size = icon2.size;
		msg.text = msg2.text;
		msg.origin = msg2.origin;
		msgk.text = msgk2.text;
		msgk.origin = msgk2.origin;
		timestamp.text = timestamp2.text;
		timestamp.origin = timestamp2.origin;

		icon.flags = icon2.flags;
		msg.flags = msg2.flags;
		msgk.flags = msgk2.flags;
		timestamp.flags = timestamp2.flags;
	}
	
	line = ui_killfeed_lines[KILLFEED_NOTIFY_LINES - 1];
	line.skin = 0;

	if (stroffs_icon)
		strunzone(stroffs_icon);
	if (stroffs_text)
		strunzone(stroffs_text);
	if (stroffs_textimg)
		strunzone(stroffs_textimg);
	if (stroffs_timestamp)
		strunzone(stroffs_timestamp);
}

uielement_c Killfeed_AllocateLine(void)
{
	float time_prev = 0;
	for(float i = 0; i < KILLFEED_NOTIFY_LINES; i++)
	{
		uielement_c line = ui_killfeed_lines[i];
		if (line.skin)
		{
			time_prev = line.skin;
			continue;
		}
		
		line.skin = bound(time + KILLFEED_NOTIFY_TIME, time_prev + 0.34, time + (KILLFEED_NOTIFY_TIME * 2));
		line.colormap = time;
		return line;
	}

	//HUD_ShuffleNotificationsUp();
	// go into overflow line
	//HUD_ShuffleNotificationsUp();
	Killfeed_ShuffleNotificationsUp();

	uielement_c line = ui_killfeed_lines[KILLFEED_NOTIFY_LINES - 1];
	line.skin = bound(time + KILLFEED_NOTIFY_TIME, time_prev + 0.34, time + (KILLFEED_NOTIFY_TIME * 2));
	line.colormap = time;
	return line;
}
/* #endregion */


void HUD_Render()
{
	// Reki: Zoom hud fadeout
	#define HUDALPHA_SPEED 2.5
	#define HUDALPHA_STEPS 4
	static float hud_alpha;
	float hud_alpha_wanted = 1;
	//hud_alpha_wanted *= getstatf(STAT_ZOOM); // zoom
	if (view_subject.health <= 0) // health
		hud_alpha_wanted = 0.5;

	hud_alpha_wanted = bound(0, hud_alpha_wanted, 1);
	if (hud_alpha < hud_alpha_wanted)
		hud_alpha = min(hud_alpha_wanted, hud_alpha + (clframetime * HUDALPHA_SPEED * 1.1));
	else
		hud_alpha = max(hud_alpha_wanted, hud_alpha - (clframetime * HUDALPHA_SPEED));
	ui_hud.alpha = slerp(0, 1, hud_alpha);
	ui_hud.alpha = round(ui_hud.alpha * HUDALPHA_STEPS) / HUDALPHA_STEPS;
	//

	ui_clipsize = '0 0';
	uielement_c old_hover = ui_hover;
	float old_usemouse = ui_usemouse;
	ui_hover = __NULL__;
	ui_mouseposition = getmousepos();
	ui_usemouse = FALSE;
	ui_renderframe = TRUE;
	ui_alpha = 1;
	for(uielement_c ui_chain = ui_screen_queue; ui_chain; ui_chain = ui_chain._next)
	{
		UI_RenderElements(ui_chain);
	}
	if (!ui_usemouse)
		ui_hover = __NULL__;
	if (ui_hover != old_hover)
	{
		if (old_hover.m_leave)
			old_hover.m_leave(old_hover);
	}
	if (ui_hover && ui_hover.m_over)
		ui_hover.m_over(ui_hover);
	drawresetcliparea();
	ui_clipsize = '0 0';
	ui_renderframe = FALSE;
	//
}

void HUD_SetHazeAndSaturation()
{
	float saturation_wanted = 1;
	float saturation_speed = 1;
	float healthhaze_wanted = 0;
	float healthhaze_speed = 0.2;
	if (view_subject.deadflag != DEAD_NO)
	{
		saturation_wanted = 0.4;
		saturation_speed = 2;
	}
	else
	{

		const float danger_health = 15;
		const float low_health = 40;

		if (view_subject.health > 50)
		{
			saturation_speed = 8;
		}
		else if (view_subject.health <= danger_health)
		{
			float sinwave = sin(time * 6);

			saturation_wanted = min(saturation_wanted, 0.7 + (sinwave * 0.07));
			healthhaze_wanted = max(healthhaze_wanted, 0.1 + (-sinwave * 0.04));
		}
		else if (view_subject.health < low_health)
		{
			float sinwave = sin(time * 2.5);
			float frac = slerp(1, 0, ((view_subject.health - danger_health) / (low_health - danger_health)));

			saturation_wanted = min(saturation_wanted, 1 - ((0.2 + (sinwave * 0.07)) * frac));
			healthhaze_wanted = max(healthhaze_wanted, 0.04 * frac);
		}

		if (view_subject.health > 100) // overhealth raises saturation a tad
		{
			float frac = min(1, (view_subject.health - 100) / 100) * 0.1;
			saturation_wanted += frac;
		}
	}
	if (r_saturation != saturation_wanted)
	{
		if (r_saturation < saturation_wanted)
			r_saturation = min(saturation_wanted, r_saturation + (frametime * saturation_speed));
		else
			r_saturation = max(saturation_wanted, r_saturation - (frametime * saturation_speed));
	}
	if (r_healthhaze != healthhaze_wanted)
	{
		if (r_healthhaze < healthhaze_wanted)
			r_healthhaze = min(healthhaze_wanted, r_healthhaze + (frametime * healthhaze_speed));
		else
			r_healthhaze = max(healthhaze_wanted, r_healthhaze - (frametime * healthhaze_speed));
	}
}


