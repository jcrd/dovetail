local awful = require('awful')
local beautiful = require('beautiful')
local gtable = require('gears.table')

local dovetail = require('awesome-dovetail')
local selected_tag = require('dovetail.util').selected_tag
local workspace = require('awesome-launch.workspace')

local config = require('dovetail.config')
local menu = require('dovetail.menu')

local ws = {}

local history = {2, 1}

tag.connect_signal('request::default_layouts', function ()
    awful.layout.append_default_layouts {
        dovetail.layout.left,
        awful.layout.suit.max,
    }
end)

local function emit_arrange(t)
    t.screen:emit_signal('arrange', t.screen)
end

tag.connect_signal('tagged', emit_arrange)
tag.connect_signal('untagged', emit_arrange)
tag.connect_signal('property::layout', emit_arrange)

screen.connect_signal('arrange', function (s)
    local cls = s.tiled_clients
    local layout = awful.layout.get(s).name

    if #cls == 1 or layout == 'max' then
        for _, c in ipairs(cls) do
            c.border_width = 0
        end
    else
        for _, c in ipairs(cls) do
            c.border_width = beautiful.border_width
        end
    end

    for _, c in ipairs(s.clients) do
        if c.floating then
            c.border_width = beautiful.border_width
        end
    end
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
    if not (tag and tag.name == n) then
        return false
    end
    local c = tag:clients()
    return #c == 0 or (#c == 1 and c[1].launch_panel)
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
