#!/usr/bin/env bash
# Clipboard history (cliphist) in fuzzel at the bottom of the screen with image previews,
# then pastes into the focused window. Ctrl+Del deletes an entry, Alt+Del wipes history.
# (port of the KoolDots rofi ClipManager.sh)
CONF=$HOME/.config/fuzzel/clipboard.ini
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-img
mkdir -p "$CACHE"

if [[ ${1:-} != --* ]]; then
    pkill -x fuzzel && exit 0
fi

build_list() {
    cliphist list | while IFS=$'\t' read -r id content; do
        if [[ $content =~ ^\[\[\ binary\ data.*(png|jpe?g|webp|bmp) ]]; then
            img=$CACHE/$id.png
            [[ -s $img ]] || cliphist decode "$id" >"$img" 2>/dev/null
            content=${content#"[[ binary data "}
            content=${content%" ]]"}
            printf '%s\t🖼  %s\0icon\x1f%s\n' "$id" "$content" "$img"
        else
            printf '%s\t%s\n' "$id" "$content"
        fi
    done
}

# The window to paste into, taken before fuzzel opens: after it closes, focus may not be back yet,
# and a shortcut sent "to the active window" then went nowhere (paste worked only every other time).
read -r win class < <(hyprctl activewindow -j | jq -r '"\(.address // "") \(.class // "" | ascii_downcase)"')

paste() {
    [[ -n $win ]] || return
    hyprctl dispatch "hl.dsp.focus({ window = \"address:$win\" })" >/dev/null
    local i
    for i in {1..10}; do
        [[ $(hyprctl activewindow -j | jq -r '.address // ""') == "$win" ]] && break
        sleep 0.05
    done
    # Images: Ctrl+V everywhere (in a terminal it reaches the app: Claude Code attaches the image).
    # Text: Ctrl+Shift+V in terminals and VS Code (its terminal pastes with it, and the editor does
    # too via a keybinding in ~/.config/Code/User/keybindings.json), Ctrl+V elsewhere.
    local mods=CTRL
    if ! wl-paste -l 2>/dev/null | grep -q '^image/'; then
        case $class in
        *kitty* | *alacritty* | *foot* | *wezterm* | *ghostty* | *konsole* | *terminal* | *xterm* | *vscode*)
            mods="CTRL SHIFT" ;;
        esac
    fi
    # V by keycode: a key name is looked up in the active layout, and Russian has no "V"
    hyprctl dispatch "hl.dsp.send_shortcut({ mods = \"$mods\", key = \"code:55\" })" >/dev/null
}

case ${1:-} in
--list)
    window=$(hyprctl activewindow -j)
    entries=$(build_list | tr '\0' '\n' | awk -F '\t' 'NF >= 2 && $1 ~ /^[0-9]+$/ { print $1 "\t" $2 }' | jq -Rsc 'split("\n") | map(select(length > 0) | split("\t") | {id: .[0], label: .[1]})')
    jq -nc --argjson window "$window" --argjson entries "$entries" '{window: $window, entries: $entries}'
    exit ;;
--paste)
    win=$3 class=$4
    cliphist decode "$2" | wl-copy || exit 1
    sleep 0.1
    paste
    exit ;;
--delete)
    cliphist list | awk -F '\t' -v id="$2" '$1 == id' | cliphist delete
    rm -f "$CACHE/$2.png"
    exit ;;
--wipe)
    cliphist wipe
    rm -f "$CACHE"/*.png
    exit ;;
esac

while :; do
    sel=$(build_list | fuzzel --dmenu --config "$CONF" --with-nth=2 --accept-nth=1 --counter)
    case $? in
    0)
        [[ -n $sel ]] || exit 0
        cliphist decode "$sel" | wl-copy
        sleep 0.1
        paste
        exit 0 ;;
    10) # Ctrl+Del
        [[ -n $sel ]] && cliphist list | awk -F'\t' -v id="$sel" '$1 == id' | cliphist delete
        rm -f "$CACHE/$sel.png" ;;
    11) # Alt+Del
        cliphist wipe
        rm -f "$CACHE"/*.png
        exit 0 ;;
    *) exit 0 ;;
    esac
done
