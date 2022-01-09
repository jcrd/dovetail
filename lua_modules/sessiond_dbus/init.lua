-- This project is licensed under the MIT License (see LICENSE).

--[[--
    A library for interfacing with the `sessiond` DBus service.

    @usage
    session = require("sessiond_dbus")

    -- Increase the 'default' backlight's brightness by 10.
    session.backlights.default.inc_brightness(10)

    -- Set the 'default' backlight's brightness to 50.
    session.backlights.default.set_brightness(50)

    -- Decrease 'intel_backlight' brightness by 100.
    session.backlights.intel_backlight.dec_brightness(100)

    -- Increase the 'default' audio sink's volume by 0.1.
    session.audiosinks.default.inc_volume(0.1)

    -- Toggle the 'default' audio sink's mute state.
    session.audiosinks.default.toggle_mute()

    -- Lock the session.
    session.lock()

    -- Inhibit.
    id = session.inhibit('chromium', 'media')

    -- Stop inhibitor.
    session.uninhibit(id)

    -- Connect callback to sessiond DBus signal.
    session.connect_signal("PrepareForSleep", function (state)
        if state then
            print("Preparing for sleep...")
        end
    end)

    -- Add function to be called when the DBus service appears.
    session.add_hook(function (appear)
        if appear then
            print("Service appeared")
        end
    end)

    @author James Reed <jcrd@tuta.io>
    @copyright 2020 James Reed
    @license MIT
    @module sessiond-dbus
]]

local dbus = require("dbus_proxy")

local session = {}
local backlights = {}
local callbacks = {}
local hooks = {}

local session_proxy
local default_audiosink_id

session.backlights = {}
session.on_backlight_error = function () end

session.audio_enabled = false
session.audiosinks = {}
session.on_default_audiosink_change = function () end

local dummy_backlight = {
    inc_brightness = function () end,
    dec_brightness = function () end,
    set_brightness = function () end,
}

setmetatable(session.backlights, {__index = function (_, k)
    local bl
    if k == 'default' then
        _, bl = next(backlights)
    else
        bl = backlights[k]
    end
    if not bl then
        session.on_backlight_error("Backlight '"..k.."' not found")
        return dummy_backlight
    end
    return bl
end})

local function new_backlight(path)
    local bl = {}
    bl.obj_path = path
    bl.proxy = dbus.Proxy:new {
        bus = dbus.Bus.SESSION,
        name = "org.sessiond.session1",
        interface = "org.sessiond.session1.Backlight",
        path = path,
    }

    --- Increase backlight brightness.
    --
    -- @param i Increase by given value
    -- @function backlights.default.inc_brightness
    function bl.inc_brightness(i)
        bl.proxy:IncBrightness(i)
    end

    --- Decrease backlight brightness.
    --
    -- @param i Decrease by given value
    -- @function backlights.default.dec_brightness
    function bl.dec_brightness(i)
        bl.proxy:IncBrightness(-i)
    end

    --- Set backlight brightness.
    --
    -- @param i Brightness value
    -- @function backlights.default.set_brightness
    function bl.set_brightness(i)
        bl.proxy:SetBrightness(i)
    end

    return bl
end

local function add_backlight(_, path)
    local bl = new_backlight(path)
    backlights[bl.proxy.Name] = bl
end

local function remove_backlight(_, path)
    for n, bl in pairs(backlights) do
        if bl.obj_path == path then
            backlights[n] = nil
            return
        end
    end
end

local function new_audiosink(path)
    local as = {}
    as.obj_path = path
    as.proxy = dbus.Proxy:new {
        bus = dbus.Bus.SESSION,
        name = "org.sessiond.session1",
        interface = "org.sessiond.session1.AudioSink",
        path = path,
    }

    local function on_change(...)
        if as.proxy.Id == default_audiosink_id then
            session.on_default_audiosink_change(...)
        end
    end

    as.proxy:connect_signal(function (_, v)
        on_change(v, as.proxy.Mute)
    end, "ChangeVolume")
    as.proxy:connect_signal(function (_, m)
        on_change(as.proxy.Volume, m)
    end, "ChangeMute")

    --- Increase audio sink volume.
    --
    -- @param i Increase by given value
    -- @function audiosinks.default.inc_volume
    function as.inc_volume(i)
        as.proxy:IncVolume(i)
    end

    --- Decrease audio sink volume.
    --
    -- @param i Decrease by given value
    -- @function audiosinks.default.dec_volume
    function as.dec_volume(i)
        as.proxy:IncVolume(-i)
    end

    --- Set audio sink volume.
    --
    -- @param i Volume value
    -- @function audiosinks.default.set_volume
    function as.set_volume(i)
        as.proxy:SetVolume(i)
    end

    --- Set audio sink mute state.
    --
    -- @param m Mute state
    -- @function audiosinks.default.set_mute
    function as.set_mute(m)
        as.proxy:SetMute(m)
    end

    --- Toggle audio sink mute state.
    --
    -- @function audiosinks.default.toggle_mute
    function as.toggle_mute()
        as.proxy:ToggleMute()
    end

    --- Call `on_default_audiosink_change` function if sink is default.
    --
    -- @function audiosinks.default.update
    function as.update()
        on_change(as.proxy.Volume, as.proxy.Mute)
    end

    return as
end

local function add_audiosink(_, path)
    local as = new_audiosink(path)
    session.audiosinks[as.proxy.Id] = as
    if as.proxy.Id == default_audiosink_id then
        session.audiosinks.default = as
        as.update()
    end
end

local function remove_audiosink(_, path)
    for i, as in pairs(session.audiosinks) do
        if as.obj_path == path then
            session.audiosinks[i] = nil
            if as.proxy.Id == default_audiosink_id then
                session.audiosinks.default = nil
            end
            return
        end
    end
end

local function change_default_audiosink(_, path)
    default_audiosink_id = tonumber(string.match(path, "/(%d+)$"))

    for _, as in pairs(session.audiosinks) do
        if as.obj_path == path then
            session.audiosinks.default = as
            as.update()
            return
        end
    end

    session.audiosinks.default = nil
end

local function callback(p, appear)
    if appear then
        for _, path in ipairs(p.Backlights) do
            add_backlight(p, path)
        end

        p:connect_signal(add_backlight, "AddBacklight")
        p:connect_signal(remove_backlight, "RemoveBacklight")

        if p.AudioSinks then
            for _, path in ipairs(p.AudioSinks) do
                add_audiosink(_, path)
            end

            change_default_audiosink(_, p.DefaultAudioSink)

            p:connect_signal(add_audiosink, "AddAudioSink")
            p:connect_signal(remove_audiosink, "RemoveAudioSink")
            p:connect_signal(change_default_audiosink, "ChangeDefaultAudioSink")

            session.audio_enabled = true
        end

        for _, cb in ipairs(callbacks) do
            p:connect_signal(function (_, ...)
                cb.func(...)
            end, cb.name)
        end
        callbacks = {}
    else
        for n in pairs(backlights) do
            backlights[n] = nil
        end

        for i in pairs(session.audiosinks) do
            session.audiosinks[i] = nil
        end

        session.audio_enabled = false
    end

    for _, func in ipairs(hooks) do
        func(appear)
    end
end

local function connected()
    return session_proxy and session_proxy.is_connected
end

--- Lock the current session.
--
-- @function lock
function session.lock()
    if connected() then
        return session_proxy:Lock()
    end
end

--- Inhibit inactivity.
--
-- @param who A string describing who is inhibiting.
-- @param why A string describing why the inhibitor is running.
-- @return An ID used to stop the inhibitor.
-- @function inhibit
function session.inhibit(who, why)
    if connected() then
        return session_proxy:Inhibit(who or '', why or '')
    end
end

--- Stop an inhibitor.
--
-- @param id The ID of the inhibitor to stop.
-- @function uninhibit
function session.uninhibit(id)
    if connected() then
        session_proxy:Uninhibit(id)
    end
end

--- Connect callback to sessiond DBus signal.
--
-- @param name Name of signal.
-- @param cb Callback function.
-- @function connect_signal
function session.connect_signal(name, cb)
    if connected() then
        session_proxy:connect_signal(cb, name)
    else
        table.insert(callbacks, {name=name, func=cb})
    end
end

--- Add a function to be called when the DBus service appears or disappears.
--
-- @param func Hook function, with appear state as its only argument.
-- @function add_hook
function session.add_hook(func)
    table.insert(hooks, func)
end

--- Connect to sessiond DBus service.
--
-- @function connect
function session.connect()
    session_proxy = dbus.monitored.new({
        bus = dbus.Bus.SESSION,
        name = "org.sessiond.session1",
        interface = "org.sessiond.session1.Session",
        path = "/org/sessiond/session1",
    }, callback)
end

return session
