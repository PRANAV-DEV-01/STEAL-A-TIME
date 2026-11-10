local Players = game:GetService("Players")

local UIKit = require(script.Parent.UIKit)

local Panels = {}

local api
local root
local titleLabel
local content
local currentKind
local state = {
	profile = nil,
	bank = nil,
	daily = nil,
	leaderboard = nil,
	gang = nil,
	gangInvite = nil,
	trade = nil,
	event = nil,
	tutorial = nil,
}

local function feedback(text: string, kind: string?)
	if api.Feedback then
		api.Feedback.Push(text, kind or "announcement")
	end
end

local function invoke(remoteName: string, ...)
	local remote = api.Remotes.Get(remoteName)
	local args = { ... }
	local ok, result = pcall(function()
		return remote:InvokeServer(table.unpack(args))
	end)
	if not ok then
		feedback("Request failed", "error")
		return nil
	end
	if type(result) == "table" and result.ok == false then
		feedback("Failed: " .. tostring(result.reason), "error")
	end
	return result
end

local function clearContent()
	for _, child in content:GetChildren() do
		if child:IsA("GuiObject") or child:IsA("UIListLayout") or child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function scroll()
	local list = UIKit.Scroll(content, 0)
	list.Size = UDim2.new(1, 0, 1, 0)
	return list
end

local function sectionLabel(list, text: string, order: number)
	local label = UIKit.Label(list, text, 20, UIKit.Palette.muted)
	label.LayoutOrder = order
	label.Font = Enum.Font.GothamBold
	return label
end

local function amountBox(parent: Instance, placeholder: string)
	local box = UIKit.TextBox(parent, placeholder)
	box.Size = UDim2.new(0, 110, 0, 44)
	return box
end

local function renderBank()
	clearContent()
	local list = scroll()
	local bank = state.bank or { bankedTime = state.profile and state.profile.bankedTime or 0, cap = state.profile and state.profile.bankCap or 0 }
	sectionLabel(list, ("BANKED: %ds / %ds"):format(bank.bankedTime or 0, bank.cap or 0), 1)
	sectionLabel(list, ("ACTIVE: %ds (decays outside sanctuary)"):format(state.profile and state.profile.activeTime or 0), 2)

	local box = amountBox(list, "amount")
	box.LayoutOrder = 3
	box.Size = UDim2.new(1, -4, 0, 44)

	local depositRow = UIKit.Row(list, 48, 4)
	UIKit.RowLabel(depositRow, "Deposit active time into the bank")
	UIKit.RowButton(depositRow, "DEPOSIT", UIKit.Palette.good, function()
		local amount = tonumber(box.Text) or 0
		api.Remotes.Get("TS_BankDeposit"):FireServer(amount)
	end)

	local withdrawRow = UIKit.Row(list, 48, 5)
	UIKit.RowLabel(withdrawRow, "Withdraw banked time to active")
	UIKit.RowButton(withdrawRow, "WITHDRAW", UIKit.Palette.gold, function()
		local amount = tonumber(box.Text) or 0
		api.Remotes.Get("TS_BankWithdraw"):FireServer(amount)
	end)

	local offline = UIKit.Row(list, 48, 6)
	UIKit.RowLabel(offline, ("Offline time ready: %ds"):format(state.profile and state.profile.offlinePending or 0))
	UIKit.RowButton(offline, "COLLECT", UIKit.Palette.good, function()
		invoke("TS_ClaimOffline")
	end)

	sectionLabel(list, "Banked time is safe. Active time is what thieves can take.", 7)
end

local function renderShop()
	clearContent()
	local list = scroll()
	local profile = state.profile or { upgrades = {}, pets = {}, bankedTime = 0, bankCapIndex = 0 }
	sectionLabel(list, ("BANKED: %ds"):format(profile.bankedTime or 0), 1)

	local order = 2
	sectionLabel(list, "UPGRADES", order)
	order += 1

	local upgradeIds = {}
	for id in pairs(api.Balance.Upgrades) do
		table.insert(upgradeIds, id)
	end
	table.sort(upgradeIds)
	for _, id in ipairs(upgradeIds) do
		local def = api.Balance.Upgrades[id]
		local level = profile.upgrades[id] or 0
		local row = UIKit.Row(list, 48, order)
		order += 1
		local maxed = level >= def.maxLevel
		UIKit.RowLabel(row, ("%s  Lv %d/%d"):format(id, level, def.maxLevel))
		local cost = math.floor(def.cost * math.max(1, level + 1))
		UIKit.RowButton(row, maxed and "MAX" or ("%ds"):format(cost), maxed and UIKit.Palette.muted or UIKit.Palette.gold, function()
			if maxed then
				return
			end
			invoke("TS_PurchaseRequest", { kind = "upgrade", id = id })
		end)
	end

	sectionLabel(list, "BANK CAPACITY", order)
	order += 1
	local capRow = UIKit.Row(list, 48, order)
	order += 1
	local nextIndex = (profile.bankCapIndex or 0) + 1
	local capCost = api.Balance.BankCapCosts[nextIndex + 1]
	if capCost then
		UIKit.RowLabel(capRow, ("Next cap: %ds"):format(api.Balance.BankCapLevels[nextIndex + 1]))
		UIKit.RowButton(capRow, ("%ds"):format(capCost), UIKit.Palette.gold, function()
			invoke("TS_PurchaseRequest", { kind = "bankcap" })
		end)
	else
		UIKit.RowLabel(capRow, "Maximum bank capacity", UIKit.Palette.muted)
	end

	sectionLabel(list, "PETS", order)
	order += 1
	local petIds = {}
	for id in pairs(api.Balance.Pets) do
		table.insert(petIds, id)
	end
	table.sort(petIds)
	for _, id in ipairs(petIds) do
		local def = api.Balance.Pets[id]
		local owned = profile.pets[id]
		local row = UIKit.Row(list, 48, order)
		order += 1
		local label = ("%s  (%s)"):format(id, def.rarity)
		if owned then
			label = label .. (owned.equipped and "  EQUIPPED" or "  owned")
		end
		UIKit.RowLabel(row, label)
		if owned then
			UIKit.RowButton(row, owned.equipped and "UNEQUIP" or "EQUIP", UIKit.Palette.accent, function()
				invoke("TS_PurchaseRequest", { kind = "pet", id = id })
			end)
		else
			UIKit.RowButton(row, def.cost > 0 and ("%ds"):format(def.cost) or "EVENT", UIKit.Palette.gold, function()
				invoke("TS_PurchaseRequest", { kind = "pet", id = id })
			end)
		end
	end
end

local function renderDaily()
	clearContent()
	local list = scroll()
	local daily = state.daily or { streak = 0, canClaim = true, cycle = 1, reward = nil }
	sectionLabel(list, ("STREAK: %d days"):format(daily.streak or 0), 1)
	local reward = daily.reward
	if reward then
		local text = reward.type == "bank" and ("+%ds banked time"):format(reward.amount)
			or reward.type == "ability" and ("Unlock %s"):format(reward.ability)
			or reward.type == "temporaryPet" and ("Pet: %s"):format(reward.pet)
			or reward.type == "title" and ("Title: %s"):format(reward.title)
			or "Reward"
		sectionLabel(list, ("Day %d reward: %s"):format(daily.cycle or 1, text), 2)
	end
	local row = UIKit.Row(list, 56, 3)
	UIKit.RowLabel(row, daily.canClaim and "Daily reward ready" or "Already claimed today")
	UIKit.RowButton(row, daily.canClaim and "CLAIM" or "CLAIMED", daily.canClaim and UIKit.Palette.good or UIKit.Palette.muted, function()
		invoke("TS_ClaimDaily")
	end)
	sectionLabel(list, "Come back tomorrow to keep the streak alive.", 4)
end

local function renderLeaderboard()
	clearContent()
	local list = scroll()
	local boards = state.leaderboard or {}
	local order = 1
	local labels = { totalTimeStolen = "MOST TIME STOLEN", bankedTime = "RICHEST BANK" }
	for _, board in ipairs({ "totalTimeStolen", "bankedTime" }) do
		sectionLabel(list, labels[board], order)
		order += 1
		local rows = boards[board] or {}
		if #rows == 0 then
			sectionLabel(list, "No entries yet", order)
			order += 1
		else
			for _, entry in ipairs(rows) do
				local row = UIKit.Row(list, 40, order)
				order += 1
				UIKit.RowLabel(row, ("#%d  %s"):format(entry.rank or 0, entry.name or "?"))
				local value = UIKit.Label(row, ("%ds"):format(entry.value or 0), 20, UIKit.Palette.gold)
				value.Size = UDim2.new(0, 110, 1, 0)
				value.Position = UDim2.new(1, -120, 0, 0)
				value.TextXAlignment = Enum.TextXAlignment.Right
			end
		end
	end
end

local function renderGang()
	clearContent()
	local list = scroll()
	local gang = state.gang
	local invite = state.gangInvite

	if invite and not gang then
		sectionLabel(list, ("INVITE: %s invited you to %s"):format(invite.from or "Someone", invite.name or "a gang"), 0)
		local acceptRow = UIKit.Row(list, 52, 1)
		UIKit.RowLabel(acceptRow, "Join this gang?")
		UIKit.RowButton(acceptRow, "ACCEPT", UIKit.Palette.good, function()
			invoke("TS_GangAction", { action = "accept" })
		end)
		local declineRow = UIKit.Row(list, 52, 2)
		UIKit.RowLabel(declineRow, "Decline the invite")
		UIKit.RowButton(declineRow, "DECLINE", UIKit.Palette.bad, function()
			invoke("TS_GangAction", { action = "decline" })
		end)
	end

	if not gang then
		sectionLabel(list, ("Create a gang for %ds banked time"):format(api.Social.Gangs.CreateCost), 3)
		local box = UIKit.TextBox(list, "gang name")
		box.LayoutOrder = 4
		box.Size = UDim2.new(1, -4, 0, 44)
		local row = UIKit.Row(list, 52, 5)
		UIKit.RowLabel(row, "Name rules: 3-20 letters, numbers, spaces")
		UIKit.RowButton(row, "CREATE", UIKit.Palette.good, function()
			invoke("TS_GangAction", { action = "create", name = box.Text })
		end)
		return
	end

	local order = 10
	sectionLabel(list, ("%s  (bank %ds)"):format(gang.name, gang.bank or 0), order)
	order += 1
	local box = amountBox(list, "amount")
	box.LayoutOrder = order
	order += 1
	box.Size = UDim2.new(1, -4, 0, 44)
	local depositRow = UIKit.Row(list, 48, order)
	order += 1
	UIKit.RowLabel(depositRow, "Deposit banked time into the gang bank")
	UIKit.RowButton(depositRow, "DEPOSIT", UIKit.Palette.gold, function()
		invoke("TS_GangAction", { action = "deposit", amount = tonumber(box.Text) or 0 })
	end)

	sectionLabel(list, "MEMBERS", order)
	order += 1
	local isOwner = gang.ownerId == api.Player.UserId
	local memberIds = {}
	for _, member in ipairs(gang.members or {}) do
		memberIds[member.userId] = true
		local row = UIKit.Row(list, 44, order)
		order += 1
		local label = member.name
		if member.userId == gang.ownerId then
			label = label .. "  (leader)"
		end
		if not member.online then
			label = label .. "  offline"
		end
		UIKit.RowLabel(row, label, member.userId == gang.ownerId and UIKit.Palette.gold or nil)
		if isOwner and member.userId ~= api.Player.UserId then
			UIKit.RowButton2(row, "KICK", UIKit.Palette.bad, function()
				invoke("TS_GangAction", { action = "kick", userId = member.userId })
			end)
		end
	end

	sectionLabel(list, "INVITE PLAYERS", order)
	order += 1
	local anyInvitable = false
	for _, other in Players:GetPlayers() do
		if not memberIds[other.UserId] then
			anyInvitable = true
			local row = UIKit.Row(list, 44, order)
			order += 1
			UIKit.RowLabel(row, other.DisplayName)
			UIKit.RowButton(row, "INVITE", UIKit.Palette.accent, function()
				invoke("TS_GangAction", { action = "invite", userId = other.UserId })
			end)
		end
	end
	if not anyInvitable then
		sectionLabel(list, "No players available to invite", order)
		order += 1
	end

	local leaveRow = UIKit.Row(list, 52, order)
	order += 1
	UIKit.RowLabel(leaveRow, isOwner and "Leaving transfers leadership" or "Leave the gang")
	UIKit.RowButton(leaveRow, "LEAVE", UIKit.Palette.bad, function()
		invoke("TS_GangAction", { action = "leave" })
	end)
	if isOwner then
		local disbandRow = UIKit.Row(list, 52, order)
		UIKit.RowLabel(disbandRow, "Disband the gang")
		UIKit.RowButton(disbandRow, "DISBAND", UIKit.Palette.bad, function()
			invoke("TS_GangAction", { action = "disband" })
		end)
	end
end

local function renderTrade()
	clearContent()
	local list = scroll()
	local trade = state.trade
	if trade and trade.state == "requested" then
		sectionLabel(list, ("%s wants to trade"):format(trade.partnerName or "Someone"), 1)
		local row = UIKit.Row(list, 56, 2)
		UIKit.RowLabel(row, "Accept the trade request?")
		UIKit.RowButton(row, "ACCEPT", UIKit.Palette.good, function()
			invoke("TS_TradeAction", { action = "respond", accept = true })
		end)
		local decline = UIKit.Row(list, 52, 3)
		UIKit.RowLabel(decline, "Decline")
		UIKit.RowButton(decline, "DECLINE", UIKit.Palette.bad, function()
			invoke("TS_TradeAction", { action = "respond", accept = false })
		end)
		return
	end

	if trade and trade.state == "outgoing" then
		sectionLabel(list, ("Waiting for %s to accept"):format(trade.partnerName or "your partner"), 1)
		local cancelRow = UIKit.Row(list, 52, 2)
		UIKit.RowLabel(cancelRow, "Cancel the trade request")
		UIKit.RowButton(cancelRow, "CANCEL", UIKit.Palette.bad, function()
			invoke("TS_TradeAction", { action = "cancel" })
		end)
		return
	end

	if trade and trade.state == "open" then
		sectionLabel(list, ("Trading with %s"):format(trade.partnerName or "?"), 1)
		local myOffer = trade.offers and trade.offers[api.Player.UserId] or 0
		local theirOffer = trade.offers and trade.offers[trade.partner] or 0
		sectionLabel(list, ("Your offer: %ds   Their offer: %ds"):format(myOffer, theirOffer), 2)

		local box = amountBox(list, "your offer")
		box.LayoutOrder = 3
		box.Size = UDim2.new(1, -4, 0, 44)
		local offerRow = UIKit.Row(list, 48, 4)
		UIKit.RowLabel(offerRow, "Set your banked-time offer")
		UIKit.RowButton(offerRow, "OFFER", UIKit.Palette.accent, function()
			invoke("TS_TradeAction", { action = "offer", amount = tonumber(box.Text) or 0 })
		end)

		local confirmRow = UIKit.Row(list, 52, 5)
		local mine = trade.confirmed and trade.confirmed[api.Player.UserId]
		UIKit.RowLabel(confirmRow, mine and "You confirmed — waiting" or "Confirm when ready")
		UIKit.RowButton(confirmRow, "CONFIRM", UIKit.Palette.good, function()
			invoke("TS_TradeAction", { action = "confirm" })
		end)

		local cancelRow = UIKit.Row(list, 52, 6)
		UIKit.RowLabel(cancelRow, "Cancel the trade")
		UIKit.RowButton(cancelRow, "CANCEL", UIKit.Palette.bad, function()
			invoke("TS_TradeAction", { action = "cancel" })
		end)
		return
	end

	sectionLabel(list, "Pick a player to trade banked time with", 1)
	local order = 2
	for _, other in Players:GetPlayers() do
		if other ~= api.Player then
			local row = UIKit.Row(list, 48, order)
			order += 1
			UIKit.RowLabel(row, other.DisplayName)
			UIKit.RowButton(row, "TRADE", UIKit.Palette.accent, function()
				invoke("TS_TradeAction", { action = "request", target = other.UserId })
			end)
		end
	end
	if order == 2 then
		sectionLabel(list, "No other players online", 2)
	end
end

local function renderPrestige()
	clearContent()
	local list = scroll()
	local profile = state.profile or { prestige = 0, totalTimeLived = 0 }
	local tier = api.Balance.PrestigeTiers[(profile.prestige or 0) + 1]
	sectionLabel(list, ("PRESTIGE: %d"):format(profile.prestige or 0), 1)
	sectionLabel(list, ("Time lived: %s"):format(("%.1f hours"):format((profile.totalTimeLived or 0) / 3600)), 2)

	local row = UIKit.Row(list, 60, 3)
	if tier then
		local required = tier.hours * 3600
		local ready = (profile.totalTimeLived or 0) >= required
		UIKit.RowLabel(row, ready and ("Ready for Prestige %d"):format(profile.prestige + 1) or ("Requires %dh lived"):format(tier.hours))
		UIKit.RowButton(row, ready and "PRESTIGE" or "LOCKED", ready and UIKit.Palette.gold or UIKit.Palette.muted, function()
			if ready then
				invoke("TS_PrestigeRequest")
			end
		end)
	else
		UIKit.RowLabel(row, "Maximum prestige reached", UIKit.Palette.gold)
	end

	sectionLabel(list, "Prestige resets upgrades, banked time and bank capacity, but keeps pets and titles. Each prestige grants +5% steal power (max +25%).", 4)
end

local function renderEvent()
	clearContent()
	local list = scroll()
	local event = state.event and state.event.event
	if event then
		sectionLabel(list, ("ACTIVE EVENT: %s"):format(event.name), 1)
		sectionLabel(list, event.description or "", 2)
	else
		sectionLabel(list, "No event active today", 1)
		sectionLabel(list, "Events rotate on a weekly schedule.", 2)
	end
	sectionLabel(list, "Check back daily — weekend and vault events boost steals.", 3)
end

local function renderSettings()
	clearContent()
	local list = scroll()
	local settings = (state.profile and state.profile.settings) or {}
	sectionLabel(list, "SETTINGS", 1)
	local order = 2
	local labels = {
		music = "Music",
		sfx = "Sound effects",
		showTutorial = "Show tutorial",
		screenShake = "Screen shake",
		particles = "Particles",
	}
	for key, label in pairs(labels) do
		local row = UIKit.Row(list, 48, order)
		order += 1
		UIKit.RowLabel(row, label)
		local enabled = settings[key] ~= false
		UIKit.RowButton(row, enabled and "ON" or "OFF", enabled and UIKit.Palette.good or UIKit.Palette.muted, function()
			invoke("TS_SettingsAction", { key = key, value = not enabled })
		end)
	end
end

local function renderTutorial()
	clearContent()
	local list = scroll()
	local tutorial = state.tutorial or { step = 0, total = 6 }
	sectionLabel(list, ("Tutorial progress: %d/%d"):format(tutorial.step or 0, tutorial.total or 6), 1)
	sectionLabel(list, "Steps: travel, steal, return, bank, upgrade. Rewards +20 banked time.", 2)
	local restart = UIKit.Row(list, 52, 3)
	UIKit.RowLabel(restart, "Restart the tutorial hints")
	UIKit.RowButton(restart, "RESTART", UIKit.Palette.accent, function()
		invoke("TS_TutorialAction", { action = "restart" })
	end)
	local skip = UIKit.Row(list, 52, 4)
	UIKit.RowLabel(skip, "Hide tutorial hints")
	UIKit.RowButton(skip, "SKIP", UIKit.Palette.muted, function()
		invoke("TS_TutorialAction", { action = "skip" })
	end)
end

local RENDERERS = {
	bank = renderBank,
	shop = renderShop,
	daily = renderDaily,
	leaderboard = renderLeaderboard,
	gang = renderGang,
	trade = renderTrade,
	prestige = renderPrestige,
	event = renderEvent,
	settings = renderSettings,
	tutorial = renderTutorial,
}

local TITLES = {
	bank = "TIME BANK",
	shop = "UPGRADE SHOP",
	daily = "DAILY REWARD",
	leaderboard = "LEADERBOARD",
	gang = "GANGS",
	trade = "TRADE",
	prestige = "PRESTIGE",
	event = "EVENTS",
	settings = "SETTINGS",
	tutorial = "TUTORIAL",
}

local function rerender()
	if not currentKind or not root.Visible then
		return
	end
	local renderer = RENDERERS[currentKind]
	if renderer then
		renderer()
	end
end

function Panels.Create(createApi)
	api = createApi
	root = Instance.new("Frame")
	root.Name = "Panels"
	root.Size = UDim2.new(0.92, 0, 0.88, 0)
	root.Position = UDim2.new(0.5, 0, 0.5, 0)
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.BackgroundColor3 = UIKit.Palette.panel
	root.BackgroundTransparency = 0.05
	root.BorderSizePixel = 0
	root.Visible = false
	root.ZIndex = 50
	root.Parent = api.Root

	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(560, 640)
	constraint.Parent = root
	UIKit.Corner(root, 14)
	UIKit.Stroke(root, UIKit.Palette.accent, 2)

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundTransparency = 1
	header.Parent = root

	titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -70, 1, 0)
	titleLabel.Position = UDim2.new(0, 16, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = ""
	titleLabel.TextColor3 = UIKit.Palette.accent
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 22
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = header

	local close = UIKit.Button(header, "X", UIKit.Palette.row, function()
		Panels.Close()
	end)
	close.Size = UDim2.new(0, 44, 0, 44)
	close.Position = UDim2.new(1, -56, 0, 6)
	close.TextColor3 = UIKit.Palette.text

	content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -24, 1, -72)
	content.Position = UDim2.new(0, 12, 0, 60)
	content.BackgroundTransparency = 1
	content.Parent = root

	return Panels
end

function Panels.Open(kind: string)
	if not RENDERERS[kind] then
		return
	end
	currentKind = kind
	root.Visible = true
	titleLabel.Text = TITLES[kind] or string.upper(kind)
	rerender()
	if kind == "leaderboard" then
		task.spawn(function()
			local boards = invoke("TS_LeaderboardRequest")
			if type(boards) == "table" then
				state.leaderboard = boards
				rerender()
			end
		end)
	end
end

function Panels.Close()
	if root then
		root.Visible = false
	end
	currentKind = nil
end

function Panels.IsOpen()
	return root and root.Visible or false
end

function Panels.Toggle(kind: string)
	if Panels.IsOpen() and currentKind == kind then
		Panels.Close()
	else
		Panels.Open(kind)
	end
end

function Panels.SetProfile(profile)
	state.profile = profile
	if currentKind == "shop" or currentKind == "bank" or currentKind == "prestige" or currentKind == "settings" then
		rerender()
	end
end

function Panels.SetBank(bank)
	state.bank = bank
	if currentKind == "bank" then
		rerender()
	end
end

function Panels.SetDaily(daily)
	state.daily = daily
	if currentKind == "daily" then
		rerender()
	end
end

function Panels.SetLeaderboard(boards)
	state.leaderboard = boards
	if currentKind == "leaderboard" then
		rerender()
	end
end

function Panels.SetGang(payload)
	state.gang = payload and payload.gang or nil
	state.gangInvite = payload and payload.invite or nil
	if currentKind == "gang" then
		rerender()
	end
	if state.gangInvite then
		feedback("Gang invite from " .. tostring(state.gangInvite.from or "a player"), "announcement")
	end
end

function Panels.SetTrade(payload)
	state.trade = payload
	if currentKind == "trade" then
		rerender()
	end
	if payload and payload.state == "requested" then
		feedback("Trade request from " .. tostring(payload.partnerName or "a player"), "announcement")
		if not Panels.IsOpen() then
			Panels.Open("trade")
		end
	elseif payload and payload.state == "ended" and payload.reason == "complete" then
		feedback("Trade complete", "steal")
	elseif payload and payload.state == "ended" then
		feedback("Trade ended: " .. tostring(payload.reason), "warn")
	end
end

function Panels.SetEvent(payload)
	state.event = payload
	if currentKind == "event" then
		rerender()
	end
end

function Panels.SetTutorial(payload)
	state.tutorial = payload
	if currentKind == "tutorial" then
		rerender()
	end
end

function Panels.GetProfile()
	return state.profile
end

return Panels
