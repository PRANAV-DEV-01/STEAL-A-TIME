local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local TimeSanctuary = ReplicatedStorage:WaitForChild("TimeSanctuary", 15)
local SharedLoader = require(TimeSanctuary:WaitForChild("SharedLoader", 15))

local Config = {
	Game = SharedLoader.Get("Config", "GameConfig"),
	Balance = SharedLoader.Get("Config", "BalanceConfig"),
	Zones = SharedLoader.Get("Config", "ZoneConfig"),
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
	Remotes = Remotes,
	Player = player,
	PlayerGui = PlayerGui,
	Root = ScreenGui,
}

local TimerHud = require(script.ui.TimerHud)
local Feedback = require(script.ui.Feedback)
local ActionBar = require(script.ui.ActionBar)
local DeathOverlay = require(script.ui.DeathOverlay)

local timerHud = TimerHud.Create(api)
local feedback = Feedback.Create(api)
local actionBar = ActionBar.Create(api)
local deathOverlay = DeathOverlay.Create(api)

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
	feedback.Push(payload.text, payload.kind)
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

Remotes.Get("TS_RespawnNotice").OnClientEvent:Connect(function()
	feedback.Push("Returned to the sanctuary", "announcement")
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.E then
		actionBar.Fire()
	end
end)

print("[TimeSanctuary] client bootstrap ready")