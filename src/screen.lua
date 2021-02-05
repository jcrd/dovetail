local awful = require('awful')
local beautiful = require('beautiful')
local gears = require('gears')
local wibox = require('wibox')

local launch = require('awesome-launch')
local session = require('sessiond_dbus')

local audio = require('dovetail.widgets.audio')
local config = require('dovetail.config')
local ws = require('dovetail.workspace')

local clock_widget = wibox.widget.textclock(beautiful.clock_format)

session.connect_signal('PrepareForSleep', function (before)
    if not before then
        clock_widget:force_update()
    end
end)

local info = {
    {
        audio.widget.volumebar(),
        widget = wibox.container.margin,
        left = beautiful.info_margins,
        right = beautiful.info_margins,
    },
    {
        {
            clock_widget,
            widget = wibox.container.margin,
            left = beautiful.info_margins,
            right = beautiful.info_margins,
        },
        widget = wibox.container.background,
        fg = beautiful.fg_focus,
        bg = beautiful.bg_focus,
    },
    layout = wibox.layout.fixed.horizontal,
}

if config.options.enable_battery_widget then
    table.insert(info, 1, {
        require('dovetail.widgets.battery').widget.time(),
        widget = wibox.container.margin,
        left = beautiful.info_margins,
        right = beautiful.info_margins,
    })
end

local function index_markup(i)
    i = i or #awful.screen.focused().tags + 1
    return '<b> '..i..' </b>'
end

local function set_taglist_index(self, _, i)
    self:get_children_by_id('index_role')[1].markup = index_markup(i)
end

local function new_workspace_indicator(s)
    local w = wibox.widget {
        {
            id = 'id_index',
            markup = index_markup(),
            widget = wibox.widget.textbox,
        },
        {
            markup = '<b><big>+</big></b>',
            widget = wibox.widget.textbox,
        },
        layout = wibox.layout.fixed.horizontal,
    }
    local function update()
        gears.timer.delayed_call(function ()
            w.visible = not ws.emptyp()
            if w.visible then
                w.id_index.markup = index_markup()
            end
        end)
    end
    s:connect_signal('tag::history::update', update)
    tag.connect_signal('tagged', update)
    tag.connect_signal('untagged', update)
    return w
end

local function stack_indicator(s, c)
    local w = wibox.widget {
        markup = string.format('<b><big>%s</big></b>',
            gears.string.xml_escape(c)),
        visible = false,
        widget = wibox.widget.textbox,
    }
    local function update()
        if not client.focus or client.focus.floating then
            w.visible = false
            return
        end
        local layout = awful.layout.get(s).name
        local cls = client.focus.screen.tiled_clients
        if layout == 'max' and #cls > 1 then
            w.visible = true
            return
        end
        local m = awful.client.getmaster()
        w.visible = #cls > 2 and client.focus ~= m
    end
    client.connect_signal('focus', function ()
        gears.timer.delayed_call(update)
    end)
    client.connect_signal('unfocus', function ()
        gears.timer.delayed_call(update)
    end)
    tag.connect_signal('property::layout', update)
    return w
end

screen.connect_signal('request::desktop_decoration', function (s)
    -- Workaround for: https://github.com/awesomeWM/awesome/issues/2780
    -- With three tags, select in this order:
    -- 3, 2, 3, 1, 3,
    -- then close the client on tag 3, removing the volatile tag.
    -- Tag 1 will have focus, press M-1 to switch to previous tag
    -- and no tag will be selected.
    s:connect_signal('tag::history::update', function ()
        if #s.selected_tags == 0 and s.tags[1] then
            s.tags[1]:view_only()
        end
    end)

    awful.tag.add(config.options.default_workspace_name, {
        screen = s,
        selected = true,
        layout = awful.layout.layouts[1],
    })

    s.dovetail_taglist = {
        awful.widget.taglist {
            screen = s,
            filter = awful.widget.taglist.filter.all,
            widget_template = {
                {
                    {
                        id = 'index_role',
                        widget = wibox.widget.textbox,
                    },
                    {
                        {
                            id = 'text_role',
                            widget = wibox.widget.textbox,
                        },
                        id = 'background_role',
                        widget = wibox.container.background,
                    },
                    layout = wibox.layout.fixed.horizontal,
                },
                layout = wibox.layout.fixed.horizontal,
                create_callback = set_taglist_index,
                update_callback = set_taglist_index,
            },
        },
        new_workspace_indicator(s),
        layout = wibox.layout.fixed.horizontal,
    }

    s.dovetail_clientlist = {
        {
            stack_indicator(s, '< '),
            awful.widget.tasklist {
                screen = s,
                filter = awful.widget.tasklist.filter.focused,
                widget_template = {
                    {
                        {
                            {
                                {
                                    id = 'text_role',
                                    widget = wibox.widget.textbox,
                                },
                                layout = wibox.container.constraint,
                                width = s.geometry.width / 3,
                            },
                            id = 'text_margin_role',
                            left = beautiful.bar_growth,
                            right = beautiful.bar_growth,
                            widget = wibox.container.margin,
                        },
                        layout = wibox.layout.fixed.horizontal,
                    },
                    id = 'background_role',
                    widget = wibox.container.background,
                },
            },
            launch.widget.launchbar {
                screen = s,
            },
            stack_indicator(s, ' >'),
            layout = wibox.layout.fixed.horizontal,
        },
        layout = wibox.container.constraint,
        width = s.geometry.width / 2,
    }

    s.dovetail_wibox = awful.wibar {
        height = beautiful.wibar_height,
        screen = s,
    }

    s.dovetail_wibox:setup {
        s.dovetail_taglist,
        s.dovetail_clientlist,
        info,
        layout = wibox.layout.align.horizontal,
        expand = 'none',
    }
end)
