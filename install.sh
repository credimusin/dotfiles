#!/bin/bash
set -eo pipefail

# ANSI color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌌 Welcome to the dotfiles Setup Script!${NC}\n"

# 1. Detect Environment & OS
IN_CONTAINER=false
if [ -f /run/.containerenv ] || [ -f /.dockerenv ] || [ "$HOSTNAME" = "toolbx" ] || [ -n "$container" ]; then
    IN_CONTAINER=true
fi

OS_NAME="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$ID
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_NAME="macos"
fi

echo -e "System detected: ${GREEN}${OS_NAME}${NC} (Container: ${YELLOW}${IN_CONTAINER}${NC})"

# Packages list
PACKAGES_FEDORA="alacritty bat btop chromium eza fastfetch fd-find fish fzf helix jq pass ripgrep swappy tldr tmux wtype zoxide"
PACKAGES_DEBIAN="alacritty bat btop chromium-browser eza fastfetch fd-find fish fzf jq pass ripgrep tmux zoxide"
PACKAGES_ARCH="alacritty bat btop chromium eza fastfetch fd fish fzf helix jq pass ripgrep swappy tldr tmux wtype zoxide"
PACKAGES_MACOS="alacritty bat btop eza fastfetch fd fish fzf helix jq pass ripgrep tealdeer tmux zoxide"

# 2. Package Installation Phase
install_system_packages() {
    echo -e "\n${BLUE}[1/4] Installing system packages...${NC}"
    if [ "$IN_CONTAINER" = true ]; then
        echo -e "${YELLOW}Warning: You are running inside a container (Toolbox/Docker).${NC}"
        echo -e "System packages (window managers, terminal emulator, shell) should be installed on the host system."
        read -p "Do you want to attempt installing inside the container anyway? (y/N) " choice
        case "$choice" in
            [yY]*) ;;
            *) echo "Skipping system packages install."; return ;;
        esac
    fi

    if [ "$OS_NAME" = "fedora" ]; then
        if command -v rpm-ostree &>/dev/null; then
            echo -e "Detected ${GREEN}Fedora Atomic Desktop (rpm-ostree)${NC}."
            echo "Installing layered packages..."
            sudo rpm-ostree install -y $PACKAGES_FEDORA
        else
            echo -e "Detected ${GREEN}Fedora Workstation (dnf)${NC}."
            sudo dnf install -y $PACKAGES_FEDORA
        fi
    elif [ "$OS_NAME" = "debian" ] || [ "$OS_NAME" = "ubuntu" ] || [ "$OS_NAME" = "pop" ]; then
        echo -e "Detected ${GREEN}Debian-based system (apt)${NC}."
        sudo apt-get update
        sudo apt-get install -y $PACKAGES_DEBIAN
    elif [ "$OS_NAME" = "arch" ] || [ "$OS_NAME" = "manjaro" ]; then
        echo -e "Detected ${GREEN}Arch Linux (pacman)${NC}."
        sudo pacman -S --needed --noconfirm $PACKAGES_ARCH
    elif [ "$OS_NAME" = "macos" ]; then
        echo -e "Detected ${GREEN}macOS (Homebrew)${NC}."
        if ! command -v brew &>/dev/null; then
            echo "Homebrew is not installed. Installing Homebrew first..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install $PACKAGES_MACOS
    else
        echo -e "${RED}Unsupported OS for automatic package installation.${NC}"
        echo "Please install packages manually: alacritty, bat, btop, eza, fastfetch, fd, fish, fzf, helix, pass, ripgrep, tmux, zoxide."
    fi
}

# 3. Flatpak GUI Apps Installation
install_flatpaks() {
    echo -e "\n${BLUE}[2/4] Installing Flatpak applications...${NC}"
    if ! command -v flatpak &>/dev/null; then
        echo "Flatpak is not installed on this system. Skipping Flatpak installation."
        return
    fi

    echo "Adding Flathub repository..."
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

    # Ask user what flatpaks to install
    echo -e "Select GUI applications to install:"
    FLATPAKS=()
    read -p "Install mpv (media player)? (Y/n) " mpv_choice
    [[ "$mpv_choice" =~ ^[nN]$ ]] || FLATPAKS+=("io.mpv.Mpv")

    read -p "Install Obsidian (knowledge base)? (Y/n) " obsidian_choice
    [[ "$obsidian_choice" =~ ^[nN]$ ]] || FLATPAKS+=("md.obsidian.Obsidian")

    read -p "Install LocalSend (file sharing)? (Y/n) " localsend_choice
    [[ "$localsend_choice" =~ ^[nN]$ ]] || FLATPAKS+=("org.localsend.localsend_app")

    read -p "Install cmus (console music player)? (Y/n) " cmus_choice
    [[ "$cmus_choice" =~ ^[nN]$ ]] || FLATPAKS+=("io.github.cmus.cmus")

    if [ ${#FLATPAKS[@]} -gt 0 ]; then
        echo "Installing Flatpaks..."
        flatpak install --user -y flathub "${FLATPAKS[@]}"
    else
        echo "No Flatpaks selected."
    fi
}

# 4. Symlinking Configuration Files
symlink_dotfiles() {
    echo -e "\n${BLUE}[3/4] Creating symlinks for dotfiles...${NC}"
    
    # Get absolute directory of the script
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)

    # Function to symlink a file or directory
    link_item() {
        local src="$1"
        local dest="$2"

        # Check if source exists
        if [ ! -e "$src" ]; then
            echo -e "${RED}Source does not exist: $src${NC}"
            return
        fi

        # Ensure destination parent directory exists
        mkdir -p "$(dirname "$dest")"

        # Check if destination already exists
        if [ -e "$dest" ] || [ -L "$dest" ]; then
            # If it's a symlink pointing to the correct source, we're good
            if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
                echo -e "${GREEN}Already linked:${NC} $dest"
                return
            fi
            
            # Backup existing
            echo -e "${YELLOW}Backing up:${NC} $dest -> $dest.bak.$TIMESTAMP"
            mv "$dest" "$dest.bak.$TIMESTAMP"
        fi

        # Create symlink
        ln -sf "$src" "$dest"
        echo -e "${GREEN}Linked:${NC} $dest -> $src"
    }

    # Symlink individual configuration directories in ~/.config
    # (We link individual subfolders so we don't block other applications from writing to ~/.config)
    CONFIGS=$(find "$DOTFILES_DIR/.config" -maxdepth 1 -mindepth 1)
    for cfg in $CONFIGS; do
        basename_cfg=$(basename "$cfg")
        # Ignore .gitignore in .config
        if [ "$basename_cfg" = ".gitignore" ]; then
            continue
        fi
        link_item "$cfg" "$HOME/.config/$basename_cfg"
    done

    # Symlink individual custom scripts in ~/.local/bin
    SCRIPTS=$(find "$DOTFILES_DIR/.local/bin" -maxdepth 1 -mindepth 1)
    for script in $SCRIPTS; do
        basename_script=$(basename "$script")
        # Ignore .gitignore in .local/bin
        if [ "$basename_script" = ".gitignore" ]; then
            continue
        fi
        link_item "$script" "$HOME/.local/bin/$basename_script"
    done

    # Symlink desktop application entries in ~/.local/share/applications
    if [ -d "$DOTFILES_DIR/.local/share" ]; then
        APPS=$(find "$DOTFILES_DIR/.local/share/applications" -maxdepth 1 -mindepth 1 2>/dev/null || true)
        for app in $APPS; do
            basename_app=$(basename "$app")
            if [ "$basename_app" = ".gitignore" ]; then
                continue
            fi
            link_item "$app" "$HOME/.local/share/applications/$basename_app"
        done
    fi

    # Symlink root dotfiles
    link_item "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
    link_item "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"
    link_item "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
    
    # Symlink .tmux.conf to .config/tmux/tmux.conf
    # (Sway expects this or uses standard config location. We'll link ~/.tmux.conf to the config file)
    link_item "$HOME/.config/tmux/tmux.conf" "$HOME/.tmux.conf"

    # Symlink pictures/wallpapers
    if [ -d "$DOTFILES_DIR/Pictures" ]; then
        PICTURES=$(find "$DOTFILES_DIR/Pictures" -maxdepth 1 -mindepth 1)
        for pic in $PICTURES; do
            basename_pic=$(basename "$pic")
            # Ignore .gitignore in Pictures
            if [ "$basename_pic" = ".gitignore" ]; then
                continue
            fi
            link_item "$pic" "$HOME/Pictures/$basename_pic"
        done
    fi
}

# 5. Shell Activation Phase
configure_shell() {
    echo -e "\n${BLUE}[4/4] Configuring shell...${NC}"
    if command -v fish &>/dev/null; then
        CURRENT_SHELL=$(basename "$SHELL")
        if [ "$CURRENT_SHELL" != "fish" ]; then
            read -p "Do you want to set fish as your default shell? (y/N) " chsh_choice
            case "$chsh_choice" in
                [yY]*)
                    # chsh might fail inside container
                    if [ "$IN_CONTAINER" = true ]; then
                        echo "Changing shell inside container is not recommended. Please change it on the host."
                    else
                        sudo chsh -s "$(which fish)" "$USER"
                        echo -e "${GREEN}Default shell changed to Fish. Please log out and back in.${NC}"
                    fi
                    ;;
                *)
                    echo "Keeping current shell."
                    ;;
            esac
        else
            echo -e "${GREEN}Fish is already your default shell.${NC}"
        fi
    else
        echo -e "${YELLOW}Fish shell is not installed. Skipping shell configuration.${NC}"
    fi
}

# Execute phases
read -p "Install system packages? (y/N) " run_pkg
[[ "$run_pkg" =~ ^[yY]$ ]] && install_system_packages

read -p "Install Flatpak applications? (y/N) " run_flat
[[ "$run_flat" =~ ^[yY]$ ]] && install_flatpaks

read -p "Symlink configurations and scripts? (y/N) " run_sym
[[ "$run_sym" =~ ^[yY]$ ]] && symlink_dotfiles

read -p "Configure default shell? (y/N) " run_shell
[[ "$run_shell" =~ ^[yY]$ ]] && configure_shell

echo -e "\n${GREEN}✨ dotfiles setup completed!${NC}"
echo -e "Remember to configure your secret credentials using 'pass' as described in the README."
