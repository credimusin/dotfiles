#!/bin/bash
EMOJI_FILE="/var/home/bmo/.config/rofi/emojis.txt"

if [ "$#" -gt 0 ]; then
    # The user selected an emoji line (e.g. "😀  grinning face")
    # Extract the emoji character (first field)
    emoji=$(echo "$*" | awk '{print $1}')
    echo -n "$emoji" | wl-copy
    notify-send -t 1500 "Emoji" "Copied: $emoji"
    exit 0
else
    cat "$EMOJI_FILE"
fi
