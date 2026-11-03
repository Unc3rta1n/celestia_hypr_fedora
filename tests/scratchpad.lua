package.path = "hypr-lua/?.lua;" .. package.path

local commands, shown, neighbour = {}, false, nil
local monitor = { width = 1920, height = 1080, scale = 1, reserved = { 0, 0, 0, 0 } }
local window = {
    class = "org.telegram.desktop", address = "telegram", floating = false,
    workspace = { id = 6, special = false },
    at = { x = 960, y = 0 }, size = { x = 960, y = 1080 },
}
local function command(kind)
    return function(args) return { kind = kind, args = args } end
end
hl = {
    get_windows = function() return { window } end,
    get_workspace_windows = function() return { window, neighbour } end,
    get_active_workspace = function() return { id = 6 } end,
    get_active_monitor = function() return monitor end,
    get_active_special_workspace = function()
        return shown and { name = "special:telegram" } or nil
    end,
    get_window = function(selector)
        return neighbour and selector == "address:" .. neighbour.address and neighbour or nil
    end,
    dsp = {
        window = { move = command("move"), float = command("float"),
            resize = command("resize"), center = command("center") },
        focus = command("focus"), layout = command("layout"), exec_cmd = command("exec"),
        workspace = { toggle_special = command("special") },
    },
    dispatch = function(cmd)
        commands[#commands + 1] = cmd
        if cmd.kind == "special" then shown = not shown end
        if cmd.kind == "float" then window.floating = cmd.args.action == "set" end
        if cmd.kind == "move" and cmd.args.workspace then
            window.workspace = { id = cmd.args.workspace, special = type(cmd.args.workspace) == "string" }
        end
        if cmd.kind == "resize" then window.size = { x = cmd.args.x, y = cmd.args.y } end
        if cmd.kind == "move" and cmd.args.x then window.at = { x = cmd.args.x, y = cmd.args.y } end
    end,
}

local scratchpad = require("lua.scratchpad")
local function last(kind)
    for i = #commands, 1, -1 do
        if commands[i].kind == kind then return commands[i].args end
    end
end

scratchpad.toggle()
assert(window.floating, "scratchpad must explicitly float Telegram")
assert(window.size.x == 1536 and window.size.y == 864, "scratchpad must fit 80% of the work area")
assert(last("center").window == "address:telegram", "scratchpad must center the target window")
scratchpad.toggle()
assert(not window.floating and window.workspace.id == 6, "hide must restore tiled mode and workspace")

window.floating = true
window.at, window.size = { x = 120, y = 80 }, { x = 700, y = 600 }
scratchpad.toggle()
scratchpad.toggle()
assert(window.floating, "hide must retain an originally floating window")
assert(window.at.x == 120 and window.at.y == 80, "hide must restore floating position")
assert(window.size.x == 700 and window.size.y == 600, "hide must restore floating size")

window.workspace = { id = -1, special = true }
shown = false
commands = {}
scratchpad.toggle()
assert(shown and window.floating and last("center"), "hidden special window must reopen centered and floating")
scratchpad.toggle()
monitor = { width = 2560, height = 1440, scale = 1.25, transform = 1, reserved = { 10, 20, 30, 40 } }
scratchpad.toggle()
assert(window.size.x == 889 and window.size.y == 1590,
    "scratchpad sizing must respect rotation, scaling and reserved screen space")
scratchpad.toggle()
window.workspace, window.floating = { id = 6, special = false }, false
window.at, window.size = { x = 960, y = 0 }, { x = 960, y = 1080 }
neighbour = { address = "neighbour", floating = false,
    at = { x = 0, y = 0 }, size = { x = 960, y = 1080 } }
commands = {}
scratchpad.toggle()
scratchpad.toggle()
assert(last("layout") == "preselect r", "return must recreate the split next to the original neighbour")
local preselect, returning, retiling
for i, cmd in ipairs(commands) do
    if cmd.kind == "layout" then preselect = i end
    if cmd.kind == "move" and cmd.args.workspace == 6 then returning = i end
    if cmd.kind == "float" and cmd.args.action == "unset" then retiling = i end
end
assert(preselect < returning and returning < retiling, "return must preselect, move, then retile")
print("scratchpad: passed")
