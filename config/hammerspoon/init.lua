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

local browserApps = {
  ["app.zen-browser.zen"] = "Zen Browser",
  ["com.apple.Safari"] = "Safari",
  ["com.brave.Browser"] = "Brave Browser",
  ["com.google.Chrome"] = "Google Chrome",
  ["com.microsoft.edgemac"] = "Microsoft Edge",
  ["company.thebrowser.Browser"] = "Arc",
}

local websiteInputSources = {
  {
    domains = { "bilibili.com" },
    inputSourceID = inputSources.chinese,
  },
  {
    domains = { "auctions.yahoo.co.jp" },
    inputSourceID = inputSources.japanese,
  },
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
    "app.zen-browser.zen",
    "com.apple.Safari",
    "com.brave.Browser",
    "com.google.Chrome",
    "com.microsoft.edgemac",
    "company.thebrowser.Browser",
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
local switchInputSource

local function normalizeURLHost(url)
  if not url or url == "" then
    return nil
  end

  local host = url:match("^[%w+.-]+://([^/?#]+)") or url:match("^([^/?#]+)")
  if not host then
    return nil
  end

  host = host:lower():gsub(":.*$", ""):gsub("^www%.", "")
  if host == "" or host == "about:blank" then
    return nil
  end

  return host
end

local function hostMatchesDomain(host, domain)
  return host == domain or host:sub(-(domain:len() + 1)) == "." .. domain
end

local function inputSourceForURL(url)
  local host = normalizeURLHost(url)
  if not host then
    return nil
  end

  for _, rule in ipairs(websiteInputSources) do
    for _, domain in ipairs(rule.domains) do
      if hostMatchesDomain(host, domain) then
        return rule.inputSourceID, host
      end
    end
  end

  return inputSources.abc, host
end

local function runAppleScript(script)
  local ok, result = hs.osascript.applescript(script)
  if ok and result and result ~= "" then
    return result
  end

  return nil
end

local function frontmostBrowserURL(appName)
  if appName == "Safari" then
    return runAppleScript([[
      tell application "Safari"
        if not (exists front window) then return ""
        return URL of current tab of front window
      end tell
    ]])
  end

  return runAppleScript(string.format([[
    tell application "%s"
      if not (exists front window) then return ""
      return URL of active tab of front window
    end tell
  ]], appName))
end

local function syncInputSourceForBrowser(app)
  local bundleID = app and app:bundleID()
  local appName = bundleID and browserApps[bundleID]
  if not appName then
    return false
  end

  local url = frontmostBrowserURL(appName)
  local inputSourceID, host = inputSourceForURL(url)
  if not inputSourceID then
    inputSourceID = inputSources.abc
  end

  if hs.keycodes.currentSourceID() == inputSourceID then
    return true
  end

  log.i(string.format("browser %s host %s -> %s", bundleID, host or "<unknown>", inputSourceID))
  switchInputSource(inputSourceID)
  return true
end

switchInputSource = function(inputSourceID)
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
  if syncInputSourceForBrowser(app) then
    return
  end

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

if state.browserURLTimer then
  state.browserURLTimer:stop()
  state.browserURLTimer = nil
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

state.browserURLTimer = hs.timer.doEvery(1, function()
  syncInputSourceForBrowser(hs.application.frontmostApplication())
end)

log.i("input source watcher started")

syncInputSourceForWindow(hs.window.focusedWindow())
syncInputSourceForApp(hs.application.frontmostApplication())

hs.alert.show("Input source watcher loaded")
