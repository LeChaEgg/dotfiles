local applicationWatcher = require("hs.application.watcher")
require("hs.ipc")

local log = hs.logger.new("input-source", "info")
local state = _G.inputSourceSwitcherState or {}
_G.inputSourceSwitcherState = state

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

local macismCandidates = {
	"/opt/homebrew/bin/macism",
	"/usr/local/bin/macism",
}
local macismWaitMs = "150"

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
state.appLastInputSources = state.appLastInputSources or hs.settings.get("inputSourceSwitcher.appLastInputSources") or {}
state.activeTasks = state.activeTasks or {}

local function rememberInputSource(bundleID, inputSourceID)
	if not bundleID or not inputSourceID or forcedInputSources[bundleID] then
		return
	end

	state.appLastInputSources[bundleID] = inputSourceID
	hs.settings.set("inputSourceSwitcher.appLastInputSources", state.appLastInputSources)
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
		log.e("macism not found in expected locations")
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
	task = hs.task.new(macismBin, function(exitCode, stdOut, stdErr)
		if state.activeSwitchTask == task then
			state.activeSwitchTask = nil
		end
		state.activeTasks[task] = nil
		suppressProgrammaticInputSourceEvents()

		if exitCode == 0 then
			log.i(string.format("switched to %s", inputSourceID))
		else
			log.e(string.format(
				"macism failed for %s (exit=%d, stdout=%s, stderr=%s)",
				inputSourceID,
				exitCode,
				stdOut or "",
				stdErr or ""
			))
		end

		startQueuedInputSourceSwitch()
		if scheduleCurrentAppSync then
			scheduleCurrentAppSync()
		end
	end, { inputSourceID, macismWaitMs })

	if not task then
		log.e("failed to create macism task")
		return
	end

	state.activeSwitchTask = task
	state.activeTasks[task] = true
	if not task:start() then
		state.activeSwitchTask = nil
		state.activeTasks[task] = nil
		log.e("failed to start macism task")
	end
end

local function syncInputSourceForApp(app)
	if not app then
		return
	end

	local bundleID = app:bundleID()
	if not bundleID or state.lastHandledBundleID == bundleID then
		return
	end
	state.lastHandledBundleID = bundleID

	local inputSourceID = forcedInputSources[bundleID]
	if inputSourceID then
		log.i(string.format("app %s -> forced %s", bundleID, inputSourceID))
		queueInputSourceSwitch(inputSourceID)
		return
	end

	inputSourceID = state.appLastInputSources[bundleID]
	if inputSourceID then
		log.i(string.format("app %s -> remembered %s", bundleID, inputSourceID))
		queueInputSourceSwitch(inputSourceID)
	else
		rememberInputSource(bundleID, hs.keycodes.currentSourceID())
		log.i(string.format("app %s -> keeping current input source", bundleID))
	end
end

scheduleCurrentAppSync = function()
	-- macOS can change a document's input source as part of app activation.
	-- Ignore that event before it can overwrite the app's remembered source.
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

state.watcher = applicationWatcher.new(function(_, eventType, app)
	if eventType == applicationWatcher.activated then
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

log.i("per-app input source watcher started")
scheduleCurrentAppSync()
hs.alert.show("Input source watcher loaded")
