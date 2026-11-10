local BankService = {}

local ctxData

local function capFor(profile)
	return ctxData.ProfileSchema.BankCap(profile)
end

local function sendUpdate(player: Player)
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return
	end
	local remote = ctxData.Remotes.Get("TS_BankUpdate")
	remote:FireClient(player, {
		bankedTime = math.floor(profile.bankedTime),
		cap = capFor(profile),
	})
end

local function feedback(player: Player, text: string, kind: string)
	ctxData.Remotes.Get("TS_Feedback"):FireClient(player, { text = text, kind = kind })
end

local function canAct(player: Player): boolean
	if ctxData.state.processingDeath[player.UserId] then
		return false
	end
	if ctxData.Services.TimeDeathService.IsProcessing(player) then
		return false
	end
	return true
end

local function deposit(player: Player, rawAmount: any)
	if not ctxData.Services.RateLimiter.Allow(player, "bank") then
		ctxData.Services.RateLimiter.Suspect(player, "bank")
		return
	end
	if not canAct(player) then
		feedback(player, "Cannot bank right now", "error")
		return
	end

	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return
	end

	local amount = math.floor(
		ctxData.Validation.NormalizeFiniteNumber(
			rawAmount,
			0,
			ctxData.Config.Economy.Bank.MaxAmountPerRequest,
			0
		)
	)
	if amount < ctxData.Config.Economy.Bank.MinAmount then
		feedback(player, "Enter an amount to bank", "error")
		return
	end

	local active = ctxData.Services.TimeService.GetTime(player)
	amount = math.min(amount, math.floor(active))
	local room = capFor(profile) - profile.bankedTime
	amount = math.min(amount, math.floor(room))
	if amount <= 0 then
		feedback(player, "Bank is full or you have no active time", "error")
		return
	end

	ctxData.Services.TimeService.SetTime(player, active - amount)
	profile.bankedTime += amount
	ctxData.Services.ProfileService.SetDirty(player)
	sendUpdate(player)
	feedback(player, ("Banked %ds"):format(amount), "steal")

	local tutorial = ctxData.Services.TutorialService
	if tutorial and tutorial.Notify then
		tutorial.Notify(player, "deposited")
	end
end

local function withdraw(player: Player, rawAmount: any)
	if not ctxData.Services.RateLimiter.Allow(player, "bank") then
		ctxData.Services.RateLimiter.Suspect(player, "bank")
		return
	end
	if not canAct(player) then
		feedback(player, "Cannot withdraw right now", "error")
		return
	end

	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return
	end

	local amount = math.floor(
		ctxData.Validation.NormalizeFiniteNumber(
			rawAmount,
			0,
			ctxData.Config.Economy.Bank.MaxAmountPerRequest,
			0
		)
	)
	if amount < ctxData.Config.Economy.Bank.MinAmount then
		feedback(player, "Enter an amount to withdraw", "error")
		return
	end

	local active = ctxData.Services.TimeService.GetTime(player)
	local room = ctxData.Config.Game.MaxActiveTime - active
	amount = math.min(amount, math.floor(profile.bankedTime), math.floor(room))
	if amount <= 0 then
		feedback(player, "No room for more active time", "error")
		return
	end

	profile.bankedTime -= amount
	ctxData.Services.TimeService.SetTime(player, active + amount)
	ctxData.Services.ProfileService.SetDirty(player)
	sendUpdate(player)
	feedback(player, ("Withdrew %ds"):format(amount), "announcement")
end

function BankService.Start(ctx)
	ctxData = ctx

	local depositRemote = ctxData.Remotes.Get("TS_BankDeposit")
	depositRemote.OnServerEvent:Connect(function(player, amount)
		deposit(player, amount)
	end)

	local withdrawRemote = ctxData.Remotes.Get("TS_BankWithdraw")
	withdrawRemote.OnServerEvent:Connect(function(player, amount)
		withdraw(player, amount)
	end)

	return true
end

function BankService.OnProfileReady(player: Player)
	sendUpdate(player)
end

function BankService.SendUpdate(player: Player)
	sendUpdate(player)
end

function BankService.Sync(player: Player)
	sendUpdate(player)
end

function BankService.GetCap(player: Player)
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	return profile and capFor(profile) or 0
end

return BankService
