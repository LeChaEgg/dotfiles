#!/bin/bash
#
# Restores portable macOS system preferences.
#
# Usage:
#   macos/system/defaults.sh            apply
#   DRY_RUN=1 macos/system/defaults.sh  print what would be written
#
# Only user-level preferences are written here, except for the few steps that
# need sudo (Touch ID for sudo, power management). Those are skipped if sudo is
# not available non-interactively and sudo was not cached by the caller.
#
# Machine-specific state (Dock app list, wallpaper, display layout, Control
# Center item positions, accounts) is deliberately excluded.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="${DRY_RUN:-0}"

run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '  [dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

d() { run defaults "$@"; }

have_sudo() {
  [ "$DRY_RUN" = "1" ] && return 0
  sudo -n true 2> /dev/null
}

# --- Appearance / language / text input -------------------------------------
d write NSGlobalDomain AppleInterfaceStyle -string Dark
d write NSGlobalDomain AppleLanguages -array en-JP zh-Hans-JP ja-JP
d write NSGlobalDomain AppleLocale -string en_JP
d write NSGlobalDomain AppleShowAllExtensions -bool true
d write NSGlobalDomain AppleMiniaturizeOnDoubleClick -bool false
d write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool false
d write NSGlobalDomain NSTableViewDefaultSizeMode -int 2
d write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
d write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
d write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
d write NSGlobalDomain WebAutomaticSpellingCorrectionEnabled -bool false
d write NSGlobalDomain com.apple.keyboard.fnState -bool false
d write NSGlobalDomain NSUserDictionaryReplacementItems -array \
  '<dict><key>on</key><integer>1</integer><key>replace</key><string>omw</string><key>with</key><string>On my way!</string></dict>' \
  '<dict><key>on</key><integer>1</integer><key>replace</key><string>msd</string><key>with</key><string>马上到！</string></dict>'

# Input sources: ABC, Pinyin (Simplified), Japanese Romaji. Takes effect after
# the next log out / log in.
d write com.apple.HIToolbox AppleFnUsageType -int 3
d write com.apple.HIToolbox AppleCapsLockPressAndHoldToggleOff -bool false
d write com.apple.HIToolbox AppleEnabledInputSources -array \
  '<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>252</integer><key>KeyboardLayout Name</key><string>ABC</string></dict>' \
  '<dict><key>Bundle ID</key><string>com.apple.inputmethod.SCIM</string><key>Input Mode</key><string>com.apple.inputmethod.SCIM.ITABC</string><key>InputSourceKind</key><string>Input Mode</string></dict>' \
  '<dict><key>Bundle ID</key><string>com.apple.inputmethod.SCIM</string><key>InputSourceKind</key><string>Keyboard Input Method</string></dict>' \
  '<dict><key>Bundle ID</key><string>com.apple.CharacterPaletteIM</string><key>InputSourceKind</key><string>Non Keyboard Input Method</string></dict>' \
  '<dict><key>Bundle ID</key><string>com.apple.PressAndHold</string><key>InputSourceKind</key><string>Non Keyboard Input Method</string></dict>' \
  '<dict><key>Bundle ID</key><string>com.apple.inputmethod.ironwood</string><key>InputSourceKind</key><string>Non Keyboard Input Method</string></dict>' \
  '<dict><key>Bundle ID</key><string>com.apple.inputmethod.Kotoeri.RomajiTyping</string><key>Input Mode</key><string>com.apple.inputmethod.Japanese</string><key>InputSourceKind</key><string>Input Mode</string></dict>' \
  '<dict><key>Bundle ID</key><string>com.apple.inputmethod.Kotoeri.RomajiTyping</string><key>InputSourceKind</key><string>Keyboard Input Method</string></dict>' \
  '<dict><key>Bundle ID</key><string>com.apple.50onPaletteIM</string><key>InputSourceKind</key><string>Non Keyboard Input Method</string></dict>'

# --- Trackpad / mouse ---------------------------------------------------------
trackpad_domains=(com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad)
for domain in "${trackpad_domains[@]}"; do
  d write "$domain" Clicking -bool true
  d write "$domain" Dragging -bool false
  d write "$domain" DragLock -bool false
  d write "$domain" TrackpadThreeFingerDrag -bool true
  d write "$domain" TrackpadRightClick -bool true
  d write "$domain" TrackpadCornerSecondaryClick -int 0
  d write "$domain" TrackpadHandResting -bool true
  d write "$domain" TrackpadHorizScroll -bool true
  d write "$domain" TrackpadMomentumScroll -bool true
  d write "$domain" TrackpadPinch -bool true
  d write "$domain" TrackpadRotate -bool true
  d write "$domain" TrackpadScroll -bool true
  d write "$domain" TrackpadTwoFingerDoubleTapGesture -int 1
  d write "$domain" TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3
  d write "$domain" TrackpadThreeFingerHorizSwipeGesture -int 0
  d write "$domain" TrackpadThreeFingerVertSwipeGesture -int 0
  d write "$domain" TrackpadThreeFingerTapGesture -int 2
  d write "$domain" TrackpadFourFingerHorizSwipeGesture -int 2
  d write "$domain" TrackpadFourFingerVertSwipeGesture -int 2
  d write "$domain" TrackpadFourFingerPinchGesture -int 2
  d write "$domain" TrackpadFiveFingerPinchGesture -int 2
done
d write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1
d write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 1
d write com.apple.AppleMultitouchTrackpad ActuateDetents -int 1
d write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
d -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
d write com.apple.AppleMultitouchMouse MouseButtonMode -string OneButton
d write com.apple.AppleMultitouchMouse MouseVerticalScroll -bool true
d write com.apple.AppleMultitouchMouse MouseHorizontalScroll -bool true
d write com.apple.AppleMultitouchMouse MouseMomentumScroll -bool true

# --- Dock / windows / Mission Control ---------------------------------------
d write com.apple.dock autohide -bool true
d write com.apple.dock tilesize -int 46
d write com.apple.dock largesize -int 16
d write com.apple.dock magnification -bool false
d write com.apple.dock minimize-to-application -bool true
d write com.apple.dock wvous-br-corner -int 1
d write com.apple.WindowManager AppWindowGroupingBehavior -int 1
d write com.apple.WindowManager EnableTiledWindowMargins -bool false
d write com.apple.WindowManager HideDesktop -bool true

# --- Finder -------------------------------------------------------------------
d write com.apple.finder ShowPathbar -bool true
d write com.apple.finder ShowStatusBar -bool true
d write com.apple.finder FXPreferredViewStyle -string Nlsv
d write com.apple.finder FXDefaultSearchScope -string SCcf
d write com.apple.finder NewWindowTarget -string PfHm
d write com.apple.finder FXRemoveOldTrashItems -bool true
d write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
d write com.apple.finder ShowHardDrivesOnDesktop -bool true
d write com.apple.finder ShowMountedServersOnDesktop -bool true
d write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# --- Menu bar / screenshots -------------------------------------------------
d write com.apple.menuextra.clock ShowAMPM -bool true
d write com.apple.menuextra.clock ShowDayOfWeek -bool true
d write com.apple.menuextra.clock ShowDate -int 0
d write com.apple.menuextra.clock IsAnalog -bool false
d write com.apple.menuextra.clock ShowSeconds -bool false
d -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
d write com.apple.screencapture target -string clipboard

# --- Keyboard shortcuts (Spotlight off, screenshot, input source, ...) ------
# The plist contains only AppleSymbolicHotKeys, so importing replaces just that.
if [ -f "$HERE/symbolichotkeys.plist" ]; then
  d import com.apple.symbolichotkeys "$HERE/symbolichotkeys.plist"
fi

# --- sudo-only settings -------------------------------------------------------
if have_sudo; then
  if ! grep -qs '^auth[[:space:]]\+sufficient[[:space:]]\+pam_tid.so' /etc/pam.d/sudo_local 2> /dev/null; then
    echo "  Enabling Touch ID for sudo"
    run sudo sh -c 'printf "auth       sufficient     pam_tid.so\n" > /etc/pam.d/sudo_local'
  fi

  # Battery: display sleep 5 min, system sleep 1 min, slightly dim on battery.
  # AC: display sleep 10 min, never system sleep, wake for network access.
  run sudo pmset -b displaysleep 5 sleep 1 lessbright 1
  run sudo pmset -c displaysleep 10 sleep 0 womp 1
else
  echo "  Skipped sudo-only settings (Touch ID for sudo, power management)."
  echo "  Re-run with: sudo -v && $0"
fi

# --- Apply -------------------------------------------------------------------
if [ "$DRY_RUN" != "1" ]; then
  /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2> /dev/null || true
  for app in Dock Finder SystemUIServer; do
    killall "$app" &> /dev/null || true
  done
fi

echo "  System preferences applied. Log out and back in for input sources and keyboard shortcuts."
