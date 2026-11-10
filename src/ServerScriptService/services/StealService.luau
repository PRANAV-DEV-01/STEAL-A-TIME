local Players = game:GetService("Players")

local StealService = {}

local ctxData
local cooldowns = {}
local session = {}

local function playerRoot(player: Player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function getOrCreateCooldowns(userId: number)
	local entry = cooldowns[userId]
	if not entry then
		entry = {}
		cooldowns[userId] = entry
	end
	return entry
end

local function checkHourlyCap(player: Player, amount: number)
	local hourSlot = math.floor(os.time() / 3600)
	local entry = session[player.UserId]
	if not entry or entry.hourSlot ~= hourSlot then
		entry = { hourSlot = hourSlot, total = 0 }
		session[player.UserId] = entry
	end
	if entry.total + amount > ctxData.Config.Game.HardStealCapPerHour then
		return false
	end
	entry.total += amount
	return true
end

local function npcPowerMultiplier(player: Player)
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return 1
	end
	local upgrade = ctxData.Config.Balance.Upgrades.Power_I
	if not upgrade then
		return 1
	end
	local level = profile.upgrades.Power_I or 0
	level = math.min(level, upgrade.maxLevel)
	return 1 + level * upgrade.amount
end

local function petStealMultiplier(player: Player)
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return 0
	end
	local bonus = 0
	for petId, entry in pairs(profile.pets) do
		local def = ctxData.Config.Balance.Pets[petId]
		if def and entry.equipped and def.effect == "stealMult" then
			bonus += def.amount
		end
	end
	return math.min(bonus, ctxData.Config.Balance.MaxPetBonus)
end

local function prestigeMultiplier(player: Player)
	local service = ctxData.Services.PrestigeService
	if service and service.GetStealBonus then
		return 1 + service.GetStealBonus(player)
	end
	return 1
end

local function tryNpcSteal(player: Player, pillarId: string, targetKey: string)
	local pillar = ctxData.Services.NpcTimeSourceService.GetPillar(pillarId)
	if not pillar then
		return nil, "no_source"
	end

	local playerZone = ctxData.Services.ZoneService.GetPlayerZone(player)
	if not playerZone or playerZone.isHub then
		return nil, "hub"
	end
	if pillar.zone ~= playerZone.id then
		return nil, "zone"
	end

	local root = playerRoot(player)
	if not root then
		return nil, "no_character"
	end

	local distance = (root.Position - pillar.position).Magnitude
	if distance > playerZone.maxStealDistance then
		return nil, "too_far"
	end

	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return nil, "no_profile"
	end

	local activeTime = ctxData.Services.TimeService.GetTime(player)
	if activeTime < playerZone.minActiveToSteal then
		return nil, "low_time"
	end

	if not ctxData.Services.NpcTimeSourceService.HasTime(pillarId) then
		return nil, "empty"
	end

	local cooldownTable = getOrCreateCooldowns(player.UserId)
	local now = os.clock()
	if (cooldownTable[targetKey] or 0) > now then
		return nil, "cooldown"
	end

	local eventMult = 1
	if ctxData.Services.EventService then
		eventMult = ctxData.Services.EventService.GetNpcMultiplier(playerZone.id)
	end

	local multiplier = math.min(
		ctxData.Config.Game.MaxComboMultiplier,
		npcPowerMultiplier(player) * (1 + petStealMultiplier(player)) * prestigeMultiplier(player) * eventMult
	)

	local rawReward = playerZone.baseReward * multiplier
	local desired = math.min(
		rawReward,
		ctxData.Config.Balance.MaximumStolenTimePerStealNPC
	)
	local taken = ctxData.Services.NpcTimeSourceService.Take(pillarId, desired)
	if taken <= 0 then
		return nil, "empty"
	end

	if not checkHourlyCap(player, taken) then
		ctxData.Services.NpcTimeSourceService.Refund(pillarId, taken)
		return nil, "cap"
	end

	cooldownTable[targetKey] = now + playerZone.stealCooldown

	ctxData.Services.TimeService.AwardTime(player, taken)
	profile.totalTimeStolen = (profile.totalTimeStolen or 0) + taken
	profile.stats.steals = (profile.stats.steals or 0) + 1
	ctxData.Services.ProfileService.SetDirty(player)
	if ctxData.Services.LeaderboardService then
		ctxData.Services.LeaderboardService.Submit("totalTimeStolen", player, profile.totalTimeStolen)
	end

	local tutorial = ctxData.Services.TutorialService
	if tutorial and tutorial.Notify then
		tutorial.Notify(player, "steal_success")
	end

	return math.floor(taken), nil
end

local function tryPvPSteal(player: Player, victimUserId: string, targetKey: string)
	local victim = Players:GetPlayerByUserId(tonumber(victimUserId) or -1)
	if not victim or victim == player then
		return nil, "no_target"
	end

	if ctxData.state.processingDeath[victim.UserId] or ctxData.Services.TimeDeathService.IsProcessing(victim) then
		return nil, "target_busy"
	end

	if ctxData.Services.TimeService.IsProtected(victim) then
		return nil, "target_protected"
	end

	local playerZone = ctxData.Services.ZoneService.GetPlayerZone(player)
	local victimZone = ctxData.Services.ZoneService.GetPlayerZone(victim)
	if not playerZone or playerZone.isHub or playerZone.id ~= (victimZone and victimZone.id) then
		return nil, "zone"
	end

	local playerRootPart = playerRoot(player)
	local victimRoot = playerRoot(victim)
	if not playerRootPart or not victimRoot then
		return nil, "no_character"
	end

	local distance = (playerRootPart.Position - victimRoot.Position).Magnitude
	if distance > playerZone.maxStealDistance then
		return nil, "too_far"
	end

	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return nil, "no_profile"
	end

	local activeTime = ctxData.Services.TimeService.GetTime(player)
	if activeTime < playerZone.minActiveToSteal then
		return nil, "low_time"
	end

	local victimActive = ctxData.Services.TimeService.GetTime(victim)
	if victimActive <= 0 then
		return nil, "target_empty"
	end

	local cooldownTable = getOrCreateCooldowns(player.UserId)
	local now = os.clock()
	if (cooldownTable[targetKey] or 0) > now then
		return nil, "cooldown"
	end

	local eventMult = 1
	if ctxData.Services.EventService then
		eventMult = ctxData.Services.EventService.GetPvpMultiplier()
	end

	local reward = math.min(
		victimActive * ctxData.Config.Balance.PvPStealFraction * prestigeMultiplier(player) * eventMult,
		ctxData.Config.Balance.MaximumStolenTimePerStealPvP
	)
	reward = math.floor(reward)
	if reward <= 0 then
		return nil, "target_empty"
	end
	if not checkHourlyCap(player, reward) then
		return nil, "cap"
	end

	cooldownTable[targetKey] = now + playerZone.stealCooldown

	ctxData.Services.TimeService.SetTime(victim, victimActive - reward)
	ctxData.Services.TimeService.AwardTime(player, reward)

	profile.totalTimeStolen = (profile.totalTimeStolen or 0) + reward
	profile.stats.steals = (profile.stats.steals or 0) + 1
	ctxData.Services.ProfileService.SetDirty(player)
	if ctxData.Services.LeaderboardService then
		ctxData.Services.LeaderboardService.Submit("totalTimeStolen", player, profile.totalTimeStolen)
	end

	local victimWarn = ctxData.Remotes.Get("TS_VictimWarn")
	victimWarn:FireClient(victim, { amount = reward })
	ctxData.Services.TimeService.Protect(victim, 12)

	local tutorial = ctxData.Services.TutorialService
	if tutorial and tutorial.Notify then
		tutorial.Notify(player, "steal_success")
	end

	return reward, nil
end

local function processSteal(player: Player, targetKey: string)
	if ctxData.state.processingDeath[player.UserId] or ctxData.Services.TimeDeathService.IsProcessing(player) then
		return nil, "busy"
	end

	if string.sub(targetKey, 1, 4) == "npc:" then
		local pillarId = string.sub(targetKey, 5)
		return tryNpcSteal(player, pillarId, targetKey)
	elseif string.sub(targetKey, 1, 7) == "player:" then
		local userIdStr = string.sub(targetKey, 8)
		return tryPvPSteal(player, userIdStr, targetKey)
	end
	return nil, "invalid"
end

local function handleStealRequest(player: Player, targetKey: any)
	local resultRemote = ctxData.Remotes.Get("TS_StealResult")
	if not ctxData.Services.RateLimiter.Allow(player, "steal") then
		ctxData.Services.RateLimiter.Suspect(player, "steal")
		resultRemote:FireClient(player, { ok = false, amount = 0, reason = "rate" })
		return
	end

	if type(targetKey) ~= "string" or #targetKey > 128 then
		ctxData.Services.RateLimiter.Suspect(player, "steal")
		resultRemote:FireClient(player, { ok = false, amount = 0, reason = "invalid" })
		return
	end

	local amount, reason = processSteal(player, targetKey)

	if amount then
		resultRemote:FireClient(player, { ok = true, amount = amount, reason = "ok" })
		ctxData.Remotes.Get("TS_Feedback"):FireClient(player, { text = "+" .. tostring(amount) .. "s", kind = "steal" })
	else
		resultRemote:FireClient(player, { ok = false, amount = 0, reason = reason })
		ctxData.Remotes.Get("TS_Feedback"):FireClient(player, { text = "Steal failed: " .. tostring(reason), kind = "error" })
	end
end

function StealService.Start(ctx)
	ctxData = ctx

	ctxData.Remotes.Get("TS_StealRequest").OnServerEvent:Connect(handleStealRequest)

	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player.UserId] = nil
		session[player.UserId] = nil
	end)

	return true
end

function StealService.TrySteal(player: Player, targetKey: string)
	local amount, reason = processSteal(player, targetKey)
	return amount, reason
end

return StealService
