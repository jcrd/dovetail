local naughty = require('naughty')

local session = require('sessiond_dbus')

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
