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

#include "client.h"
#include "physics.h"
#include "prediction.h"
#include "uielement.h"

void CSQC_Init()
{
	PM_UpdateMovementStats();
	W_Init();
	IT_Init();

	// Reki: Init HUD elements
	ui_hud = spawn(uielement_c, flags: UIFLAG::STRETCH | UIFLAG::MULTALPHA, alpha: 1);
	HUD_InitializeUI();
	HUD_InitializeNotifications();
	Killfeed_InitializeNotifications();

	// Precache hud notification icons
	string searchpath = "gfx/hud/messages/icons/*.tga";
	float searchhandle = search_begin(searchpath, TRUE, TRUE);
	if (searchhandle >= 0)
	{
		float searchsize = search_getsize(searchhandle);
		for(float i = 0; i < searchsize; i++)
			precache_pic(search_getfilename(searchhandle, i));
		search_end(searchhandle);
	}
	string searchpath = sprintf("gfx/hud/messages/%s/*.tga", cvar_string("prvm_language"));
	float searchhandle = search_begin(searchpath, TRUE, TRUE);
	if (searchhandle >= 0)
	{
		float searchsize = search_getsize(searchhandle);
		for(float i = 0; i < searchsize; i++)
			precache_pic(search_getfilename(searchhandle, i));
		search_end(searchhandle);
	}
}

void CSQC_Shutdown()
{

}

void CSQC_Input_Frame()
{
	cltime = gettime(GETTIME_FRAMESTART);
	xframe_lasttime = cltime;

	if (input_impulse == 35)
	{
		scoreboard_visible = !scoreboard_visible;
		Journal_Sound();
	}
}

float CSQC_InputEvent(float EventType, float charx, float scany)
{
	// Reki: Input for UI elements
	if (EventType == 0 && charx == 512 && ui_usemouse)
	{
		ui_mouseposition = getmousepos();
		uielement_c old_selected = ui_selected;
		ui_selected = __NULL__;
		for(uielement_c ui_chain = ui_screen_queue; ui_chain; ui_chain = ui_chain._next)
		{
			UI_CheckClick(ui_chain);
		}
		if (!ui_usemouse)
			ui_selected = __NULL__;
		
		if ((ui_selected.flags & UIFLAG::CLICKABLE) && !(ui_selected.flags & UIFLAG::SELECTABLE))
		{
			uielement_c u_sel = ui_selected;
			if (ui_selected && ui_selected.m_click)
				ui_selected.m_click(ui_selected);
			if (ui_selected == u_sel) // if our click transferred to another default select, don't stomp it
				ui_selected = __NULL__;
		}
		
		// keep select means blank space doesn't matter
		if (old_selected.flags & UIFLAG::KEEPSELECT && !ui_selected)
		{
			ui_selected = old_selected;
		}
		
		if (old_selected && ui_selected != old_selected)
		{
			if (old_selected.m_unclick)
				old_selected.m_unclick(old_selected);
		}

		if (ui_selected && ui_selected != old_selected && ui_selected.m_click)
			ui_selected.m_click(ui_selected);
		
		return TRUE;
	}
	//

	return FALSE;
}

float CSQC_Event_Sound(float ent, float channel, string soundname, float vol, float attenuation, vector pos, float pitchmod, float flags, float tzoid)
{
	if (ent == player_localentnum && autocvar_cl_movement)
	{
		if (channel >= CHAN_PREDICT && channel <= CHAN_PREDICT_END)
			return TRUE;
	}

	return FALSE;
}

float CSQC_Parse_TempEntity()
{
	local float nTEID;
	nTEID = ReadByte();
	switch (nTEID)
	{
		case TEMPENT::NOTIFICATION:
			string s_icon = ReadString();
			string s_msg = localization_str[ReadShort()];
			float m_flags = ReadByte();

			float msg_mode = 0;
			string s_msg_pic = sprintf("gfx/hud/messages/%s/msg_%s.tga", cvar_string("prvm_language"), s_icon);
			if (fexists(s_msg_pic))
				msg_mode |= 0x01;
			s_icon = sprintf("gfx/hud/messages/icons/msgicon_%s.tga", s_icon);
			if (fexists(s_icon))
				msg_mode |= 0x02;

			uielement_c line = HUD_AllocateLine();
			uipicture_c icon = (uipicture_c)line.partner;
			uitext_c msg = (uitext_c)line.partner2;
			uipicture_c msgpic = (uipicture_c)line.partner3;
			uitext_c tstamp = (uitext_c)line.partner4;

			// figure out icon size
			if (msg_mode & 0x02)
			{
				vector isize = draw_getimagesize(s_icon);
				isize[1] = max(isize[1], 1); // prevent div0 error
				icon.size = [(isize[0] / isize[1]) * 32, 32];

				msg.origin = msgpic.origin = [icon.size[0] + 6, 0];

				precache_pic(s_icon);
				icon.flags &= ~UIFLAG::HIDE;
			}
			else
			{
				msg.origin = msgpic.origin = '0 0';
				icon.flags |= UIFLAG::HIDE;
			}
			//

			icon.image = strzone(s_icon);
			if (msg_mode & 0x01) // img mode
			{
				msg.text = strzone("");
				msg.flags |= UIFLAG::HIDE;

				precache_pic(s_msg_pic);
				msgpic.image = strzone(s_msg_pic);
				msgpic.flags &= ~UIFLAG::HIDE;

				vector isize = draw_getimagesize(s_msg_pic);
				isize[1] = max(isize[1], 1); // prevent div0 error
				msgpic.size = [(isize[0] / isize[1]) * 32, 32];
			}
			else // text mode
			{
				msg.text = strzone(s_msg);
				msg.flags &= ~UIFLAG::HIDE;

				msgpic.image = strzone("");
				msgpic.flags |= UIFLAG::HIDE;
			}

			// add timestamp
			if (m_flags & NOTIFICATIONFLAG::TIMESTAMP)
			{
				float min, sec;
				GameTime_GetStamp(min, sec);
				tstamp.text = strzone(sprintf("(%g:%02g)", min, sec));
				tstamp.origin = msg.origin + '6 -6';
			}
		break;
		case TEMPENT::KILLFEED:
			string s_icon = ReadString();
			float killer = ReadShort();
			float victim = ReadShort();
			float m_flags = ReadByte();

			string s_name1 = "";
			string s_name2 = "";

			if (killer)
				s_name2 = getplayerkeyvalue(killer - 1, INFOKEY_P_NAME);
			if (victim)
				s_name1 = getplayerkeyvalue(victim - 1, INFOKEY_P_NAME);

			float msg_mode = 0;
			s_icon = sprintf("gfx/hud/messages/icons/msgicon_%s.tga", s_icon);
			if (fexists(s_icon))
				msg_mode |= 0x02;

			uielement_c line = Killfeed_AllocateLine();
			uipicture_c icon = (uipicture_c)line.partner;
			uitext_c msg = (uitext_c)line.partner2;
			uitext_c msg2 = (uitext_c)line.partner3;
			uitext_c tstamp = (uitext_c)line.partner4;

			msg.text = strzone(s_name1);
			msg.flags &= ~UIFLAG::HIDE;
			
			msg2.text = strzone(s_name2);
			msg2.flags &= ~UIFLAG::HIDE;

			// figure out icon size
			icon.image = strzone(s_icon);
			if (msg_mode & 0x02)
			{
				vector isize = draw_getimagesize(s_icon);
				isize[1] = max(isize[1], 1); // prevent div0 error
				icon.size = [(isize[0] / isize[1]) * 32, 32];

				msg.origin = '0 0';
				icon.origin[0] = -(6 + msg.totalsize()[0]);
				msg2.origin[0] = icon.origin[0] - (icon.size[0] + 6);

				//msg.origin = msg2.origin = [icon.size[0] + 6, 0];
				precache_pic(s_icon);
				icon.flags &= ~UIFLAG::HIDE;
			}
			else
			{
				msg.origin = '0 0';
				msg2.origin[0] = -(6 + msg.totalsize()[0]);
				icon.flags |= UIFLAG::HIDE;
			}
			//

			// add timestamp
			if (m_flags & NOTIFICATIONFLAG::TIMESTAMP)
			{
				float min, sec;
				GameTime_GetStamp(min, sec);
				tstamp.text = strzone(sprintf("(%g:%02g)", min, sec));
				tstamp.origin = msg.origin;
				tstamp.origin[0] -= 2;
				tstamp.origin[1] -= 6;
			}
		break;
		case TEMPENT::BLADEDASH:
			float enum = ReadShort();
			entity pl = findfloat(world, entnum, enum);
			if (!pl || pl.classname != "player")
				break;
			BladeDash_Spawn(pl);
		break;
		case TEMPENT::LANCEBEAM:
			TempEnt_LanceBeam();
			break;
		case TEMPENT::FIXANGLE:
			vector ang = ReadVectorL();
			setproperty(VF_CL_VIEWANGLES_X, ang_x);
			setproperty(VF_CL_VIEWANGLES_Y, ang_y);
			break;
		default:
			return FALSE;
	}

	return TRUE;
}

float CSQC_ConsoleCommand(string s)
{
	return FALSE;
}

void CSQC_Ent_Update(float is_new)
{
	float type = ReadByte();
	
	switch (type)
	{
		case NENT::Player:
			EntUpdate_Player(is_new);
			break;
		case NENT::Projectile:
			EntUpdate_Projectile(is_new);
			break;
		case NENT::PredEvent:
			EntUpdate_PEvent(is_new);
			break;
		case NENT::ItemPickup:
			EntUpdate_ItemPickup(is_new);
			break;
		case NENT::ScoreboardEntry:
			EntUpdate_ScoreboardEntry(is_new);
	}
}

void CSQC_Ent_Remove()
{
	if (self.is_actor)
		Actor_RemoveFromList(self);

	if (self.RemoveEntity)
		self.RemoveEntity();
	else
		remove(self);
}

float cl_framespeed;
float oldsvframenumber;
float oldcltime;
void CSQC_UpdateView(float vwidth, float vheight)
{
	PEvent_Cleanup();
	PM_UpdateMovementStats();
	cltime = gettime(GETTIME_FRAMESTART);
	clframetime = cltime - oldcltime;
	oldcltime = cltime;

	vid_width = cvar("vid_conwidth");
	vid_height = cvar("vid_conheight");
	vid_rwidth = cvar("vid_width");
	vid_rheight = cvar("vid_height");

	// Reki: Hud Scaling
	#define HUD_W	960
	#define HUD_H	540
	float hud_scaling = 1;
	vector hud_ratio = [vid_width / HUD_W, vid_height / HUD_H];
	if ((hud_ratio[0] == hud_ratio[1]) || hud_ratio[0] < hud_ratio[1]) // we do these hacky functions to preserve integer scaling, there's undoubtedly a better way
	{	// 16:9
		if (vid_width <= HUD_W * 0.4) // teeny tiny screen
			hud_scaling = vid_width / HUD_W;
		else if (vid_width <= HUD_W * 0.8) // 720p ish
			hud_scaling = 0.5;
		else
			hud_scaling = max(1, floor(vid_width / HUD_W));
	}
	else
	{	// 4:3, 5:4, or similar
		if (vid_height <= HUD_H * 0.4) // teeny tiny screen
			hud_scaling = vid_height / HUD_H;
		else if (vid_height <= HUD_H * 0.8) // 720p ish
			hud_scaling = 0.5;
		else
			hud_scaling = max(1, floor(vid_height / HUD_H));
	}
	if (autocvar_scr_hudscale > 0)
		hud_scaling *= autocvar_scr_hudscale;
	ui_scale = [hud_scaling, hud_scaling];
	//



	cl_framenum += (frametime / sv_ticrate) * cl_framespeed * 0.5;
	if (sv_framenum != oldsvframenumber)
	{
		cl_framespeed = 1.0;
		float diff = sv_framenum - cl_framenum;
		if (diff > 0.4 || diff < -0.4)
		{
			cl_framenum = sv_framenum;
		}
		else if (diff > 0.2)
			cl_framespeed = 1.1;
		else if (diff > 0.1)
			cl_framespeed = 1.04;
		else if (diff > 0.02)
			cl_framespeed = 1.02;
		else if (diff < -0.2)
			cl_framespeed = 0.9;
		else if (diff < -0.1)
			cl_framespeed = 0.96;
		else if (diff < -0.02)
			cl_framespeed = 0.98;
		else if (fabs(diff > 0.0001))
			cl_framespeed = 1 + (diff * sv_ticrate);
		oldsvframenumber = sv_framenum;

		// predict all actors
		self = view_subject;
		float o_frametime = frametime;
		Predict_RewindAllActors(netg_server);
		Predict_SaveAllActors(netg_oldserver);
		frametime = sv_ticrate;
		Predict_RunAllActors();
		Predict_SaveAllActors(netg_server);
		frametime = o_frametime;
	}
	cl_framenum += (frametime / sv_ticrate) * cl_framespeed * 0.5;

	view_subject = 0;
	clearscene();
	addentities(MASK_PLAYER);
	addentities(MASK_ENGINE | MASK_VIEWMODEL);
	setproperty(VF_ORIGIN, view_origin);
	setproperty(VF_ANGLES, view_angles);
	setproperty(VF_SATURATION, r_saturation);
	renderscene();

	float crosshair_scale = 1;
	vector crosshair_size = '32 32 0' * crosshair_scale;
	vector crosshair_pos = [vid_width, vid_height] / 2;
	crosshair_pos -= crosshair_size / 2;
	string crosshair_image = "gfx/hud/crosshair1.tga";
	if (cltime < r_crosshairhighlight_time)
		crosshair_image = "gfx/hud/crosshair1_active.tga";
	drawpic(crosshair_pos, crosshair_image, crosshair_size, '1 1 1', 1, DRAWFLAG_NORMAL);

	HUD_SetHazeAndSaturation();
	HUD_Render();
}



