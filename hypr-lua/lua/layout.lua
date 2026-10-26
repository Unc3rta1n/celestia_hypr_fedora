-- Layout: dwindle only. Switching between master/dwindle/scrolling/monocle (was ChangeLayout.sh, then
-- per-layout rebinds here) was never used, and in dwindle SUPER+arrows only cycled the windows of the
-- workspace, so they never reached the other monitors. Now they move focus by direction: to the window
-- on that side, or to the next monitor when there is none.

hl.config({ general = { layout = "dwindle" } })

local function bind(key, dsp, text)
    hl.bind(key, dsp, { description = "Layout|" .. key .. "|" .. text })
end

bind("SUPER + left", hl.dsp.focus({ direction = "left" }), "focus left (window or monitor)")
bind("SUPER + right", hl.dsp.focus({ direction = "right" }), "focus right (window or monitor)")
bind("SUPER + up", hl.dsp.focus({ direction = "up" }), "focus up (window or monitor)")
bind("SUPER + down", hl.dsp.focus({ direction = "down" }), "focus down (window or monitor)")
