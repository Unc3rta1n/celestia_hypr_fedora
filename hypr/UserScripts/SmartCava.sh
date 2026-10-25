#!/bin/bash
PLAYING=0
LAST_CHECK=0

"$HOME/.config/hypr/scripts/WaybarCava.sh" | while IFS= read -r line; do
    NOW=$SECONDS
    if (( NOW - LAST_CHECK >= 1 )); then
        [[ $(pactl list short sink-inputs 2>/dev/null | wc -l) -gt 0 ]] && PLAYING=1 || PLAYING=0
        LAST_CHECK=$NOW
    fi
    (( PLAYING )) && echo "$line" || echo ""
done
