#!/usr/bin/env bash
# Integration test: real user service + journal, without restarting Hyprland.
set -euo pipefail
: "${XDG_RUNTIME_DIR:?Run inside a user systemd session}"
root=$(cd "$(dirname "$0")/.." && pwd)
export HYPRLAND_INSTANCE_SIGNATURE=logtest_$$_$RANDOM
instance=$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE
unit=hyprland-log-$HYPRLAND_INSTANCE_SIGNATURE.service
mkdir -p "$instance"
sleep 30 &
compositor_pid=$!
cleanup() {
    kill "$compositor_pid" 2>/dev/null || true
    wait "$compositor_pid" 2>/dev/null || true
    systemctl --user stop "$unit" 2>/dev/null || true
    rm -rf "$instance"
}
trap cleanup EXIT
printf '%s\nwayland-test\n' "$compositor_pid" > "$instance/hyprland.lock"
printf 'startup-test\n' > "$instance/hyprland.log"

"$root/hypr-lua/scripts/hyprland-log"
"$root/hypr-lua/scripts/hyprland-log"
printf 'final-crash-test\n' >> "$instance/hyprland.log"
kill "$compositor_pid"
wait "$compositor_pid" 2>/dev/null || true

for ((attempt=0; attempt<50; attempt++)); do
    output=$(journalctl --user -u "$unit" -o cat --no-pager -q)
    if [[ $output == *final-crash-test* ]] && ! systemctl --user is-active --quiet "$unit"; then
        [[ $(printf '%s\n' "$output" | grep -cx startup-test) == 1 ]]
        [[ $(printf '%s\n' "$output" | grep -cx final-crash-test) == 1 ]]
        echo "PASS: startup and final lines preserved once; follower exited after compositor"
        exit 0
    fi
    sleep 0.1
done
echo "FAIL: missing journal lines or follower did not exit" >&2
printf '%s\n' "$output" >&2
exit 1
