-- Telegram scratchpad (Super+`):
--   on a normal workspace -> remember it, pull Telegram into special:telegram and show it
--   shown                 -> hide and put Telegram back on the workspace it was taken from
--   hidden in special     -> show
--   not running           -> start it (opens on the current workspace; next press pulls it in)
local M = {}

local CLASS   = "org.telegram.desktop"
local SPECIAL = "telegram"

-- survives `hyprctl reload` if the Lua state does; otherwise hiding just leaves it in special
_G.scratchpad_origin = _G.scratchpad_origin or {}

local function find_window()
    for _, w in ipairs(hl.get_windows()) do
        if w.class == CLASS then return w end
    end
end

function M.toggle()
    local w = find_window()
    if not w then
        hl.dispatch(hl.dsp.exec_cmd("Telegram"))
        return
    end

    local addr = "address:" .. w.address
    local shown = hl.get_active_special_workspace()
    shown = shown and shown.name == "special:" .. SPECIAL

    if not w.workspace.special then
        _G.scratchpad_origin[CLASS] = w.workspace.id
        hl.dispatch(hl.dsp.window.move({ window = addr, workspace = "special:" .. SPECIAL, follow = false }))
        if not shown then hl.dispatch(hl.dsp.workspace.toggle_special(SPECIAL)) end
        hl.dispatch(hl.dsp.focus({ window = addr }))
    elseif shown then
        local origin = _G.scratchpad_origin[CLASS]
        hl.dispatch(hl.dsp.workspace.toggle_special(SPECIAL))
        if origin then
            hl.dispatch(hl.dsp.window.move({ window = addr, workspace = origin, follow = false }))
            _G.scratchpad_origin[CLASS] = nil
        end
    else
        hl.dispatch(hl.dsp.workspace.toggle_special(SPECIAL))
        hl.dispatch(hl.dsp.focus({ window = addr }))
    end
end

return M
