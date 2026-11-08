#!/usr/bin/env bash
# Data and actions for Caelestia's small searchable menus.
set -euo pipefail
mode=${1:-}
action=${2:-list}
value=${3:-}
case "$mode:$action" in
    emoji:list) caelestia emoji ;;
    zsh:list) printf '%s\n' Random; find -L "$HOME/.oh-my-zsh/themes" -name '*.zsh-theme' -printf '%f\n' | sed 's/\.zsh-theme$//' | sort ;;
    animations:list) find -L "$HOME/.config/hypr/animations" -maxdepth 1 -name '*.lua' -printf '%f\n' | sed 's/\.lua$//' | sort -V ;;
    ghostty:list) ghostty +list-themes --plain | sed 's/ (resources)$//; s/ (user)$//' ;;
    emoji:apply) printf '%s' "$value" | wl-copy ;;
    zsh:apply)
        if [[ $value == Random ]]; then
            value=$(find -L "$HOME/.oh-my-zsh/themes" -name '*.zsh-theme' -printf '%f\n' | shuf -n1 | sed 's/\.zsh-theme$//')
        fi
        [[ $value =~ ^[a-zA-Z0-9_.-]+$ && -f $HOME/.oh-my-zsh/themes/$value.zsh-theme ]] || exit 1
        sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$value\"/" "$HOME/.zshrc"
        notify-send -e -u low "oh-my-zsh" "Theme: $value (restart terminal)" ;;
    animations:apply)
        [[ $value =~ ^[a-zA-Z0-9_.-]+$ && -f $HOME/.config/hypr/animations/$value.lua ]] || exit 1
        command cp -f "$HOME/.config/hypr/animations/$value.lua" "$HOME/.config/hypr/lua/animations.lua"
        hyprctl reload >/dev/null
        notify-send -e -u low Animations "$value" ;;
    ghostty:apply)
        ghostty +list-themes --plain | sed 's/ (resources)$//; s/ (user)$//' | grep -Fxq -- "$value" || exit 1
        [[ $value != *$'\n'* && $value != *'"'* && $value != *'\'* ]] || exit 1
        cfg=$HOME/.config/ghostty/config
        escaped=${value//&/\\&}; escaped=${escaped//|/\\|}
        if grep -q '^theme *=' "$cfg"; then sed -i "s|^theme *=.*|theme = \"$escaped\"|" "$cfg"; else printf 'theme = "%s"\n' "$value" >>"$cfg"; fi
        pkill -USR2 -x ghostty || true
        notify-send -e -u low Ghostty "Theme: $value" ;;
    *) exit 2 ;;
esac
