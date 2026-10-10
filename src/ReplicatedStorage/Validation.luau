local Validation = {}

local TYPES = {
	string = "string",
	number = "number",
	boolean = "boolean",
	table = "table",
}

function Validation.IsType(value, typeName: string)
	return type(value) == TYPES[typeName]
end

function Validation.IsString(value, maxLength: number?)
	if type(value) ~= "string" then
		return false
	end
	if maxLength and #value > maxLength then
		return false
	end
	return true
end

function Validation.IsFiniteNumber(value, min: number, max: number)
	if type(value) ~= "number" then
		return false
	end
	if value ~= value or value == math.huge or value == -math.huge then
		return false
	end
	if min and value < min then
		return false
	end
	if max and value > max then
		return false
	end
	return true
end

function Validation.IsNonNegativeNumber(value)
	if type(value) ~= "number" then
		return false
	end
	if value ~= value or value == math.huge or value == -math.huge then
		return false
	end
	return value >= 0
end

function Validation.IsBoolean(value)
	return type(value) == "boolean"
end

function Validation.IsScalarTable(value, maxEntries: number)
	if type(value) ~= "table" then
		return false
	end
	local count = 0
	for _ in pairs(value) do
		count += 1
		if count > maxEntries then
			return false
		end
	end
	return true
end

function Validation.NormalizeString(value: any, maxLength: number, fallback: string)
	if type(value) ~= "string" then
		return fallback
	end
	if maxLength and #value > maxLength then
		value = string.sub(value, 1, maxLength)
	end
	return value
end

function Validation.NormalizeFiniteNumber(value: any, min: number, max: number, fallback: number)
	if type(value) ~= "number" then
		return fallback
	end
	if value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return math.clamp(value, min, max)
end

return Validation