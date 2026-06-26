#!/bin/bash
# Helper script to simulate layout-independent keyboard shortcuts (Copy, Paste, Cut, Undo) in Sway.
# It handles terminal-specific copy/paste (Ctrl+Shift+C/V) and handles layouts safely.

action="$1"

# 1. Get the focused window's class/app_id
focused_app=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | .app_id // .window_properties.class // ""')
focused_app_lower=$(echo "$focused_app" | tr '[:upper:]' '[:lower:]')

# Check if the focused app is a terminal emulator
is_terminal=false
case "$focused_app_lower" in
    *terminal*|*alacritty*|*foot*|*kitty*|*wezterm*)
        is_terminal=true
        ;;
esac

# 2. Map action to modifiers and key (always English keysyms)
mods="ctrl"
key=""

case "$action" in
    copy)
        if [ "$is_terminal" = true ]; then mods="ctrl+shift"; fi
        key="c"
        ;;
    paste)
        if [ "$is_terminal" = true ]; then mods="ctrl+shift"; fi
        key="v"
        ;;
    cut)
        key="x"
        ;;
    undo)
        key="z"
        ;;
    *)
        echo "Usage: $0 {copy|paste|cut|undo}"
        exit 1
        ;;
esac

# 3. Get active layout index of the primary keyboard
layout_index=$(swaymsg -t get_inputs | jq -r '[.[] | select(.type == "keyboard" and .xkb_active_layout_index != null)][0].xkb_active_layout_index')

# Function to restore original layout on exit
restore_layout() {
    if [ -n "$layout_index" ] && [ "$layout_index" -ne 0 ] 2>/dev/null; then
        swaymsg input type:keyboard xkb_switch_layout "$layout_index" >/dev/null
    fi
}
# Set up trap to ensure layout is ALWAYS restored, even on error or script interruption
trap restore_layout EXIT

# 4. If active layout is not English (0), switch to English (0)
if [ -n "$layout_index" ] && [ "$layout_index" -ne 0 ] 2>/dev/null; then
    swaymsg input type:keyboard xkb_switch_layout 0 >/dev/null
fi

# 5. Simulate the keys using wtype
wtype_args=()
IFS='+' read -ra ADDR <<< "$mods"
for mod in "${ADDR[@]}"; do
    wtype_args+=("-M" "$mod")
done
wtype_args+=("-k" "$key")

wtype "${wtype_args[@]}"
