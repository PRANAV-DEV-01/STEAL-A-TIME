local BalanceConfig = {
	StartingTime = 60,

	DeathBankSetbackFraction = 0.10,
	InsuranceSetbackFraction = 0.05,
	RespawnProtectionDuration = 30,
	ComebackFlatBonus = 15,
	ComebackWindow = 300,

	MaximumStolenTimePerStealNPC = 40,
	MaximumStolenTimePerStealPvP = 15,
	PvPStealFraction = 0.20,

	DefaultBankCap = 300,
	BankCapLevels = { 300, 600, 1000, 1500 },
	BankCapCosts = { 0, 500, 900, 1500 },

	OfflineEarningsFractionPerHour = 0.05,
	OfflineEarningsMaxHours = 12,
	OfflineEarningsCap = 500,

	Upgrades = {
		Speed_I = { cost = 120, category = "Speed", maxLevel = 1, effect = "walkspeed", amount = 0.08 },
		Speed_II = { cost = 300, category = "Speed", maxLevel = 1, effect = "walkspeed", amount = 0.08 },
		Speed_III = { cost = 700, category = "Speed", maxLevel = 1, effect = "walkspeed", amount = 0.04 },
		Time_Dash = { cost = 400, category = "Speed", maxLevel = 1, effect = "dash" },
		Stealth_I = { cost = 250, category = "Stealth", maxLevel = 1, effect = "invis", amount = 3 },
		Stealth_II = { cost = 600, category = "Stealth", maxLevel = 1, effect = "invis", amount = 6 },
		Shadow_Step = { cost = 900, category = "Stealth", maxLevel = 1, effect = "blink" },
		Power_I = { cost = 150, category = "Power", maxLevel = 10, effect = "npcReward", amount = 0.05 },
		Auto_Steal = { cost = 1200, category = "Power", maxLevel = 1, effect = "autoSteal" },
		Time_Insurance = { cost = 450, category = "Defense", maxLevel = 1, effect = "insurance" },
		Second_Chance = { cost = 1000, category = "Defense", maxLevel = 1, effect = "secondChance" },
		Bounty_Protection = { cost = 750, category = "Defense", maxLevel = 1, effect = "bountyProtection" },
	},

	Pets = {
		Time_Puppy = { cost = 200, rarity = "Common", effect = "stealMult", amount = 0.02 },
		Clockwork_Owl = { cost = 550, rarity = "Rare", effect = "bankMult", amount = 0.05 },
		Golden_Clock = { cost = 1200, rarity = "Epic", effect = "dailyMult", amount = 0.10 },
		Time_Dragon = { cost = 2400, rarity = "Mythic", effect = "stealMult", amount = 0.08 },
		Void_Phoenix = { cost = 0, rarity = "Event", effect = "comebackMult", amount = 0.15 },
	},

	MaxPetBonus = 0.20,
	MaxPrestigeBonus = 0.25,

	DailyRewards = {
		{ day = 1, type = "bank", amount = 30 },
		{ day = 2, type = "ability", ability = "Second_Chance" },
		{ day = 3, type = "bank", amount = 60 },
		{ day = 4, type = "temporaryPet", pet = "Time_Puppy" },
		{ day = 5, type = "bank", amount = 120 },
		{ day = 6, type = "title", title = "Streak Master" },
		{ day = 7, type = "title", title = "Chrono" },
	},

	PrestigeTiers = {
		{ hours = 100, stealBonus = 0.05 },
		{ hours = 250, stealBonus = 0.05 },
		{ hours = 500, stealBonus = 0.05 },
		{ hours = 1000, stealBonus = 0.05 },
		{ hours = 2500, stealBonus = 0.05 },
	},
}

return BalanceConfig