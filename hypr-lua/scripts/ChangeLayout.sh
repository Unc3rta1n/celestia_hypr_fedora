#!/usr/bin/env bash
# Lua config: layout switching + per-layout binds live in ~/.config/hypr/lua/layout.lua.
# Usage: ChangeLayout.sh [toggle|next|init|master|dwindle|scrolling|monocle]
arg="${1:-toggle}"
case "$arg" in
init) exit 0 ;; # done on config load
toggle | next | master | dwindle | scrolling | monocle) exec hyprctl eval "kool_layout('$arg')" ;;
*) echo "Usage: $(basename "$0") [toggle|next|init|master|dwindle|scrolling|monocle]" >&2; exit 1 ;;
esac
