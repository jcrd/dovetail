local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = require('beautiful.xresources').apply_dpi

local log = require('dovetail.log')

local session = require('sessiond_dbus')

local audio = {}

local widget
local backend
local backend_name

local function format_icon(i)
    return '<span rise="4000">'..i..'</span>'
end

local function on_change(v, m)
    if audio.on_change then
        audio.on_change(v * 100, m)
    end

    if not widget then
        return
    end

    widget.id_progress.value = v
    widget.id_icon.markup = format_icon(audio.widget.icons[m])

    if not widget.visible then
        widget.visible = true
    end
end

local function with_backend(func_name, ...)
    if not backend then
        return
    end
    if not backend.default then
        log.error('[audio] Failed to get default sink')
        return
    end
    backend.default[func_name](...)
end

local function connect_backend(appear)
    if not appear then
        backend = nil
        if backend_name then
            log.error('[audio] Lost connection to backend: %s', backend_name)
            backend_name = nil
        end
        return
    end

    if session.audio_enabled then
        backend_name = 'sessiond'
        backend = session.audiosinks
        session.on_default_audiosink_change = on_change
    else
        backend_name = 'pulseaudio'
        backend = require('dovetail.widgets.backend.pulseaudio').connect()
        if backend then
            backend.on_default_audiosink_change = on_change
        end
    end

    if not backend then
        log.error('[audio] Failed to connect to backend: %s', backend_name)
        return
    end

    with_backend('update')
end

session.add_hook(function (appear)
    gears.timer.delayed_call(function ()
        connect_backend(appear)
    end)
end)

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
                max_value = 1,
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
            visible = false,
        }
    end
    return widget
end

function audio.inc_volume(v)
    with_backend('inc_volume', v)
end

function audio.dec_volume(v)
    with_backend('dec_volume', v)
end

function audio.toggle_mute()
    with_backend('toggle_mute')
end

return audio
