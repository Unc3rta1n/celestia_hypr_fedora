-- Battery saver: on battery, drop the GPU-heavy eye candy. Evaluated on every (re)load;
-- scripts/power-watch reloads Hyprland when the charger is plugged/unplugged.
local function read(path)
    local f = io.open(path)
    if not f then return nil end
    local s = f:read("l")
    f:close()
    return s
end

-- battery = there is a Mains supply and none of them is online (desktops have no Mains -> never)
local function on_battery()
    local ls = io.popen("ls -d /sys/class/power_supply/* 2>/dev/null")
    if not ls then return false end
    local has_mains = false
    for dir in ls:lines() do
        if read(dir .. "/type") == "Mains" then
            has_mains = true
            if read(dir .. "/online") == "1" then
                ls:close()
                return false
            end
        end
    end
    ls:close()
    return has_mains
end

if on_battery() then
    hl.config({
        animations = { enabled = false },
        decoration = { blur = { enabled = false }, shadow = { enabled = false } },
    })
end
