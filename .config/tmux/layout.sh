#!/usr/bin/env bash

# Try to find SWAYSOCK if not set (often happens inside tmux or non-login shells)
if [ -z "$SWAYSOCK" ]; then
    export SWAYSOCK=$(find /run/user/$(id -u) -name "sway-ipc.*.sock" 2>/dev/null | head -n1)
fi

layout=""

# 1. Try running swaymsg directly
if command -v swaymsg >/dev/null 2>&1; then
    layout=$(swaymsg -t get_inputs -r 2>/dev/null | grep -m1 "xkb_active_layout_name" | cut -d'"' -f4)
fi

# 2. Try running swaymsg via flatpak-spawn (if inside a sandbox/flatpak container)
if [ -z "$layout" ] && command -v flatpak-spawn >/dev/null 2>&1; then
    layout=$(flatpak-spawn --host swaymsg -t get_inputs -r 2>/dev/null | grep -m1 "xkb_active_layout_name" | cut -d'"' -f4)
fi

# 3. Format and output result with tmux style tags
case "$layout" in
    *"English"*)
        # Cool ice blue color for EN
        echo -n "#[fg=color75,bold]EN#[default]"
        ;;
    *"Russian"*)
        # Warm coral red color for RU
        echo -n "#[fg=color203,bold]RU#[default]"
        ;;
    "")
        # Yellow bold indicator for unknown/failed detection
        echo -n "#[fg=yellow,bold]??#[default]"
        ;;
    *)
        # Fallback: first 2 chars in bold white
        short=$(echo "$layout" | cut -c1-2 | tr '[:lower:]' '[:upper:]')
        echo -n "#[fg=white,bold]${short}#[default]"
        ;;
esac
