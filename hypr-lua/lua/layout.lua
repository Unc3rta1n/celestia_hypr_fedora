-- Layout switching (was scripts/ChangeLayout.sh + KeybindsLayoutInit.sh, which used `hyprctl keyword`,
-- unavailable with the Lua config). Rebinds SUPER+J/K/arrows/O per layout exactly like the script did.
local util = require("lua.util")

local layouts = { "master", "dwindle", "scrolling", "monocle" }
local dynamic = {}

local cycle_prev = hl.dsp.window.cycle_next({ next = false })
local cycle_next = hl.dsp.window.cycle_next()

local per_layout = {
    dwindle = {
        ["SUPER + J"] = cycle_next,                  ["SUPER + K"] = cycle_prev,
        ["SUPER + left"] = cycle_prev,               ["SUPER + up"] = cycle_prev,
        ["SUPER + right"] = cycle_next,              ["SUPER + down"] = cycle_next,
        ["SUPER + O"] = hl.dsp.layout("togglesplit"),
    },
    scrolling = {
        ["SUPER + J"] = cycle_next,                  ["SUPER + K"] = cycle_prev,
        ["SUPER + left"] = cycle_prev,               ["SUPER + up"] = cycle_prev,
        ["SUPER + right"] = cycle_next,              ["SUPER + down"] = cycle_next,
    },
    monocle = {
        ["SUPER + J"] = hl.dsp.layout("cyclenext"),  ["SUPER + K"] = hl.dsp.layout("cycleprev"),
        ["SUPER + left"] = hl.dsp.layout("cycleprev"), ["SUPER + up"] = hl.dsp.layout("cycleprev"),
        ["SUPER + right"] = hl.dsp.layout("cyclenext"), ["SUPER + down"] = hl.dsp.layout("cyclenext"),
    },
    master = {
        ["SUPER + J"] = hl.dsp.layout("cyclenext"),  ["SUPER + K"] = hl.dsp.layout("cycleprev"),
        ["SUPER + left"] = hl.dsp.focus({ direction = "left" }),
        ["SUPER + right"] = hl.dsp.focus({ direction = "right" }),
        ["SUPER + up"] = hl.dsp.focus({ direction = "up" }),
        ["SUPER + down"] = hl.dsp.focus({ direction = "down" }),
    },
}

local titles = { dwindle = " Dwindle Layout", scrolling = " Scrolling Layout", monocle = " Monocle Layout", master = " Master Layout" }

local function apply(target, quiet)
    if not per_layout[target] then return end
    hl.config({ general = { layout = target } })

    for _, b in ipairs(dynamic) do b:remove() end
    dynamic = {}
    for key, dsp in pairs(per_layout[target]) do
        dynamic[#dynamic + 1] = hl.bind(key, dsp, { description = "Layout|" .. key .. "|focus / navigate (" .. target .. ")" })
    end

    if not quiet then util.notify(titles[target]) end
end

local function current()
    return hl.get_config("general.layout") or "dwindle"
end

local function toggle()
    local cur = current()
    for i, name in ipairs(layouts) do
        if name == cur then return apply(layouts[i % #layouts + 1]) end
    end
    apply(layouts[1])
end

-- Global so scripts can call it: hyprctl eval 'kool_layout("master")'
function kool_layout(name)
    if name == nil or name == "toggle" or name == "next" then toggle() else apply(name) end
end

-- init (was `exec-once = ChangeLayout.sh init`)
apply(current(), true)

return { apply = apply, toggle = toggle }
