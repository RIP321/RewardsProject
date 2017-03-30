#include <amxmodx>
#include <nvault>

#define PLUGIN "<IR> Reward-System"
#define VERSION "0.6.1"
#define AUTHOR "yas17sin"

// Tag for messages
#define TAG "<IR> Reward-System"

#define MAX_PLAYERS 32

#define ADMIN_ACCESS ADMIN_LEVEL_H

new g_iPoints[MAX_PLAYERS +1], g_iName[MAX_PLAYERS +1];

new g_iVault;

new bool:g_bGiveRemove;

new g_szPoints[100];

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	
	register_clcmd( "say /rewardmenu", "main_menu")
	register_clcmd( "say_team /rewardmenu", "main_menu")
	register_clcmd( "say /rdm", "main_menu")
	register_clcmd( "say_team /rdm", "main_menu")
	
	register_clcmd("say /points", "My_Point")
	register_clcmd("say /point", "My_Point")
	register_clcmd("say /ps", "My_Point")
	
	register_clcmd("say /givepoints", "Playerlist")
	register_clcmd("point", "PointsAction")
	
	new g_iVault = nvault_open("Reward-System");
	
	if ( g_iVault == INVALID_HANDLE )
	set_fail_state( "Error opening nVault" );
	
	set_task(300.0, "Task_Advertise", _, _, _, "b");
}
public plugin_end() 
	nvault_close(g_iVault)
	
public client_putinserver(id)
{
	if(is_user_hltv(id) || is_user_bot(id))
		return PLUGIN_HANDLED;

	Load(id);
	return PLUGIN_HANDLED;
}
public client_disconnect(id)
{
	if(is_user_hltv(id) || is_user_bot(id))
		return PLUGIN_HANDLED;
	
	Save(id);
	return PLUGIN_HANDLED;
}
public main_menu(id)
{
	new menu = menu_create("\r<IR> Reward\y-\rSystem", "reward_handler")
	
	if(g_iPoints[id] >= 10 )
		menu_additem(menu, "\wthis item is 10 point", "", 0)
	else
		menu_additem(menu, "\dthis item is 10 point", "", 0)
	
	menu_display(id, menu, 0)
}
public reward_handler(id, menu, item)
{
	switch(item)
	{
		case 0:
		{
			if(is_user_connected(id))
			{
				client_print(id, print_center, "[%s] you success buying this item say thanks to yas17sin :3", TAG)
			}
		}
		case MENU_EXIT:
		{
			menu_destroy(menu)
		}
	}
	return PLUGIN_HANDLED;
}
public My_Point(id)
{
	if(!is_user_alive(id) && is_user_connected(id))
		return PLUGIN_HANDLED;
		
	client_print(id, print_chat, "[%s] you have %d points.", TAG, g_iPoints[id])
	
	return PLUGIN_HANDLED
}
public Playerlist(id) 
{
	if(get_user_flags(id) & ADMIN_ACCESS)
	{
		new Playermenu, Temp[64];
	
		formatex(Temp, charsmax(Temp), "\w[\r%s\w]\y Playerlist", TAG);
		Playermenu = menu_create(Temp, "PlayerlistHandler");
	
		new players[32], pnum, tempid;
		new szName[32], szTempid[10];
		
		formatex(Temp, charsmax(Temp), "\y[\r%s\y]^n", g_bGiveRemove ? "REMOVE" : "GIVE");  
		menu_additem(Playermenu, Temp, "0");
	
		get_players(players, pnum, "ch");
		for( new i; i<pnum; i++ )
		{
			tempid = players[i];
		
			get_user_name(tempid, szName, charsmax(szName));
			num_to_str(tempid, szTempid, charsmax(szTempid));
			menu_additem(Playermenu, szName, szTempid, 0);
		}
	
		menu_display(id, Playermenu);
	}
}
public PlayerlistHandler(id, menu, item) {
	if( item == MENU_EXIT )
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[6], szName[32];
	new access, callback;
	menu_item_getinfo(menu, item, access, data, charsmax(data), szName, charsmax(szName), callback);
	
	new key = str_to_num(data);
	if(key == 0)
	{
		g_bGiveRemove = ! g_bGiveRemove;
		
		menu_destroy(menu);
		Playerlist(id);
		
		return PLUGIN_HANDLED;  	
	}
	
	g_iName[id] = key;
	
	client_cmd(id, "messagemode point");
	client_cmd(id, "spk fvox/blip");
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}
public PointsAction(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	new szAmount[11];
	read_argv(1,szAmount,charsmax(szAmount));
	
	new iAmount = str_to_num(szAmount);
	
	new szName[2][32];
	get_user_name(id, szName[0], 31);
	get_user_name(g_iName[id], szName[1], 31);
	
	if(iAmount >= 9999999999)
	{
		client_print(id, print_chat, "[%s] You cant %s that much points.", TAG, g_bGiveRemove ? "remove" : "give");
		return PLUGIN_HANDLED;
	}
	if(!is_user_connected(g_iName[id]))
	{
		client_print(id, print_chat, "[%s] User %s isnt connected.", TAG, szName[1]);
		return PLUGIN_HANDLED;
	}
	
	client_print(0, print_chat, "[%s] %s %s %s %i points", TAG, szName[0], g_bGiveRemove ? "took away" : "gave", szName[1], iAmount);
	
	client_cmd(0, "spk buttons/bell1");
	
	if( g_bGiveRemove )
		g_iPoints[g_iName[id]] -= iAmount;
	else
		g_iPoints[g_iName[id]] += iAmount;
	
	CheckPoint(g_iName[id]);
	
	return PLUGIN_HANDLED;
}
public Task_Advertise()
{
	client_print(0, print_chat, "[%s] This Server is Runing Reward-System By yas17sin.", TAG);
}
CheckPoint(id)
{
	if(g_iPoints[id] >= g_szPoints[g_iPoints[id]+1] && g_szPoints[g_iPoints[id]+1] != 0)
	{
		g_iPoints[id]++;
		
		if(g_iPoints[id] >= g_szPoints[g_iPoints[id]+1] && g_szPoints[g_iPoints[id]+1] != 0)
		{
			CheckPoint(id);
			return PLUGIN_HANDLED;
		}
		
		client_cmd(0, "spk events/task_complete.wav");
		
	}
	if(g_iPoints[id] != 0 && g_iPoints[id] <= g_szPoints[g_iPoints[id]-1])
	{
		g_iPoints[id]--;
		
		if(g_iPoints[id] != 0 && g_iPoints[id] <= g_szPoints[g_iPoints[id]-1])
		{
			CheckPoint(id);
			return PLUGIN_HANDLED;
		}
		
		client_print(id, print_chat, "You Points got a downgrade. You are now %i Points ", TAG, g_iPoints[id]);
	}
	return PLUGIN_HANDLED;
}
Save(id)
{
    new szAuthId[32]; 
    get_user_authid(id, szAuthId, charsmax(szAuthId));
    
    new szName[32]; 
    get_user_name(id, szName, charsmax(szName));
    
    new szData[200];
    formatex(szData, charsmax(szData), "^"%s^" ^"%i^"", szName, g_iPoints[id]);
	
    nvault_set(g_iVault, szAuthId, szData);
}
Load(id)
{   
    new szAuthId[32]; get_user_authid(id, szAuthId, charsmax(szAuthId));
    
    new szData[200], iTimeStamp;
    if(nvault_lookup(g_iVault, szAuthId, szData, charsmax(szData), iTimeStamp))
    {
              new szSavedname[32], szPoint[16];
              parse(szData, szSavedname, charsmax(szSavedname), szPoint, charsmax(szPoint))
              remove_quotes(szSavedname)
              remove_quotes(szPoint)
              set_user_info(id, "name", szSavedname)
              g_iPoints[id] = str_to_num(szPoint)
     }
}
/* Stopped right here to finish later all comented lines are to continue later */
