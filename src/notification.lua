local naughty = require('naughty')

local session = require('sessiond_dbus')

local config = require('dovetail.config')
local inhibit = require('dovetail.inhibit')

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

if config.options.enable_battery_widget then
    local battery = require('dovetail.widgets.battery')

    local batt_charged = false
    local batt_low = false

    battery.on_update = function (power, time, percent)
        if power then
            batt_low = false
            if percent >= config.options.battery_charged_percent then
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
            if percent <= config.options.battery_low_percent then
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
