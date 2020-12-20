local awful = require('awful')
local beautiful = require('beautiful')

require('awful.autofocus')

client.connect_signal('property::floating', function (c)
    if c.floating then
        c.skip_taskbar = true
        awful.placement.centered(c)
        if not c.active then
            c.border_color = beautiful.border_normal_floating
        end
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
