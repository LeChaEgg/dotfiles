local applicationWatcher = require("hs.application.watcher")
local windowFilter = require("hs.window.filter")
require("hs.ipc")
local log = hs.logger.new("input-source", "info")
local state = _G.inputSourceSwitcherState or {}
_G.inputSourceSwitcherState = state

local inputSources = {
  abc = "com.apple.keylayout.ABC",
  chinese = "com.apple.inputmethod.SCIM.ITABC",
  japanese = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese",
}

local macismCandidates = {
  "/opt/homebrew/bin/macism",
  "/usr/local/bin/macism",
}

local appGroups = {
  [inputSources.chinese] = {
    "com.tencent.xinWeChat",
    "com.larksuite.larkApp",
  },
  [inputSources.abc] = {
    "com.mitchellh.ghostty",
    "com.openai.chat",
    "com.openai.codex",
    "com.raycast.macos",
    "com.anthropic.claudefordesktop",
    "com.microsoft.VSCode",
    "com.apple.Terminal",
    "com.apple.finder",
    "com.apple.mail",
  },
  [inputSources.japanese] = {
    "net.ankiweb.launcher",
  },
}

local appInputSources = {}

for inputSourceID, bundleIDs in pairs(appGroups) do
  for _, bundleID in ipairs(bundleIDs) do
    appInputSources[bundleID] = inputSourceID
  end
end

state.activeTasks = state.activeTasks or {}
state.appInputSources = appInputSources

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

local function switchInputSource(inputSourceID)
  if not macismBin then
    log.e("macism not found in expected locations")
    return
  end

  local currentSourceID = hs.keycodes.currentSourceID()
  if currentSourceID == inputSourceID then
    log.i(string.format("skip switch, already on %s", inputSourceID))
    return
  end

  local task
  task = hs.task.new(macismBin, function(exitCode, stdOut, stdErr)
    state.activeTasks[task] = nil

    if exitCode == 0 then
      log.i(string.format("switched to %s", inputSourceID))
      return
    end

    log.e(string.format(
      "macism failed for %s (exit=%d, stdout=%s, stderr=%s)",
      inputSourceID,
      exitCode,
      stdOut or "",
      stdErr or ""
    ))
  end, { inputSourceID })

  if not task then
    log.e("failed to create macism task")
    return
  end

  state.activeTasks[task] = true
  if not task:start() then
    state.activeTasks[task] = nil
    log.e("failed to start macism task")
  end
end

local function syncInputSourceForApp(app)
  if not app then
    return
  end

  local bundleID = app:bundleID()
  local inputSourceID = bundleID and appInputSources[bundleID]
  if not inputSourceID then
    log.i(string.format("no mapped input source for %s", bundleID or "<nil>"))
    return
  end

  log.i(string.format("app %s -> %s", bundleID, inputSourceID))
  switchInputSource(inputSourceID)
end

local function syncInputSourceForWindow(window)
  if not window then
    return
  end

  syncInputSourceForApp(window:application())
end

if state.watcher then
  state.watcher:stop()
  state.watcher = nil
end

if state.windowFilter then
  state.windowFilter:unsubscribeAll()
  state.windowFilter = nil
end

if state.ghosttyWindowFilter then
  state.ghosttyWindowFilter:unsubscribeAll()
  state.ghosttyWindowFilter = nil
end

state.watcher = applicationWatcher.new(function(_, eventType, app)
  if eventType ~= applicationWatcher.activated then
    return
  end

  syncInputSourceForApp(app)
end)

state.watcher:start()

state.windowFilter = windowFilter.new()
state.windowFilter:subscribe(windowFilter.windowFocused, function(window)
  syncInputSourceForWindow(window)
end)

state.ghosttyWindowFilter = windowFilter
  .new(false)
  :setAppFilter("Ghostty", {
    visible = true,
    allowRoles = "*",
  })

state.ghosttyWindowFilter:subscribe({
  windowFilter.windowCreated,
  windowFilter.windowFocused,
  windowFilter.windowVisible,
}, function(window)
  syncInputSourceForWindow(window)
end)

log.i("input source watcher started")

syncInputSourceForWindow(hs.window.focusedWindow())
syncInputSourceForApp(hs.application.frontmostApplication())

hs.alert.show("Input source watcher loaded")
