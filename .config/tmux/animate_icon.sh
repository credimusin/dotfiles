#!/usr/bin/env bash

# Animation styles: 'typing', 'spinner', 'rainbow', 'pulse', 'smooth'
STYLE="smooth"
INTERVAL=0.1 # Faster interval for smoother animation (if using daemon mode)

# Frame definitions
case "$STYLE" in
    "smooth")
        frames=(
            "#[fg=#f28585,bold]  #[default]"
            "#[fg=#f28a85,bold]  #[default]"
            "#[fg=#f29085,bold]  #[default]"
            "#[fg=#f29585,bold]  #[default]"
            "#[fg=#f29b85,bold]  #[default]"
            "#[fg=#f2a085,bold]  #[default]"
            "#[fg=#f2a585,bold]  #[default]"
            "#[fg=#f2ab85,bold]  #[default]"
            "#[fg=#f2b085,bold]  #[default]"
            "#[fg=#f2b685,bold]  #[default]"
            "#[fg=#f2bb85,bold]  #[default]"
            "#[fg=#f2c185,bold]  #[default]"
            "#[fg=#f2c685,bold]  #[default]"
            "#[fg=#f2cc85,bold]  #[default]"
            "#[fg=#f2d185,bold]  #[default]"
            "#[fg=#f2d685,bold]  #[default]"
            "#[fg=#f2dc85,bold]  #[default]"
            "#[fg=#f2e185,bold]  #[default]"
            "#[fg=#f2e785,bold]  #[default]"
            "#[fg=#f2ec85,bold]  #[default]"
            "#[fg=#f2f285,bold]  #[default]"
            "#[fg=#ecf285,bold]  #[default]"
            "#[fg=#e7f285,bold]  #[default]"
            "#[fg=#e1f285,bold]  #[default]"
            "#[fg=#dcf285,bold]  #[default]"
            "#[fg=#d6f285,bold]  #[default]"
            "#[fg=#d1f285,bold]  #[default]"
            "#[fg=#ccf285,bold]  #[default]"
            "#[fg=#c6f285,bold]  #[default]"
            "#[fg=#c1f285,bold]  #[default]"
            "#[fg=#bbf285,bold]  #[default]"
            "#[fg=#b6f285,bold]  #[default]"
            "#[fg=#b0f285,bold]  #[default]"
            "#[fg=#abf285,bold]  #[default]"
            "#[fg=#a5f285,bold]  #[default]"
            "#[fg=#a0f285,bold]  #[default]"
            "#[fg=#9bf285,bold]  #[default]"
            "#[fg=#95f285,bold]  #[default]"
            "#[fg=#90f285,bold]  #[default]"
            "#[fg=#8af285,bold]  #[default]"
            "#[fg=#85f285,bold]  #[default]"
            "#[fg=#85f28a,bold]  #[default]"
            "#[fg=#85f290,bold]  #[default]"
            "#[fg=#85f295,bold]  #[default]"
            "#[fg=#85f29b,bold]  #[default]"
            "#[fg=#85f2a0,bold]  #[default]"
            "#[fg=#85f2a5,bold]  #[default]"
            "#[fg=#85f2ab,bold]  #[default]"
            "#[fg=#85f2b0,bold]  #[default]"
            "#[fg=#85f2b6,bold]  #[default]"
            "#[fg=#85f2bb,bold]  #[default]"
            "#[fg=#85f2c1,bold]  #[default]"
            "#[fg=#85f2c6,bold]  #[default]"
            "#[fg=#85f2cc,bold]  #[default]"
            "#[fg=#85f2d1,bold]  #[default]"
            "#[fg=#85f2d6,bold]  #[default]"
            "#[fg=#85f2dc,bold]  #[default]"
            "#[fg=#85f2e1,bold]  #[default]"
            "#[fg=#85f2e7,bold]  #[default]"
            "#[fg=#85f2ec,bold]  #[default]"
            "#[fg=#85f2f2,bold]  #[default]"
            "#[fg=#85ecf2,bold]  #[default]"
            "#[fg=#85e7f2,bold]  #[default]"
            "#[fg=#85e1f2,bold]  #[default]"
            "#[fg=#85dcf2,bold]  #[default]"
            "#[fg=#85d6f2,bold]  #[default]"
            "#[fg=#85d1f2,bold]  #[default]"
            "#[fg=#85ccf2,bold]  #[default]"
            "#[fg=#85c6f2,bold]  #[default]"
            "#[fg=#85c1f2,bold]  #[default]"
            "#[fg=#85bbf2,bold]  #[default]"
            "#[fg=#85b6f2,bold]  #[default]"
            "#[fg=#85b0f2,bold]  #[default]"
            "#[fg=#85abf2,bold]  #[default]"
            "#[fg=#85a5f2,bold]  #[default]"
            "#[fg=#85a0f2,bold]  #[default]"
            "#[fg=#859bf2,bold]  #[default]"
            "#[fg=#8595f2,bold]  #[default]"
            "#[fg=#8590f2,bold]  #[default]"
            "#[fg=#858af2,bold]  #[default]"
            "#[fg=#8585f2,bold]  #[default]"
            "#[fg=#8a85f2,bold]  #[default]"
            "#[fg=#9085f2,bold]  #[default]"
            "#[fg=#9585f2,bold]  #[default]"
            "#[fg=#9b85f2,bold]  #[default]"
            "#[fg=#a085f2,bold]  #[default]"
            "#[fg=#a585f2,bold]  #[default]"
            "#[fg=#ab85f2,bold]  #[default]"
            "#[fg=#b085f2,bold]  #[default]"
            "#[fg=#b685f2,bold]  #[default]"
            "#[fg=#bb85f2,bold]  #[default]"
            "#[fg=#c185f2,bold]  #[default]"
            "#[fg=#c685f2,bold]  #[default]"
            "#[fg=#cc85f2,bold]  #[default]"
            "#[fg=#d185f2,bold]  #[default]"
            "#[fg=#d685f2,bold]  #[default]"
            "#[fg=#dc85f2,bold]  #[default]"
            "#[fg=#e185f2,bold]  #[default]"
            "#[fg=#e785f2,bold]  #[default]"
            "#[fg=#ec85f2,bold]  #[default]"
            "#[fg=#f285f2,bold]  #[default]"
            "#[fg=#f285ec,bold]  #[default]"
            "#[fg=#f285e7,bold]  #[default]"
            "#[fg=#f285e1,bold]  #[default]"
            "#[fg=#f285dc,bold]  #[default]"
            "#[fg=#f285d6,bold]  #[default]"
            "#[fg=#f285d1,bold]  #[default]"
            "#[fg=#f285cc,bold]  #[default]"
            "#[fg=#f285c6,bold]  #[default]"
            "#[fg=#f285c1,bold]  #[default]"
            "#[fg=#f285bb,bold]  #[default]"
            "#[fg=#f285b6,bold]  #[default]"
            "#[fg=#f285b0,bold]  #[default]"
            "#[fg=#f285ab,bold]  #[default]"
            "#[fg=#f285a5,bold]  #[default]"
            "#[fg=#f285a0,bold]  #[default]"
            "#[fg=#f2859b,bold]  #[default]"
            "#[fg=#f28595,bold]  #[default]"
            "#[fg=#f28590,bold]  #[default]"
            "#[fg=#f2858a,bold]  #[default]"
        )
        ;;
esac

num_frames=${#frames[@]}

# If run with --daemon, run an infinite loop updating tmux status-left directly
if [ "$1" = "--daemon" ]; then
    # Trap SIGTERM so tmux doesn't show an error when the old daemon is killed
    trap "exit 0" SIGTERM

    # Prevent multiple daemons running (kill old one if exists)
    LOCKFILE="/tmp/tmux_animate_icon.lock"
    if [ -f "$LOCKFILE" ]; then
        old_pid=$(cat "$LOCKFILE" 2>/dev/null)
        if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
            kill "$old_pid" 2>/dev/null
            sleep 0.05
        fi
    fi
    echo $$ > "$LOCKFILE"

    i=0
    # Wait for tmux server to start and make sure we don't spin if server dies
    while true; do
        if ! tmux info &>/dev/null; then
            # If tmux server is not running or we can't connect, exit daemon
            exit 0
        fi
        
        tmux set-option -g status-left "${frames[i]} "
        i=$(( (i + 1) % num_frames ))
        sleep "$INTERVAL"
    done
else
    # One-shot mode (called by tmux via status-interval)
    # Calculate index based on current epoch time (seconds)
    sec=$(date +%s)
    index=$(( sec % num_frames ))
    echo -e "${frames[index]} "
fi
