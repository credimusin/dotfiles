#!/usr/bin/env bash

path="$1"
cmd="$2"
# Strip brackets from window name (e.g., [tmux] -> tmux)
cmd="${cmd//[\[\]]/}"
active="$3"
index="$4"

# 1. Format the path
if [ "$path" = "/var/home/bmo" ] || [ "$path" = "/home/bmo" ] || [ "$path" = "~" ]; then
    display_path="~"
else
    # Extract basename using pure bash parameter expansion (no subprocess)
    base="${path##*/}"
    if [ -z "$base" ]; then
        display_path="/"
    else
        display_path="/$base"
        # Truncate if long (greater than 15 characters)
        if [ ${#display_path} -gt 15 ]; then
            first="${display_path:0:8}"
            last="${display_path: -4}"
            display_path="${first}...${last}"
        fi
    fi
fi

# 2. Get process icon
icon=""
case "$cmd" in
    fish)
        icon="󰈺"
        ;;
    bash|sh|zsh)
        icon=""
        ;;
    vim|nvim|vi|nano)
        icon=""
        ;;
    helix|hx)
        icon="🧬"
        ;;
    podman|podman-compose)
        icon="🦭"
        ;;
    toolbox|toolbx)
        icon=""
        ;;
    agy|antigravity|antigravitycli)
        icon="🛸"
        ;;
    git|lazygit)
        icon=""
        ;;
    tmux*)
        icon=""
        ;;
    python|python3|ipython)
        icon=""
        ;;
    node|nodejs|npm|yarn)
        icon=""
        ;;
    ssh)
        icon="󰣀"
        ;;
    docker|docker-compose)
        icon=""
        ;;
    htop|top|btop)
        icon="󰄧"
        ;;
    cargo|rustc)
        icon=""
        ;;
    go)
        icon=""
        ;;
    make|gcc|g++|clang)
        icon="🛠️"
        ;;
    sudo)
        icon="🔒"
        ;;
    man|less|more)
        icon="📖"
        ;;
    opencode)
        icon="🔲"
        ;;
    ruby|irb)
        icon=""
        ;;
    php)
        icon="󰌟"
        ;;
    java|javac)
        icon=""
        ;;
    lua)
        icon=""
        ;;
    perl)
        icon=""
        ;;
    tail|cat|grep|awk|sed|jq|yq)
        icon="󰈙"
        ;;
    psql|mysql|sqlite3|redis-cli|mongosh)
        icon=""
        ;;
    curl|wget|httpie)
        icon="󰖟"
        ;;
    k9s|kubectl|helm|minikube|k|k3s)
        icon="󱃾"
        ;;
    terraform|tf|terragrunt)
        icon="󱁢"
        ;;
    ansible|ansible-playbook|chef|puppet)
        icon="󱂚"
        ;;
    ping|traceroute|mtr)
        icon="󰲝"
        ;;
    ncat|nc|nmap|netstat|ss)
        icon="󰜎"
        ;;
    pnpm|bun)
        icon="󰎙"
        ;;
    gh)
        icon=""
        ;;
    fzf)
        icon="󰈢"
        ;;
    *)
        icon="🌀"
        ;;
esac

# 3. Format output based on active window status
if [ "$active" = "1" ]; then
    # Active window styling: bright yellow index, vibrant green path, yellow/bold icon
    path_style="#[fg=green,bold]"
    icon_style="#[fg=yellow,bold]"
    echo -n " #[fg=yellow,bold]${index} ${path_style}${display_path} ${icon_style}${icon} "
else
    # Inactive window styling: muted gray index, muted gray/blue path and process
    path_style="#[fg=color245]"
    icon_style="#[fg=color240]"
    echo -n " #[fg=color240]${index} ${path_style}${display_path} ${icon_style}${icon} "
fi
