-- Do not disturb while the screen is shared (calls): notification popups stay out of the picture.
-- Screenshots (grim, the caelestia picker) fire the same event for a moment, so DND is turned on only
-- once a share has lasted DELAY ms, and turned back off afterwards only if it was turned on here
-- (the marker in the runtime dir survives config reloads).

local DELAY = 2000
local IPC = "qs -c caelestia ipc call notifs "
local MARK = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/caelestia-dnd-screenshare"

local active = 0

hl.on("screenshare.state", function(on)
    if on then
        active = active + 1
        hl.timer(function()
            if active > 0 then
                hl.exec_cmd(('[ "$(%sisDndEnabled)" = false ] && %senableDnd && touch "%s"'):format(IPC, IPC, MARK))
            end
        end, { timeout = DELAY, type = "oneshot" })
    else
        active = math.max(active - 1, 0)
        if active == 0 then
            hl.exec_cmd(('[ -e "%s" ] && rm -f "%s" && %sdisableDnd'):format(MARK, MARK, IPC))
        end
    end
end)
