local applicationWatcher = require("hs.application.watcher")
require("hs.ipc")
local log = hs.logger.new("input-source", "info")

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

local activeTasks = {}
local lastInputSourceID = nil

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

  if lastInputSourceID == inputSourceID then
    log.i(string.format("skip switch, already on %s", inputSourceID))
    return
  end

  local task
  task = hs.task.new(macismBin, function(exitCode, stdOut, stdErr)
    activeTasks[task] = nil

    if exitCode == 0 then
      lastInputSourceID = inputSourceID
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

  activeTasks[task] = true
  if not task:start() then
    activeTasks[task] = nil
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

local watcher = applicationWatcher.new(function(_, eventType, app)
  if eventType ~= applicationWatcher.activated then
    return
  end

  syncInputSourceForApp(app)
end)

watcher:start()
log.i("input source watcher started")

syncInputSourceForApp(hs.application.frontmostApplication())

hs.alert.show("Input source watcher loaded")
