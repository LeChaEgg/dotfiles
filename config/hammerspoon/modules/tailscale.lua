local M = {}

local function isFile(path)
	local attributes = path and hs.fs.attributes(path)
	return attributes and attributes.mode == "file"
end

local function resolveBinary(config)
	local candidates = {
		config.binary,
		"/opt/homebrew/bin/tailscale",
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
		work = hs.settings.get("dotfiles.tailscale.lastWorkSwitchDate"),
		personal = hs.settings.get("dotfiles.tailscale.lastPersonalSwitchDate"),
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
			settingKey = "dotfiles.tailscale.lastPersonalSwitchDate"
		elseif now.hour >= workHour then
			targetAccount = config.work_account
			switchKey = "work"
			settingKey = "dotfiles.tailscale.lastWorkSwitchDate"
		else
			return
		end

		local dateKey = os.date("%Y-%m-%d")
		if state.lastSwitchDates[switchKey] == dateKey or state.task then
			return
		end

		local task
		task = hs.task.new(binary, function(exitCode, stdout, stderr)
			if state.task ~= task then
				return
			end
			state.task = nil
			if exitCode == 0 then
				state.lastSwitchDates[switchKey] = dateKey
				hs.settings.set(settingKey, dateKey)
				log.i(string.format("Switched to %s", targetAccount))
			else
				log.e(string.format(
					"Switch to %s failed (exit=%d, stdout=%s, stderr=%s)",
					targetAccount,
					exitCode,
					stdout or "",
					stderr or ""
				))
				hs.alert.show("Tailscale account switch failed")
			end
		end, { "switch", targetAccount })

		if not task then
			log.e("Failed to create Tailscale switch task")
			return
		end
		state.task = task
		if not task:start() then
			state.task = nil
			log.e("Failed to start Tailscale switch task")
		end
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
