-- Hyprland Lua config (migrated from KoolDots hyprland.conf, 2026-10-25)
-- Old hyprlang files (*.conf, configs/, UserConfigs/) are kept for rollback:
-- delete/rename this file and Hyprland falls back to hyprland.conf.
-- Each require() runs in its own scope: an error in one module doesn't stop the others.

require("lua.env")
require("lua.settings")
require("lua.decorations")
require("lua.animations")
require("lua.power")    -- after look & feel: battery overrides
require("lua.windowrules")
require("lua.keybinds")
require("lua.layout")   -- after keybinds: per-layout SUPER+J/K/O/arrows
require("lua.autostart")

-- nwg-displays output (it writes monitors.lua / workspaces.lua itself)
require("monitors")
require("workspaces")

-- Local overrides that should survive updates
pcall(require, "lua.user")
