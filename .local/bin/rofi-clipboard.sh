#!/bin/bash
CLIP_HISTORY="/var/home/bmo/.cache/rofi-clipboard-history.txt"

if [ "$#" -gt 0 ]; then
    query="$*"
    
    # If the user selects the clear history button
    if [ "$query" = "Clear " ]; then
        > "$CLIP_HISTORY"
        notify-send -t 1500 "Clipboard" "History cleared"
        exit 0
    fi
    
    # User selected a line from history
    echo -n "$query" | wl-copy
    notify-send -t 1500 "Clipboard" "Copied to clipboard"
    exit 0
else
    if [ -f "$CLIP_HISTORY" ] && [ -s "$CLIP_HISTORY" ]; then
        echo "Clear "
        cat "$CLIP_HISTORY"
    else
        echo "Clipboard history is empty"
    fi
fi
