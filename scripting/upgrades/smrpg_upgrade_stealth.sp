#pragma semicolon 1
#include <sourcemod>
#include <smrpg>
#include <smlib>

#define UPGRADE_SHORTNAME "stealth"
#define STEALTH_INC 40

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "SM:RPG Upgrade > Stealth",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Stealth upgrade for SM:RPG. Renders players opaque.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_OnPlayerSpawn);
}

public OnPluginEnd()
{
	if(SMRPG_UpgradeExists(UPGRADE_SHORTNAME))
		SMRPG_UnregisterUpgradeType(UPGRADE_SHORTNAME);
}

public OnAllPluginsLoaded()
{
	OnLibraryAdded("smrpg");
}

public OnLibraryAdded(const String:name[])
{
	// Register this upgrade in SM:RPG
	if(StrEqual(name, "smrpg"))
		SMRPG_RegisterUpgradeType("Stealth", UPGRADE_SHORTNAME, 5, true, 5, 15, 10, SMRPG_BuySell, SMRPG_ActiveQuery);
}

public OnMapStart()
{
	// Just to make sure there's nothing else messing with this effect.
	CreateTimer(10.0, Timer_SetVisibilities, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Event callbacks
 */
public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!SMRPG_IsEnabled())
		return;
	
	new upgrade[UpgradeInfo];
	SMRPG_GetUpgradeInfo(UPGRADE_SHORTNAME, upgrade);
	if(!upgrade[UI_enabled])
		return;
	
	// Are bots allowed to use this upgrade?
	if(IsFakeClient(client) && SMRPG_IgnoreBots())
		return;
	
	SetClientVisibility(client);
}

/**
 * SM:RPG Upgrade callbacks
 */
public SMRPG_BuySell(client, UpgradeQueryType:type)
{
	if(!IsClientInGame(client))
		return;
	
	SetClientVisibility(client);
}

public bool:SMRPG_ActiveQuery(client)
{
	// This is a passive effect, so it's always active, if the player got at least level 1
	new upgrade[UpgradeInfo];
	SMRPG_GetUpgradeInfo(UPGRADE_SHORTNAME, upgrade);
	return SMRPG_IsEnabled() && upgrade[UI_enabled] && SMRPG_GetClientUpgradeLevel(client, UPGRADE_SHORTNAME) > 0;
}

/**
 * Timer callbacks
 */
public Action:Timer_SetVisibilities(Handle:timer, any:data)
{
	SetVisibilities();
	
	return Plugin_Continue;
}

/**
 * Helper functions
 */
SetVisibilities()
{
	if(!SMRPG_IsEnabled())
		return;
	
	new upgrade[UpgradeInfo];
	SMRPG_GetUpgradeInfo(UPGRADE_SHORTNAME, upgrade);
	if(!upgrade[UI_enabled])
		return;
	
	new bool:bBotEnable = SMRPG_IgnoreBots();
	
	new iLevel;
	for(new i=1;i<=MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		// Are bots allowed to use this upgrade?
		if(!bBotEnable && IsFakeClient(i))
			continue;
		
		// Player didn't buy this upgrade yet.
		iLevel = SMRPG_GetClientUpgradeLevel(i, UPGRADE_SHORTNAME);
		if(iLevel <= 0)
			continue;
		
		SetClientVisibility(i);
	}
}

SetClientVisibility(client)
{
	if(!SMRPG_RunUpgradeEffect(client, UPGRADE_SHORTNAME))
		return; // Some other plugin doesn't want this effect to run
	
	new iLevel = SMRPG_GetClientUpgradeLevel(client, UPGRADE_SHORTNAME);
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	Entity_SetRenderColor(client, -1, -1, -1, 255 - iLevel * STEALTH_INC);
}