#!/bin/bash
sleep 0.05


# Load a random tip/joke/kaomoji from the tips database
if [ -f "/var/home/bmo/.config/rofi/tips.txt" ]; then
    selected_tip=$(shuf -n 1 /var/home/bmo/.config/rofi/tips.txt)
else
    selected_tip="Search apps..."
fi

# Run Rofi in standard drun mode and let it launch apps directly
rofi -show drun \
    -theme-str "entry { placeholder: \"$selected_tip\"; placeholder-color: #8087a2; }" \
    2>/dev/null
