local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = require('beautiful.xresources').apply_dpi

local pulse = require('pulseaudio_dbus')

local audio = {}

local connection_failed = false
local conn
local core
local sink
local widget

local function get_volume()
    if not sink then
        return 0
    end
    return sink:get_volume_percent()[1]
end

local function update_volume(v)
    v = v or get_volume()
    if audio.on_update then
        audio.on_update(sink:is_muted(), v)
    end
    if not widget then
        return
    end
    widget.id_progress.value = v
end

local function format_icon(i)
    return '<span rise="4000">'..i..'</span>'
end

local function update_muted(m)
    m = m or sink:is_muted()
    if audio.on_update then
        audio.on_update(m, get_volume())
    end
    if not widget then
        return
    end
    widget.id_icon.markup = format_icon(audio.widget.icons[m])
end

local function update()
    update_volume()
    update_muted()
end

local function connect_device(dev)
    if not dev then
        return
    end
    if dev.signals.VolumeUpdated then
        dev:connect_signal(
            function (s)
                if s.object_path == sink.object_path then
                    update_volume()
                end
            end, 'VolumeUpdated')
    end
    if dev.signals.MuteUpdated then
        dev:connect_signal(
            function (s, muted)
                if s.object_path == sink.object_path then
                    update_muted(muted)
                end
            end, 'MuteUpdated')
    end
end

local function update_sink(s)
    if conn then
        sink = pulse.get_device(conn, s or core:get_sinks()[1])
        return sink
    end
end

local function connect()
    if connection_failed then
        return false
    end
    if not conn then
        _, conn = xpcall(function ()
            return pulse.get_connection(pulse.get_address())
        end,
        function (err)
            print(string.format('[pulseaudio] dbus connection failed: %s', err))
        end)
        if not conn then
            widget.visible = false
            connection_failed = true
            return false
        end
    end
    if not core then
        core = pulse.get_core(conn)

        core:ListenForSignal('org.PulseAudio.Core1.Device.VolumeUpdated', {})
        core:ListenForSignal('org.PulseAudio.Core1.Device.MuteUpdated', {})
        core:ListenForSignal('org.PulseAudio.Core1.NewSink', {core.object_path})

        core:connect_signal(function (_, s)
            connect_device(update_sink(s))
            update()
        end, 'NewSink')

        connect_device(update_sink())
    end
    if not sink then
        print('[pulseaudio] failed to get sink')
        widget.visible = false
        connection_failed = true
        return false
    end

    return true
end

audio.widget = {}
audio.widget.icons = {[false] = '', [true] = ''}

function audio.widget.volumebar()
    if not widget then
        local m = dpi(2)
        widget = wibox.widget {
            {
                id = 'id_icon',
                widget = wibox.widget.textbox,
                forced_width = beautiful.font_size + m,
            },
            {
                id = 'id_progress',
                widget = wibox.widget.progressbar,
                max_value = 100,
                forced_width = dpi(50),
                margins = {
                    top = beautiful.wibar_height / 2 - m,
                    bottom = beautiful.wibar_height / 2 - m,
                    left = m,
                    right = m,
                },
                color = beautiful.fg_normal,
                background_color = beautiful.bg_normal_alt
                    or beautiful.bg_normal,
            },
            layout = wibox.layout.fixed.horizontal,
        }
        gears.timer.delayed_call(function ()
            if connect() then
                update()
            end
        end)
    end
    return widget
end

function audio.adjust(v)
    if not connect() then
        return
    end
    local i = math.max(0, math.min(get_volume() + v, 100))
    sink:set_volume_percent({i})
end

function audio.toggle()
    if not connect() then
        return
    end
    sink:toggle_muted()
end

return audio
