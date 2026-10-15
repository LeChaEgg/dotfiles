#!/bin/bash
set -euo pipefail

domain="com.tinycast.app"

write_bool() {
  defaults write "$domain" "$1" -bool "$2"
}

write_int() {
  defaults write "$domain" "$1" -int "$2"
}

write_string() {
  defaults write "$domain" "$1" -string "$2"
}

# Portable settings and shortcuts only. Do not add AI connection data here.
defaults write "$domain" boundAppBundleIDs -array \
  "com.apple.Safari" \
  "net.ankiweb.launcher" \
  "dev.zed.Zed" \
  "com.tencent.xinWeChat" \
  "com.apple.mail" \
  "com.larksuite.larkApp" \
  "com.liguangming.Shadowrocket" \
  "com.openai.codex" \
  "com.carriez.rustdesk" \
  "com.apple.finder" \
  "com.apple.systempreferences" \
  "com.apple.iCal" \
  "com.apple.Passwords" \
  "com.google.Chrome" \
  "com.apple.Terminal" \
  "com.apple.ScreenContinuity" \
  "com.todesktop.230313mzl4w4u92" \
  "com.anthropic.claudefordesktop" \
  "com.apple.Notes"

write_bool calendarEnabled true
write_int calendarMenuBarDisplay 0
write_bool compactMode true
write_string emojiSkinTone mediumDark
write_bool extensionsEnabled true
write_bool hyperKeyIncludesShift true
write_int popToRootTimeout 90
write_bool quicklinksEnabled true
write_bool showFavoritesInCompactMode true
write_bool showInMenuBar false
write_bool windowManagementEnabled true

write_string 'hotkey.app.com.anthropic.claudefordesktop' '{"combo":{"_0":{"carbonModifiers":6400,"carbonKeyCode":44}}}'
write_string 'hotkey.app.com.apple.Notes' '{"combo":{"_0":{"carbonKeyCode":45,"carbonModifiers":6400}}}'
write_string 'hotkey.app.com.apple.Passwords' '{"combo":{"_0":{"carbonKeyCode":35,"carbonModifiers":6400}}}'
write_string 'hotkey.app.com.apple.Safari' '{"combo":{"_0":{"carbonKeyCode":1,"carbonModifiers":6400}}}'
write_string 'hotkey.app.com.apple.ScreenContinuity' '{"combo":{"_0":{"carbonKeyCode":34,"carbonModifiers":6400}}}'
write_string 'hotkey.app.com.apple.Terminal' '{"combo":{"_0":{"carbonKeyCode":17,"carbonModifiers":6400}}}'
write_string 'hotkey.app.com.apple.finder' '{"combo":{"_0":{"carbonKeyCode":3,"carbonModifiers":6400}}}'
write_string 'hotkey.app.com.apple.iCal' '{"combo":{"_0":{"carbonKeyCode":8,"carbonModifiers":6400}}}'
write_string 'hotkey.app.com.apple.mail' '{"combo":{"_0":{"carbonKeyCode":46,"carbonModifiers":6400}}}'
write_string 'hotkey.app.com.apple.systempreferences' '{"combo":{"_0":{"carbonKeyCode":99,"carbonModifiers":0}}}'
write_string 'hotkey.app.com.carriez.rustdesk' '{"combo":{"_0":{"carbonKeyCode":15,"carbonModifiers":6400}}}'
write_string 'hotkey.app.com.google.Chrome' '{"combo":{"_0":{"carbonKeyCode":5,"carbonModifiers":6400}}}'
write_string 'hotkey.app.com.larksuite.larkApp' '{"combo":{"_0":{"carbonKeyCode":37,"carbonModifiers":6400}}}'
write_string 'hotkey.app.com.liguangming.Shadowrocket' '{"combo":{"_0":{"carbonKeyCode":9,"carbonModifiers":6400}}}'
write_string 'hotkey.app.com.openai.codex' '{"combo":{"_0":{"carbonKeyCode":47,"carbonModifiers":6400}}}'
write_string 'hotkey.app.com.tencent.xinWeChat' '{"combo":{"_0":{"carbonKeyCode":43,"carbonModifiers":6400}}}'
write_string 'hotkey.app.com.todesktop.230313mzl4w4u92' '{"combo":{"_0":{"carbonModifiers":6400,"carbonKeyCode":39}}}'
write_string 'hotkey.app.dev.zed.Zed' '{"combo":{"_0":{"carbonKeyCode":6,"carbonModifiers":6400}}}'
write_string 'hotkey.app.net.ankiweb.launcher' '{"combo":{"_0":{"carbonKeyCode":0,"carbonModifiers":6400}}}'
write_string 'hotkey.command:ai-chat' '{"doubleTap":{"_0":"shift"}}'
write_string 'hotkey.command:clipboard-history' '{"combo":{"_0":{"carbonKeyCode":4,"carbonModifiers":6400}}}'
write_string 'hotkey.systemAction.sleep-displays' '{"combo":{"_0":{"carbonKeyCode":97,"carbonModifiers":0}}}'
write_string 'hotkey.togglePalette' '{"doubleTap":{"_0":"command"}}'
write_string 'hotkey.windowCommand.bottom-left-quarter' '{"combo":{"_0":{"carbonModifiers":6400,"carbonKeyCode":20}}}'
write_string 'hotkey.windowCommand.bottom-right-quarter' '{"combo":{"_0":{"carbonKeyCode":21,"carbonModifiers":6400}}}'
write_string 'hotkey.windowCommand.left-half' '{"combo":{"_0":{"carbonModifiers":6400,"carbonKeyCode":123}}}'
write_string 'hotkey.windowCommand.maximize' '{"combo":{"_0":{"carbonModifiers":6400,"carbonKeyCode":125}}}'
write_string 'hotkey.windowCommand.next-display' '{"combo":{"_0":{"carbonKeyCode":126,"carbonModifiers":6400}}}'
write_string 'hotkey.windowCommand.right-half' '{"combo":{"_0":{"carbonKeyCode":124,"carbonModifiers":6400}}}'
write_string 'hotkey.windowCommand.top-left-quarter' '{"combo":{"_0":{"carbonKeyCode":18,"carbonModifiers":6400}}}'
write_string 'hotkey.windowCommand.top-right-quarter' '{"combo":{"_0":{"carbonModifiers":6400,"carbonKeyCode":19}}}'
