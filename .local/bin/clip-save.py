#!/usr/bin/env python3
import os
import sys
import subprocess

HISTORY_PATH = "/var/home/bmo/.cache/rofi-clipboard-history.txt"
os.makedirs(os.path.dirname(HISTORY_PATH), exist_ok=True)

try:
    text = subprocess.check_output(["wl-paste", "-t", "text"]).decode("utf-8", errors="ignore").strip()
except Exception:
    sys.exit(0)

# Replace newlines/tabs with spaces to keep it single line per entry in rofi
text_clean = text.replace("\n", " ").replace("\r", "").replace("\t", " ")
# Strip extra spaces
text_clean = " ".join(text_clean.split())

if not text_clean:
    sys.exit(0)

# Read existing history
history = []
if os.path.exists(HISTORY_PATH):
    try:
        with open(HISTORY_PATH, "r", encoding="utf-8") as f:
            history = [line.strip() for line in f if line.strip()]
    except Exception:
        pass

# If already at the top, do nothing
if history and history[0] == text_clean:
    sys.exit(0)

# Remove duplicates from history
if text_clean in history:
    history.remove(text_clean)

# Insert at top
history.insert(0, text_clean)

# Limit to 100 entries
history = history[:100]

try:
    with open(HISTORY_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(history) + "\n")
except Exception:
    pass

# Feed new clip to CopyQ
try:
    subprocess.run(["flatpak", "run", "com.github.hluk.copyq", "add", text], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
except Exception:
    pass
