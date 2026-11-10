local SettingsService = {}

local ctxData

function SettingsService.Start(ctx)
	ctxData = ctx
	ctxData.Remotes.Get("TS_SettingsAction").OnServerInvoke = function(player, payload)
		if type(payload) ~= "table" then
			return { ok = false, reason = "invalid" }
		end
		local profile = ctxData.Services.ProfileService.GetProfile(player)
		if not profile then
			return { ok = false, reason = "no_profile" }
		end
		local defaults = ctxData.ProfileSchema.Default().settings
		local key = payload.key
		if type(key) ~= "string" or defaults[key] == nil then
			return { ok = false, reason = "invalid_key" }
		end
		if type(payload.value) ~= "boolean" then
			return { ok = false, reason = "invalid_value" }
		end
		profile.settings[key] = payload.value
		ctxData.Services.ProfileService.SetDirty(player)
		ctxData.Services.ProfileService.Sync(player)
		return { ok = true, key = key, value = payload.value }
	end
	return true
end

return SettingsService
