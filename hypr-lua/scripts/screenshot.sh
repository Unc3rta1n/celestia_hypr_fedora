#!/usr/bin/env bash
# Non-area screenshots, same flow as the caelestia area picker (patches/0003):
# save to ~/Pictures/Screenshots + copy to clipboard, notification click opens swappy. No sound.
#   screenshot.sh now        focused monitor
#   screenshot.sh in N       focused monitor after N seconds (open a panel/menu meanwhile)
#   screenshot.sh active     active window
# (replaces KoolDots ScreenShot.sh --now/--in5/--in10/--active)
set -uo pipefail

DIR=$HOME/Pictures/Screenshots
FILE=$DIR/$(date +%Y-%m-%d_%H-%M-%S).png
mkdir -p "$DIR"

monitor() { hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'; }

case ${1:-} in
now) grim -o "$(monitor)" "$FILE" ;;
in)
    secs=${2:-5}
    for ((i = secs; i > 0; i--)); do
        notify-send -e -u low -t 900 -h string:x-canonical-private-synchronous:shot "Screenshot in $i s"
        sleep 1
    done
    sleep 0.3 # let the countdown toast fade out of the frame
    grim -o "$(monitor)" "$FILE"
    ;;
active)
    geom=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
    grim -g "$geom" "$FILE"
    ;;
*) sed -n '4,7p' "$0" >&2; exit 1 ;;
esac || { notify-send -u critical "Screenshot failed"; exit 1; }

wl-copy --type image/png <"$FILE"
action=$(notify-send -a caelestia-cli -i "$FILE" -A edit=Edit "Screenshot taken" "Copied to clipboard. Click to edit")
[[ $action == edit ]] && exec swappy -f "$FILE"
