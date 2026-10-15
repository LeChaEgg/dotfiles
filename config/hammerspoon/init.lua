require("hs.ipc")

local log = hs.logger.new("dotfiles", "info")

local function loadLocalConfig()
	local configPath = hs.configdir .. "/config.lua"
	if not hs.fs.attributes(configPath) then
		log.i("No local Hammerspoon config; device-specific automations are disabled")
		return {}
	end

	local ok, config = pcall(dofile, configPath)
	if not ok then
		log.e("Failed to load " .. configPath .. ": " .. tostring(config))
		return {}
	end
	if type(config) ~= "table" then
		log.e("Expected " .. configPath .. " to return a table")
		return {}
	end
	return config
end

local function startModule(name, settings)
	local ok, err = pcall(function()
		require(name).start(settings or {})
	end)
	if not ok then
		log.e(string.format("Failed to start %s: %s", name, tostring(err)))
	end
end

local config = loadLocalConfig()

startModule("modules.wifi", config.wifi)
startModule("modules.tailscale", config.tailscale)
startModule("modules.input_source", config.input_source)

hs.alert.show("Dotfiles Hammerspoon loaded")
