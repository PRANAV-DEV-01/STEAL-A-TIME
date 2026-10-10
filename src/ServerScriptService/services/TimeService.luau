local Players = game:GetService("Players")

local TimeService = {}

local ctxData
local active = {}
local protectedUntil = {}
local lastSyncAt = {}
local started = false

local function broadcast(player: Player)
	local userId = player.UserId
	local time = math.floor(active[userId] or 0)
	local zoneId = "hub"
	local zone = ctxData.services.ZoneService.GetPlayerZone(player)
	if zone then
		zoneId = zone.id
	end
	local syncRemote = ctxData.Remotes.Get("TS_SyncTime")
	syncRemote:FireClient(player, { time = time, zone = zoneId })
end

local function decayLoop()
	local lastClock = os.clock()
	while started do
		task.wait(ctxData.Config.Game.DecayTick)
		local now = os.clock()
		local dt = math.min(now - lastClock, 5)
		lastClock = now

		local deadNow = {}
		for _, player in Players:GetPlayers() do
			local userId = player.UserId
			local value = active[userId]
			if value == nil then
				continue
			end

			local zone = ctxData.services.ZoneService.GetPlayerZone(player)

			local processing = ctxData.state.processingDeath[userId] or false
			local protected = (protectedUntil[userId] or 0) > now

			if zone and not zone.isHub and not processing and not protected then
				local decay = zone.decayPerSecond * dt
				value = math.max(0, value - decay)
				active[userId] = value

				local profile = ctxData.services.ProfileService.GetProfile(player)
				if profile then
					profile.activeTime = value
					profile.totalTimeLived += decay
				end
				ctxData.services.ProfileService.SetDirty(player)

				if value <= 0 then
					table.insert(deadNow, player)
				end
			end

			if now - (lastSyncAt[userId] or 0) >= ctxData.Config.Game.BroadcastThrottle then
				lastSyncAt[userId] = now
				broadcast(player)
			end
		end

		for _, player in deadNow do
			task.spawn(function()
				pcall(ctxData.services.TimeDeathService.HandleTimeUp, ctxData.services.TimeDeathService, player)
			end)
		end
	end
end

function TimeService.Start(ctx)
	ctxData = ctx

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			while not ctxData.services.ProfileService.GetProfile(player) do
				task.wait(0.1)
			end
			local profile = ctxData.services.ProfileService.GetProfile(player)
			active[player.UserId] = profile.activeTime
			lastSyncAt[player.UserId] = 0
			task.wait(0.5)
			broadcast(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		active[player.UserId] = nil
		protectedUntil[player.UserId] = nil
		lastSyncAt[player.UserId] = nil
	end)

	if not started then
		started = true
		task.spawn(decayLoop)
	end

	return true
end

function TimeService.GetTime(player: Player)
	return active[player.UserId] or 0
end

function TimeService.SetTime(player: Player, value: number)
	value = math.clamp(value, 0, ctxData.Config.Game.MaxActiveTime)
	active[player.UserId] = value
	local profile = ctxData.services.ProfileService.GetProfile(player)
	if profile then
		profile.activeTime = value
		ctxData.services.ProfileService.SetDirty(player)
	end
	broadcast(player)
end

function TimeService.AwardTime(player: Player, amount: number)
	if amount <= 0 then
		return 0
	end
	local current = active[player.UserId] or 0
	local awarded = math.min(amount, ctxData.Config.Game.MaxActiveTime - current)
	active[player.UserId] = current + awarded
	local profile = ctxData.services.ProfileService.GetProfile(player)
	if profile then
		profile.activeTime = active[player.UserId]
		ctxData.services.ProfileService.SetDirty(player)
	end
	broadcast(player)
	return awarded
end

function TimeService.Protect(player: Player, seconds: number)
	protectedUntil[player.UserId] = os.clock() + seconds
end

function TimeService.IsProtected(player: Player)
	return (protectedUntil[player.UserId] or 0) > os.clock()
end

return TimeService