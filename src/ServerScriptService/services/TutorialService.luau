local TutorialService = {}

local ctxData

local TOTAL_STEPS = 6

local EVENT_STEP = {
	joined = 0,
	entered_zone = 2,
	steal_success = 3,
	returned_hub = 4,
	deposited = 5,
	purchased = 6,
}

local function send(player: Player)
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return
	end
	local show = profile.settings and profile.settings.showTutorial ~= false
	ctxData.Remotes.Get("TS_TutorialUpdate"):FireClient(player, {
		step = profile.tutorialStep or 0,
		total = TOTAL_STEPS,
		show = show and (profile.tutorialStep or 0) < TOTAL_STEPS,
		complete = (profile.tutorialStep or 0) >= TOTAL_STEPS,
	})
end

local function complete(player: Player, profile)
	if profile.tutorialRewardClaimed then
		return
	end
	profile.tutorialRewardClaimed = true

	local reward = ctxData.Config.Economy.Tutorial.CompletionReward
	local cap = ctxData.ProfileSchema.BankCap(profile)
	local room = math.max(0, cap - profile.bankedTime)
	local toBank = math.min(room, reward)
	profile.bankedTime += toBank
	if reward > toBank then
		ctxData.Services.TimeService.AwardTime(player, reward - toBank)
	end

	for _, title in ipairs(profile.titles) do
		if title == "Initiate" then
			return
		end
	end
	if #profile.titles < ctxData.ProfileSchema.MaxTitles then
		table.insert(profile.titles, "Initiate")
	end

	ctxData.Services.ProfileService.SetDirty(player)
	ctxData.Services.ProfileService.Sync(player)
	if ctxData.Services.BankService then
		ctxData.Services.BankService.SendUpdate(player)
	end
	ctxData.Remotes.Get("TS_Feedback"):FireClient(player, {
		text = ("Tutorial complete! +%ds banked"):format(reward),
		kind = "steal",
	})
end

function TutorialService.Notify(player: Player, eventName: string)
	local step = EVENT_STEP[eventName]
	if not step then
		return
	end
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return
	end

	if step > TOTAL_STEPS then
		return
	end
	if step > (profile.tutorialStep or 0) then
		profile.tutorialStep = step
		ctxData.Services.ProfileService.SetDirty(player)
	end

	send(player)

	if profile.tutorialStep >= TOTAL_STEPS then
		complete(player, profile)
	end
end

function TutorialService.Start(ctx)
	ctxData = ctx

	ctxData.Remotes.Get("TS_TutorialAction").OnServerInvoke = function(player, payload)
		if type(payload) ~= "table" then
			return { ok = false, reason = "invalid" }
		end
		local profile = ctxData.Services.ProfileService.GetProfile(player)
		if not profile then
			return { ok = false, reason = "no_profile" }
		end
		local action = payload.action
		if action == "skip" then
			profile.settings.showTutorial = false
			ctxData.Services.ProfileService.SetDirty(player)
			send(player)
			return { ok = true }
		elseif action == "restart" then
			profile.tutorialStep = 0
			profile.settings.showTutorial = true
			ctxData.Services.ProfileService.SetDirty(player)
			send(player)
			return { ok = true }
		end
		return { ok = false, reason = "unknown_action" }
	end

	return true
end

function TutorialService.OnProfileReady(player: Player)
	send(player)
	TutorialService.Notify(player, "joined")
end

function TutorialService.Sync(player: Player)
	send(player)
end

function TutorialService.GetStep(player: Player): number
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	return profile and profile.tutorialStep or 0
end

return TutorialService
