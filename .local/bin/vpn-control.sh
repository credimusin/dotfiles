#!/bin/bash
# VPN Control Script
# This script manages the OpenConnect VPN connection for user bm0.

# Load local configuration
VPN_CONFIG_FILE="$HOME/.vpn-config"
if [ -f "$VPN_CONFIG_FILE" ]; then
    source "$VPN_CONFIG_FILE"
else
    echo "Error: Configuration file $VPN_CONFIG_FILE not found." >&2
    exit 1
fi

if [ -z "${VPN_HOST:-}" ] || [ -z "${VPN_PIN:-}" ]; then
    echo "Error: VPN_HOST or VPN_PIN is not configured in $VPN_CONFIG_FILE" >&2
    exit 1
fi

# Get VPN password using pass, if pass is initialized and contains the key, otherwise prompt
export PASSWORD_STORE_DIR="$HOME/.password-store-local"
if command -v pass &>/dev/null && pass show vpn/qwesta &>/dev/null; then
    VPN_PASS=$(pass show vpn/qwesta | head -n 1)
else
    # Fallback: prompt for password if not found in pass
    read -rs -p "Enter VPN password for bm0: " VPN_PASS
    echo
fi

run_openconnect() {
    echo "$VPN_PASS" | sudo openconnect --background --protocol=anyconnect "$VPN_HOST" --user=bm0 --passwd-on-stdin --servercert "$VPN_PIN"
}

wait_for_network() {
    local max_retries=15
    local count=0
    local host_ip="${VPN_HOST%%:*}"
    local host_port="${VPN_HOST#*:}"
    if [ "$host_ip" = "$host_port" ]; then
        host_port=443
    fi
    echo "Waiting for VPN gateway ($host_ip) to be reachable..."
    while [ $count -lt $max_retries ]; do
        if timeout 1 bash -c "true < /dev/tcp/$host_ip/$host_port" >/dev/null 2>&1; then
            echo "VPN gateway is reachable."
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    echo "Timeout waiting for VPN gateway to be reachable."
    return 1
}

case "$1" in
    up)
        if pgrep -x openconnect >/dev/null; then
            echo "VPN is already running."
        else
            wait_for_network
            if [ $? -eq 0 ]; then
                echo "Starting VPN..."
                run_openconnect
            else
                echo "Cannot start VPN: gateway is unreachable."
                exit 1
            fi
        fi
        ;;
    down)
        echo "Stopping VPN..."
        sudo pkill openconnect
        ;;
    restart)
        echo "Restarting VPN..."
        sudo pkill openconnect
        sleep 1
        wait_for_network
        if [ $? -eq 0 ]; then
            run_openconnect
        else
            echo "Cannot start VPN: gateway is unreachable."
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {up|down|restart}"
        exit 1
        ;;
esac
