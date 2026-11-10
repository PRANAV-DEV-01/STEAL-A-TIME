local BalanceConfig = require(script.Parent.Config.BalanceConfig)
local GameConfig = require(script.Parent.Config.GameConfig)

local ProfileSchema = {
	SchemaVersion = 2,
	MaxUpgrades = 64,
	MaxPets = 64,
	MaxTitles = 64,
	MaxCosmetics = 64,
}

local LIMITS = {
	activeTime = { min = 0, max = GameConfig.MaxActiveTime, fallback = BalanceConfig.StartingTime },
	bankedTime = { min = 0, max = 1000000, fallback = 0 },
	bankCapIndex = { min = 0, max = #BalanceConfig.BankCapLevels, fallback = 0 },
	totalTimeStolen = { min = 0, max = 1000000000, fallback = 0 },
	totalTimeLived = { min = 0, max = 1000000000, fallback = 0 },
	offlineEarningsAt = { min = 0, max = 10000000000, fallback = 0 },
	offlinePending = { min = 0, max = BalanceConfig.OfflineEarningsCap, fallback = 0 },
	dailyStreak = { min = 0, max = 365, fallback = 0 },
	prestige = { min = 0, max = 100, fallback = 0 },
	lastSeenAt = { min = 0, max = 10000000000, fallback = 0 },
	lastPrestigeAt = { min = 0, max = 10000000000, fallback = 0 },
	tutorialStep = { min = 0, max = 6, fallback = 0 },
}

function ProfileSchema.Default()
	return {
		schema = ProfileSchema.SchemaVersion,
		activeTime = BalanceConfig.StartingTime,
		bankedTime = 0,
		bankCapIndex = 0,
		totalTimeStolen = 0,
		totalTimeLived = 0,
		upgrades = {},
		pets = {},
		cosmetics = {},
		equipped = {},
		gangId = nil,
		dailyStreak = 0,
		lastDailyClaim = "",
		offlineEarningsAt = 0,
		offlinePending = 0,
		lastSeenAt = 0,
		lastPrestigeAt = 0,
		prestige = 0,
		titles = {},
		tutorialStep = 0,
		tutorialRewardClaimed = false,
		stats = { steals = 0, deaths = 0, heists = 0, purchases = 0, trades = 0, prestiges = 0 },
		settings = { music = true, sfx = true, showTutorial = true, screenShake = true, particles = true },
	}
end

local function sanitizeNumber(value, limits)
	local fallback = limits.fallback
	if type(value) ~= "number" then
		return fallback
	end
	if value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return math.clamp(value, limits.min, limits.max)
end

local function sanitizeLevelsTable(value)
	local out = {}
	if type(value) ~= "table" then
		return out
	end
	for id, level in pairs(value) do
		if type(id) == "string" and type(level) == "number" and level >= 0 and level <= 100 then
			out[string.sub(id, 1, 48)] = math.floor(level)
		end
	end
	return out
end

local function sanitizePetsTable(value)
	local out = {}
	if type(value) ~= "table" then
		return out
	end
	for id, entry in pairs(value) do
		if type(id) == "string" and type(entry) == "table" then
			out[string.sub(id, 1, 48)] = {
				level = math.floor(sanitizeNumber(entry.level, { min = 1, max = 100, fallback = 1 })),
				xp = sanitizeNumber(entry.xp, { min = 0, max = 1000000000, fallback = 0 }),
				equipped = type(entry.equipped) == "boolean" and entry.equipped or false,
			}
		end
	end
	return out
end

local function sanitizeStringTable(value, maxEntries)
	local out = {}
	if type(value) ~= "table" then
		return out
	end
	local count = 0
	for _, v in pairs(value) do
		count += 1
		if count > maxEntries then
			break
		end
		if type(v) == "string" and #v <= 64 then
			table.insert(out, v)
		end
	end
	return out
end

local function sanitizeSettings(value)
	local defaults = ProfileSchema.Default().settings
	local out = {}
	if type(value) ~= "table" then
		return defaults
	end
	for key, fallback in pairs(defaults) do
		if type(value[key]) == "boolean" then
			out[key] = value[key]
		else
			out[key] = fallback
		end
	end
	return out
end

function ProfileSchema.Sanitize(loaded: any)
	local def = ProfileSchema.Default()
	if type(loaded) ~= "table" then
		return def
	end

	local profile = {
		schema = ProfileSchema.SchemaVersion,
		activeTime = sanitizeNumber(loaded.activeTime, LIMITS.activeTime),
		bankedTime = sanitizeNumber(loaded.bankedTime, LIMITS.bankedTime),
		bankCapIndex = math.floor(sanitizeNumber(loaded.bankCapIndex, LIMITS.bankCapIndex)),
		totalTimeStolen = sanitizeNumber(loaded.totalTimeStolen, LIMITS.totalTimeStolen),
		totalTimeLived = sanitizeNumber(loaded.totalTimeLived, LIMITS.totalTimeLived),
		upgrades = sanitizeLevelsTable(loaded.upgrades),
		pets = sanitizePetsTable(loaded.pets),
		cosmetics = sanitizeStringTable(loaded.cosmetics, ProfileSchema.MaxCosmetics),
		equipped = type(loaded.equipped) == "table" and loaded.equipped or {},
		gangId = type(loaded.gangId) == "string" and string.sub(loaded.gangId, 1, 64) or nil,
		dailyStreak = math.floor(sanitizeNumber(loaded.dailyStreak, LIMITS.dailyStreak)),
		lastDailyClaim = type(loaded.lastDailyClaim) == "string" and string.sub(loaded.lastDailyClaim, 1, 10) or "",
		offlineEarningsAt = sanitizeNumber(loaded.offlineEarningsAt, LIMITS.offlineEarningsAt),
		offlinePending = math.floor(sanitizeNumber(loaded.offlinePending, LIMITS.offlinePending)),
		lastSeenAt = math.floor(sanitizeNumber(loaded.lastSeenAt, LIMITS.lastSeenAt)),
		lastPrestigeAt = math.floor(sanitizeNumber(loaded.lastPrestigeAt, LIMITS.lastPrestigeAt)),
		prestige = math.floor(sanitizeNumber(loaded.prestige, LIMITS.prestige)),
		titles = sanitizeStringTable(loaded.titles, ProfileSchema.MaxTitles),
		tutorialStep = math.floor(sanitizeNumber(loaded.tutorialStep, LIMITS.tutorialStep)),
		tutorialRewardClaimed = loaded.tutorialRewardClaimed == true,
		stats = type(loaded.stats) == "table" and loaded.stats or def.stats,
		settings = sanitizeSettings(loaded.settings),
	}

	if type(profile.stats) == "table" then
		for key, limits in pairs({
			steals = { min = 0, max = 1000000000, fallback = 0 },
			deaths = { min = 0, max = 1000000000, fallback = 0 },
			heists = { min = 0, max = 1000000000, fallback = 0 },
			purchases = { min = 0, max = 1000000000, fallback = 0 },
			trades = { min = 0, max = 1000000000, fallback = 0 },
			prestiges = { min = 0, max = 1000000000, fallback = 0 },
		}) do
			profile.stats[key] = sanitizeNumber(profile.stats[key], limits)
		end
	end

	if type(profile.equipped) == "table" then
		local cleaned = {}
		for k, v in pairs(profile.equipped) do
			if type(k) == "string" and type(v) == "string" and #k <= 64 and #v <= 64 then
				cleaned[k] = v
			end
		end
		profile.equipped = cleaned
	end

	return profile
end

function ProfileSchema.BankCap(profile: any)
	local index = math.clamp((profile and profile.bankCapIndex or 0) + 1, 1, #BalanceConfig.BankCapLevels)
	return BalanceConfig.BankCapLevels[index] or BalanceConfig.DefaultBankCap
end

-- Client-facing projection. Never send the whole stored profile.
function ProfileSchema.Snapshot(profile: any)
	if type(profile) ~= "table" then
		return {}
	end
	return {
		activeTime = math.floor(profile.activeTime or 0),
		bankedTime = math.floor(profile.bankedTime or 0),
		bankCap = ProfileSchema.BankCap(profile),
		bankCapIndex = profile.bankCapIndex or 0,
		totalTimeStolen = math.floor(profile.totalTimeStolen or 0),
		totalTimeLived = math.floor(profile.totalTimeLived or 0),
		upgrades = profile.upgrades or {},
		pets = profile.pets or {},
		cosmetics = profile.cosmetics or {},
		equipped = profile.equipped or {},
		gangId = profile.gangId,
		dailyStreak = profile.dailyStreak or 0,
		lastDailyClaim = profile.lastDailyClaim or "",
		offlinePending = math.floor(profile.offlinePending or 0),
		prestige = profile.prestige or 0,
		titles = profile.titles or {},
		tutorialStep = profile.tutorialStep or 0,
		stats = profile.stats or {},
		settings = profile.settings or {},
	}
end

function ProfileSchema.SanitizeOutgoing(profile: any)
	return ProfileSchema.Snapshot(profile)
end

return ProfileSchema
