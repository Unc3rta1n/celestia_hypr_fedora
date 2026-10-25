#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Clipboard Manager: cliphist + rofi + wl-copy + hyprctl
# Зависимости: cliphist, rofi, wl-clipboard, jq

# Variables
rofi_theme="$HOME/.config/rofi/config-clipboard.rasi"
msg='👀 **note**  CTRL DEL = cliphist del (entry)   or   ALT DEL - cliphist wipe (all)'
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-img"
mkdir -p "$CACHE_DIR"

# Build list with image previews
build_list() {
    cliphist list | while IFS=$'\t' read -r id content; do
        if [[ "$content" =~ \[\[\ binary\ data.*png ]] || \
           [[ "$content" =~ \[\[\ binary\ data.*jpg ]] || \
           [[ "$content" =~ \[\[\ binary\ data.*jpeg ]]; then
            img="$CACHE_DIR/${id}.png"
            if [[ ! -f "$img" ]]; then
                cliphist decode "$id" > "$img" 2>/dev/null
            fi
            printf '%s\t🖼 [image]\0icon\x1f%s\n' "$id" "$img"
        else
            printf '%s\t%s\n' "$id" "$content"
        fi
    done
}

# Вставка в активное окно: терминалам — Ctrl+Shift+V, остальным — Ctrl+V
paste_to_window() {
    local class
    class=$(hyprctl activewindow -j | jq -r '.class' | tr '[:upper:]' '[:lower:]')
    case "$class" in
        *kitty*|*alacritty*|*foot*|*wezterm*|*ghostty*|*konsole*|*gnome-terminal*|*terminal*|*xterm*|*urxvt*|*st-256color*)
            hyprctl dispatch sendshortcut "CTRL SHIFT, V, activewindow"
            ;;
        *)
            hyprctl dispatch sendshortcut "CTRL, V, activewindow"
            ;;
    esac
}

# Check if rofi is already running
if pidof rofi > /dev/null; then
    pkill rofi
    exit
fi

while true; do
    result=$(
        build_list | rofi -i -dmenu \
            -kb-custom-1 "Control-Delete" \
            -kb-custom-2 "Alt-Delete" \
            -config "$rofi_theme" \
            -show-icons \
            -mesg "$msg"
    )
    case "$?" in
        1)
            exit
            ;;
        0)
            case "$result" in
                "")
                    continue
                    ;;
                *)
                    id=$(cut -f1 <<< "$result")
                    # Копируем в clipboard и primary (на случай Shift+Insert)
                    cliphist decode "$id" | wl-copy
                    cliphist decode "$id" | wl-copy --primary
                    # Ждём, пока rofi закроется и фокус вернётся в окно
                    sleep 0.10
                    paste_to_window
                    exit
                    ;;
            esac
            ;;
        10)
            cliphist delete <<< "$result"
            ;;
        11)
            cliphist wipe
            rm -f "$CACHE_DIR"/*.png
            ;;
    esac
done
