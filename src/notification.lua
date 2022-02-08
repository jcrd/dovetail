local naughty = require('naughty')

local session = require('sessiond_dbus')

local config = require('dovetail.config')
local menu = require('dovetail.menu')
local screenshot = require('dovetail.screenshot')

naughty.connect_signal('request::display', function (n)
    naughty.layout.box {notification = n}
end)

naughty.connect_signal('request::display_error', function (message, startup)
    naughty.notification {
        urgency = 'critical',
        title   = 'Error'..(startup and ' during startup' or ''),
        message = message,
    }
end)

session.on_backlight_error = function (msg)
    naughty.notification {
        urgency = 'critical',
        title = 'Session backlight error',
        message = msg,
    }
end

menu.on_spawn_error = function (msg)
    naughty.notification {
        urgency = 'critical',
        title = 'Menu spawn error',
        message = msg,
    }
end

screenshot.on_command_error = function (msg)
    naughty.notification {
        urgency = 'critical',
        title = 'Screenshot error',
        message = msg,
    }
end

config.add_hook(function (opts)
    if opts.fullscreen_audio_notifications then
        local audio = require('dovetail.widgets.audio')
        local audio_notif

        audio.on_change = function (v, m)
            if not (client.focus and client.focus.fullscreen) then
                return
            end
            local msg = string.format('%s %d%%', audio.widget.icons[m], v)
            if not audio_notif or audio_notif.is_expired then
                audio_notif = naughty.notification {
                    message = msg,
                    timeout = 1,
                }
            else
                audio_notif.message = msg
            end
        end
    end
end)

config.add_hook(function (opts)
    if opts.enable_battery_widget then
        local battery = require('dovetail.widgets.battery')

        local batt_charged = false
        local batt_low = false

        battery.on_update = function (power, time, percent)
            if power then
                batt_low = false
                if percent >= opts.battery_charged_percent then
                    if batt_charged then
                        return
                    end
                    naughty.notification {
                        urgency = 'normal',
                        title = string.format('Full battery (%d%%)', percent),
                        message = 'Battery is charged',
                    }
                    batt_charged = true
                end
            else
                batt_charged = false
                if percent <= opts.battery_low_percent then
                    if batt_low then
                        return
                    end
                    naughty.notification {
                        urgency = 'critical',
                        title = string.format('Low battery (%d%%)', percent),
                        message = string.format('Time to empty: %s', time),
                    }
                    batt_low = true
                end
            end
        end
    end
end)
