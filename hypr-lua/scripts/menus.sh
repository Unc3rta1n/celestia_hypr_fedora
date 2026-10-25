#!/usr/bin/env bash
# fuzzel replacements for the KoolDots rofi menus.
#   menus.sh search       web search with the default browser   (was RofiSearch.sh)
#   menus.sh ssh          ssh hosts from ~/.ssh/config in ghostty (was rofi-ssh-menu.sh)
#   menus.sh keys         searchable list of current binds       (was KeyHints.sh)
#   menus.sh zsh-theme    oh-my-zsh theme                        (was ZshChangeTheme.sh)
#   menus.sh term-theme   ghostty theme                          (was Kitty_themes.sh)
#   menus.sh animations   Hyprland animation preset              (was Animations.sh)
set -uo pipefail

SEARCH_ENGINE="https://www.google.com/search?q="
TERMINAL="ghostty"
KEY_GROUPS="Apps Shell Windows Workspaces Layout Capture Media Tools System Laptop"

menu() { # menu PROMPT [fuzzel args...]
    local prompt=$1
    shift
    pkill -x fuzzel 2>/dev/null
    fuzzel --dmenu --prompt "$prompt  " "$@"
}

notify() { notify-send -e -u low "$@"; }

search() {
    local q
    q=$(menu "󰖟" --prompt-only "󰖟  " --placeholder "Search the web") || exit 0
    [[ -n $q ]] || exit 0
    xdg-open "${SEARCH_ENGINE}$(jq -rn --arg q "$q" '$q|@uri')" >/dev/null 2>&1 &
}

ssh_menu() {
    local cfg=$HOME/.ssh/config sel host
    [[ -f $cfg ]] || { notify "SSH" "No $cfg"; exit 1; }
    sel=$(awk '
        { sub(/[ \t]*#.*/, "") }
        $1 == "Host" { delete cur; for (i = 2; i <= NF; i++) if ($i !~ /[*?!]/) { cur[$i] = 1; if (!($i in seen)) { seen[$i] = 1; order[++n] = $i } } next }
        $1 == "HostName" { for (h in cur) hn[h] = $2 }
        $1 == "User"     { for (h in cur) us[h] = $2 }
        END { for (i = 1; i <= n; i++) { h = order[i]; printf "%s  │  %s@%s\n", h, (h in us ? us[h] : ENVIRON["USER"]), (h in hn ? hn[h] : h) } }
    ' "$cfg" | menu "󰣀") || exit 0
    host=${sel%%  │*}
    [[ -n $host ]] && exec "$TERMINAL" +new-window --title="SSH $host" -e ssh "$host"
}

keys() {
    # descriptions are "Category|KEYS|text" (lua/keybinds.lua bind()); KEY_GROUPS sets the order
    hyprctl binds -j | jq -r '.[] | select(.has_description) | .description | split("|")
            | select(length == 3) | @tsv' |
        sort -u | awk -F'\t' -v order="$KEY_GROUPS" '
            BEGIN { n = split(order, o, " "); for (i = 1; i <= n; i++) rank[o[i]] = i }
            { printf "%02d\t%s\t%s\t%s\n", ($1 in rank) ? rank[$1] : 99, $1, $2, $3 }' |
        sort -t $'\t' -k1,1n -k3,3 | awk -F'\t' '
            $2 != cur { cur = $2; print "━━ " cur " ━━" }
            { printf "   %s\t%s\t%s\n", $3, $4, $2 }' |
        column -t -s $'\t' | menu "" --width 100 --lines 25 >/dev/null
}

zsh_theme() {
    local dir=$HOME/.oh-my-zsh/themes theme
    theme=$({ echo Random; find -L "$dir" -name '*.zsh-theme' -printf '%f\n' | sed 's/\.zsh-theme$//' | sort; } | menu "") || exit 0
    [[ -n $theme ]] || exit 0
    if [[ $theme == Random ]]; then
        theme=$(find -L "$dir" -name '*.zsh-theme' -printf '%f\n' | shuf -n1 | sed 's/\.zsh-theme$//')
    fi
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$theme\"/" "$HOME/.zshrc"
    notify "oh-my-zsh" "Theme: $theme (restart terminal)"
}

term_theme() {
    local cfg=$HOME/.config/ghostty/config theme
    theme=$(ghostty +list-themes --plain | sed 's/ (resources)$//; s/ (user)$//' | menu "") || exit 0
    [[ -n $theme ]] || exit 0
    if grep -q '^theme *=' "$cfg"; then
        sed -i "s|^theme *=.*|theme = \"$theme\"|" "$cfg"
    else
        printf 'theme = "%s"\n' "$theme" >>"$cfg"
    fi
    pkill -USR2 -x ghostty # live reload of open windows
    notify "Ghostty" "Theme: $theme"
}

animations() {
    local dir=$HOME/.config/hypr/animations preset
    preset=$(find -L "$dir" -maxdepth 1 -name '*.lua' -printf '%f\n' | sed 's/\.lua$//' | sort -V | menu "") || exit 0
    [[ -n $preset ]] || exit 0
    cp "$dir/$preset.lua" "$HOME/.config/hypr/lua/animations.lua"
    hyprctl reload >/dev/null
    notify "Animations" "$preset"
}

case ${1:-} in
search) search ;;
ssh) ssh_menu ;;
keys) keys ;;
zsh-theme) zsh_theme ;;
term-theme) term_theme ;;
animations) animations ;;
*) sed -n '2,9p' "$0" >&2; exit 1 ;;
esac
