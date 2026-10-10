local BalanceConfig = require(script.Parent.Config.BalanceConfig)
local GameConfig = require(script.Parent.Config.GameConfig)

local ProfileSchema = {
	SchemaVersion = 1,
	MaxUpgrades = 64,
	MaxPets = 64,
	MaxTitles = 64,
	MaxCosmetics = 64,
}

local LIMITS = {
	activeTime = { min = 0, max = GameConfig.MaxActiveTime, fallback = BalanceConfig.StartingTime },
	bankedTime = { min = 0, max = 100000, fallback = 0 },
	bankCapIndex = { min = 0, max = #BalanceConfig.BankCapLevels, fallback = 0 },
	totalTimeStolen = { min = 0, max = 1000000000, fallback = 0 },
	totalTimeLived = { min = 0, max = 1000000000, fallback = 0 },
	offlineEarningsAt = { min = 0, max = 10000000000, fallback = 0 },
	dailyStreak = { min = 0, max = 365, fallback = 0 },
	prestige = { min = 0, max = 100, fallback = 0 },
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
		prestige = 0,
		titles = {},
		stats = { steals = 0, deaths = 0, heists = 0 },
		settings = {},
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
			out[id] = math.floor(level)
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
			out[id] = {
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
		prestige = math.floor(sanitizeNumber(loaded.prestige, LIMITS.prestige)),
		titles = sanitizeStringTable(loaded.titles, ProfileSchema.MaxTitles),
		stats = type(loaded.stats) == "table" and loaded.stats or def.stats,
		settings = type(loaded.settings) == "table" and loaded.settings or {},
	}

	if type(profile.stats) == "table" then
		for key, limits in pairs({
			steals = { min = 0, max = 1000000000, fallback = 0 },
			deaths = { min = 0, max = 1000000000, fallback = 0 },
			heists = { min = 0, max = 1000000000, fallback = 0 },
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

function ProfileSchema.SanitizeOutgoing(profile: any)
	local view = {}
	for key, value in pairs(profile) do
		if type(value) == "table" then
			view[key] = {}
		else
			view[key] = value
		end
	end
	return view
end

return ProfileSchema