#!/usr/bin/env bash
prev=""
socat - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
  if [[ "$line" == "activelayout>>at-translated-set-2-keyboard,"* ]]; then
    layout="${line#activelayout>>at-translated-set-2-keyboard,}"
    if [[ "$layout" != "$prev" ]]; then
      notify-send -u low -t 2000 "Раскладка" "$layout"
      prev="$layout"
    fi
  fi
done
