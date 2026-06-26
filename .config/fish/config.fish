if status is-interactive
    # Remove default welcome message
    set -g fish_greeting ''
    
    # Disable default mouse binding to let Tmux/terminal handle selections
    set -g fish_mouse_default_binding none

    # Manage Paths safely (checks for duplicates automatically)
    fish_add_path /usr/local/bin
    fish_add_path $HOME/.local/bin
    fish_add_path /home/bmo/.opencode/bin
    fish_add_path $HOME/.config/composer/vendor/bin

    # --- Theme & Colors (Catppuccin Macchiato) ---
    set -g fish_color_normal cad3f5
    set -g fish_color_command 8aadf4
    set -g fish_color_param f5bde6
    set -g fish_color_keyword ed8796
    set -g fish_color_quote eed49f
    set -g fish_color_redirection f4dbd6
    set -g fish_color_end f5a97f
    set -g fish_color_error ed8796
    set -g fish_color_gray 6e738d
    set -g fish_color_selection --background=36394f
    set -g fish_color_search_match --background=36394f
    set -g fish_color_operator 8bd5ca
    set -g fish_color_escape f4dbd6
    set -g fish_color_autosuggestion 6e738d

    # --- Autostart Tmux ---
    # Only start Tmux automatically if we are NOT already in a Tmux session,
    # and if the shell was NOT launched by an IDE or editor like VSCode/Zed
    if not set -q TMUX
        if test "$TERM_PROGRAM" != "zed"; \
           and test "$TERM_PROGRAM" != "vscode"; \
           and test "$TERM_PROGRAM" != "vscodium"; \
           and test "$TERM_PROGRAM" != "clion"; \
           and test "$TERM_PROGRAM" != "rider"; \
           and test "$TERM_PROGRAM" != "pycharm"; \
           and test "$TERM_PROGRAM" != "webstorm"; \
           and test "$TERM_PROGRAM" != "rubymine"; \
           and test "$INSIDE_EMACS" = ""; \
           and test "$TERMINAL_EMULATOR" != "JetBrains-JediTerm"
            tmux attach || tmux
        end
    end

    # --- Aliases ---
    # General shortcuts
    alias helix=hx
    alias py=python
    alias lg="toolbox run lazygit"
    alias gh="toolbox run gh"
    alias ollama="toolbox run ollama"
    alias fastfetch="toolbox run fastfetch"
    
    # Modern alternatives
    alias cat=bat
    alias mkdir="mkdir -p"
    alias ...="cd ../.."
    alias ....="cd ../../.."

    # EZA (Better ls)
    alias ls='eza --icons --group-directories-first --color=always --header --git'
    alias ll='eza -l --icons --group-directories-first --color=always'
    alias la='eza -la --icons --group-directories-first --color=always'
    alias lt='eza -T --group-directories-first --color=always'
    alias l.='eza -la | grep "^\."'
    alias lsg='eza --git --long --group --header --icons'
    alias l1='eza -1'

    # Utilities
    alias ipinfo="curl -s ipinfo.io | jq '.city, .ip'"
    alias speed="cloudflare-speed-cli"

    # VPN Control
    alias vu="vpn-control.sh up"
    alias vd="vpn-control.sh down"
    alias vr="vpn-control.sh restart"

    # Bluetooth Headphones Control
    alias hr="bluetooth-reconnect.sh"
    alias hpr="bluetooth-reconnect.sh"

    # Interactive Fuzzy Search (fzf + bat)
    alias ff="fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'"

    # --- Prompt & Navigation Init ---
    if type -q starship
        starship init fish | source
    end
    if type -q zoxide
        zoxide init fish | source
    end

    if test -f /usr/share/fzf/shell/key-bindings.fish
        source /usr/share/fzf/shell/key-bindings.fish
        fzf_key_bindings
    end
end
