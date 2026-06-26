function fbp --description "Select a fabric pattern using fzf and run it"
    set -l pattern (fabric --listpatterns | fzf --height 40% --layout=reverse --border --prompt="Fabric Pattern ❯ ")
    if test -n "$pattern"
        fabric --pattern $pattern $argv
    end
end
