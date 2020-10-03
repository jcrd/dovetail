local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local launch = require('awesome-launch')
local session = require('sessiond_dbus')

local audio = require('dovetail.widgets.audio')
local config = require('dovetail.config')

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

local function set_taglist_index(self, _, i)
    self:get_children_by_id('index_role')[1].markup = '<b> '..i..' </b>'
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

    awful.tag.add(config.options.default_workspace_name or 'main', {
        screen = s,
        selected = true,
        layout = awful.layout.layouts[1],
    })

    s.dovetail_taglist = awful.widget.taglist {
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
    }

    s.dovetail_clientlist = {
        {
            awful.widget.tasklist {
                screen = s,
                filter = awful.widget.tasklist.filter.focused,
                widget_template = {
                    {
                        {
                            {
                                id = 'text_role',
                                widget = wibox.widget.textbox,
                            },
                            id = 'text_margin_role',
                            left = beautiful.bar_growth,
                            right = beautiful.bar_growth,
                            widget = wibox.container.margin,
                        },
                        fill_space = true,
                        layout = wibox.layout.fixed.horizontal,
                    },
                    id = 'background_role',
                    widget = wibox.container.background,
                },
            },
            launch.widget.launchbar {
                screen = s,
            },
            fill_space = true,
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
