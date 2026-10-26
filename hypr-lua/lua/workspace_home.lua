-- Workspaces go back to their monitor when it is plugged in again.
-- Workspace rules only place workspaces when they are created: once 1-3 have fallen back to the
-- laptop (HP unplugged when leaving the office), they stay there after it is plugged in again.
-- The workspace -> monitor map is taken from the rules in workspaces.lua (written by nwg-displays),
-- so this module has to be required before it.

local home = {}

local workspace_rule = hl.workspace_rule
hl.workspace_rule = function(rule)
    if rule.workspace and rule.monitor then
        home[tostring(rule.workspace)] = rule.monitor
    end
    return workspace_rule(rule)
end

hl.on("monitor.added", function(monitor)
    local active = hl.get_active_workspace()
    local moved = false
    for _, ws in ipairs(hl.get_workspaces()) do
        if home[ws.name] == monitor.name and not (ws.monitor and ws.monitor.name == monitor.name) then
            hl.dispatch(hl.dsp.workspace.move({ workspace = ws.name, monitor = monitor.name }))
            moved = true
        end
    end
    -- moving a workspace focuses it; keep working where you were
    if moved and active then
        hl.dispatch(hl.dsp.focus({ workspace = active.name }))
    end
end)
