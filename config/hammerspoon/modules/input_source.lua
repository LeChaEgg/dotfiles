local applicationWatcher = require("hs.application.watcher")
local M = {}

function M.start(config)
	local log = hs.logger.new("input-source", "info")
	if config.enabled == false then
		log.i("Input source switching is disabled")
		return
	end

	local state = _G.dotfilesInputSourceState or {}
	_G.dotfilesInputSourceState = state

	local inputSources = {
		abc = "com.apple.keylayout.ABC",
		japanese = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese",
	}

	local forcedInputSources = {
		["com.apple.Terminal"] = inputSources.abc,
		["com.googlecode.iterm2"] = inputSources.abc,
		["net.ankiweb.launcher"] = inputSources.japanese,
		["net.ankiweb.anki"] = inputSources.japanese,
	}

	local macismCandidates = config.macism_candidates or {
		"/opt/homebrew/bin/macism",
	}
	local macismWaitMs = tostring(config.macism_wait_ms or 150)

	local function resolveMacism()
		for _, candidate in ipairs(macismCandidates) do
			local attributes = hs.fs.attributes(candidate)
			if attributes and attributes.mode == "file" then
				return candidate
			end
		end
		return nil
	end

	local macismBin = resolveMacism()
	state.appLastInputSources = state.appLastInputSources
		or hs.settings.get("inputSourceSwitcher.appLastInputSources")
		or {}
	state.activeTasks = state.activeTasks or {}

	local function rememberInputSource(bundleID, inputSourceID)
		if not bundleID or not inputSourceID or forcedInputSources[bundleID] then
			return
		end
		state.appLastInputSources[bundleID] = inputSourceID
		hs.settings.set("inputSourceSwitcher.appLastInputSources", state.appLastInputSources)
	end

	local function isRegularApplication(app)
		return app and app:kind() == 1
	end

	local scheduleCurrentAppSync
	local startQueuedInputSourceSwitch

	local function suppressProgrammaticInputSourceEvents()
		state.ignoreInputSourceEvents = true
		if state.programmaticSourceTimer then
			state.programmaticSourceTimer:stop()
		end
		state.programmaticSourceTimer = hs.timer.doAfter(0.75, function()
			state.ignoreInputSourceEvents = false
			state.programmaticSourceTimer = nil
		end)
	end

	local function queueInputSourceSwitch(inputSourceID)
		if not macismBin then
			log.w("macism not found; skipping input source switch")
			return
		end
		state.queuedInputSourceID = inputSourceID
		startQueuedInputSourceSwitch()
	end

	startQueuedInputSourceSwitch = function()
		if state.activeSwitchTask then
			return
		end

		local inputSourceID = state.queuedInputSourceID
		state.queuedInputSourceID = nil
		if not inputSourceID or hs.keycodes.currentSourceID() == inputSourceID then
			return
		end

		local task
		suppressProgrammaticInputSourceEvents()
		task = hs.task.new(macismBin, function(exitCode, stdout, stderr)
			if state.activeSwitchTask == task then
				state.activeSwitchTask = nil
			end
			state.activeTasks[task] = nil
			suppressProgrammaticInputSourceEvents()

			if exitCode == 0 then
				log.i("Switched to " .. inputSourceID)
			else
				log.e(string.format(
					"macism failed for %s (exit=%d, stdout=%s, stderr=%s)",
					inputSourceID,
					exitCode,
					stdout or "",
					stderr or ""
				))
			end

			startQueuedInputSourceSwitch()
			if scheduleCurrentAppSync then
				scheduleCurrentAppSync()
			end
		end, { inputSourceID, macismWaitMs })

		if not task then
			log.e("Failed to create macism task")
			return
		end

		state.activeSwitchTask = task
		state.activeTasks[task] = true
		if not task:start() then
			state.activeSwitchTask = nil
			state.activeTasks[task] = nil
			log.e("Failed to start macism task")
		end
	end

	local function syncInputSourceForApp(app)
		if not isRegularApplication(app) then
			return
		end

		local bundleID = app:bundleID()
		if not bundleID or state.lastHandledBundleID == bundleID then
			return
		end
		state.lastHandledBundleID = bundleID

		local inputSourceID = forcedInputSources[bundleID]
		if inputSourceID then
			log.i(string.format("App %s -> forced %s", bundleID, inputSourceID))
			queueInputSourceSwitch(inputSourceID)
			return
		end

		inputSourceID = state.appLastInputSources[bundleID]
		if inputSourceID then
			log.i(string.format("App %s -> remembered %s", bundleID, inputSourceID))
			queueInputSourceSwitch(inputSourceID)
		else
			rememberInputSource(bundleID, hs.keycodes.currentSourceID())
			log.i(string.format("App %s -> keeping current input source", bundleID))
		end
	end

	scheduleCurrentAppSync = function()
		suppressProgrammaticInputSourceEvents()
		if state.appActivationTimer then
			state.appActivationTimer:stop()
		end
		state.appActivationTimer = hs.timer.doAfter(0.15, function()
			state.appActivationTimer = nil
			state.lastHandledBundleID = nil
			syncInputSourceForApp(hs.application.frontmostApplication())
		end)
	end

	if state.watcher then
		state.watcher:stop()
		state.watcher = nil
	end
	if state.appActivationTimer then
		state.appActivationTimer:stop()
		state.appActivationTimer = nil
	end
	if state.programmaticSourceTimer then
		state.programmaticSourceTimer:stop()
		state.programmaticSourceTimer = nil
	end
	state.ignoreInputSourceEvents = false
	for task in pairs(state.activeTasks) do
		task:terminate()
	end
	state.activeTasks = {}
	state.activeSwitchTask = nil
	state.queuedInputSourceID = nil
	state.lastHandledBundleID = nil

	state.watcher = applicationWatcher.new(function(_, eventType, app)
		if eventType == applicationWatcher.activated and isRegularApplication(app) then
			scheduleCurrentAppSync()
		end
	end)
	state.watcher:start()

	hs.keycodes.inputSourceChanged(function()
		if state.activeSwitchTask or state.ignoreInputSourceEvents then
			return
		end
		local inputSourceID = hs.keycodes.currentSourceID()
		local app = hs.application.frontmostApplication()
		local bundleID = app and app:bundleID()
		if bundleID and not forcedInputSources[bundleID] then
			rememberInputSource(bundleID, inputSourceID)
		end
	end)

	log.i("Per-app input source watcher started")
	if macismBin then
		hs.alert.show("Input source watcher loaded")
	else
		log.w("Install macism to enable input source switching")
	end
	scheduleCurrentAppSync()
end

return M
