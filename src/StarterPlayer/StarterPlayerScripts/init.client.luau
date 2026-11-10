local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local TimeSanctuary = ReplicatedStorage:WaitForChild("TimeSanctuary", 15)
local SharedLoader = require(TimeSanctuary:WaitForChild("SharedLoader", 15))

local Config = {
	Game = SharedLoader.Get("Config", "GameConfig"),
	Balance = SharedLoader.Get("Config", "BalanceConfig"),
	Zones = SharedLoader.Get("Config", "ZoneConfig"),
	Economy = SharedLoader.Get("Config", "EconomyConfig"),
	Social = SharedLoader.Get("Config", "SocialConfig"),
}
local Remotes = SharedLoader.GetRoot("Remotes")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Name = "StealATimeHUD"
ScreenGui.Parent = PlayerGui

local api = {
	Config = Config,
	Balance = Config.Balance,
	Economy = Config.Economy,
	Social = Config.Social,
	Remotes = Remotes,
	Player = player,
	PlayerGui = PlayerGui,
	Root = ScreenGui,
}

local TimerHud = require(script.ui.TimerHud)
local Feedback = require(script.ui.Feedback)
local ActionBar = require(script.ui.ActionBar)
local DeathOverlay = require(script.ui.DeathOverlay)
local Panels = require(script.ui.Panels)
local PadInteraction = require(script.ui.PadInteraction)
local DashButton = require(script.ui.DashButton)
local TutorialHud = require(script.ui.TutorialHud)

local timerHud = TimerHud.Create(api)
local feedback = Feedback.Create(api)
api.Feedback = feedback
local actionBar = ActionBar.Create(api)
local deathOverlay = DeathOverlay.Create(api)
local panels = Panels.Create(api)
local padInteraction = PadInteraction.Create(api, panels)
local dashButton = DashButton.Create(api)
local tutorialHud = TutorialHud.Create(api)

Remotes.Get("TS_SyncTime").OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	timerHud.Apply(payload.time, payload.zone)
end)

Remotes.Get("TS_Feedback").OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.text and payload.text ~= "" then
		feedback.Push(payload.text, payload.kind)
	end
end)

Remotes.Get("TS_Announcement").OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	feedback.Push(payload.text, "announcement")
end)

Remotes.Get("TS_StealResult").OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.ok then
		feedback.Push("+" .. tostring(payload.amount or 0) .. "s stolen", "steal")
	else
		feedback.Push("Steal failed: " .. tostring(payload.reason or "unknown"), "error")
	end
end)

Remotes.Get("TS_VictimWarn").OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	feedback.Push("-" .. tostring(payload.amount or 0) .. "s taken", "warn")
end)

Remotes.Get("TS_TimeUp").OnClientEvent:Connect(function()
	deathOverlay.Show()
	feedback.Push("TIME'S UP", "danger")
end)

Remotes.Get("TS_RespawnNotice").OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and payload.secondChance then
		feedback.Push("Second Chance saved your bank!", "announcement")
	else
		feedback.Push("Returned to the sanctuary", "announcement")
	end
end)

Remotes.Get("TS_SyncProfile").OnClientEvent:Connect(function(profile)
	if type(profile) == "table" then
		panels.SetProfile(profile)
	end
end)

Remotes.Get("TS_BankUpdate").OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		panels.SetBank(payload)
	end
end)

Remotes.Get("TS_DailyUpdate").OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		panels.SetDaily(payload)
	end
end)

Remotes.Get("TS_LeaderboardUpdate").OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		panels.SetLeaderboard(payload)
	end
end)

Remotes.Get("TS_GangUpdate").OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		panels.SetGang(payload)
	end
end)

Remotes.Get("TS_TradeUpdate").OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		panels.SetTrade(payload)
	end
end)

Remotes.Get("TS_EventUpdate").OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		panels.SetEvent(payload)
	end
end)

Remotes.Get("TS_TutorialUpdate").OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		panels.SetTutorial(payload)
		tutorialHud.Apply(payload)
	end
end)

Remotes.Get("TS_AbilityState").OnClientEvent:Connect(function(payload)
	dashButton.Apply(payload)
end)

-- Ask the server for the current snapshot (events may have fired before this script connected).
task.spawn(function()
	for _ = 1, 10 do
		local ok, snapshot = pcall(function()
			return Remotes.Get("TS_ProfileRequest"):InvokeServer()
		end)
		if ok and type(snapshot) == "table" then
			panels.SetProfile(snapshot)
			return
		end
		task.wait(0.5)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.E then
		if not padInteraction.TryInteract() then
			actionBar.Fire()
		end
	elseif input.KeyCode == Enum.KeyCode.Escape then
		panels.Close()
	end
end)

print("[TimeSanctuary] client bootstrap ready")
