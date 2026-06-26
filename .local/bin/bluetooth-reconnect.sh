#!/bin/bash
# Script to disconnect and reconnect Bluetooth headphones

MAC="A8:C0:92:5F:25:88" # HUAWEI FreeBuds SE 2
if [ -n "$1" ]; then
    MAC="$1"
fi

# Detect if we are inside a Toolbx container
IN_CONTAINER=false
if [ -f /run/.containerenv ] || [ -f /.dockerenv ] || [ "$HOSTNAME" = "toolbx" ] || [ -n "$container" ]; then
    IN_CONTAINER=true
fi

run_cmd() {
    if [ "$IN_CONTAINER" = true ]; then
        flatpak-spawn --host "$@"
    else
        "$@"
    fi
}

echo "Disconnecting device $MAC..."
notify-send "Bluetooth Reconnect" "Disconnecting $MAC..." -t 2000
run_cmd bluetoothctl disconnect "$MAC"

echo "Waiting for 2 seconds..."
sleep 2

echo "Connecting device $MAC..."
notify-send "Bluetooth Reconnect" "Connecting $MAC..." -t 2000
if run_cmd bluetoothctl connect "$MAC"; then
    notify-send "Bluetooth Reconnect" "Successfully reconnected!" -t 3000
else
    notify-send "Bluetooth Reconnect" "Failed to reconnect!" -t 3000
fi
