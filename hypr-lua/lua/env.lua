-- configs/ENVariables.conf + UserConfigs/ENVariables.conf

-- ~/.local/bin (caelestia CLI from `uv tool`) is not in the session PATH; the shell itself calls `caelestia`
local HOME = os.getenv("HOME")
local PATH = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
if not PATH:find(HOME .. "/.local/bin", 1, true) then
    hl.env("PATH", HOME .. "/.local/bin:" .. PATH)
end
hl.env("DOTS_VERSION", "2.3.23")

-- Toolkit backends
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("CLUTTER_BACKEND", "wayland")

-- XDG specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- QT
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("QT_QUICK_CONTROLS_STYLE", "org.hyprland.style")

-- Scaling
hl.env("GDK_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "1")

-- Cursor
hl.env("HYPRCURSOR_THEME", "gruvbox-light")
hl.env("HYPRCURSOR_SIZE", "28")
-- XCursor fallback (XWayland/Electron/GTK): same theme, rebuilt by hyprcursor2xcursor.py
hl.env("XCURSOR_THEME", "gruvbox-light")
hl.env("XCURSOR_SIZE", "28")

-- Apps
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- GPU
hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("GSK_RENDERER", "ngl")
hl.env("__GL_GSYNC_ALLOWED", "0")

-- User
hl.env("VMWARE_USE_SHIPPED_LIBS", "1")

-- SSH passwords from GNOME Keyring (ssh-menu, Super+C, execs ssh directly
-- via ghostty -e, bypassing zsh/extras.zsh -- must be set compositor-wide)
hl.env("SSH_ASKPASS", HOME .. "/.local/bin/ssh-askpass-keyring")
hl.env("SSH_ASKPASS_REQUIRE", "force")
