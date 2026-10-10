local SharedLoader = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TimeSanctuary = ReplicatedStorage:WaitForChild("TimeSanctuary", 10)

if not TimeSanctuary then
	error("[TimeSanctuary] SharedLoader: ReplicatedStorage.TimeSanctuary not found")
end

function SharedLoader.Get(containerName: string, moduleName: string)
	local container = TimeSanctuary:FindFirstChild(containerName)
	if not container then
		error("[TimeSanctuary] SharedLoader: missing container " .. containerName)
	end
	local module = container:FindFirstChild(moduleName)
	if not module then
		error("[TimeSanctuary] SharedLoader: missing module " .. containerName .. "." .. moduleName)
	end
	return require(module)
end

function SharedLoader.GetRoot(moduleName: string)
	local module = TimeSanctuary:FindFirstChild(moduleName)
	if not module then
		error("[TimeSanctuary] SharedLoader: missing root module " .. moduleName)
	end
	return require(module)
end

return SharedLoader