local M = {}

local function isFile(path)
	local attributes = path and hs.fs.attributes(path)
	return attributes and attributes.mode == "file"
end

local function resolveBinary(config)
	if isFile(config.binary) then
		return config.binary
	end
	local candidates = {
		"/opt/homebrew/bin/tailscale",
		"/usr/local/bin/tailscale",
		"/Applications/Tailscale.app/Contents/MacOS/Tailscale",
	}
	for _, candidate in ipairs(candidates) do
		if isFile(candidate) then
			return candidate
		end
	end
	return nil
end

function M.start(config)
	local log = hs.logger.new("tailscale-switch", "info")
	if config.enabled ~= true then
		log.i("Tailscale account switching is disabled")
		return
	end
	if type(config.work_account) ~= "string" or type(config.personal_account) ~= "string" then
		log.e("Tailscale account names are not configured")
		return
	end

	local binary = resolveBinary(config)
	if not binary then
		log.w("Tailscale CLI not found; account switching is disabled")
		return
	end

	local workHour = tonumber(config.work_switch_hour) or 9
	local personalHour = tonumber(config.personal_switch_hour) or 20
	local state = _G.dotfilesTailscaleState or {}
	_G.dotfilesTailscaleState = state
	state.lastSwitchDates = state.lastSwitchDates or {
		work = hs.settings.get("dotfiles.tailscale.verifiedWorkSwitchDate"),
		personal = hs.settings.get("dotfiles.tailscale.verifiedPersonalSwitchDate"),
	}

	if state.timer then
		state.timer:stop()
	end
	if state.task then
		state.task:terminate()
		state.task = nil
	end

	local function maybeSwitch()
		local now = os.date("*t")
		local targetAccount
		local switchKey
		local settingKey
		if now.hour >= personalHour then
			targetAccount = config.personal_account
			switchKey = "personal"
			settingKey = "dotfiles.tailscale.verifiedPersonalSwitchDate"
		elseif now.hour >= workHour then
			targetAccount = config.work_account
			switchKey = "work"
			settingKey = "dotfiles.tailscale.verifiedWorkSwitchDate"
		else
			return
		end

		local dateKey = os.date("%Y-%m-%d")
		if state.lastSwitchDates[switchKey] == dateKey or state.task then
			return
		end

		local function fail(message)
			log.e(message)
			hs.alert.show("Tailscale account switch failed")
		end

		local function runTask(args, callback)
			local task
			task = hs.task.new(binary, function(exitCode, stdout, stderr)
				if state.task ~= task then
					return
				end
				state.task = nil
				callback(exitCode, stdout or "", stderr or "")
			end, args)
			if not task then
				fail("Failed to create Tailscale task")
				return
			end
			state.task = task
			if not task:start() then
				state.task = nil
				fail("Failed to start Tailscale task")
			end
		end

		runTask({ "switch", targetAccount }, function(exitCode, stdout, stderr)
			if exitCode ~= 0 then
				fail(string.format("Switch to %s failed (exit=%d, stdout=%s, stderr=%s)",
					targetAccount, exitCode, stdout, stderr))
				return
			end
			runTask({ "switch", "--list", "--json" }, function(listExit, listOutput, listError)
				local ok, profiles = pcall(hs.json.decode, listOutput)
				if listExit ~= 0 or not ok or type(profiles) ~= "table" then
					fail(string.format("Could not verify Tailscale account (exit=%d, stderr=%s)", listExit, listError))
					return
				end
				for _, profile in ipairs(profiles) do
					if profile.selected and (profile.id == targetAccount or profile.account == targetAccount
						or profile.nickname == targetAccount or profile.tailnet == targetAccount) then
						state.lastSwitchDates[switchKey] = dateKey
						hs.settings.set(settingKey, dateKey)
						log.i(string.format("Switched to and verified %s", targetAccount))
						return
					end
				end
				fail(string.format("Tailscale did not select %s", targetAccount))
			end)
		end)
	end

	state.timer = hs.timer.doEvery(60, maybeSwitch)
	log.i(string.format(
		"Daily account switch watcher started (%02d:00 -> %s, %02d:00 -> %s)",
		workHour,
		config.work_account,
		personalHour,
		config.personal_account
	))
	maybeSwitch()
end

return M
