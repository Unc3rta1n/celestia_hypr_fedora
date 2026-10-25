-- Shared variables (was $vars spread across KoolDots .conf files)
local HOME = os.getenv("HOME")

local M = {
    HOME        = HOME,
    mainMod     = "SUPER",
    hyprDir     = HOME .. "/.config/hypr",
    scriptsDir  = HOME .. "/.config/hypr/scripts",
    UserScripts = HOME .. "/.config/hypr/UserScripts",

    -- UserConfigs/01-UserDefaults.conf
    term         = "ghostty",
    files        = "dolphin",
    tuiFiles     = "ghostty +new-window --title=yazi -e yazi", -- +new-window: single-instance ghostty ignores plain CLI flags
    edit         = os.getenv("EDITOR") or "nano",
    searchEngine = "https://www.google.com/search?q={}",

    wallDIR = HOME .. "/Pictures/wallpapers",

    -- caelestia shell; QT_QUICK_CONTROLS_STYLE / kvantum override would restyle its QML controls
    caelestia        = "env -u QT_QUICK_CONTROLS_STYLE -u QT_STYLE_OVERRIDE caelestia shell -d",
    caelestiaRestart = "qs -c caelestia kill; sleep .2; env -u QT_QUICK_CONTROLS_STYLE -u QT_STYLE_OVERRIDE caelestia shell -d",

    touchpadDevice = "syn1b8b:00-06cb:ce7d-touchpad",
}

return M
