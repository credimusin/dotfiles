#!/bin/bash

# Path to the default wallpaper and blurred output
wallpaper="/home/bmo/Pictures/botanica.jpg"
blurred="/tmp/screen_locked_blur.png"

# 1. Switch keyboard layout to English (us - index 0)
swaymsg input type:keyboard xkb_switch_layout 0

# 2. Create a beautiful blurred background using the static wallpaper
# Stronger blur (scale to 5%, blur 3px, scale back to 2000%)
convert "$wallpaper" \
    -scale 5% -blur 0x3 -scale 2000% \
    "$blurred"

# 4. Lock screen using swaylock with Catppuccin Macchiato colors
# Styled as a tiny, elegant minimalist ring (--indicator-radius 25, thickness 4)
# You can replace the indicator flags with --no-unlock-indicator to hide it completely
swaylock -i "$blurred" \
    -f \
    --indicator-radius 25 \
    --indicator-thickness 4 \
    --inside-color 24273aee \
    --inside-ver-color 8aadf4ee \
    --inside-wrong-color ed8796ee \
    --inside-clear-color a6da95ee \
    --key-hl-color 8aadf4 \
    --ring-color 494d64 \
    --ring-ver-color 8aadf4 \
    --ring-wrong-color ed8796 \
    --ring-clear-color a6da95 \
    --line-uses-ring \
    --text-color 00000000 \
    --text-ver-color 00000000 \
    --text-wrong-color 00000000 \
    --text-clear-color 00000000 \
    --font "Cantarell" \
    --font-size 12 \
    --ignore-empty-password \
    --show-failed-attempts \
    --hide-keyboard-layout

# 5. Clean up temporary blurred file
rm "$blurred"
