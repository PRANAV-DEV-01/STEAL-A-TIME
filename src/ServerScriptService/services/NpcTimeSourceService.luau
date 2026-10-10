local NpcTimeSourceService = {}

local pools = {}
local ctxData
local started = false

local function registerPillars()
	for _, def in ctxData.Config.Zones.NpcPillars do
		pools[def.id] = {
			current = def.pool,
			max = def.pool,
			respawnTime = def.respawnTime,
			position = def.position,
			zone = def.zone,
			depletedAt = nil,
		}
	end
end

local function respawnLoop()
	while started do
		task.wait(1)
		local now = os.clock()
		for _, pool in pairs(pools) do
			if pool.current >= pool.max then
				pool.depletedAt = nil
			elseif pool.depletedAt then
				local rate = pool.max / pool.respawnTime
				local elapsed = now - pool.depletedAt
				pool.current = math.clamp(elapsed * rate, 0, pool.max)
				if pool.current >= pool.max then
					pool.current = pool.max
					pool.depletedAt = nil
				end
			end
		end
	end
end

function NpcTimeSourceService.Start(ctx)
	ctxData = ctx
	registerPillars()
	started = true
	task.spawn(respawnLoop)
	return true
end

function NpcTimeSourceService.GetPillar(id: string)
	return pools[id]
end

function NpcTimeSourceService.HasTime(id: string)
	local pool = pools[id]
	if not pool then
		return false
	end
	return pool.current > 0
end

function NpcTimeSourceService.Take(id: string, amount: number)
	local pool = pools[id]
	if not pool then
		return 0
	end
	if pool.current <= 0 then
		return 0
	end
	local taken = math.min(pool.current, amount)
	pool.current -= taken
	if pool.current <= 0 then
		pool.current = 0
		pool.depletedAt = os.clock()
	end
	return taken
end

function NpcTimeSourceService.CurrentAmount(id: string)
	local pool = pools[id]
	if pool then
		return pool.current
	end
	return 0
end

return NpcTimeSourceService