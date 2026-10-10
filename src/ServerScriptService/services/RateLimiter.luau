local RateLimiter = {}

local DEFAULT_LIMITS = {
	steal = { window = 60, max = 6 },
	teleport = { window = 60, max = 6 },
	purchase = { window = 60, max = 10 },
	claim = { window = 60, max = 3 },
	bank = { window = 60, max = 10 },
}

local buckets = {}
local abuse = {}

function RateLimiter.SetLimits(action: string, window: number, maxHits: number)
	DEFAULT_LIMITS[action] = { window = window, max = maxHits }
end

function RateLimiter.Allow(player: Player, action: string)
	local limits = DEFAULT_LIMITS[action]
	if not limits then
		return true
	end

	local key = tostring(player.UserId) .. ":" .. action
	local bucket = buckets[key]
	if not bucket then
		bucket = { stamps = {} }
		buckets[key] = bucket
	end

	local now = os.clock()
	local recent = 0
	local pruneIndex = 0
	for i = #bucket.stamps, 1, -1 do
		if now - bucket.stamps[i] > limits.window then
			pruneIndex = i
		else
			recent += 1
		end
	end
	if pruneIndex > 0 then
		table.remove(bucket.stamps, 1, pruneIndex)
	end

	if recent >= limits.max then
		return false
	end

	table.insert(bucket.stamps, now)
	return true
end

function RateLimiter.Suspect(player: Player, action: string)
	local key = tostring(player.UserId) .. ":" .. action
	local level = (abuse[key] or 0) + 1
	abuse[key] = level
	return level
end

function RateLimiter.SuspectLevel(player: Player, action: string)
	local key = tostring(player.UserId) .. ":" .. action
	return abuse[key] or 0
end

function RateLimiter.ClearSuspect(player: Player, action: string)
	local key = tostring(player.UserId) .. ":" .. action
	abuse[key] = nil
	buckets[key] = nil
end

function RateLimiter.ResetPlayer(player: Player)
	local userId = tostring(player.UserId)
	for key, _ in pairs(buckets) do
		if string.sub(key, 1, #userId) == userId then
			buckets[key] = nil
		end
	end
	for key, _ in pairs(abuse) do
		if string.sub(key, 1, #userId) == userId then
			abuse[key] = nil
		end
	end
end

return RateLimiter