#!/bin/bash
# Status script for System details (Battery, CPU, RAM, Network, VPN)

# 1. Battery
if [ -d /sys/class/power_supply/BAT0 ]; then
    BAT_CAP=$(cat /sys/class/power_supply/BAT0/capacity)
    BAT_STAT=$(cat /sys/class/power_supply/BAT0/status)
    if [ "$BAT_STAT" = "Charging" ]; then
        BAT_ICON=""
    else
        BAT_ICON=""
    fi
    BAT_STR="${BAT_ICON}  Battery: ${BAT_CAP}%"
else
    BAT_STR="  Battery: No battery"
fi

# 2. CPU load (1 min average)
CPU_LOAD=$(cat /proc/loadavg | awk '{print $1}')
CPU_STR="  CPU (1m): ${CPU_LOAD}"

# 3. RAM usage (Using ultra-compatible  microchip icon)
RAM_STR=$(free -m | awk '/Mem:/ {printf "  RAM: %d%% (%d MB / %d MB)", $3*100/$2, $3, $2}')

# 4. Network and VPN status
DEFAULT_ROUTE=$(ip route show default)
VPN_ACTIVE="  VPN: Disconnected"
NET_INTERFACE="  Network: Disconnected"

# Check VPN status and get geolocation if connected
if echo "$DEFAULT_ROUTE" | grep -q "tun" || pgrep -x openconnect >/dev/null; then
    VPN_LOC=$(curl -s --max-time 2 ipinfo.io/city 2>/dev/null)
    if [ -n "$VPN_LOC" ]; then
        VPN_ACTIVE="  VPN: Connected ($VPN_LOC)"
    else
        VPN_ACTIVE="  VPN: Connected"
    fi
fi

# Get Wi-Fi SSID name if connected
if echo "$DEFAULT_ROUTE" | grep -q "wlo"; then
    SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2- 2>/dev/null)
    if [ -n "$SSID" ]; then
        NET_INTERFACE="  Network: $SSID"
    else
        NET_INTERFACE="  Network: Wi-Fi"
    fi
elif echo "$DEFAULT_ROUTE" | grep -q "enp"; then
    NET_INTERFACE="  Network: Ethernet"
fi

NET_STR="${NET_INTERFACE}\n${VPN_ACTIVE}"

# Form and send notification (-r 9992 prevents duplicates, -t 10000 dismisses in 10s)
notify-send -r 9992 -t 10000 -u normal \
    "  System Status" \
    "${BAT_STR}\n${CPU_STR}\n${RAM_STR}\n${NET_STR}"
