#!/bin/bash

# Find the first unused workspace number from 1 upwards
NEXT_WS=$(swaymsg -t get_workspaces | jq -e '
  [.[] | .num] as $active |
  [range(1; 100)] |
  map(select(. as $n | $active | index($n) | not)) |
  first
')

# Default to workspace 1 if something went wrong
NEXT_WS=${NEXT_WS:-1}

# Switch to that workspace
swaymsg "workspace number $NEXT_WS"

# Launch the application
exec "$@"
