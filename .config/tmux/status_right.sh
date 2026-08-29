#!/usr/bin/env bash

# 1. CPU Temperature (instant sysfs lookup)
temp=0
for tz in /sys/class/thermal/thermal_zone*/temp; do
    if [ -f "$tz" ]; then
        t=$(cat "$tz" 2>/dev/null)
        if [ -n "$t" ] && [ "$t" -gt 0 ]; then
            temp=$((t / 1000))
            break
        fi
    fi
done

if [ "$temp" -ge 80 ]; then
    temp_fg="#[fg=red]"
elif [ "$temp" -ge 65 ]; then
    temp_fg="#[fg=yellow]"
else
    temp_fg="#[fg=green]"
fi
temp_str="${temp_fg} $(printf '%2d' "$temp")°#[default]"

# 2. CPU Usage (instant /proc/stat calculation)
stat_file="/tmp/.tmux_cpu_stat"
pct=0
if [ -f /proc/stat ]; then
    read -r _ u n s i io irq sirq st _ < /proc/stat
    total=$((u + n + s + i + io + irq + sirq + st))
    active=$((u + n + s + irq + sirq + st))
    if [ -f "$stat_file" ]; then
        read -r prev_total prev_active < "$stat_file" 2>/dev/null
        diff_total=$((total - prev_total))
        diff_active=$((active - prev_active))
        if [ -n "$diff_total" ] && [ "$diff_total" -gt 0 ]; then
            pct=$(( 100 * diff_active / diff_total ))
        fi
    fi
    echo "$total $active" > "$stat_file"
fi
cpu_str="#[fg=yellow] $(printf '%3d%%' "$pct")#[default]"

# 3. Battery
bat_str=""
if [ -f /sys/class/power_supply/BAT0/capacity ]; then
    cap=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
    status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
    if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
        icon="󰂄"
    else
        icon="󰁹"
    fi
    bat_str="#[fg=green]${icon} $(printf '%3d%%' "$cap")#[default]"
fi

# 4. Sway Keyboard Layout
layout_str=""
sock=$(ls /run/user/$(id -u)/sway-ipc.*.sock 2>/dev/null | head -n1)
if [ -n "$sock" ] && command -v swaymsg >/dev/null 2>&1; then
    l=$(SWAYSOCK="$sock" swaymsg -t get_inputs -r 2>/dev/null | grep -m1 "xkb_active_layout_name" | cut -d'"' -f4)
    case "$l" in
        *"English"*) layout_str="#[fg=color75,bold]EN#[default]" ;;
        *"Russian"*) layout_str="#[fg=color203,bold]RU#[default]" ;;
        *) layout_str="#[fg=white,bold]${l:0:2}#[default]" ;;
    esac
fi

# 5. Current Time (pure bash builtin, zero fork)
printf -v time_str '%(%H:%M)T' -1

sep="#[fg=color245]|#[default]"
out="${temp_str} ${cpu_str}"
[ -n "$bat_str" ] && out="${out} ${sep} ${bat_str}"
[ -n "$layout_str" ] && out="${out} ${sep} ${layout_str}"
out="${out} ${sep} #[fg=cyan]${time_str} #[default] "

echo "$out"
