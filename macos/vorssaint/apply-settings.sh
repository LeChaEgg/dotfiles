#!/bin/bash
set -euo pipefail

domain="com.vorssaint.utils"

write_bool() {
  defaults write "$domain" "$1" -bool "$2"
}

write_int() {
  defaults write "$domain" "$1" -int "$2"
}

write_string() {
  defaults write "$domain" "$1" -string "$2"
}

write_string appLanguage zh-Hans
write_int batteryLimitPercent 20
write_bool brightnessControlEnabled true
write_bool brightnessKeysEnabled true
write_bool brightnessOSDEnabled true
write_bool clamshellPreferred true
write_int clipboardAutoClearDelaySeconds 20
write_bool clipboardHistoryEnabled true
write_int clipboardHistoryLimit 50
write_int clipboardHistoryMenuBarPreviewLength 20
write_bool finderCutPasteEnabled true
write_bool finderRenameEnabled true
write_string finderRenameShortcut command:15
write_string keepAwakeActiveIcon coffee
write_bool keepAwakeAllowDisplaySleep false
write_bool keepAwakeConnectedToPower false
write_string keepAwakeIconTint green
write_int keepAwakeMouseJiggleIntervalMinutes 5
write_bool launchAtLoginWanted true
write_string mediaLastTool videoCompressor
write_int mediaVideoMaxDimension 1280
write_bool menuBarCombineTemperatures true
write_string menuBarIconSymbol infinity
write_string menuBarMetricAppearance values
write_string menuBarMetricSpacing compact
write_int monitorAlertBatteryPercent 15
write_int monitorAlertBatteryTemperatureThreshold 40
write_int monitorAlertCPUTemperatureThreshold 90
write_int monitorAlertCPUThreshold 90
write_int monitorAlertCooldownMinutes 15
write_int monitorAlertDiskFreePercent 10
write_int monitorIntervalSeconds 2
write_string monitorMemoryMetric used
write_bool notchAgentsCodex true
write_bool notchAgentsCopilot false
write_bool notchAgentsEnabled true
write_int notchAgentsFinishMinimum 120
write_string notchAgentsLimitDisplay remaining
write_string notchAgentsLimitFocus weekly
write_bool notchAgentsOpenCode false
write_string notchAgentsPeriod today
write_string notchAgentsReadout limit
write_bool notchEnabled true
write_string notchHoverDelay 0.35
write_bool notchHoverExpands true
write_string notchIdleContent agents
write_string notchSize compact
write_bool pastePlainEnabled true
write_string pastePlainShortcut shift+command:9
write_bool shelfEdgeDragEnabled true
write_bool shelfEnabled true
write_int switcherIconRowMode 0
write_bool switcherMergeTabs true
write_string switcherMinimizedPlacement hidden
write_string switcherPreviewSize normal
write_bool switcherSearchPinEnabled true
write_bool switcherSimpleMode false
write_bool switcherTakeOverSystemShortcuts true
write_bool urlCleanerEnabled false
write_bool vorssDisabledSleep false
