-- Helpers shared by settings/keybinds (no side effects: safe to require many times)
local M = {}

-- Desktop magnifier: multiply cursor.zoom_factor, never below 1
function M.zoom(mult)
    return function()
        local cur = tonumber(hl.get_config("cursor.zoom_factor")) or 1
        if cur < 1 then cur = 1 end
        hl.config({ cursor = { zoom_factor = math.max(1, cur * mult) } })
    end
end

function M.notify(title, body)
    hl.dispatch(hl.dsp.exec_cmd(string.format("notify-send -e -u low %q %q", title, body or "")))
end

-- Usable area of a monitor in logical px: rotation, scale and reserved space (caelestia bar) applied
local function work_area(mon)
    local w, h = mon.width / mon.scale, mon.height / mon.scale
    if (mon.transform or 0) % 2 == 1 then w, h = h, w end
    local r = mon.reserved
    if type(r) == "table" then
        local l, t, rr, b = r[1] or r.left or 0, r[2] or r.top or 0, r[3] or r.right or 0, r[4] or r.bottom or 0
        w, h = w - l - rr, h - t - b
    end
    return w, h
end

-- Toggle floating; a window that becomes floating is shrunk to fit the monitor (max 85%) and centred,
-- so it no longer sticks out past the screen edge / under the bar.
function M.toggle_float()
    local win = hl.get_active_window()
    if not win then return end
    local was_floating = win.floating
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    if was_floating then return end

    local mon = win.monitor or hl.get_active_monitor()
    if not mon then return end
    local aw, ah = work_area(mon)
    local cur = hl.get_active_window()
    local sw = cur and cur.size and (cur.size[1] or cur.size.x) or aw
    local sh = cur and cur.size and (cur.size[2] or cur.size.y) or ah
    local w = math.floor(math.min(sw, aw * 0.85))
    local h = math.floor(math.min(sh, ah * 0.85))
    hl.dispatch(hl.dsp.window.resize({ x = w, y = h, relative = false }))
    hl.dispatch(hl.dsp.window.center())
end

return M
