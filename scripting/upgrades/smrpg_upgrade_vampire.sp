#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <smrpg>

#undef REQUIRE_PLUGIN
#include <smrpg_health>

#define UPGRADE_SHORTNAME "vamp"
#define PLUGIN_VERSION "1.0"

/* Percent of damage to convert to attacker's health for each level */
#define VAMP_INC 0.075

public Plugin:myinfo = 
{
	name = "SM:RPG Upgrade > Vampire",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Vampire upgrade for SM:RPG. Steal HP from players when damaging them.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
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
		SMRPG_RegisterUpgradeType("Vampire", UPGRADE_SHORTNAME, 15, true, 10, 15, 10, SMRPG_BuySell, SMRPG_ActiveQuery);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
}

/**
 * SM:RPG Upgrade callbacks
 */
public SMRPG_BuySell(client, UpgradeQueryType:type)
{
	// Nothing to apply here immediately after someone buys this upgrade.
}

public bool:SMRPG_ActiveQuery(client)
{
	// This is a passive effect, so it's always active, if the player got at least level 1
	new upgrade[UpgradeInfo];
	SMRPG_GetUpgradeInfo(UPGRADE_SHORTNAME, upgrade);
	return SMRPG_IsEnabled() && upgrade[UI_enabled] && SMRPG_GetClientUpgradeLevel(client, UPGRADE_SHORTNAME) > 0;
}

/**
 * Hook callbacks
 */
public Hook_OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
	if(attacker <= 0 || victim <= 0)
		return;
	
	if(!SMRPG_IsEnabled())
		return;
	
	new upgrade[UpgradeInfo];
	SMRPG_GetUpgradeInfo(UPGRADE_SHORTNAME, upgrade);
	if(!upgrade[UI_enabled])
		return;
	
	// Are bots allowed to use this upgrade?
	if(IsFakeClient(attacker) && SMRPG_IgnoreBots())
		return;
	
	// Ignore team attack
	if(GetClientTeam(attacker) == GetClientTeam(victim))
		return;
	
	new iLevel = SMRPG_GetClientUpgradeLevel(attacker, UPGRADE_SHORTNAME);
	if(iLevel <= 0)
		return;
	
	new Float:fIncrease = float(iLevel) * VAMP_INC;
	fIncrease *= damage;
	fIncrease += 0.5;
	
	new iNewHealth = GetClientHealth(attacker) + RoundToFloor(fIncrease);
	new iMaxHealth = SMRPG_Health_GetClientMaxHealth(attacker);
	// Limit health gain to maxhealth
	if(iNewHealth > iMaxHealth)
		iNewHealth = iMaxHealth;
	
	SetEntityHealth(attacker, iNewHealth);
}