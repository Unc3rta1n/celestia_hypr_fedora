-- Hyprland Lua config (migrated from KoolDots hyprland.conf, 2026-10-25)
-- Old hyprlang files (hyprland.conf, configs/, most of UserConfigs/) are deleted; the rollback copy is
-- ~/hypr-backup-2026-10-25.tar.gz and hypr/ in this repo.
-- Each require() runs in its own scope: an error in one module doesn't stop the others.

require("lua.env")
require("lua.settings")
require("lua.decorations")
require("lua.animations")
require("lua.power")    -- after look & feel: battery overrides
require("lua.windowrules")
require("lua.keybinds")
require("lua.layout")   -- dwindle; SUPER+arrows
require("lua.autostart")
require("lua.screenshare_dnd") -- do not disturb while the screen is shared

-- nwg-displays output (it writes monitors.lua / workspaces.lua itself)
require("monitors")
require("lua.workspace_home") -- before workspaces: reads its rules, moves workspaces back on replug
require("workspaces")

-- Local overrides that should survive updates
pcall(require, "lua.user")
