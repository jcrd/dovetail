-- This project is licensed under the MIT License (see LICENSE).

--[[--
    A library for interfacing with the `sessiond` DBus service.

    @usage
    session = require("sessiond_dbus")

    -- Set the step by which the 'default' backlight's brightness will be changed.
    session.backlights.default.brightness_step = 10

    -- Increase the 'default' backlight's brightness by 10.
    session.backlights.default.inc_brightness()

    -- Set the 'default' backlight's brightness to 50.
    session.backlights.default.set_brightness(50)

    -- Decrease 'intel_backlight' brightness by 100.
    session.backlights.intel_backlight.dec_brightness(100)

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

    @author James Reed <jcrd@tuta.io>
    @copyright 2020 James Reed
    @license MIT
    @module sessiond-dbus
]]

local dbus = require("dbus_proxy")

local session = {}
local backlights = {}
local callbacks = {}
session.backlights = {}
session.on_backlight_error = function () end

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
    bl.brightness_step = 10

    --- Increase backlight brightness.
    --
    -- @param i Increase by given value or session.backlights.default.brightness_step
    -- @function backlights.default.inc_brightness
    function bl.inc_brightness(i)
        bl.proxy:IncBrightness(i or bl.brightness_step)
    end

    --- Decrease backlight brightness.
    --
    -- @param i Decrease by given value or session.backlights.default.brightness_step
    -- @function backlights.default.dec_brightness
    function bl.dec_brightness(i)
        bl.proxy:IncBrightness(-1 * (i or bl.brightness_step))
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
        end
    end
end

local function callback(p, appear)
    if appear then
        for _, path in ipairs(p.Backlights) do
            add_backlight(p, path)
        end
        p:connect_signal(add_backlight, "AddBacklight")
        p:connect_signal(remove_backlight, "RemoveBacklight")

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
    end
end

local proxy = dbus.monitored.new({
        bus = dbus.Bus.SESSION,
        name = "org.sessiond.session1",
        interface = "org.sessiond.session1.Session",
        path = "/org/sessiond/session1",
    }, callback)

--- Lock the current session.
--
-- @function lock
function session.lock()
    if proxy.is_connected then
        return proxy:Lock()
    end
end

--- Inhibit inactivity.
--
-- @param who A string describing who is inhibiting.
-- @param why A string describing why the inhibitor is running.
-- @return An ID used to stop the inhibitor.
-- @function inhibit
function session.inhibit(who, why)
    if proxy.is_connected then
        return proxy:Inhibit(who or '', why or '')
    end
end

--- Stop an inhibitor.
--
-- @param id The ID of the inhibitor to stop.
-- @function uninhibit
function session.uninhibit(id)
    if proxy.is_connected then
        proxy:Uninhibit(id)
    end
end

--- Connect callback to sessiond DBus signal.
--
-- @param name Name of signal.
-- @param cb Callback function.
-- @function connect_signal
function session.connect_signal(name, cb)
    if proxy.is_connected then
        proxy:connect_signal(cb, name)
    else
        table.insert(callbacks, {name=name, func=cb})
    end
end

return session
