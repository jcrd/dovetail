local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = require('beautiful.xresources').apply_dpi

local assets = require('dovetail.assets')

local pomo = {}
pomo.widget = {}

local icons = assets.pomodoro
local widget

pomo.options = {
    working = 25 * 60,
    short_break = 5 * 60,
    long_break = 20 * 60,
    set_length = 4,
}

local times = setmetatable({stopped = pomo.options.working},
    {__index = pomo.options})
local state = {}

local blink_timer = gears.timer {
    timeout = 0.5,
    callback = function ()
        widget.id_blink.visible = widget.id_time.visible
        widget.id_time.visible = not widget.id_time.visible
    end,
}

blink_timer:connect_signal('stop', function ()
    widget.id_time.visible = true
    widget.id_blink.visible = false
end)

local function update_state(tbl, k, v)
    if not widget then
        return
    end
    if blink_timer.started then
        blink_timer:stop()
    end
    if k == 'name' then
        widget.visible = not (v == 'stopped')
        widget.id_const.id_icon.image = icons[v]
        if times[v] ~= nil then
            tbl.time = times[v]
        end
    elseif k == 'time' then
        widget.id_time.text = os.date('%M:%S', v)
    elseif k == 'rep' then
        widget.id_margin.id_rep.markup = string.format(
            '<span size=\'smaller\' rise=\'2000\'>%d</span>', v)
    end
    state[k] = v
end

local s = setmetatable({}, {
    __index = function (_, k) return state[k] end,
    __newindex = update_state,
})

local function init()
    s.name = 'stopped'
    s.rep = 1
end

local function tick()
    s.time = s.time - 1
    if s.time > 0 then
        return
    end
    if s.name == 'working' then
        if s.rep == pomo.options.set_length then
            s.name = 'long_break'
        else
            s.name = 'short_break'
        end
    elseif s.name == 'long_break' then
        s.rep = 1
        s.name = 'working'
    elseif s.name == 'short_break' then
        s.rep = s.rep + 1
        s.name = 'working'
    end
end

local timer = gears.timer {
    timeout = 1,
    callback = tick,
}

function pomo.widget.timer()
    if not widget then
        widget = wibox.widget {
            {
                {
                    id = 'id_icon',
                    widget = wibox.widget.imagebox,
                },
                id = 'id_const',
                layout = wibox.container.constraint,
                strategy = 'min',
                width = beautiful.font_size,
            },
            {
                id = 'id_time',
                widget = wibox.widget.textbox,
            },
            {
                -- Same width as time in `id_time` textbox.
                text = '     ',
                visible = false,
                id = 'id_blink',
                widget = wibox.widget.textbox,
            },
            {
                {
                    id = 'id_rep',
                    widget = wibox.widget.textbox,
                },
                id = 'id_margin',
                widget = wibox.container.margin,
                left = dpi(2),
            },
            layout = wibox.layout.fixed.horizontal,
            visible = false,
        }
    end
    init()
    return widget
end

function pomo.toggle()
    if s.name == 'stopped' then
        s.name = 'working'
    end
    if timer.started then
        timer:stop()
        blink_timer:start()
    else
        blink_timer:stop()
        timer:start()
    end
end

function pomo.stop()
    if s.name ~= 'stopped' then
        timer:stop()
        init()
    end
end

function pomo.restart()
    if s.name ~= 'stopped' then
        s.time = times[s.name]
    end
end

return pomo
