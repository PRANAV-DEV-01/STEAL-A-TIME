local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TimeSanctuaryShared = ReplicatedStorage:WaitForChild("TimeSanctuary", 15)
local SharedLoader = require(TimeSanctuaryShared:WaitForChild("SharedLoader", 15))

local ctx = {}

ctx.Config = {
	Game = SharedLoader.Get("Config", "GameConfig"),
	Balance = SharedLoader.Get("Config", "BalanceConfig"),
	Zones = SharedLoader.Get("Config", "ZoneConfig"),
}
ctx.Remotes = SharedLoader.GetRoot("Remotes")
ctx.Validation = SharedLoader.GetRoot("Validation")
ctx.ProfileSchema = SharedLoader.GetRoot("ProfileSchema")

ctx.Services = {}
ctx.State = {
	processingDeath = {},
}

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
	if ctx.Services.ProfileService and ctx.Services.ProfileService.Shutdown then
		pcall(ctx.Services.ProfileService.Shutdown, ctx.Services.ProfileService)
	end
end)