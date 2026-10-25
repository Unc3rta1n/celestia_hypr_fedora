-- configs/Keybinds.conf + configs/Laptops.conf + UserConfigs/UserKeybinds.conf
-- Same keys as before. Waybar / rofi / wofi / swaync / wlogout / swww actions now go to caelestia shell.
-- Keys use keycodes (code:NN) where the original did — works on both us and ru layouts.
-- SUPER+J/K/O and SUPER+arrows are bound per layout in lua/layout.lua (like ChangeLayout.sh did).
local v    = require("lua.vars")
local util = require("lua.util")

local mod = v.mainMod
local S   = v.scriptsDir
local U   = v.UserScripts

-- every bind gets "Category|KEYS|description" for the cheat sheet (menus.sh keys):
-- hyprctl reports neither key nor keycode for code:NN binds, so the readable keys travel along
local category = "Other"
local function section(name) category = name end

local KEYCODES = { [49] = "`" }
for i, k in ipairs({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }) do KEYCODES[9 + i] = k end
for row, first in pairs({ QWERTYUIOP = 24, ASDFGHJKL = 38, ZXCVBNM = 52 }) do
    for i = 1, #row do KEYCODES[first + i - 1] = row:sub(i, i) end
end
local function pretty(keys)
    return (keys:gsub("code:(%d+)", function(c) return KEYCODES[tonumber(c)] or ("code:" .. c) end))
end

local function bind(keys, dsp, desc, flags)
    local opts = {}
    if flags then for k, val in pairs(flags) do opts[k] = val end end
    opts.description = category .. "|" .. pretty(keys) .. "|" .. desc
    return hl.bind(keys, dsp, opts)
end

local function exec(cmd) return hl.dsp.exec_cmd(cmd) end
local function M(keys) return mod .. " + " .. keys end

-- direct IPC (skips the python `caelestia shell` wrapper)
local function shell(cmd) return exec("qs -c caelestia ipc call " .. cmd) end
local function global(name) return hl.dsp.global("caelestia:" .. name) end

-- Launcher with prefilled search (patches/0002); plain launcher if the shell isn't patched yet
local function launcher_with(text)
    local ipc = "qs -c caelestia ipc "
    return exec(string.format(
        "%sshow | grep -q openLauncher && %scall drawers openLauncher '%s' || %scall drawers toggle launcher",
        ipc, ipc, text, ipc))
end

local locked           = { locked = true }
local repeating        = { repeating = true }
local locked_repeating = { locked = true, repeating = true }

---------------------------------------------------------------- STANDARD
section("Apps")
-- global "caelestia:launcher" toggles on key *release*, which a normal bind never delivers -> use IPC.
-- caelestia ignores its launcher while a fullscreen window is focused (its panels sit under it),
-- so fall back to fuzzel there (overlay layer, drawn above fullscreen).
bind(M("SPACE"), function()
    local w = hl.get_active_window()
    if w and w.fullscreen == 2 then
        hl.dispatch(exec("pkill -x fuzzel || fuzzel"))
    else
        hl.dispatch(shell("drawers toggle launcher"))
    end
end, "app launcher (caelestia; fuzzel in fullscreen)")                    -- was rofi drun
bind(M("Return"), exec(v.term), "Open terminal")
bind(M("code:26"), exec(v.files), "file manager")                                   -- E
bind(M("SHIFT + code:26"), exec(v.tuiFiles), "file manager (yazi)")                 -- E
bind(M("code:54"), exec(S .. "/menus.sh ssh"), "SSH session manager (ghostty)")         -- C

---------------------------------------------------------------- FEATURES / EXTRAS
section("Tools")
bind(M("code:28"), launcher_with(">scheme "), "colour scheme switcher (caelestia)") -- T, was wallust ThemeChanger
bind(M("ALT + code:27"), exec(v.caelestiaRestart), "restart shell (caelestia)")    -- R, was Refresh.sh (waybar/swaync)
bind(M("ALT + code:26"), exec("pkill fuzzel || caelestia emoji -p"), "emoji menu") -- E, was RofiEmoji
bind(M("ALT + code:32"), function()                                                 -- O, was ChangeBlur.sh
    local passes = tonumber(hl.get_config("decoration.blur.passes")) or 2
    if passes == 2 then
        hl.config({ decoration = { blur = { size = 2, passes = 1 } } })
        util.notify("Less Blur")
    else
        hl.config({ decoration = { blur = { size = 5, passes = 2 } } })
        util.notify("Normal Blur")
    end
end, "toggle blur")
bind(M("SHIFT + code:41"), shell("gameMode toggle"), "toggle game mode")            -- G
bind(M("ALT + code:46"), function() kool_layout("toggle") end, "toggle layouts")    -- L
bind(M("ALT + code:55"), exec(S .. "/clipboard.sh"), "clipboard manager (bottom, image previews)") -- V
bind(M("CTRL + code:45"), launcher_with(">scheme "), "colour scheme (caelestia; recolours ghostty too)") -- K
section("Capture")
-- caelestia area picker: per-monitor capture (slurp/grim -g broke across the rotated monitor), click snaps to a window
bind("ALT + SHIFT + code:39", global("screenshotFreezeClip"), "screenshot area (frozen) -> clipboard (click notification to edit)")              -- S, was hyprshot
bind(M("SHIFT + code:39"), global("screenshotClip"), "screenshot area -> clipboard (click notification to edit)")          -- S, was ScreenShot.sh --swappy
section("Windows")
bind(M("SHIFT + code:33"), hl.dsp.window.fullscreen({ mode = "fullscreen" }), "fullscreen")      -- F
bind(M("CTRL + code:33"), hl.dsp.window.fullscreen({ mode = "maximized" }), "maximize window")   -- F
bind(M("ALT + SPACE"), function()                                                   -- was Float-all-Windows.sh
    local ws = hl.get_active_workspace()
    if not ws then return end
    for _, w in ipairs(hl.get_workspace_windows(ws.id)) do
        hl.dispatch(hl.dsp.window.float({ action = "toggle", window = "address:" .. w.address }))
    end
end, "Float all windows")

-- Desktop zooming / magnifier
section("Windows")
bind(M("ALT + mouse_down"), util.zoom(2.0), "zoom in")
bind(M("ALT + mouse_up"), util.zoom(0.5), "zoom out")

---------------------------------------------------------------- BAR (was Waybar)
section("Shell")
bind(M("CTRL + ALT + code:56"), shell("drawers toggle bar"), "toggle bar")          -- B, was pkill -SIGUSR1 waybar
bind(M("CTRL + code:56"), global("dashboard"), "dashboard (caelestia)")             -- B, was waybar styles menu
bind(M("ALT + code:56"), global("utilities"), "utilities panel (caelestia)")        -- B, was waybar layout menu

---------------------------------------------------------------- FEATURES / EXTRAS (UserScripts)
section("Tools")
bind("CTRL + ALT + code:25", exec("caelestia wallpaper -r " .. v.wallDIR), "random wallpaper") -- W, was swww WallpaperRandom
bind(M("CTRL + code:32"), hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }), "toggle active window opacity") -- O
bind(M("ALT + code:54"), launcher_with(">calc "), "calculator (caelestia)") -- C, was RofiCalc
-- one switch for all devices; caelestia shows a single toast (KeyboardLayout.sh notified per press -> flood)
bind("Hyper_L", exec("hyprctl switchxkblayout all next"), "switch keyboard layout globally", { locked = true, non_consuming = true })

section("Workspaces")
-- Move current workspace to monitor (left right up down)
bind(M("CTRL + F9"),  hl.dsp.workspace.move({ monitor = "l" }), "move workspace to left monitor")
bind(M("CTRL + F10"), hl.dsp.workspace.move({ monitor = "r" }), "move workspace to right monitor")
bind(M("CTRL + F11"), hl.dsp.workspace.move({ monitor = "u" }), "move workspace to up monitor")
bind(M("CTRL + F12"), hl.dsp.workspace.move({ monitor = "d" }), "move workspace to down monitor")

---------------------------------------------------------------- SYSTEM
section("System")
bind("CTRL + ALT + Delete", hl.dsp.exit(), "exit Hyprland")
bind(M("code:24"), hl.dsp.window.close(), "close active window")                    -- Q
bind(M("SHIFT + code:24"), exec(S .. "/KillActiveProcess.sh"), "Terminate active process") -- Q
bind("CTRL + ALT + code:46", global("lock"), "lock screen (caelestia)")              -- L, was hyprlock
bind("CTRL + ALT + code:33", global("session"), "powermenu (caelestia)")            -- P, was wlogout

---------------------------------------------------------------- LAYOUTS
section("Layout")
-- Master
bind(M("CTRL + code:38"), hl.dsp.layout("removemaster"), "remove master")           -- D
bind(M("code:31"), hl.dsp.layout("addmaster"), "add master")                        -- I
bind(M("code:44"), hl.dsp.layout("cyclenext"), "cycle next")                        -- J
bind(M("code:45"), hl.dsp.layout("cycleprev"), "cycle previous")                    -- K
bind(M("CTRL + Return"), hl.dsp.layout("swapwithmaster"), "swap with master")
-- Dwindle
bind(M("SHIFT + code:31"), hl.dsp.layout("togglesplit"), "toggle split (dwindle)") -- I
bind(M("code:33"), hl.dsp.window.pseudo(), "toggle pseudo (dwindle)")               -- P
-- Either layout
bind(M("code:58"), hl.dsp.layout("splitratio 0.3"), "set split ratio 0.3")          -- M
-- Direct layout binds
bind(M("ALT + 1"), function() kool_layout("dwindle") end, "layout dwindle")
bind(M("ALT + 2"), function() kool_layout("master") end, "layout master")
bind(M("ALT + 3"), function() kool_layout("scrolling") end, "layout scrolling")
bind(M("ALT + 4"), function() kool_layout("monocle") end, "layout monocle")
-- Scrolling
bind(M("SHIFT + period"), hl.dsp.layout("move +col"), "move to right column")
bind(M("SHIFT + comma"), hl.dsp.layout("move -col"), "move to left column")
bind(M("ALT + comma"), hl.dsp.layout("swapcol l"), "swap columns left")
bind(M("ALT + period"), hl.dsp.layout("swapcol r"), "swap columns right")
bind(M("ALT + code:43"), function() hl.config({ scrolling = { direction = "right" } }) end, "Horizonal scroll right") -- H
bind(M("ALT + code:39"), function()                                                 -- S
    local dir = hl.get_config("scrolling.direction")
    hl.config({ scrolling = { direction = dir == "right" and "down" or "right" } })
end, "toggle scrolling V/H")

-- Cycle windows; if floating bring to top
bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end, "cycle next window")

---------------------------------------------------------------- SPECIAL KEYS
section("Media")
-- Volume (caelestia OSD shows level; was Volume.sh + swaync notification)
local sink, source = "@DEFAULT_AUDIO_SINK@", "@DEFAULT_AUDIO_SOURCE@"
bind("XF86AudioRaiseVolume", exec("wpctl set-mute " .. sink .. " 0; wpctl set-volume -l 1.0 " .. sink .. " 5%+"), "volume up", locked_repeating)
bind("XF86AudioLowerVolume", exec("wpctl set-mute " .. sink .. " 0; wpctl set-volume " .. sink .. " 5%-"), "volume down", locked_repeating)
bind("ALT + XF86AudioRaiseVolume", exec("wpctl set-volume -l 1.0 " .. sink .. " 1%+"), "volume up precise", locked_repeating)
bind("ALT + XF86AudioLowerVolume", exec("wpctl set-volume " .. sink .. " 1%-"), "volume down precise", locked_repeating)
bind("XF86AudioMicMute", exec("wpctl set-mute " .. source .. " toggle"), "toggle mic mute", locked)
bind("XF86AudioMute", exec("wpctl set-mute " .. sink .. " toggle"), "toggle mute", locked)
bind("XF86Sleep", exec("systemctl suspend"), "sleep", locked)
bind("XF86Rfkill", exec(S .. "/AirplaneMode.sh"), "airplane mode", locked)

-- Media
bind("XF86AudioPause", global("mediaToggle"), "pause", locked)
bind("XF86AudioPlay", global("mediaToggle"), "play", locked)
bind("XF86AudioNext", global("mediaNext"), "next track", locked)
bind("XF86AudioPrev", global("mediaPrev"), "previous track", locked)
bind("XF86AudioStop", global("mediaStop"), "stop", locked)

-- Screenshot
section("Capture")
bind(M("Print"), exec(S .. "/screenshot.sh now"), "screenshot now")
bind(M("SHIFT + Print"), global("screenshotFreezeClip"), "screenshot area (frozen) -> clipboard")
bind(M("CTRL + Print"), exec(S .. "/screenshot.sh in 5"), "screenshot in 5s")
bind(M("CTRL + SHIFT + Print"), exec(S .. "/screenshot.sh in 10"), "screenshot in 10s")
bind("ALT + Print", exec(S .. "/screenshot.sh active"), "screenshot active window")
-- OCR: caelestia picker (patches/0007) -> tesseract rus+eng -> clipboard
bind(M("SHIFT + code:28"), global("ocr"), "OCR area -> clipboard (text)")                          -- T
-- Screen recording via the shell (patches/0008: keeps the bar indicator's timer/pause in sync);
-- same key again stops; saved to ~/Videos/Recordings, path copied (paste = attach file)
bind(M("SHIFT + code:27"), shell("recorder toggle area"), "record area (again = stop)")         -- R
bind(M("CTRL + code:27"), shell("recorder toggle monitorSound"), "record monitor + sound (again = stop)") -- R
bind(M("CTRL + SHIFT + code:27"), shell("recorder pause"), "pause/resume recording")              -- R

---------------------------------------------------------------- WINDOWS
section("Windows")
-- Resize
bind(M("SHIFT + left"),  hl.dsp.window.resize({ x = -50, y = 0, relative = true }), "resize left (-50)", repeating)
bind(M("SHIFT + right"), hl.dsp.window.resize({ x = 50, y = 0, relative = true }), "resize right (+50)", repeating)
bind(M("SHIFT + up"),    hl.dsp.window.resize({ x = 0, y = -50, relative = true }), "resize up (-50)", repeating)
bind(M("SHIFT + down"),  hl.dsp.window.resize({ x = 0, y = 50, relative = true }), "resize down (+50)", repeating)
-- Move / swap
for _, d in ipairs({ "left", "right", "up", "down" }) do
    bind(M("CTRL + " .. d), hl.dsp.window.move({ direction = d }), "move window " .. d)
    bind(M("ALT + " .. d), hl.dsp.window.swap({ direction = d }), "swap window " .. d)
end

-- Groups
bind(M("code:41"), hl.dsp.group.toggle(), "toggle group")                           -- G
bind(M("CTRL + Tab"), hl.dsp.group.next(), "change active in group")
bind(M("CTRL + code:46"), hl.dsp.window.move({ into_group = "right" }), "Move Right into group") -- L
bind(M("CTRL + code:43"), hl.dsp.window.move({ out_of_group = true }), "Move active out of group") -- H

---------------------------------------------------------------- WORKSPACES
section("Workspaces")
bind(M("Tab"), hl.dsp.focus({ workspace = "m+1" }), "next workspace")
bind(M("SHIFT + Tab"), hl.dsp.focus({ workspace = "m-1" }), "previous workspace")

for i = 1, 10 do
    local code = "code:" .. (9 + i) -- 1..0
    bind(M(code), hl.dsp.focus({ workspace = i }), "workspace " .. i)
    bind(M("SHIFT + " .. code), hl.dsp.window.move({ workspace = i }), "move to workspace " .. i)
    bind(M("CTRL + " .. code), hl.dsp.window.move({ workspace = i, follow = false }), "move silently to workspace " .. i)
end
bind(M("SHIFT + bracketleft"), hl.dsp.window.move({ workspace = "-1" }), "move to previous workspace")
bind(M("SHIFT + bracketright"), hl.dsp.window.move({ workspace = "+1" }), "move to next workspace")
bind(M("CTRL + bracketleft"), hl.dsp.window.move({ workspace = "-1", follow = false }), "move silently to previous workspace")
bind(M("CTRL + bracketright"), hl.dsp.window.move({ workspace = "+1", follow = false }), "move silently to next workspace")

-- Scroll through workspaces
bind(M("mouse_down"), hl.dsp.focus({ workspace = "e+1" }), "next workspace")
bind(M("mouse_up"), hl.dsp.focus({ workspace = "e-1" }), "previous workspace")
bind(M("period"), hl.dsp.focus({ workspace = "e+1" }), "next workspace")
bind(M("comma"), hl.dsp.focus({ workspace = "e-1" }), "previous workspace")
bind(M("mouse:276"), hl.dsp.focus({ workspace = "e-1" }), "previous workspace")
bind(M("mouse:275"), hl.dsp.focus({ workspace = "e+1" }), "next workspace")

-- Move/resize with mouse
bind(M("mouse:272"), hl.dsp.window.drag(), "move window", { mouse = true })
bind(M("mouse:273"), hl.dsp.window.resize(), "resize window", { mouse = true })

---------------------------------------------------------------- LAPTOP (configs/Laptops.conf)
section("Laptop")
bind("XF86KbdBrightnessDown", exec(S .. "/BrightnessKbd.sh --dec"), "keyboard brightness down", repeating)
bind("XF86KbdBrightnessUp", exec(S .. "/BrightnessKbd.sh --inc"), "keyboard brightness up", repeating)
bind("XF86Launch1", exec("rog-control-center"), "ASUS Armory crate")
bind("XF86Launch3", exec("asusctl led-mode -n"), "keyboard RGB profile")
bind("XF86Launch4", exec("asusctl profile -n"), "fan profile")
bind("XF86MonBrightnessDown", global("brightnessDown"), "brightness down", locked_repeating) -- was Brightness.sh
bind("XF86MonBrightnessUp", global("brightnessUp"), "brightness up", locked_repeating)
bind("XF86TouchpadToggle", function()                                               -- was TouchPad.sh
    touchpad_enabled = not (touchpad_enabled ~= false)
    hl.device({ name = v.touchpadDevice, enabled = touchpad_enabled })
    util.notify(touchpad_enabled and "Enabling Touchpad" or "Disabling Touchpad")
end, "toggle touchpad")
bind(M("F6"), exec(S .. "/screenshot.sh now"), "screenshot")
bind(M("SHIFT + F6"), global("screenshotFreezeClip"), "screenshot area (frozen) -> clipboard")
bind(M("CTRL + F6"), exec(S .. "/screenshot.sh in 5"), "screenshot (5s)")
bind(M("ALT + F6"), exec(S .. "/screenshot.sh in 10"), "screenshot (10s)")
bind("ALT + F6", exec(S .. "/screenshot.sh active"), "screenshot (active window)")

---------------------------------------------------------------- USER (UserConfigs/UserKeybinds.conf)
section("Apps")
bind(M("code:56"), exec('xdg-open "https://"'), "open default browser")                           -- B
bind(M("code:39"), exec(S .. "/menus.sh search"), "web search")                                   -- S
section("Shell")
bind(M("SHIFT + code:57"), global("sidebar"), "notification panel (caelestia)")                   -- N, was swaync-client
bind(M("code:25"), launcher_with(">wallpaper "), "select wallpaper (caelestia)")      -- W, was WallpaperSelect (rofi+swww)
section("Windows")
bind(M("code:40"), util.toggle_float, "Float current window (fit to screen)")           -- D
section("Workspaces")
bind(M("SHIFT + code:30"), hl.dsp.window.move({ workspace = "special" }), "move to special workspace") -- U
bind(M("code:30"), hl.dsp.workspace.toggle_special("special"), "toggle special workspace")       -- U
-- scratchpad: pulls Telegram from its workspace, hiding puts it back there (lua/scratchpad.lua)
bind(M("code:49"), require("lua.scratchpad").toggle, "Telegram scratchpad (show/hide)")          -- ` / ё
bind(M("code:38"), exec("qs ipc -c overview call overview toggle"), "desktop overview")           -- A
section("Media")
bind(M("SHIFT + code:43"), exec(S .. "/Toggle-Active-Window-Audio.sh"), "Toggle Mute/Unmute for Active-Window") -- H
section("Tools")
bind(M("SHIFT + code:42"), shell("gameMode toggle"), "toggle game mode")                          -- G
bind(M("SHIFT + code:32"), exec(S .. "/menus.sh zsh-theme"), "change oh-my-zsh theme")             -- O
bind(M("SHIFT + code:38"), exec(S .. "/menus.sh animations"), "animations menu")                   -- A
bind(M("code:57"), exec(S .. "/Hyprsunset.sh toggle"), "toggle night light")                     -- N
-- office WireGuard (NetworkManager "wg0", was waybar custom/vpn); caelestia toasts the state change
bind(M("SHIFT + code:25"), exec([[sh -c 'if nmcli -t -f NAME connection show --active | grep -qx wg0; then nmcli connection down wg0; else nmcli connection up wg0 || notify-send -u critical "VPN" "wg0 не поднялся"; fi']]), "office VPN wg0 on/off") -- W
bind(M("code:43"), exec(S .. "/menus.sh keys"), "help / cheat sheet (all binds)")                 -- H
