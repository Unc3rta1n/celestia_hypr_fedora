-- hyprland.conf exec-once + configs/Startup_Apps.conf
-- Removed (replaced by caelestia shell): waybar, swaync, WallpaperDaemon.sh (swww)
local v = require("lua.vars")

hl.on("hyprland.start", function()
    -- Preserve the compositor log across crashes and reboots.
    hl.exec_cmd(v.scriptsDir .. "/hyprland-log")

    -- Initial boot (no-op while ~/.config/hypr/.initial_startup_done exists)
    hl.exec_cmd(v.hyprDir .. "/initial-boot.sh")

    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd(v.scriptsDir .. "/PortalHyprland.sh")

    hl.exec_cmd(v.scriptsDir .. "/Polkit.sh")

    -- Restore the saved cursor without opening its window; keep one host for launcher IPC.
    hl.exec_cmd('test ! -x "$HOME/cursor-theme-manager/cursor-theme-manager" || "$HOME/cursor-theme-manager/cursor-theme-manager" --daemon')

    -- Finish the PAM-started keyring before the lockscreen tries to unlock it.
    -- Keep the shell available even if keyring initialization fails; report the failure.
    local keyring = "gnome-keyring-daemon --start --components=secrets"
        .. " || logger -t hyprland 'GNOME Keyring initialization failed'; "
    -- Shell: bar, notifications, launcher, OSD, session menu, wallpaper
    -- lock on login like KoolDots did with `exec-once = hyprlock`, now with the caelestia lockscreen
    hl.exec_cmd(keyring .. v.caelestia .. " && sleep 3 && qs -c caelestia ipc call lock lock")
    -- Workspace overview (~/.config/quickshell/overview, Shanu-Kumawat/quickshell-overview)
    hl.exec_cmd("qs -c overview")

    -- Tray applets (shown in caelestia bar tray)
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")

    -- idle/lock: caelestia (general.idle in ~/.config/caelestia/shell.json) replaces hypridle + hyprlock
    -- night light follows the sun (Hyprsunset.sh on at sunset / off at sunrise; Super+N still overrides)
    hl.exec_cmd(v.scriptsDir .. "/nightlight-schedule")
    -- charger plug/unplug -> battery saver (lua/power.lua) + power profile
    hl.exec_cmd(v.scriptsDir .. "/power-watch")
    -- suspend: NVIDIA (HDMI) monitors off before sleep, back after resume (resume froze otherwise)
    hl.exec_cmd(v.scriptsDir .. "/sleep-watch")

    -- KDE Connect tray icon only while a phone is connected
    hl.exec_cmd(v.scriptsDir .. "/kdeconnect-watch")

    -- Steam games: gamemode + "games" tag (tearing) without per-game Launch Options
    hl.exec_cmd(v.scriptsDir .. "/steam-game-watch")

    -- Clipboard history (caelestia clipboard reads cliphist)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    -- keep the clipboard alive after the app that copied it closes. Skip events that offer image/*:
    -- Telegram offers ~35 image formats and encodes each lazily on its main thread, so persisting them froze it
    -- (the regex matches every MIME type that does not start with "image/")
    hl.exec_cmd([[wl-clip-persist --clipboard regular --all-mime-type-regex '^([^i]|i([^m]|m([^a]|a([^g]|g([^e]|e[^/])))))' 2>/dev/null || ~/.cargo/bin/wl-clip-persist --clipboard regular --all-mime-type-regex '^([^i]|i([^m]|m([^a]|a([^g]|g([^e]|e[^/])))))']])
    -- automount USB drives with a notification (no tray icon)
    hl.exec_cmd("command -v udiskie >/dev/null && udiskie --automount --notify --no-tray")
end)
