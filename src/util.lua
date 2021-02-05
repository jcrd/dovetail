local awful = require('awful')
local naughty = require('naughty')

local util = {}

function util.client_is_valid(c)
    return pcall(function () return c.valid end) and c.valid
end

function util.selected_tag(s)
    s = s or awful.screen.focused()
    return s.selected_tag
end

function util.clientinfo(c)
    c = c or client.focus
    if not c then
        return
    end
    local props = {
        valid = c.valid,
        window = c.window,
        name = c.name,
        type = c.type,
        class = c.class,
        instance = c.instance,
        floating = c.floating,
        fullscreen = c.fullscreen,
        screen = c.screen.index,
        startup_id = c.startup_id,
        wm_launch_id = c.wm_launch_id,
        single_instance_id = c.single_instance_id,
        cmdline = c.cmdline,
        launch_panel = c.launch_panel or false,
        maximized = c.maximized,
        maximized_vertical = c.maximized_vertical,
        maximized_horizontal = c.maximized_horizontal,
    }
    local text = ''
    for k, v in pairs(props) do
        text = text .. string.format('\n%s: %s', k, v)
    end
    naughty.notification {
        title = 'Client info',
        message = text,
        position = 'top_middle',
    }
end

return util
