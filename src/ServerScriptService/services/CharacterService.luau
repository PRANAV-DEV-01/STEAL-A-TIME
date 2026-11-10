local Players = game:GetService("Players")

local CharacterService = {}

local ctxData
local dashUntil = {}
local dashReadyAt = {}
local stealthReadyAt = {}
local stealthToken = {}
local autoReadyAt = {}
local started = false

local function getHumanoid(player: Player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

local function speedMultiplier(player: Player): number
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return 1
	end
	local multiplier = 1
	for id, def in pairs(ctxData.Config.Balance.Upgrades) do
		if def.effect == "walkspeed" then
			local level = math.min(profile.upgrades[id] or 0, def.maxLevel)
			multiplier += level * def.amount
		end
	end
	return multiplier
end

local function baseSpeed(player: Player): number
	local speed = ctxData.Config.Game.BaseWalkSpeed * speedMultiplier(player)
	return math.clamp(speed, ctxData.Config.Game.BaseWalkSpeed, ctxData.Config.Game.MaxWalkSpeed)
end

local function currentSpeed(player: Player): number
	local speed = baseSpeed(player)
	if (dashUntil[player.UserId] or 0) > os.clock() then
		speed = math.min(
			speed * ctxData.Config.Economy.Character.Dash.SpeedMultiplier,
			ctxData.Config.Game.MaxWalkSpeed * 2
		)
	end
	return speed
end

local function sendAbilityState(player: Player)
	local now = os.clock()
	ctxData.Remotes.Get("TS_AbilityState"):FireClient(player, {
		dashReadyIn = math.max(0, (dashReadyAt[player.UserId] or 0) - now),
		stealthReadyIn = math.max(0, (stealthReadyAt[player.UserId] or 0) - now),
	})
end

function CharacterService.ApplyStats(player: Player)
	local humanoid = getHumanoid(player)
	if not humanoid then
		return
	end
	humanoid.WalkSpeed = currentSpeed(player)
	humanoid.JumpPower = ctxData.Config.Game.JumpPower
	humanoid.UseJumpPower = true
end

function CharacterService.GetMaxSpeed(player: Player): number
	return currentSpeed(player)
end

local function useDash(player: Player)
	if not ctxData.Services.RateLimiter.Allow(player, "steal") then
		return
	end
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile or (profile.upgrades.Time_Dash or 0) <= 0 then
		return
	end
	local now = os.clock()
	if (dashReadyAt[player.UserId] or 0) > now then
		return
	end
	local cfg = ctxData.Config.Economy.Character.Dash
	dashReadyAt[player.UserId] = now + cfg.Cooldown
	dashUntil[player.UserId] = now + cfg.Duration
	CharacterService.ApplyStats(player)
	sendAbilityState(player)
	task.delay(cfg.Duration, function()
		if player.Parent then
			CharacterService.ApplyStats(player)
		end
	end)
end

local function useStealth(player: Player)
	if not ctxData.Services.RateLimiter.Allow(player, "steal") then
		return
	end
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return
	end
	local tier = 0
	if (profile.upgrades.Stealth_II or 0) > 0 then
		tier = 2
	elseif (profile.upgrades.Stealth_I or 0) > 0 then
		tier = 1
	end
	if tier == 0 then
		return
	end
	local now = os.clock()
	if (stealthReadyAt[player.UserId] or 0) > now then
		return
	end

	local cfg = ctxData.Config.Economy.Character.Stealth
	local duration = cfg.Duration + (tier - 1) * 3
	stealthReadyAt[player.UserId] = now + cfg.Cooldown
	local character = player.Character
	if not character then
		return
	end

	local token = (stealthToken[player.UserId] or 0) + 1
	stealthToken[player.UserId] = token

	local originals = {}
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			table.insert(originals, { part = part, transparency = part.Transparency })
			part.Transparency = cfg.Transparency
		end
	end
	sendAbilityState(player)

	task.delay(duration, function()
		if stealthToken[player.UserId] ~= token then
			return
		end
		for _, entry in originals do
			if entry.part and entry.part.Parent then
				entry.part.Transparency = entry.transparency
			end
		end
	end)
end

local function autoStealLoop()
	while started do
		task.wait(2)
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			local profile = ctxData.Services.ProfileService.GetProfile(player)
			if profile and (profile.upgrades.Auto_Steal or 0) > 0 then
				if (autoReadyAt[player.UserId] or 0) <= now then
					local zone = ctxData.Services.ZoneService.GetPlayerZone(player)
					if zone and not zone.isHub then
						local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						if root then
							local bestId = nil
							local bestDistance = math.huge
							local range = ctxData.Config.Economy.Character.AutoSteal.Range
							for _, pillar in ctxData.Config.Zones.NpcPillars do
								if pillar.zone == zone.id then
									local distance = (pillar.position - root.Position).Magnitude
									if distance <= range and distance < bestDistance then
										bestDistance = distance
										bestId = pillar.id
									end
								end
							end
							if bestId then
								local amount = ctxData.Services.StealService.TrySteal(player, "npc:" .. bestId)
								if amount and amount > 0 then
									autoReadyAt[player.UserId] = now
										+ ctxData.Config.Economy.Character.AutoSteal.Interval
									ctxData.Remotes.Get("TS_Feedback"):FireClient(player, {
										text = ("Auto-steal +%ds"):format(amount),
										kind = "steal",
									})
								end
							end
						end
					end
				end
			end
		end
	end
end

function CharacterService.Start(ctx)
	ctxData = ctx

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			CharacterService.ApplyStats(player)
			sendAbilityState(player)
		end)
		if player.Character then
			task.defer(CharacterService.ApplyStats, player)
		end
	end)

	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			CharacterService.ApplyStats(player)
			sendAbilityState(player)
		end)
		if player.Character then
			task.defer(CharacterService.ApplyStats, player)
		end
	end

	ctxData.Remotes.Get("TS_DashRequest").OnServerEvent:Connect(useDash)
	ctxData.Remotes.Get("TS_StealthRequest").OnServerEvent:Connect(useStealth)

	Players.PlayerRemoving:Connect(function(player)
		dashUntil[player.UserId] = nil
		dashReadyAt[player.UserId] = nil
		stealthReadyAt[player.UserId] = nil
		stealthToken[player.UserId] = nil
		autoReadyAt[player.UserId] = nil
	end)

	if not started then
		started = true
		task.spawn(autoStealLoop)
	end

	return true
end

function CharacterService.OnProfileReady(player: Player)
	task.defer(function()
		CharacterService.ApplyStats(player)
		sendAbilityState(player)
	end)
end

function CharacterService.Sync(player: Player)
	CharacterService.ApplyStats(player)
	sendAbilityState(player)
end

return CharacterService
