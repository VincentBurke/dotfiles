#!/bin/sh
set -eu

YABAI="/opt/homebrew/bin/yabai"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Apps that should never be auto-maximized
EXCLUDED_APPS="
Raycast
"

# Focused window info
WIN_JSON="$("$YABAI" -m query --windows --window 2>/dev/null || true)"
[ -n "$WIN_JSON" ] || exit 0

# Extract "app" without jq (macOS ships python3; this avoids extra deps)
APP="$(printf '%s' "$WIN_JSON" | /usr/bin/python3 -c 'import sys,json; print(json.load(sys.stdin).get("app",""))')"
TITLE="$(printf '%s' "$WIN_JSON" | /usr/bin/python3 -c 'import sys,json; print(json.load(sys.stdin).get("title",""))')"

# Skip excluded apps (exact match)
printf '%s\n' "$EXCLUDED_APPS" | /usr/bin/grep -Fxq "$APP" && exit 0

# Optional: skip if it's a popup/utility style window (uncomment if useful)
# SUBROLE="$(printf '%s' "$WIN_JSON" | /usr/bin/python3 -c 'import sys,json; print(json.load(sys.stdin).get("subrole",""))')"
# case "$SUBROLE" in
#   AXSystemDialog|AXDialog|AXFloatingWindow|AXUnknown) exit 0 ;;
# esac

# Maximize the currently focused window
"$YABAI" -m window --grid 1:1:0:0:1:1 >/dev/null 2>&1
exit 0
