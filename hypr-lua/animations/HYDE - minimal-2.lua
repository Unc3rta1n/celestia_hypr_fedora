-- KoolDots animation preset (converted). Animations.sh copies this to lua/animations.lua
hl.config({ animations = { enabled = true } })
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
--
-- # name "Minimal-2"
-- credit https://github.com/prasanthrangan/hyprdots


hl.curve("quart", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 6,
    bezier = "quart",
    style = "slide",
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 6,
    bezier = "quart",
})
hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 6,
    bezier = "quart",
})
hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 6,
    bezier = "quart",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 6,
    bezier = "quart",
})
hl.config({
    animations = {
        enabled = true,
    },
})

