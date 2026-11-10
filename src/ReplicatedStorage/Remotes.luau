local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local PARENT = script.Parent
-- NOTE: must not equal the module's own name, or FindFirstChild("Remotes")
-- can return this ModuleScript instead of the folder.
local FOLDER_NAME = "RemotesFolder"

local Catalog = {
	Events = {
		"TS_StealResult",
		"TS_SyncTime",
		"TS_Announcement",
		"TS_Feedback",
		"TS_VictimWarn",
		"TS_TimeUp",
		"TS_RespawnNotice",
		"TS_SyncProfile",
		"TS_CooldownSync",
		"TS_BankUpdate",
		"TS_DailyUpdate",
		"TS_LeaderboardUpdate",
		"TS_GangUpdate",
		"TS_TradeUpdate",
		"TS_EventUpdate",
		"TS_TutorialUpdate",
		"TS_AbilityState",
	},
	UnreliableEvents = {
		"TS_StealRequest",
		"TS_TeleportRequest",
		"TS_BankDeposit",
		"TS_BankWithdraw",
		"TS_DashRequest",
		"TS_StealthRequest",
	},
	Functions = {
		"TS_PurchaseRequest",
		"TS_ClaimDaily",
		"TS_ClaimOffline",
		"TS_PrestigeRequest",
		"TS_GangAction",
		"TS_TradeAction",
		"TS_SettingsAction",
		"TS_LeaderboardRequest",
		"TS_TutorialAction",
		"TS_ProfileRequest",
	},
}

local Remotes = {
	Catalog = Catalog,
	IS_SERVER = IS_SERVER,
	FolderName = FOLDER_NAME,
}

local function resolve(remoteName: string)
	local folder = PARENT:FindFirstChild(FOLDER_NAME)
	if folder then
		local inst = folder:FindFirstChild(remoteName)
		if inst then
			return inst
		end
	end
	local waited = PARENT:WaitForChild(FOLDER_NAME, 5)
	if not waited then
		error("[TimeSanctuary] Remotes folder missing: " .. FOLDER_NAME)
	end
	local inst = waited:WaitForChild(remoteName, 5)
	if not inst then
		error("[TimeSanctuary] Remote missing: " .. remoteName)
	end
	return inst
end

if IS_SERVER then
	local folder = PARENT:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = PARENT
	end

	for _, name in Catalog.Events do
		if not folder:FindFirstChild(name) then
			local inst = Instance.new("RemoteEvent")
			inst.Name = name
			inst.Parent = folder
		end
	end
	for _, name in Catalog.UnreliableEvents do
		if not folder:FindFirstChild(name) then
			local inst = Instance.new("UnreliableRemoteEvent")
			inst.Name = name
			inst.Parent = folder
		end
	end
	for _, name in Catalog.Functions do
		if not folder:FindFirstChild(name) then
			local inst = Instance.new("RemoteFunction")
			inst.Name = name
			inst.Parent = folder
		end
	end
end

function Remotes.Get(remoteName: string)
	return resolve(remoteName)
end

return Remotes
