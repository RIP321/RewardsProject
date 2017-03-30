#include <amxmodx>
#include <amxmisc>
#include <sqlx>

#define PLUGIN "<IR> Reward-System"
#define VERSION "0.1"
#define AUTHOR "yas17sin"

#define TAG "<IR>"

#define MAX_PLAYERS	32
#define MAX_LENGTH	32

enum
{
	LOAD_NONE,
	LOAD_POINTS,
	LOAD_ENTRIES,
	LOAD_STATUS,
	DELETE_RESTART,
	DELETE_ENTRIES
};

new g_iPlayers;

new g_status[MAX_PLAYERS + 1][7];

new g_mPoints[MAX_PLAYERS + 1];

new g_info[MAX_PLAYERS + 1][MAX_LENGTH + 1];

new g_points[MAX_PLAYERS + 1];
new g_maxplayers;

new Handle:g_SqlTuple;
new g_exists[MAX_PLAYERS + 1];
new g_total[MAX_PLAYERS + 1];

new ps_sql_fast;

new ps_lan_mode;

new g_fwd_points_pre;
new g_fwd_points_post;

new g_fwd_dummy;

new const g_table[] = "rewad_system";

public plugin_natives()
{
	register_native("rd_get_user_points",	"native_get_user_points");
	register_native("rd_set_user_points",	"native_set_user_points");
}
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_concmd("ps_add_points", "rd_add", ADMIN_BAN, "<target> <points>");
	
	register_cvar("ps_sql_host", "127.0.0.1");
	register_cvar("ps_sql_user", "root");
	
	register_cvar("ps_sql_pass", "12312300");
	register_cvar("ps_sql_db", "reward_db");
	
	ps_sql_fast	=	register_cvar("ps_sql_fastserver", "1");
	
	g_fwd_points_pre	= CreateMultiForward("rd_user_points_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	g_fwd_points_post	= CreateMultiForward("rd_user_points_post", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
}
public plugin_cfg()
{
	new host[64], user[64], pass[64], db[64], g_cache[512];
	
	get_cvar_string("ps_sql_host", host, 63);
	get_cvar_string("ps_sql_user", user, 63);
	get_cvar_string("ps_sql_pass", pass, 63);
	get_cvar_string("ps_sql_db", db, 63);
	
	g_SqlTuple = SQL_MakeDbTuple(host, user, pass, db);
	
	if(!g_SqlTuple) { set_fail_state("[PS] Could not connect to the database, check your cvars") ; }
	
	else
	{
		new data[2];
		
		data[0] = LOAD_NONE;
		data[1] = 0;
		
		formatex(g_cache, 511, "CREATE TABLE IF NOT EXISTS `%s` (`steamid` VARCHAR(32) NOT NULL default '', `name` VARCHAR(32) NOT NULL default '', `points` INT(11) NOT NULL default '0', `status` VARCHAR(32) NOT NULL default '', PRIMARY KEY(`steamid`));", g_table);
		SQL_ThreadQuery(g_SqlTuple, "sql_public_handle", g_cache, data, 2);
	}
}
public plugin_end()
{
	new id = read_data(1)
	if(is_user_connected(id))
	{
		for(new i = 1; i <= g_maxplayers; i++)
		{
			set_data(i);
		}
	}

	SQL_FreeHandle(g_SqlTuple);
}
public client_authorized(id)
{
	g_iPlayers++;
	
	switch(get_pcvar_num(ps_lan_mode))
	{
		case 0: get_user_authid(id, g_info[id], MAX_LENGTH);
		case 1: get_user_name(id, g_info[id], MAX_LENGTH);
	}
	get_data(id);
}
public client_disconnected(id)
{
	g_iPlayers--;
	
	set_data(id);
	
	g_exists[id]	= false;

}
public show_points(id)
{
	if(is_user_connected(id))
	{
		client_print(id, print_center, "[%s] your point is %d ", TAG, g_points[id]);
	}
}
public rd_add(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return 1;

	new arg1[24];
	new arg2[12];

	read_argv(1, arg1, 23);
	read_argv(2, arg2, 11);

	new points = str_to_num(arg2);

	if(arg1[0] == '@')
	{
		new bool:g_shown;
		static team;

		switch(arg1[1])
		{
			case 'T' : team = 1;
			case 'C' : team = 2;
		}

		static info[2][MAX_LENGTH + 1];

		if(get_pcvar_num(ps_lan_mode))
		{
			get_user_authid(id, info[1], MAX_LENGTH);
			info[0] = g_info[id];
		}

		else
		{
			get_user_name(id, info[0], MAX_LENGTH);
			info[1] = g_info[id];
		}

		for(new i = 1; i <= g_maxplayers; i++)
		{
			if(!team)
			{
				update_points(i, points, _, 1);

				if(!g_shown)
				{
					client_print(0, print_center, "[%s] ADMIN give you/all %s point(s).", TAG, points);

					console_print(id, "[%s] ADMIN give you/all %s", TAG, points);
					log_amx("ADMIN [%s] Gave Everyone %d point(s)", info[0], info[1], points);

					g_shown = true;
				}
			}

			else
			{
				if(get_user_team(i) == team )
				{
					update_points(i, points, _, 1);
					static string[24];

					if(!g_shown)
					{
						switch(team)
						{
							case 1: formatex(string, 23, "Terrorists");
							case 2: formatex(string, 23, "Counter-Terrorists");
						}

						client_print(0, print_center, "[%s] ADMIN Gave %s %s point(s).", TAG, string, points);

						static steamid[MAX_LENGTH + 1];

						if(get_pcvar_num(ps_lan_mode))
							get_user_authid(id, steamid, MAX_LENGTH);

						else
							formatex(steamid, MAX_LENGTH, "%s", g_info[id]);

						console_print(id, "[%s] Gave the %s %d point(s).",TAG, string, points);
						log_amx("[%s] Gave the %s %d point(s).", TAG, info[0], steamid, string, points);

						g_shown = true;
					}
				}
			}
		}
	}

	else
	{
		new target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF);
		static name[2][MAX_LENGTH + 1];

		get_user_name(id, name[0], MAX_LENGTH);
		get_user_name(target, name[1], MAX_LENGTH);

		if(!target)
		{
			console_print(id, "[%s] Player %s could not be found or targetted.", TAG, arg1);
			return 1;
		}

		else
		{
			update_points(target, points, _, 1);

			static steamid[2][MAX_LENGTH + 1];

			if(get_pcvar_num(ps_lan_mode))
			{
				get_user_authid(id, steamid[0], MAX_LENGTH);
				get_user_authid(target, steamid[1], MAX_LENGTH);
			}

			else
			{
				formatex(steamid[0], MAX_LENGTH, "%s", g_info[id]);
				formatex(steamid[1], MAX_LENGTH, "%s", g_info[target]);
			}


			client_print(0, print_center, "[%s] ADMIN Gave %s %d point(s).", TAG, name[1], points);

			console_print(id, "[%s] ADMIN Gave %s %d point(s)", TAG, name[1], points);
			log_amx(" %s SteamID: <%i> Gave %s SteamID: <%i> %d point(s).", name[0], steamid[0], name[1], steamid[1], points);

			log_amx("%s got %d points", name[1], points);
		}
	}

	return 1;
}

update_points(id, amount, status = 1, sound = 0)
{
	if(!is_user_connected(id))
	{
		ExecuteForward(g_fwd_points_pre, g_fwd_dummy, id, amount, status);

		if(status)
		{
			g_mPoints[id] += amount;
			g_points[id] += amount;

			if(sound)  client_cmd(id, "spk events/task_complete.wav");
		}

		else
		{
			g_mPoints[id] -= amount;
			g_points[id] -= amount;

			if(sound) client_cmd(id, "spk events/task_complete.wav");
		}

		if(g_points[id] < 0) g_points[id] = 0;
		ExecuteForward(g_fwd_points_post, g_fwd_dummy, id, amount, status);

		if(get_pcvar_num(ps_sql_fast))
			set_data(id);
	}
}

set_data(id)
{
	// Check Information
	if(!g_info[id][0] ) return;

	if(g_points[id]) if(g_points[id] > 9999999) g_points[id] = 9999999;

	static sql[512], data[2];

	data[0] = LOAD_NONE;
	data[1] = id;

	if(!g_exists[id]) return;

	if(g_exists[id] == -1)
	{
		formatex(sql, 511, "INSERT INTO `%s` (`steamid`) VALUES('%s')", g_table, g_info[id]);
		SQL_ThreadQuery(g_SqlTuple, "sql_public_handle", sql, data, 2);

		g_exists[id] = 1;
	}

	static name[MAX_LENGTH + 1];
	get_user_name(id, name, MAX_LENGTH);

	sqlx_check(name, sizeof(name) - 1);

	formatex(sql, 511, "UPDATE `%s` SET `name`='%s', `points`=%d, `status`='%d#%d#%d#%d#%d#%d#%d#%d' WHERE (steamid = '%s')", g_table, name, g_points[id], g_status[id][0], g_status[id][1], g_status[id][2], g_status[id][3], g_status[id][4], g_status[id][5], g_status[id][6], g_info[id]);
	SQL_ThreadQuery(g_SqlTuple, "sql_public_handle", sql, data, 2);
}

get_data(id)
{
	// Check Information
	if(!g_info[id][0] ) return;

	static sql[512], data[2];

	data[0] = LOAD_POINTS;
	data[1] = id;

	formatex(sql, 511, "SELECT `points` FROM `%s` WHERE `steamid` = '%s'", g_table, g_info[id]);
	SQL_ThreadQuery(g_SqlTuple, "sql_public_handle", sql, data, 2);

	data[0] = LOAD_STATUS;

	formatex(sql, 511, "SELECT `status` FROM `%s` WHERE `steamid` = '%s'", g_table, g_info[id]);
	SQL_ThreadQuery(g_SqlTuple, "sql_public_handle", sql, data, 2);
}

public sql_public_handle(failstate, Handle:Query, error[], errcode, data[], datasize, Float:queuetime)
{
	new mode = data[0];
	new id	 = data[1];

	switch(failstate)
	{
		case TQUERY_CONNECT_FAILED:	return set_fail_state("[PS] Could not connect to the SQL Database");
		case TQUERY_QUERY_FAILED:	return set_fail_state("[PS] The table Query Failed");
	}

	if(errcode) return log_amx("[PS][%d] Error on Query: %s", mode, error);

	switch(mode)
	{
		case LOAD_POINTS:
		{
			if(SQL_NumResults(Query))
			{
				g_points[id] = SQL_ReadResult(Query, 0);
				g_exists[id] = 1;
			}

			else
			{
				g_points[id]	= false;
				g_exists[id]	= -1;
			}
		}

		case LOAD_STATUS:
		{
			if(SQL_NumResults(Query))
			{
				new info[MAX_LENGTH + 1];
				SQL_ReadResult(Query, 0, info, MAX_LENGTH);

				new status[8][8];
				replace_all(info, MAX_LENGTH, "#", " ");

				parse(info, status[0], 7, status[1], 7, status[2], 7, status[3], 7, status[4], 7, status[5], 7, status[6], 7, status[7], 7);

				for(new i = 0; i <= 6; i++)
					g_status[id][i] = str_to_num(status[i]);
			}

			else
			{
				for(new i = 0; i <= 6; i++)
					g_status[id][i] = false;
			}
		}

		case DELETE_RESTART:
		{
			log_amx("Database Deletion took: %f seconds", queuetime);
			server_cmd("restart");
		}

		case DELETE_ENTRIES:
		{
			new times, sSteam[MAX_LENGTH + 1], sql[1024];

			formatex(sql, 1023, "DELETE FROM `%s` WHERE", g_table);

			while(SQL_MoreResults(Query))
			{
				SQL_ReadResult(Query, 0, sSteam, MAX_LENGTH);

				if(!times) format(sql, 1023, "%s `steamid`='%s'", sql, sSteam);
				else format(sql, 1023, "%s OR `steamid`='%s'", sql, sSteam);

				times++;
				SQL_NextRow(Query);
			}

			console_print(id, "%L", id, "ADMIN_REMOVED_ENTRIES", times);

			if(times)
			{
				data[0] = LOAD_NONE;
				data[1] = false;

				SQL_ThreadQuery(g_SqlTuple, "sql_public_handle", sql, data, 2);
			}
		}

		case LOAD_ENTRIES:
		{
			g_total[id] = SQL_ReadResult(Query, 0);
		}

	}

	return 0;
}
public native_get_user_points()
{
	return g_points[get_param(1)];
}

public native_set_user_points()
{
	update_points(get_param(1), get_param(2));
}
stock sqlx_check(string[], len)
{
	replace_all_mine(string, len, "'", "´");
	replace_all_mine(string, len, "`", "´");
}
stock replace_all_mine(string[], len, what[], with[])
{
	do
	{
		replace(string, len, what, with);
	}

	while(containi(string, what) != -1);
}
