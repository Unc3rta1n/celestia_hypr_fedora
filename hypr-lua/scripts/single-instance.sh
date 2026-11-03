# Sourced by the bash watchers started from lua/autostart.lua: kill older copies of the calling
# script together with everything they started (gdbus/udevadm monitors, systemd-inhibit, ...).
# After a Hyprland crash start-hyprland restarts it and autostart runs again, while the old copy
# keeps running against the dead instance (sleep-watch: hyprctl rc=4, every log line twice).
# The watchers share Hyprland's process group, so walk the tree instead of killing the group.
kill_tree() {
    local c
    for c in $(pgrep -P "$1"); do kill_tree "$c"; done
    kill "$1" 2>/dev/null
}
for pid in $(pgrep -f "scripts/${0##*/}\$"); do
    ((pid != $$)) && kill_tree "$pid"
done
unset -f kill_tree
