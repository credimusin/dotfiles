function fish_user_key_bindings
    # Bind Alt+k to clear terminal (same as Ctrl+l)
    bind \ek 'clear; commandline -f repaint'
end
