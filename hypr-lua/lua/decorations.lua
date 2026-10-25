-- UserConfigs/UserDecorations.conf
-- Colours: wallust ($color12/$color10/...) replaced by caelestia's generated scheme
-- (~/.config/hypr/scheme/current.lua, rewritten by `caelestia scheme`/wallpaper changes).
local ok, scheme = pcall(require, "scheme.current")
if not ok or type(scheme) ~= "table" then
    -- Last wallust palette, used until caelestia writes its first scheme
    scheme = { primary = "8AA3AB", outline = "D77156", onSurface = "E1E3E4", surfaceContainer = "393B3C" }
end

local function rgb(hex) return "rgb(" .. hex .. ")" end

hl.config({
    general = {
        border_size = 2,
        gaps_in     = 2,
        gaps_out    = 4,
        col = {
            active_border   = rgb(scheme.primary),
            inactive_border = rgb(scheme.outline),
        },
    },
    decoration = {
        rounding           = 10,
        active_opacity     = 1.0,
        inactive_opacity   = 0.9,
        fullscreen_opacity = 1.0,
        dim_inactive       = true,
        dim_strength       = 0.1,
        dim_special        = 0.8,
        shadow = {
            enabled        = true,
            range          = 3,
            render_power   = 1,
            color          = rgb(scheme.primary),
            color_inactive = rgb(scheme.outline),
        },
        blur = {
            enabled           = true,
            size              = 3,
            passes            = 2,
            new_optimizations = true,
            xray              = false,
            ignore_opacity    = false,
            special           = false,
            popups            = true,
        },
    },
    group = {
        col = {
            border_active = rgb(scheme.onSurface),
        },
        groupbar = {
            col = {
                active = rgb(scheme.surfaceContainer),
            },
        },
    },
})

-- UserConfigs/UserSettings.conf border override (sourced after decorations before)
hl.config({
    general = {
        border_size = 2,
        col = {
            active_border   = "rgba(89b4faff)",
            inactive_border = "rgba(595959aa)",
        },
    },
})
