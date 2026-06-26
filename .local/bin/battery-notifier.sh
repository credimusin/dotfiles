#!/bin/bash

# Battery notification daemon
# Checks the battery level and status, notifying the user when it drops to 10% or lower.

THRESHOLD=10
NOTIFIED=false

# Sleep interval in seconds (1s for real-time countdown in seconds)
CHECK_INTERVAL=1

while true; do
    if [ -d /sys/class/power_supply/BAT0 ]; then
        BAT_CAP=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
        BAT_STAT=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)

        # Ensure we got valid values
        if [[ -n "$BAT_CAP" && -n "$BAT_STAT" ]]; then
            if [ "$BAT_STAT" = "Discharging" ] && [ "$BAT_CAP" -le "$THRESHOLD" ]; then
                # Direct calculation in seconds from sysfs
                E_NOW=$(cat /sys/class/power_supply/BAT0/energy_now 2>/dev/null)
                P_NOW=$(cat /sys/class/power_supply/BAT0/power_now 2>/dev/null)
                
                SECONDS_LEFT=""
                if [[ -n "$E_NOW" && -n "$P_NOW" && "$P_NOW" -gt 0 ]]; then
                    SECONDS_LEFT=$(( E_NOW * 3600 / P_NOW ))
                fi

                # Fallback to upower if sysfs calculation failed
                if [ -z "$SECONDS_LEFT" ]; then
                    U_TIME=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep "time to empty" | awk -F: '{print $2}' | xargs)
                    if [[ "$U_TIME" == *"minute"* ]]; then
                        MINS=$(echo "$U_TIME" | awk '{print $1}')
                        SECONDS_LEFT=$(echo "$MINS * 60" | bc -l | cut -d. -f1)
                    elif [[ "$U_TIME" == *"hour"* ]]; then
                        HOURS=$(echo "$U_TIME" | awk '{print $1}')
                        SECONDS_LEFT=$(echo "$HOURS * 3600" | bc -l | cut -d. -f1)
                    fi
                fi

                # Construct time string
                if [ -n "$SECONDS_LEFT" ]; then
                    TIME_STR="${SECONDS_LEFT}s"
                else
                    TIME_STR="estimating..."
                fi

                # Send or update critical notification
                notify-send -r 9990 -u critical -a "System" -i battery-caution \
                    "   Low Battery" \
                    "Battery level: ${BAT_CAP}%\nRemaining time: ${TIME_STR}"
                
                NOTIFIED=true
            elif [ "$NOTIFIED" = true ]; then
                # If we were showing the low battery warning, but now it's charging or above threshold
                if [ "$BAT_STAT" = "Charging" ]; then
                    notify-send -r 9990 -u normal -a "System" -i battery-charging \
                        "   Charger Connected" \
                        "Battery is now charging."
                else
                    # Just clear/replace the critical notification with a temporary normal one
                    notify-send -r 9990 -u normal -a "System" -i battery-full \
                        "   Battery Recovered" \
                        "Battery level: ${BAT_CAP}%"
                fi
                NOTIFIED=false
            fi
        fi
    fi
    sleep "$CHECK_INTERVAL"
done
