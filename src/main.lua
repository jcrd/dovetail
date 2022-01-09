require('dovetail.client')
require('dovetail.notification')
require('dovetail.screen')

require('dovetail.config').run_hooks()

require('sessiond_dbus').connect()
