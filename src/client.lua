local awful = require('awful')
local beautiful = require('beautiful')
local ruled = require('ruled')

require('awful.autofocus')

local config = require('dovetail.config')
local ws = require('dovetail.workspace')

local function emit_arrange(t)
    t.screen:emit_signal('arrange', t.screen)
end

tag.connect_signal('tagged', emit_arrange)
tag.connect_signal('untagged', emit_arrange)
tag.connect_signal('property::layout', emit_arrange)

screen.connect_signal('arrange', function (s)
    local cls = s.tiled_clients
    local layout = awful.layout.get(s).name

    if (#cls == 1 and layout ~= 'focal') or layout == 'max' then
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

awful.client.property.persist('tag_index', 'number')

local clients_per_tag = {}

local scanning_rule = {
    id = 'scanning_rule',
    rule = {},
    callback = function (c)
        if not c.tag_index then
            return
        end
        local cs = clients_per_tag[c.tag_index] or {}
        table.insert(cs, c)
        clients_per_tag[c.tag_index] = cs
    end,
}

client.connect_signal('scanning', function ()
    ruled.client.append_rule(scanning_rule)
end)

client.connect_signal('scanned', function ()
    ruled.client.remove_rule(scanning_rule)
end)

awesome.connect_signal('startup', function ()
    client.connect_signal('tagged', function (c, t)
        c.tag_index = t.index
    end)
    ws.recreate(clients_per_tag)
end)

client.connect_signal('property::floating', function (c)
    if c.floating then
        c.skip_taskbar = true
        awful.placement.centered(c)
        if not c.active then
            c.border_color = beautiful.border_normal_floating
        end
        c:raise()
    else
        c.skip_taskbar = false
    end
end)

client.connect_signal('manage', function (c)
    if awesome.startup then
        if not c.size_hints.user_position
            and not c.size_hints.program_position then
            awful.placement.no_offscreen(c)
        end
    end
    awful.client.setslave(c)
end)

client.connect_signal('focus', function (c)
    c.border_color = beautiful.border_focus
    if c.floating then c:raise() end
end)

client.connect_signal('unfocus', function (c)
    if c.floating then
        c.border_color = beautiful.border_normal_floating
    else
        c.border_color = beautiful.border_normal
    end
end)

config.add_hook(function (opts)
    if not opts.allow_maximized_clients then
        local props = {
            'maximized',
            'maximized_vertical',
            'maximized_horizontal',
        }

        for _, prop in ipairs(props) do
            client.connect_signal('property::'..prop, function (c)
                if c[prop] then
                    c[prop] = false
                end
            end)
        end
    end
end)
