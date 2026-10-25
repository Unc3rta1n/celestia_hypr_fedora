-- Telegram scratchpad (Super+`):
--   on a normal workspace -> remember where it sat, pull it into special:telegram and show it
--   shown                 -> hide and put Telegram back in the same spot of the same workspace
--   hidden in special     -> show
--   not running           -> start it (opens on the current workspace; next press pulls it in)
--
-- Dwindle re-inserts a returning window next to whatever is focused, so the tile would land
-- elsewhere. On pull we remember the neighbour it was split from and on which side; on return
-- we focus that neighbour and preselect the side, which rebuilds the same split.
local M = {}

local CLASS   = "org.telegram.desktop"
local SPECIAL = "telegram"
local GAP     = 40 -- px tolerance between touching tiles (gaps + borders)

-- survives `hyprctl reload` if the Lua state does; otherwise hiding just leaves it in special
_G.scratchpad_origin = _G.scratchpad_origin or {}

local function find_window()
    for _, w in ipairs(hl.get_windows()) do
        if w.class == CLASS then return w end
    end
end

local function overlap(a1, a2, b1, b2)
    return math.max(0, math.min(a2, b2) - math.max(a1, b1))
end

-- tiled neighbour sharing the longest edge with w, and the side w sits on relative to it
local function find_neighbour(w)
    local tx, ty, tw, th = w.at.x, w.at.y, w.size.x, w.size.y
    local best, best_dir, best_len = nil, nil, 0
    for _, n in ipairs(hl.get_workspace_windows(w.workspace.id)) do
        if n.address ~= w.address and not n.floating then
            local nx, ny, nw, nh = n.at.x, n.at.y, n.size.x, n.size.y
            local v = overlap(ty, ty + th, ny, ny + nh)
            local h = overlap(tx, tx + tw, nx, nx + nw)
            local cands = {
                { math.abs(nx + nw - tx) <= GAP, v, "r" }, -- neighbour on the left -> we go right
                { math.abs(tx + tw - nx) <= GAP, v, "l" },
                { math.abs(ny + nh - ty) <= GAP, h, "d" }, -- neighbour above -> we go down
                { math.abs(ty + th - ny) <= GAP, h, "u" },
            }
            for _, c in ipairs(cands) do
                if c[1] and c[2] > best_len then best, best_dir, best_len = n, c[3], c[2] end
            end
        end
    end
    return best and best.address, best_dir
end

local function put_back(addr, origin)
    local active = hl.get_active_workspace()
    local here = active and active.id == origin.ws
    local neighbour = origin.neighbour and hl.get_window("address:" .. origin.neighbour)
    -- preselect needs focus on the neighbour: only when we are on that workspace anyway
    if here and neighbour and not origin.floating then
        hl.dispatch(hl.dsp.focus({ window = "address:" .. origin.neighbour }))
        hl.dispatch(hl.dsp.layout("preselect " .. origin.dir))
    end
    hl.dispatch(hl.dsp.window.move({ window = addr, workspace = origin.ws, follow = false }))
    if here then hl.dispatch(hl.dsp.focus({ window = addr })) end
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
        local neighbour, dir = nil, nil
        if not w.floating then neighbour, dir = find_neighbour(w) end
        _G.scratchpad_origin[CLASS] = { ws = w.workspace.id, neighbour = neighbour, dir = dir, floating = w.floating }
        hl.dispatch(hl.dsp.window.move({ window = addr, workspace = "special:" .. SPECIAL, follow = false }))
        if not shown then hl.dispatch(hl.dsp.workspace.toggle_special(SPECIAL)) end
        hl.dispatch(hl.dsp.focus({ window = addr }))
    elseif shown then
        local origin = _G.scratchpad_origin[CLASS]
        hl.dispatch(hl.dsp.workspace.toggle_special(SPECIAL))
        if origin then
            put_back(addr, origin)
            _G.scratchpad_origin[CLASS] = nil
        end
    else
        hl.dispatch(hl.dsp.workspace.toggle_special(SPECIAL))
        hl.dispatch(hl.dsp.focus({ window = addr }))
    end
end

return M
