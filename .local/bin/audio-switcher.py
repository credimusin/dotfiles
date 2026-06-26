import subprocess
import re
import sys

try:
    output = subprocess.check_output(["wpctl", "status"]).decode("utf-8")
except Exception as e:
    sys.exit(1)

sinks = []
in_sinks = False
for line in output.splitlines():
    if "Sinks:" in line:
        in_sinks = True
        continue
    if in_sinks:
        clean_line = line.replace("│", "").strip()
        if "├─" in clean_line or "└─" in clean_line or not clean_line:
            if sinks:
                break
            continue
        is_default = clean_line.startswith("*")
        clean_line = clean_line.lstrip("*").strip()
        match = re.match(r"(\d+)\.\s+(.*)", clean_line)
        if match:
            sink_id = match.group(1)
            rest = match.group(2)
            if "[" in rest:
                name = rest.split("[")[0].strip()
            else:
                name = rest.strip()
            sinks.append((sink_id, name, is_default))

if not sinks:
    subprocess.run(["notify-send", "Audio Switcher", "No audio sinks found."])
    sys.exit(0)

options_input = []
default_idx = 0
for idx, (sink_id, name, is_default) in enumerate(sinks):
    marker = "★ " if is_default else "  "
    options_input.append(f"{marker}{name} ({sink_id})")
    if is_default:
        default_idx = idx

rofi_proc = subprocess.Popen(
    [
        "rofi", "-dmenu", "-i",
        "-p", "Audio Output",
        "-theme-str", "window { width: 30%; } listview { lines: 6; }",
        "-select", options_input[default_idx]
    ],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
    text=True
)

chosen, _ = rofi_proc.communicate(input="\n".join(options_input))
chosen = chosen.strip()

if not chosen:
    sys.exit(0)

match = re.search(r"\((\d+)\)$", chosen)
if match:
    selected_id = match.group(1)
    clean_name = chosen.lstrip("★ ").rsplit("(", 1)[0].strip()
    subprocess.run(["wpctl", "set-default", selected_id])
    subprocess.run(["notify-send", "Audio Output Switched", f"Active: {clean_name}"])
