local log = require('dovetail.log')

local pulse = require('pulseaudio_dbus')

local pa = {}

pa.default = {}
pa.on_default_audiosink_change = function () end

local connection_failed = false
local conn
local core
local sink
local widget

local function get_volume(s)
    if not s then
        return 0
    end
    return s:get_volume()[1]
end

local function on_change(s, ...)
    if s.object_path == sink.object_path then
        pa.on_default_audiosink_change(...)
    end
end

local function connect_device(dev)
    if not dev then
        return
    end
    if dev.signals.VolumeUpdated then
        dev:connect_signal(function (s, v)
            on_change(s, v, s:is_muted())
        end, 'VolumeUpdated')
    end
    if dev.signals.MuteUpdated then
        dev:connect_signal(function (s, m)
            on_change(s, get_volume(s), m)
        end, 'MuteUpdated')
    end
    return dev
end

local function update_sink(s)
    if conn then
        sink = pulse.get_device(conn, s or core:get_sinks()[1])
        return sink
    end
end

local function set_volume(v)
    sink:set_volume({math.max(0, math.min(v, 1))})
end

function pa.connect()
    if connection_failed then
        return nil
    end

    if not conn then
        _, conn = xpcall(function ()
            return pulse.get_connection(pulse.get_address())
        end,
        function (err)
            log.error(string.format('[pulseaudio] Failed to connect: %s', err))
        end)
        if not conn then
            connection_failed = true
            return nil
        end
    end

    if not core then
        core = pulse.get_core(conn)

        core:ListenForSignal('org.PulseAudio.Core1.Device.VolumeUpdated', {})
        core:ListenForSignal('org.PulseAudio.Core1.Device.MuteUpdated', {})
        core:ListenForSignal('org.PulseAudio.Core1.NewSink', {core.object_path})

        core:connect_signal(function (_, s)
            if connect_device(update_sink(s)) then
                pa.default.update()
            end
        end, 'NewSink')

        if connect_device(update_sink()) then
            pa.default.update()
        end
    end

    if not sink then
        log.error('[pulseaudio] Failed to get sink')
        connection_failed = true
        return nil
    end

    return pa
end

function pa.default.inc_volume(v)
    set_volume(get_volume(sink) + v)
end

function pa.default.dec_volume(v)
    set_volume(get_volume(sink) - v)
end

function pa.default.toggle_mute()
    sink:toggle_muted()
end

function pa.default.update()
    on_change(sink, get_volume(sink), sink:is_muted())
end

return pa
