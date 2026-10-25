#!/usr/bin/env bash
# Clipboard history (cliphist) in fuzzel at the bottom of the screen with image previews,
# then pastes into the focused window. Ctrl+Del deletes an entry, Alt+Del wipes history.
# (port of KoolDots ClipManager.sh from rofi)
CONF=$HOME/.config/fuzzel/clipboard.ini
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-img
mkdir -p "$CACHE"

pkill -x fuzzel && exit 0

build_list() {
    cliphist list | while IFS=$'\t' read -r id content; do
        if [[ $content =~ ^\[\[\ binary\ data.*(png|jpe?g|webp|bmp) ]]; then
            img=$CACHE/$id.png
            [[ -s $img ]] || cliphist decode "$id" >"$img" 2>/dev/null
            printf '%s\t🖼  %s\0icon\x1f%s\n' "$id" "$(sed "s/^\[\[ binary data //; s/ \]\]$//" <<<"$content")" "$img"
        else
            printf '%s\t%s\n' "$id" "$content"
        fi
    done
}

paste() {
    local class
    class=$(hyprctl activewindow -j | jq -r '.class // ""' | tr '[:upper:]' '[:lower:]')
    case $class in
    *kitty* | *alacritty* | *foot* | *wezterm* | *ghostty* | *konsole* | *terminal* | *xterm*)
        hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "V" })' ;;
    *) hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL", key = "V" })' ;;
    esac >/dev/null
}

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
