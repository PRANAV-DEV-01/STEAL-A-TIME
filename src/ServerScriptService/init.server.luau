local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TimeSanctuaryShared = ReplicatedStorage:WaitForChild("TimeSanctuary", 15)
local SharedLoader = require(TimeSanctuaryShared:WaitForChild("SharedLoader", 15))

local ctx = {}

ctx.Config = {
	Game = SharedLoader.Get("Config", "GameConfig"),
	Balance = SharedLoader.Get("Config", "BalanceConfig"),
	Zones = SharedLoader.Get("Config", "ZoneConfig"),
	Economy = SharedLoader.Get("Config", "EconomyConfig"),
	Social = SharedLoader.Get("Config", "SocialConfig"),
}
ctx.Remotes = SharedLoader.GetRoot("Remotes")
ctx.Validation = SharedLoader.GetRoot("Validation")
ctx.ProfileSchema = SharedLoader.GetRoot("ProfileSchema")

ctx.Services = {}
-- Backwards-compatible aliases used by existing services.
ctx.services = ctx.Services
ctx.State = {
	processingDeath = {},
}
ctx.state = ctx.State

local ServicesFolder = script:WaitForChild("services", 15)
local WorldFolder = script:WaitForChild("world", 15)

local ServiceNames = {
	"RateLimiter",
	"ZoneService",
	"NpcTimeSourceService",
	"ProfileService",
	"TimeService",
	"TimeDeathService",
	"StealService",
	"TeleportService",
	"BankService",
	"ShopService",
	"DailyService",
	"OfflineService",
	"PrestigeService",
	"LeaderboardService",
	"GangService",
	"TradeService",
	"EventService",
	"TutorialService",
	"CharacterService",
	"AntiCheatService",
	"SettingsService",
}

for _, name in ServiceNames do
	ctx.Services[name] = require(ServicesFolder:WaitForChild(name, 15))
end

ctx.Services.WorldBuilder = require(WorldFolder:WaitForChild("WorldBuilder", 15))

local StartOrder = {
	"ZoneService",
	"NpcTimeSourceService",
	"ProfileService",
	"TimeService",
	"TimeDeathService",
	"StealService",
	"TeleportService",
	"BankService",
	"ShopService",
	"DailyService",
	"OfflineService",
	"PrestigeService",
	"LeaderboardService",
	"GangService",
	"TradeService",
	"EventService",
	"TutorialService",
	"CharacterService",
	"AntiCheatService",
	"SettingsService",
	"WorldBuilder",
}

for _, name in StartOrder do
	local service = ctx.Services[name]
	if service and service.Start then
		local ok, err = pcall(service.Start, service, ctx)
		if ok then
			print(("[%s] %s started"):format(ctx.Config.Game.LogPrefix, name))
		else
			warn(("[%s] %s failed to start: %s"):format(ctx.Config.Game.LogPrefix, name, tostring(err)))
		end
	end
end

print(("[%s] bootstrap complete"):format(ctx.Config.Game.LogPrefix))

game:BindToClose(function()
	for _, name in ipairs({ "ProfileService", "GangService" }) do
		local service = ctx.Services[name]
		if service and service.Shutdown then
			pcall(service.Shutdown, service)
		end
	end
end)
