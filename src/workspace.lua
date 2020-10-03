local awful = require('awful')

local dovetail = require('awesome-dovetail')
local selected_tag = require('dovetail.util').selected_tag
local workspace = require('awesome-launch.workspace')

local config = require('dovetail.config')
local menu = require('dovetail.menu')

local ws = {}

tag.connect_signal('request::default_layouts', function ()
    awful.layout.append_default_layouts {
        dovetail.layout.left,
        awful.layout.suit.max,
    }
end)

function ws.with(index, func, name, prompt)
    local s = awful.screen.focused()
    index = index or #s.tags + 1
    if index > #s.tags + 1 then
        return
    end
    local t = s.tags[index]
    if not t then
        local new_name = config.options.new_workspace_name or 'scratch'
        local p = s.tags[index - 1]
        if p and p.name == new_name and #p:clients() == 0 then
            t = s.tags[1]
        else
            if not name and prompt then
                menu.prompt('name', function (n) with_tag(index, func, n) end)
                return
            end
            if name == '' then
                return
            end
            local n = name or new_name
            t = workspace.new(n, {props={
                layout = awful.layout.layouts[1],
            }})
        end
    end
    func(t)
end

function ws.next(i, func, prompt)
    local v = selected_tag()
    index = v.index + i
    if index < 1 then
        index = #v.screen.tags + 1
    end
    ws.with(index, function (t)
        if func then
            func(t)
        end
        t:view_only()
    end, nil, prompt)
end

return ws
