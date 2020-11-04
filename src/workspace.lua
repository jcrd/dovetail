local awful = require('awful')
local gtable = require('gears.table')

local dovetail = require('awesome-dovetail')
local selected_tag = require('dovetail.util').selected_tag
local workspace = require('awesome-launch.workspace')

local config = require('dovetail.config')
local menu = require('dovetail.menu')

local ws = {}

local history = {}

tag.connect_signal('request::default_layouts', function ()
    awful.layout.append_default_layouts {
        dovetail.layout.left,
        awful.layout.suit.max,
    }
end)

screen.connect_signal('tag::history::update', function (s)
    local t = selected_tag(s)
    if not t then
        return
    end
    local i = gtable.hasitem(history, t.index)
    if i then
        table.remove(history, i)
    end
    table.insert(history, t.index)
end)

function ws.restore()
    local tag = selected_tag()
    for index=#history,1,-1 do
        local i = history[index]
        if i ~= tag.index then
            ws.with(i, nil, function (t)
                t:view_only()
            end)
            break
        end
    end
end

function ws.emptyp(tag)
    tag = tag or selected_tag()
    local n = config.options.new_workspace_name
    return tag and tag.name == n and #tag:clients() == 0
end

function ws.with(index, prompt, func, name)
    local s = awful.screen.focused()
    index = index or #s.tags + 1
    if index > #s.tags + 1 then
        return
    end
    local t = s.tags[index]
    if not t then
        if ws.emptyp(s.tags[index - 1]) then
            t = s.tags[1]
        else
            if not name and prompt then
                menu.prompt('name', function (n) ws.with(index, func, n) end)
                return
            end
            if name == '' then
                return
            end
            t = workspace.new(name or config.options.new_workspace_name)
        end
    end
    func(t)
end

function ws.next(i, prompt, func)
    local v = selected_tag()
    index = v.index + i
    if index < 1 then
        index = #v.screen.tags + 1
    end
    ws.with(index, prompt, function (t)
        if func then
            func(t)
        end
        t:view_only()
    end)
end

return ws
