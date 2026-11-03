local callbacks, monitors, rules, cursor = {}, {}, {}, nil
hl = {
    on = function(event, callback) callbacks[event] = callback end,
    get_monitors = function() return monitors end,
    monitor = function(rule) rules[#rules + 1] = rule end,
    config = function(config) cursor = config.cursor.no_hardware_cursors end,
}
dofile("hypr-lua/lua/tv_display.lua")
local tv = { description = "Samsung Electric Company SAMSUNG 0x01000E00" }
local office = { description = "Samsung Electric Company S24C450 HLND300483" }

-- Reload applies monitor rules before the TV-only callback disables the panel.
dofile("hypr-lua/monitors.lua")
local panel, television
for _, rule in ipairs(rules) do
    if rule.output == "eDP-1" then panel = rule end
    if rule.output == "desc:" .. tv.description then television = rule end
end
local function rectangle(rule)
    local x, y = rule.position:match("^(%-?%d+)x(%-?%d+)$")
    local w, h = rule.mode:match("^(%d+)x(%d+)")
    return tonumber(x), tonumber(y), tonumber(w) / rule.scale, tonumber(h) / rule.scale
end
local px, py, pw, ph = rectangle(panel)
local tx, ty, tw, th = rectangle(television)
assert(px + pw <= tx or tx + tw <= px or py + ph <= ty or ty + th <= py,
    "reload must not overlap TV and laptop before the panel is disabled")

callbacks["hyprland.start"]()
assert(rules[#rules].disabled == false and cursor == 1, "laptop without TV")
local count = #rules
callbacks["monitor.added"](office)
assert(#rules == count, "office monitor must not disable laptop")
callbacks["monitor.added"](tv)
assert(rules[#rules].disabled == true and cursor == 0, "TV hotplug")
monitors = { tv }
callbacks["config.reloaded"]()
assert(rules[#rules].disabled == true, "reload with TV")
callbacks["monitor.removed"](tv)
assert(rules[#rules].disabled == false and cursor == 1, "TV unplug restores laptop")
count = #rules
callbacks["monitor.added"]({ description = "BOE 0x0A1C" })
assert(#rules == count, "restoring laptop must not trigger a loop")
monitors = { office }
callbacks["config.reloaded"]()
assert(rules[#rules].disabled == false, "reload at office")
print("TV display checks passed")
