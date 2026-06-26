#!/bin/bash
HISTORY_FILE="/var/home/bmo/.cache/rofi-calc-history.txt"
LAST_FILE="/tmp/rofi-calc-last.txt"
touch "$HISTORY_FILE"

if [ "$#" -gt 0 ]; then
    query="$*"
    
    # If the user selects the prompt itself, do nothing
    if [ "$query" = "Enter expression..." ]; then
        exit 0
    fi
    
    # If the user selects the clear history button
    if [ "$query" = "Clear " ]; then
        > "$HISTORY_FILE"
        > "$LAST_FILE"
        notify-send -t 1500 "Calculator" "History cleared"
        exit 0
    fi
    
    # Read last computed result
    last_computed=""
    if [ -f "$LAST_FILE" ]; then
        last_computed=$(cat "$LAST_FILE")
    fi
    
    # If the user selects the last computed result
    if [ -n "$last_computed" ] && [ "$query" = "$last_computed" ]; then
        echo -n "$last_computed" | wl-copy
        notify-send -t 1500 "Calculator" "Copied: $last_computed"
        exit 0
    fi
    
    # If the user selects a history item (e.g. "2+2 = 4")
    if [[ "$query" == *" = "* ]]; then
        result="${query##* = }"
        echo -n "$result" | wl-copy
        notify-send -t 1500 "Calculator" "Copied: $result"
        exit 0
    fi
    
    # Process expression
    py_query=$(echo "$query" | sed 's/\^/**/g')
    res=$(python3 -c "import math; print(eval('$py_query', {'__builtins__': None, 'math': math}))" 2>/dev/null)
    
    if [ -n "$res" ]; then
        # Print the result without "=" prefix
        echo "$res"
        echo "$res" > "$LAST_FILE"
        
        # Copy to clipboard immediately upon calculation
        echo -n "$res" | wl-copy
        
        # Save to history if it's new
        last_hist=$(head -n 1 "$HISTORY_FILE" 2>/dev/null)
        if [ "$query = $res" != "$last_hist" ]; then
            echo -e "$query = $res\n$(cat "$HISTORY_FILE")" | head -n 20 > "$HISTORY_FILE.tmp"
            mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
        fi
    else
        echo "Error: Invalid expression"
    fi
else
    echo "Enter expression..."
    if [ -s "$HISTORY_FILE" ]; then
        echo "Clear "
        cat "$HISTORY_FILE"
    fi
fi
