#!/bin/bash
# VPN Control Script
# This script manages the OpenConnect VPN connection for user bm0 with automatic failover and notifications.

# Load local configuration
VPN_CONFIG_FILE="$HOME/.vpn-config"
if [ -f "$VPN_CONFIG_FILE" ]; then
    source "$VPN_CONFIG_FILE"
else
    echo "Error: Configuration file $VPN_CONFIG_FILE not found." >&2
    exit 1
fi

LONDON_HOST="${VPN_HOST_LONDON:-${VPN_HOST:-}}"
LONDON_PIN="${VPN_PIN_LONDON:-${VPN_PIN:-}}"

DEFAULT_LOC="${DEFAULT_VPN_LOCATION:-auto}"

# Gateway priority order for automatic failover
GATEWAYS=("london")

# Desktop notifications helper
send_notification() {
    local urgency="${1:-normal}"
    local title="$2"
    local message="$3"
    if command -v notify-send &>/dev/null; then
        notify-send -u "$urgency" -a "VPN" "$title" "$message"
    fi
}

# Parse action and location arguments
ACTION=""
LOCATION_ARG=""

case "$1" in
    up|down|restart|status)
        ACTION="$1"
        LOCATION_ARG="$2"
        ;;
    london|lon|auto)
        ACTION="up"
        LOCATION_ARG="$1"
        ;;
    "")
        ACTION="up"
        LOCATION_ARG=""
        ;;
    *)
        echo "Error: Unknown command or location '$1'" >&2
        echo "Usage: $0 {up|down|restart|status} [london|lon|auto]" >&2
        exit 1
        ;;
esac

SELECTED_LOC="${LOCATION_ARG:-$DEFAULT_LOC}"

# Check server reachability via HTTPS/TLS handshake (curl)
check_server_reachability() {
    local target_host="$1"
    if [ -z "$target_host" ]; then
        return 1
    fi
    if curl -sk --connect-timeout 2 "https://$target_host" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Resolve location settings
set_location() {
    case "$1" in
        london|lon)
            TARGET_HOST="$LONDON_HOST"
            TARGET_PIN="$LONDON_PIN"
            LOCATION_NAME="London"
            ;;
        *)
            TARGET_HOST=""
            TARGET_PIN=""
            LOCATION_NAME=""
            ;;
    esac
}

# Get VPN password using pass, if pass is initialized, otherwise prompt
get_password() {
    export PASSWORD_STORE_DIR="$HOME/.password-store-local"
    if command -v pass &>/dev/null && pass show vpn/qwesta &>/dev/null; then
        VPN_PASS=$(pass show vpn/qwesta | head -n 1)
    else
        read -rs -p "Enter VPN password for bm0: " VPN_PASS
        echo
    fi
}

run_openconnect() {
    if [ -z "$TARGET_HOST" ] || [ -z "$TARGET_PIN" ]; then
        echo "Error: Host or PIN for $LOCATION_NAME is not configured in $VPN_CONFIG_FILE" >&2
        exit 1
    fi
    echo "Connecting to $LOCATION_NAME ($TARGET_HOST)..."
    echo "$VPN_PASS" | sudo openconnect --background --protocol=anyconnect "$TARGET_HOST" --user=bm0 --passwd-on-stdin --servercert "$TARGET_PIN"
}

# Wait for network and select best reachable gateway
wait_and_select_gateway() {
    local max_retries=15
    local count=0

    if [ "$SELECTED_LOC" != "auto" ]; then
        set_location "$SELECTED_LOC"
        if [ -z "$TARGET_HOST" ]; then
            echo "Error: Configuration for $LOCATION_NAME is missing in $VPN_CONFIG_FILE" >&2
            return 1
        fi
        echo "Waiting for VPN gateway $LOCATION_NAME (${TARGET_HOST})..."
        while [ $count -lt $max_retries ]; do
            if check_server_reachability "$TARGET_HOST"; then
                echo "VPN gateway ($LOCATION_NAME) is reachable."
                return 0
            fi
            sleep 1
            count=$((count + 1))
        done
        echo "Timeout waiting for VPN gateway ($LOCATION_NAME) to respond."
        return 1
    fi

    # Auto mode: try gateways in priority order
    echo "Waiting for network and checking VPN gateways (auto failover)..."
    while [ $count -lt $max_retries ]; do
        for loc in "${GATEWAYS[@]}"; do
            set_location "$loc"
            if [ -n "$TARGET_HOST" ] && check_server_reachability "$TARGET_HOST"; then
                echo "VPN gateway ($LOCATION_NAME - $TARGET_HOST) is reachable."
                return 0
            fi
        done

        sleep 1
        count=$((count + 1))
    done

    echo "Timeout: No VPN gateway is currently reachable."
    return 1
}

# Check if openconnect is running and which host it is connected to
is_connected() {
    if pgrep -x openconnect >/dev/null; then
        if [ -n "${TARGET_HOST:-}" ]; then
            local target_ip="${TARGET_HOST%%:*}"
            if ps aux | grep openconnect | grep -q "$target_ip"; then
                return 0 # connected to target host
            else
                return 1 # connected to different host
            fi
        fi
        return 0 # connected
    else
        return 2 # not running
    fi
}

case "$ACTION" in
    up)
        if [ "$SELECTED_LOC" != "auto" ]; then
            set_location "$SELECTED_LOC"
            is_connected
            status_code=$?
            if [ $status_code -eq 0 ]; then
                echo "VPN is already running ($LOCATION_NAME)."
                exit 0
            fi
        fi

        if pgrep -x openconnect >/dev/null && [ "$SELECTED_LOC" = "auto" ]; then
            echo "VPN is already running."
            exit 0
        fi

        wait_and_select_gateway
        if [ $? -eq 0 ]; then
            # If openconnect was running on another server, stop it first
            if pgrep -x openconnect >/dev/null; then
                sudo pkill openconnect
                sleep 1
            fi
            get_password
            run_openconnect
            send_notification "normal" "VPN Connected" "Connected to $LOCATION_NAME ($TARGET_HOST)"
        else
            echo "Cannot start VPN: gateways are unreachable." >&2
            send_notification "critical" "VPN Connection Failed" "No VPN gateway is reachable. Continuing without VPN."
            exit 0
        fi
        ;;
    down)
        echo "Stopping VPN..."
        if pgrep -x openconnect >/dev/null; then
            sudo pkill openconnect
            send_notification "normal" "VPN Disconnected" "VPN connection stopped."
        fi
        ;;
    restart)
        echo "Restarting VPN..."
        sudo pkill openconnect
        sleep 1
        wait_and_select_gateway
        if [ $? -eq 0 ]; then
            get_password
            run_openconnect
            send_notification "normal" "VPN Connected" "Connected to $LOCATION_NAME ($TARGET_HOST)"
        else
            echo "Cannot start VPN: gateways are unreachable." >&2
            send_notification "critical" "VPN Connection Failed" "No VPN gateway is reachable. Continuing without VPN."
            exit 0
        fi
        ;;
    status)
        if pgrep -x openconnect >/dev/null; then
            echo "VPN is running:"
            ps aux | grep openconnect | grep -v grep
        else
            echo "VPN is stopped."
        fi
        ;;
esac
