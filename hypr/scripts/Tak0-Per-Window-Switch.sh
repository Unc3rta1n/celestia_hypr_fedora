#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# TAK_0's Per-Window-Switch (fixed)
# Usage:
#   Tak0-Per-Window-Switch.sh toggle   — toggle layout for current window (bind this to hotkey)
#   Tak0-Per-Window-Switch.sh listener — start focus listener (exec-once in hyprland)

MAP_FILE="$HOME/.cache/kb_layout_per_window"
USER_CFG="$HOME/.config/hypr/UserConfigs/UserSettings.conf"
SYS_CFG="$HOME/.config/hypr/configs/SystemSettings.conf"
ICON="$HOME/.config/swaync/images/ja.png"

# Ignore non-keyboard devices
ignore_patterns=(
  "power-button"
  "video-bus"
  "sleep-button"
  "consumer-control"
  "system-control"
  "avrcp"
  "logitech-g304"
  "cmf-buds"
)

touch "$MAP_FILE"

# Read layouts from config
if grep -q 'kb_layout' "$USER_CFG" 2>/dev/null; then
  CFG_FILE="$USER_CFG"
elif grep -q 'kb_layout' "$SYS_CFG" 2>/dev/null; then
  CFG_FILE="$SYS_CFG"
else
  echo "Error: cannot find kb_layout" >&2
  exit 1
fi

kb_layouts=($(grep 'kb_layout' "$CFG_FILE" | cut -d '=' -f2 | tr -d '[:space:]' | tr ',' ' '))
count=${#kb_layouts[@]}

get_win() {
  hyprctl activewindow -j | jq -r '.address // .id'
}

is_ignored() {
  local name=$1
  for pattern in "${ignore_patterns[@]}"; do
    [[ "$name" == *"$pattern"* ]] && return 0
  done
  return 1
}

get_keyboards() {
  hyprctl devices -j | jq -r '.keyboards[].name' | while read -r name; do
    is_ignored "$name" || echo "$name"
  done
}

save_map() {
  local W=$1 L=$2
  grep -v "^${W}:" "$MAP_FILE" >"$MAP_FILE.tmp"
  echo "${W}:${L}" >>"$MAP_FILE.tmp"
  mv "$MAP_FILE.tmp" "$MAP_FILE"
}

load_map() {
  local W=$1
  local E
  E=$(grep "^${W}:" "$MAP_FILE")
  [[ -n "$E" ]] && echo "${E#*:}" || echo "${kb_layouts[0]}"
}

do_switch() {
  local IDX=$1
  for kb in $(get_keyboards); do
    hyprctl switchxkblayout "$kb" "$IDX" 2>/dev/null
  done
}

cmd_toggle() {
  local W=$(get_win)
  [[ -z "$W" ]] && return
  local CUR=$(load_map "$W")
  local i=0
  for idx in "${!kb_layouts[@]}"; do
    if [[ "${kb_layouts[idx]}" == "$CUR" ]]; then
      i=$idx
      break
    fi
  done
  local NEXT=$(((i + 1) % count))
  do_switch "$NEXT"
  save_map "$W" "${kb_layouts[NEXT]}"
  notify-send -u low -t 1000 -i "$ICON" "kb_layout: ${kb_layouts[NEXT]}" -h string:x-canonical-private-synchronous:kb_layout -h string:x-swaync-skip-history:true
}
cmd_restore() {
  local W=$(get_win)
  [[ -z "$W" ]] && return
  local LAY=$(load_map "$W")
  for idx in "${!kb_layouts[@]}"; do
    if [[ "${kb_layouts[idx]}" == "$LAY" ]]; then
      do_switch "$idx"
      break
    fi
  done
}

cmd_listener() {
  local SOCKET2="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
  [[ -S "$SOCKET2" ]] || {
    echo "Error: Hyprland socket not found." >&2
    exit 1
  }
  socat -u UNIX-CONNECT:"$SOCKET2" - | while read -r line; do
    [[ "$line" =~ ^activewindow ]] && cmd_restore
  done
}

case "$1" in
toggle | "") cmd_toggle ;;
listener) cmd_listener ;;
*)
  echo "Usage: $0 [toggle|listener]" >&2
  exit 1
  ;;
esac
