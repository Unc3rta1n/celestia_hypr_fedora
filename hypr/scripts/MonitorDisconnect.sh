#!/bin/bash
# ==================================================
# Monitor disconnect handler
# Run via exec-once in hyprland:
#   exec-once = ~/.config/hypr/scripts/MonitorDisconnect.sh
# ==================================================

SOCKET2="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

[[ -S "$SOCKET2" ]] || { echo "Error: Hyprland socket not found." >&2; exit 1; }

socat -u UNIX-CONNECT:"$SOCKET2" - | while read -r line; do
  if [[ "$line" =~ ^monitorremoved ]]; then
    removed_monitor="${line#monitorremoved>>}"
    
    # Find the remaining active monitor
    remaining=$(hyprctl monitors -j | jq -r '.[0].name')
    
    echo "Monitor $removed_monitor disconnected, moving workspaces to $remaining"
    
    # Get all workspaces that were on the removed monitor
    # Move all workspaces to the remaining monitor
    hyprctl workspaces -j | jq -r '.[] | select(.monitor == "'"$removed_monitor"'") | .id' | while read -r wsid; do
      hyprctl dispatch moveworkspacetomonitor "$wsid" "$remaining"
    done
  fi
done
