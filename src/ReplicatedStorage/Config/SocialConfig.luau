local SocialConfig = {
	Gangs = {
		CreateCost = 250,
		MinNameLength = 3,
		MaxNameLength = 20,
		MaxMembers = 20,
		MinDeposit = 10,
		MaxDeposit = 300,
		StoreName = "StealATime_GANGS_V1",
		StoreKey = "registry",
		SaveDebounce = 15,
	},

	Trade = {
		SessionSeconds = 60,
		MinAmount = 1,
		MaxAmount = 500,
	},

	Leaderboards = {
		StolenBoard = "totalTimeStolen",
		BankedBoard = "bankedTime",
	},

	Events = {
		{
			id = "weekend_time_rush",
			name = "Weekend Time Rush",
			days = { 6, 7 },
			description = "All NPC steals grant +25% time.",
			npcMultiplier = 1.25,
		},
		{
			id = "vault_heist",
			name = "Vault Heist",
			days = { 3 },
			zone = "time_vaults",
			description = "Time Vault steals are doubled.",
			zoneNpcMultiplier = 2,
		},
		{
			id = "gang_war",
			name = "Gang War",
			days = { 5 },
			description = "Player steals grant +50% time.",
			pvpMultiplier = 1.5,
		},
	},

	AntiCheat = {
		MaxOutOfBoundsStuds = 3000,
		FallYLimit = -80,
		SpeedCheckSeconds = 2,
		SuspectKickLevel = 40,
		MaxSpeedSlack = 30,
	},

	GangNames = {
		AllowedPattern = "^[%w _%-]+$",
	},
}

return SocialConfig