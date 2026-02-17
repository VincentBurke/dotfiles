#!/usr/bin/env bash

# The direction to focus (e.g., "south", "north") is passed as the first argument.
DIRECTION=$1
STATE_FILE="/tmp/yabai_last_focus_direction.txt"

# Read the last direction that was focused.
LAST_DIRECTION=$(cat "$STATE_FILE" 2>/dev/null)

# If the new direction is the same as the last one, we toggle back.
if [[ "$DIRECTION" == "$LAST_DIRECTION" ]]; then
  # Focus the most recently focused window.
  yabai -m window --focus recent
  # Clear the state file so the next press is a normal focus again.
  rm "$STATE_FILE"
else
  # It's a new direction, so we do a normal focus.
  # First, save the current direction to our state file for the next keypress.
  echo "$DIRECTION" > "$STATE_FILE"
  # Then, perform the focus.
  yabai -m window --focus "$DIRECTION"
fi
