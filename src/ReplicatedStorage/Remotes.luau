local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local PARENT = script.Parent

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
	},
	UnreliableEvents = {
		"TS_StealRequest",
		"TS_TeleportRequest",
		"TS_BankDeposit",
		"TS_BankWithdraw",
	},
	Functions = {
		"TS_PurchaseRequest",
		"TS_ClaimDaily",
		"TS_ClaimOffline",
	},
}

local Remotes = {
	Catalog = Catalog,
	IS_SERVER = IS_SERVER,
}

local function resolve(remoteName: string)
	local folder = PARENT:FindFirstChild("Remotes")
	if folder then
		local inst = folder:FindFirstChild(remoteName)
		if inst then
			return inst
		end
	end
	return PARENT:WaitForChild("Remotes", 5):WaitForChild(remoteName, 5)
end

if IS_SERVER then
	local folder = PARENT:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
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