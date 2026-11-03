-- Only the home TV disables the laptop panel; office monitors keep their layout.
local tv = "Samsung Electric Company SAMSUNG 0x01000E00"

local function set_tv_only(enabled)
    hl.monitor({
        output = "eDP-1",
        mode = "1920x1080@165.0",
        position = "0x1242",
        scale = 1,
        disabled = enabled,
    })
    hl.config({ cursor = { no_hardware_cursors = enabled and 0 or 1 } })
end

local function sync_tv()
    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.description == tv then
            set_tv_only(true)
            return
        end
    end
    set_tv_only(false)
end

hl.on("monitor.added", function(monitor)
    if monitor.description == tv then set_tv_only(true) end
end)
hl.on("monitor.removed", function(monitor)
    if monitor.description == tv then set_tv_only(false) end
end)
hl.on("config.reloaded", sync_tv)
hl.on("hyprland.start", sync_tv)
