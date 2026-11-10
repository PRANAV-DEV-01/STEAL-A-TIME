local BalanceConfig = require(script.Parent.BalanceConfig)

-- Economy tuning that is not part of the core balance table.
-- Anything that changes player power/earnings belongs in BalanceConfig.
local EconomyConfig = {
	Bank = {
		MinAmount = 1,
		MaxAmountPerRequest = 300,
		ActionCooldown = 0.2,
	},

	Shop = {
		-- Purchases are paid from banked time only.
		Currency = "bankedTime",
		UpgradeCostScaling = 1.0, -- cost * (level + 1) * scaling
		BankCapCosts = BalanceConfig.BankCapCosts,
	},

	Offline = {
		MinHours = 0.25,
	},

	Prestige = {
		ResetUpgrades = true,
		ResetBanked = true,
		ResetActive = true,
		KeepPets = true,
		KeepTitles = true,
		KeepBankCap = false,
	},

	Daily = {
		-- Cycle length follows #BalanceConfig.DailyRewards.
		AnnounceHourUTC = 0,
	},

	Leaderboards = {
		TopCount = 10,
		RefreshSeconds = 60,
		StoreName = "StealATime_LEADERBOARD_V1",
	},

	Tutorial = {
		CompletionReward = 20,
		PollSeconds = 2,
	},

	Character = {
		Dash = {
			SpeedMultiplier = 1.5,
			Duration = 2,
			Cooldown = 8,
		},
		Stealth = {
			Duration = 3,
			Cooldown = 30,
			Transparency = 0.75,
		},
		AutoSteal = {
			Interval = 5,
			Range = 18,
		},
	},
}

return EconomyConfig