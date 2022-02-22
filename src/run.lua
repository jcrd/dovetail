return function (share)
    require('dovetail.global').share = share
    require('dovetail.client')
    require('dovetail.notification')
    require('dovetail.screen')

    require('dovetail.config').run_hooks()

    local session = require('sessiond_dbus')

    require('dovetail.widgets.audio').init {
        logger = require('dovetail.log'),
        pulseaudio_backend = require('dovetail.widgets.audio.backend.pulseaudio'),
        pulseaudio_dbus = require('pulseaudio_dbus'),
        sessiond_dbus = session,
    }

    session.connect()
end
