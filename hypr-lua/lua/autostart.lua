-- hyprland.conf exec-once + configs/Startup_Apps.conf
-- Removed (replaced by caelestia shell): waybar, swaync, WallpaperDaemon.sh (swww)
local v = require("lua.vars")

hl.on("hyprland.start", function()
    -- Initial boot (no-op while ~/.config/hypr/.initial_startup_done exists)
    hl.exec_cmd(v.hyprDir .. "/initial-boot.sh")

    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd(v.scriptsDir .. "/PortalHyprland.sh")

    hl.exec_cmd(v.scriptsDir .. "/Polkit.sh")

    -- Shell: bar, notifications, launcher, OSD, session menu, wallpaper
    hl.exec_cmd(v.caelestia)
    -- lock on login like KoolDots did with `exec-once = hyprlock`, now with the caelestia lockscreen
    hl.exec_cmd("sleep 3 && qs -c caelestia ipc call lock lock")
    -- Workspace overview (~/.config/quickshell/overview, Shanu-Kumawat/quickshell-overview)
    hl.exec_cmd("qs -c overview")

    -- Tray applets (shown in caelestia bar tray)
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")

    -- idle/lock: caelestia (general.idle in ~/.config/caelestia/shell.json) replaces hypridle + hyprlock
    hl.exec_cmd(v.scriptsDir .. "/Hyprsunset.sh init")
    -- charger plug/unplug -> battery saver (lua/power.lua) + power profile
    hl.exec_cmd(v.scriptsDir .. "/power-watch")
    -- synced lyrics from Musixmatch & co. into ~/Music/Lyrics for the media panel
    hl.exec_cmd(v.scriptsDir .. "/lyrics-fetch")

    -- Clipboard history (caelestia clipboard reads cliphist)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
