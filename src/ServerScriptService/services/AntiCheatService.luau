local Players = game:GetService("Players")

local AntiCheatService = {}

local ctxData
local started = false

local function horizontalSpeed(root)
	local velocity = root.AssemblyLinearVelocity
	return Vector3.new(velocity.X, 0, velocity.Z).Magnitude
end

local function sendToHub(player: Player, reason: string)
	ctxData.Services.ZoneService.PlaceAtHub(player)
	ctxData.Services.TimeService.Protect(player, 2)
	ctxData.Remotes.Get("TS_Feedback"):FireClient(player, {
		text = "Returned to sanctuary (" .. reason .. ")",
		kind = "warn",
	})
end

local function checkLoop()
	local cfg = ctxData.Config.Social.AntiCheat
	while started do
		task.wait(cfg.SpeedCheckSeconds)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid then
				if root.Position.Y < cfg.FallYLimit then
					sendToHub(player, "fell out of world")
					ctxData.Services.RateLimiter.Suspect(player, "movement")
				elseif root.Position.Magnitude > cfg.MaxOutOfBoundsStuds then
					sendToHub(player, "left the play area")
					ctxData.Services.RateLimiter.Suspect(player, "movement")
				else
					local allowed = ctxData.Services.CharacterService.GetMaxSpeed(player) + cfg.MaxSpeedSlack
					if humanoid.WalkSpeed > allowed + 0.5 then
						ctxData.Services.RateLimiter.Suspect(player, "movement")
						ctxData.Services.CharacterService.ApplyStats(player)
					end
					if horizontalSpeed(root) > allowed * 3 then
						ctxData.Services.RateLimiter.Suspect(player, "movement")
					end
				end

				local level = ctxData.Services.RateLimiter.SuspectLevel(player, "movement")
				if level >= cfg.SuspectKickLevel then
					player:Kick("Anticheat: movement anomaly")
				end
			end
		end
	end
end

function AntiCheatService.Start(ctx)
	ctxData = ctx
	if not started then
		started = true
		task.spawn(checkLoop)
	end
	return true
end

return AntiCheatService
