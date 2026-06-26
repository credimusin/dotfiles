#!/bin/bash
# Kill any existing wl-paste watches for this script to avoid duplicates
pkill -f "wl-paste --type text --watch /var/home/bmo/.local/bin/clip-save.py" 2>/dev/null
# Start watching in the foreground (Sway will handle backgrounding this script)
exec wl-paste --type text --watch /var/home/bmo/.local/bin/clip-save.py
