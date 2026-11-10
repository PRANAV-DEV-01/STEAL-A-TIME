local DailyService = {}

local ctxData

local function utcDate(offsetSeconds: number?)
	return os.date("!%Y-%m-%d", os.time() + (offsetSeconds or 0))
end

local function cycleFor(streak: number)
	local rewards = ctxData.Config.Balance.DailyRewards
	local index = ((math.max(streak, 1) - 1) % #rewards) + 1
	return rewards[index], index
end

local function sendUpdate(player: Player)
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return
	end
	local today = utcDate()
	local reward, cycle = cycleFor(math.max(profile.dailyStreak, 1))
	ctxData.Remotes.Get("TS_DailyUpdate"):FireClient(player, {
		streak = profile.dailyStreak,
		claimedToday = profile.lastDailyClaim == today,
		canClaim = profile.lastDailyClaim ~= today,
		cycle = cycle,
		reward = reward,
	})
end

local function applyReward(player: Player, profile, reward)
	if reward.type == "bank" then
		local cap = ctxData.ProfileSchema.BankCap(profile)
		local room = math.max(0, cap - profile.bankedTime)
		local toBank = math.min(room, reward.amount)
		profile.bankedTime += toBank
		local overflow = reward.amount - toBank
		if overflow > 0 then
			ctxData.Services.TimeService.AwardTime(player, overflow)
		end
		return ("+%ds banked"):format(reward.amount)
	elseif reward.type == "ability" then
		local current = profile.upgrades[reward.ability] or 0
		profile.upgrades[reward.ability] = math.max(1, current)
		local characterService = ctxData.Services.CharacterService
		if characterService and characterService.ApplyStats then
			characterService.ApplyStats(player)
		end
		return ("Unlocked %s"):format(tostring(reward.ability))
	elseif reward.type == "temporaryPet" then
		if not profile.pets[reward.pet] then
			profile.pets[reward.pet] = { level = 1, xp = 0, equipped = true }
		end
		return ("Received %s"):format(tostring(reward.pet))
	elseif reward.type == "title" then
		local had = false
		for _, title in ipairs(profile.titles) do
			if title == reward.title then
				had = true
				break
			end
		end
		if not had and #profile.titles < ctxData.ProfileSchema.MaxTitles then
			table.insert(profile.titles, reward.title)
		end
		return ("Title: %s"):format(tostring(reward.title))
	end
	return "Reward granted"
end

local function claim(player: Player)
	if not ctxData.Services.RateLimiter.Allow(player, "claim") then
		ctxData.Services.RateLimiter.Suspect(player, "claim")
		return { ok = false, reason = "rate" }
	end

	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return { ok = false, reason = "no_profile" }
	end

	local today = utcDate()
	if profile.lastDailyClaim == today then
		return { ok = false, reason = "already_claimed" }
	end

	local yesterday = utcDate(-86400)
	if profile.lastDailyClaim == yesterday then
		profile.dailyStreak = math.min(profile.dailyStreak + 1, 365)
	else
		profile.dailyStreak = 1
	end

	local reward, cycle = cycleFor(profile.dailyStreak)
	profile.lastDailyClaim = today
	local message = applyReward(player, profile, reward)
	ctxData.Services.ProfileService.SetDirty(player)
	ctxData.Services.ProfileService.Sync(player)
	if ctxData.Services.BankService then
		ctxData.Services.BankService.SendUpdate(player)
	end

	ctxData.Remotes.Get("TS_Feedback"):FireClient(player, { text = message, kind = "steal" })
	sendUpdate(player)

	return { ok = true, message = message, cycle = cycle }
end

function DailyService.Start(ctx)
	ctxData = ctx
	ctxData.Remotes.Get("TS_ClaimDaily").OnServerInvoke = function(player)
		local ok, result = pcall(claim, player)
		if ok then
			return result
		end
		warn(("%s daily error: %s"):format(ctxData.Config.Game.LogPrefix, tostring(result)))
		return { ok = false, reason = "server_error" }
	end
	return true
end

function DailyService.OnProfileReady(player: Player)
	sendUpdate(player)
end

function DailyService.Sync(player: Player)
	sendUpdate(player)
end

return DailyService
