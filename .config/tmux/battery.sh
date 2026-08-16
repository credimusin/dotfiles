#!/bin/sh
status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)

if [ -z "$capacity" ]; then
    exit 0
fi

if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
    echo "󰂄 $capacity%"
else
    echo "󰁹 $capacity%"
fi
