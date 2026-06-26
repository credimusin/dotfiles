#!/bin/bash

# Powermenu options in English
options="Lock screen\nSuspend\nReboot\nPower off"

# Run Rofi in dmenu mode without icons and without input/search bar
chosen=$(echo -e "$options" | rofi -dmenu -i -no-show-icons -p "Power" -theme-str 'window { width: 20%; } listview { lines: 4; } inputbar { enabled: false; }' 2>/dev/null)

case "$chosen" in
    *Lock*)
        /var/home/bmo/.local/bin/lock-screen.sh
        ;;
    *Suspend*)
        systemctl suspend
        ;;
    *Reboot*)
        systemctl reboot
        ;;
    *Power*)
        systemctl poweroff
        ;;
esac
