local awful = require('awful')
local gears = require('gears')
local naughty = require('naughty')

local dovetail = require('awesome-dovetail')
local launch = require('awesome-launch')
local panel = require('awesome-launch.panel')
local session = require('sessiond_dbus')

local audio = require('dovetail.widgets.audio')
local config = require('dovetail.config')
local menu = require('dovetail.menu')
local util = require('dovetail.util')
local screenshot = require('dovetail.screenshot')
local selected_tag = util.selected_tag
local ws = require('dovetail.workspace')

require('dovetail.panel')

local cmd = {}

-- Spawning.

function cmd.spawn(arg)
    awful.spawn(arg)
end

function cmd.launch(args)
    if args.set_master then
        args.raise_callback = function (c)
            gears.timer.delayed_call(function ()
                cmd.client.set_master(c)
            end)
        end
    end
    launch.spawn.here().raise_or_spawn(args.cmd, args)
end

function cmd.relaunch(args)
    launch.spawn.here().spawn(args.cmd, args)
end

-- Workspaces.
cmd.workspace = {}

function cmd.workspace.view(index)
    ws.with(index, false, function (t)
        if t == selected_tag() then
            ws.restore()
        else
            t:view_only()
        end
    end)
end

function cmd.workspace.new(args)
    ws.new(args)
end

function cmd.workspace.next(prompt)
    ws.next(1, prompt)
end

function cmd.workspace.prev(prompt)
    ws.next(-1, prompt)
end

cmd.workspace.restore = ws.restore

function cmd.workspace.toggle_panel(args)
    panel.toggle(args.cmd, args)
end

function cmd.workspace.adjust_master_width(i)
    awful.tag.incmwfact(i)
end

-- Clients.
cmd.client = {}

function cmd.client.normalize(c)
    c.floating = false
    c.fullscreen = false
    c.maximized = false
    c.maximized_horizontal = false
    c.maximized_vertical = false
    c.sticky = false
    c.ontop = false
end

function cmd.client.move_to_workspace(index, follow)
    ws.with(index, false, function (t)
        if client.focus then
            client.focus:move_to_tag(t)
            if follow then
                t:view_only()
            end
        end
    end)
end

function cmd.client.follow_to_workspace(index)
    cmd.client.move_to_workspace(index, true)
end

function cmd.client.set_master(c)
    if not dovetail.layout() then
        awful.layout.set(awful.layout.layouts[1], selected_tag())
    end
    if c ~= awful.client.getmaster(c.screen) then
        awful.client.setmaster(c)
    end
end

function cmd.client.toggle_max()
    awful.layout.inc(1)
end

function cmd.client.toggle_floating(c)
    c.floating = not c.floating
end

function cmd.client.toggle_fullscreen(c)
    c.fullscreen = not c.fullscreen
    c:raise()
end

function cmd.client.close(c)
    c:kill()
end

cmd.client.focus = {}

cmd.client.focus.other = dovetail.focus.other

local function client_focus_next(i)
    if not dovetail.focus.byidx(i) then
        awful.client.focus.byidx(i)
    end
end

function cmd.client.focus.next()
    client_focus_next(1)
end

function cmd.client.focus.prev()
    client_focus_next(-1)
end

function cmd.client.focus.other_layer()
    if not client.focus then
        return
    end

    local found

    local function history_get(func)
        local s = awful.screen.focused()
        awful.client.focus.history.get(s, 0, function (c)
            if not found and func(c) then
                found = c
                return true
            end
        end)
    end

    if client.focus.floating then
        history_get(function (c)
            return not c.floating
        end)
    else
        history_get(function (c)
            return c.floating
        end)
    end

    if found then
        found:emit_signal('request::activate',
            'dovetail.cmd.client.focus.other_layer', {raise=true})
    end
end

-- Menu.
cmd.menu = {}
cmd.menu.new_workspace = menu.workspace.new
cmd.menu.run_workspace = menu.workspace.run
cmd.menu.rename_workspace = menu.workspace.rename
cmd.menu.run = menu.run

-- Mouse.
cmd.mouse = {}

function cmd.mouse.focus(client)
    client:activate { context = 'mouse_click' }
end

function cmd.mouse.move(client)
    client:activate { context = 'mouse_click', action = 'mouse_move' }
end

function cmd.mouse.resize(client)
    client:activate { context = 'mouse_click', action = 'mouse_resize' }
end

function cmd.mouse.hide()
    local geom = mouse.screen.geometry
    mouse.coords({x = geom.width, y = geom.height}, true)
end

-- Notifications.
cmd.notification = {}
cmd.notification.destroy_all = naughty.destroy_all_notifications

local function backlight(func)
    return function ()
        local c = config.options[func..'_cmd']
        if c then
            awful.spawn(string.format(c, config.options.brightness_step))
        else
            local bl = session.backlights[config.options.backlight_name]
            bl[func](config.options.brightness_step)
        end
    end
end

-- Session.
cmd.session = {}
cmd.session.lock = session.lock
cmd.session.brightness = {}
cmd.session.brightness.inc = backlight('inc_brightness')
cmd.session.brightness.dec = backlight('dec_brightness')

-- Audio.
cmd.audio = {}
cmd.audio.adjust = audio.adjust
cmd.audio.toggle = audio.toggle

-- Screenshot.
cmd.screenshot = {}
cmd.screenshot.take = screenshot.take
cmd.screenshot.take_region = function () screenshot.take(true) end

-- Window manager.
cmd.wm = {}
cmd.wm.restart = awesome.restart
cmd.wm.quit = awesome.quit

-- System.
cmd.system = {}

function cmd.system.suspend()
    awful.spawn('systemctl suspend')
end

function cmd.system.poweroff()
    awful.spawn('systemctl poweroff')
end

cmd.util = {}
cmd.util.clientinfo = util.clientinfo

return cmd
