local M = {}

function M.start(config)
	local log = hs.logger.new("wifi-config", "info")
	if config.enabled ~= true then
		log.i("Wi-Fi configuration is disabled")
		return
	end

	local required = { "service", "ssid", "ip", "mask", "router", "dns" }
	for _, key in ipairs(required) do
		if type(config[key]) ~= "string" or config[key] == "" then
			log.e("Missing Wi-Fi config value: " .. key)
			return
		end
	end

	local state = _G.dotfilesWifiState or {}
	_G.dotfilesWifiState = state

	local function stopPrevious()
		if state.watcher then
			state.watcher:stop()
			state.watcher = nil
		end
		if state.syncTimer then
			state.syncTimer:stop()
			state.syncTimer = nil
		end
		if state.task then
			state.task:terminate()
			state.task = nil
		end
	end

	local function networksetupTask(arguments, callback)
		local executable
		local taskArguments
		if config.sudo == false then
			executable = "/usr/sbin/networksetup"
			taskArguments = arguments
		else
			executable = "/usr/bin/sudo"
			taskArguments = { "-n", "/usr/sbin/networksetup", table.unpack(arguments) }
		end
		return hs.task.new(executable, callback, taskArguments)
	end

	local scheduleSync
	local function configure(mode)
		local commands
		if mode == "manual" then
			commands = {
				{ "-setmanual", config.service, config.ip, config.mask, config.router },
				{ "-setdnsservers", config.service, config.dns },
			}
		else
			commands = {
				{ "-setdhcp", config.service },
				{ "-setdnsservers", config.service, "Empty" },
			}
		end

		local function runCommand(index)
			if index > #commands then
				state.task = nil
				local ssid = hs.wifi.currentNetwork()
				local currentMode = ssid and (ssid == config.ssid and "manual" or "dhcp")
				if currentMode and currentMode ~= mode then
					state.appliedMode = nil
					configure(currentMode)
					return
				end

				state.appliedMode = currentMode and mode or nil
				log.i(string.format("Wi-Fi %s configuration applied", mode))
				if state.requestedMode and state.requestedMode ~= mode then
					local nextMode = state.requestedMode
					state.requestedMode = nil
					configure(nextMode)
				end
				return
			end

			local task
			task = networksetupTask(commands[index], function(exitCode, stdout, stderr)
				if state.task ~= task then
					return
				end
				if exitCode ~= 0 then
					state.task = nil
					hs.alert.show("Wi-Fi configuration failed")
					log.e(string.format(
						"networksetup failed (exit=%d, stdout=%s, stderr=%s)",
						exitCode,
						stdout or "",
						stderr or ""
					))
					return
				end
				runCommand(index + 1)
			end)

			if not task then
				log.e("Failed to create networksetup task")
				return
			end
			state.task = task
			if not task:start() then
				state.task = nil
				log.e("Failed to start networksetup task")
			end
		end

		runCommand(1)
	end

	local function sync()
		local ssid = hs.wifi.currentNetwork()
		if not ssid then
			state.requestedMode = nil
			state.retryCount = (state.retryCount or 0) + 1
			if state.retryCount <= 5 then
				log.i(string.format("Wi-Fi SSID is not ready; retrying (%d/5)", state.retryCount))
				scheduleSync(1)
			else
				state.retryCount = 0
				log.i("Wi-Fi is not associated; leaving its configuration unchanged")
			end
			return
		end

		state.retryCount = 0
		local mode = ssid == config.ssid and "manual" or "dhcp"
		state.requestedMode = mode
		if state.task or state.appliedMode == mode then
			return
		end
		state.requestedMode = nil
		configure(mode)
	end

	scheduleSync = function(delay)
		if state.syncTimer then
			state.syncTimer:stop()
		end
		state.syncTimer = hs.timer.doAfter(delay or 0.5, function()
			state.syncTimer = nil
			sync()
		end)
	end

	local authorization = hs.location.authorizationStatus()
	if authorization == "undefined" then
		hs.location.start()
		authorization = hs.location.authorizationStatus()
	end
	log.i("Location Services authorization: " .. tostring(authorization))

	stopPrevious()
	state.appliedMode = nil
	state.watcher = hs.wifi.watcher.new(function()
		scheduleSync()
	end)
	state.watcher:start()
	log.i("Wi-Fi configuration watcher started")
	scheduleSync()
end

return M
