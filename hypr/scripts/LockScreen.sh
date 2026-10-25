#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================

setsid bash "$HOME/.config/hypr/UserScripts/WeatherWrap.sh" >/dev/null 2>&1 < /dev/null &
disown

for m in $(hyprctl monitors -j | jq -r '.[].name'); do
    grim -l 0 -o "$m" "/tmp/hyprlock_${m}.png" &
done
wait

loginctl lock-session
