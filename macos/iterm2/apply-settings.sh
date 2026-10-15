#!/bin/bash
#
# Merges the tracked, portable iTerm2 preferences (profile, colors, font,
# key bindings, pointer actions, UI behaviour) into the live preferences.
# AI settings, window frames, update state and other machine-local keys are
# not tracked, so they are left as they are.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
domain="${ITERM2_DOMAIN:-com.googlecode.iterm2}"
tracked="$HERE/preferences.plist"

if [ ! -f "$tracked" ]; then
  echo "Missing $tracked" >&2
  exit 1
fi

python3 -I - "$domain" "$tracked" << 'PY'
import os
import plistlib
import subprocess
import sys

domain, tracked_path = sys.argv[1], sys.argv[2]

try:
    current = plistlib.loads(subprocess.check_output(["defaults", "export", domain, "-"], stderr=subprocess.DEVNULL))
except subprocess.CalledProcessError:
    current = {}

with open(tracked_path, "rb") as handle:
    tracked = plistlib.load(handle)

for profile in tracked.get("New Bookmarks", []):
    if profile.get("Working Directory") == "~":
        profile["Working Directory"] = os.path.expanduser("~")

current.update(tracked)
subprocess.run(["defaults", "import", domain, "-"], input=plistlib.dumps(current), check=True)
PY
