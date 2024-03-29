local awful = require('awful')
local gears = require('gears')
local naughty = require('naughty')

local dovetail = require('awesome-dovetail')
local launch = require('awesome-launch')
local panel = require('awesome-launch.panel')
local session = require('sessiond_dbus')

local audio = require('dovetail.widgets.audio')
local pomodoro = require('dovetail.widgets.pomodoro')
local config = require('dovetail.config')
local menu = require('dovetail.menu')
local util = require('dovetail.util')
local screenshot = require('dovetail.screenshot')
local selected_tag = util.selected_tag
local ws = require('dovetail.workspace')

require('dovetail.panel')

local minimized_clients = {}

local cmd = {}

-- Spawning.

function cmd.spawn(arg)
    awful.spawn(arg)
end

function cmd.launch(args)
    if args.set_master then
        args.raise_callback = function (c)
            gears.timer.delayed_call(function ()
                cmd.client.master.set(c)
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

function cmd.workspace.adjust_width(i)
    local t = selected_tag()
    if t.layout.name == 'focal' then
        local w = t.focal_width + i
        if w >= 0 and w <= 1 then
            t.focal_width = w
        end
    else
        awful.tag.incmwfact(i, t)
    end
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

local function with_layout(func)
    local set = not dovetail.layout()
    if set then
        awful.layout.set(awful.layout.layouts[1], selected_tag())
    end
    func(set)
end

cmd.client.master = {}

function cmd.client.master.set(c)
    with_layout(function ()
        if c ~= awful.client.getmaster(c.screen) then
            awful.client.setmaster(c)
        end
    end)
end

function cmd.client.master.demote()
    with_layout(dovetail.master.demote)
end

function cmd.client.master.promote()
    with_layout(dovetail.master.promote)
end

function cmd.client.master.cycle()
    with_layout(dovetail.master.cycle)
end

function cmd.client.minimize(c)
    c.minimized = true
    table.insert(minimized_clients, c)
end

function cmd.client.replace(c)
    local tag = c.first_tag
    local function tagged(cl, t)
        if util.client_is_valid(c) and t == tag then
            cmd.client.minimize(c)
            cl:connect_signal('untagged', function (_, t)
                if util.client_is_valid(c) and t == tag then
                    cmd.client.unminimize(c)
                end
            end)
            client.disconnect_signal('tagged', tagged)
        end
    end
    client.connect_signal('tagged', tagged)
end

function cmd.client.unminimize()
    local c = util.next_valid_client(minimized_clients)
    if not c then
        local s = awful.screen.focused()
        if #s.hidden_clients == 0 then
            return
        end
        c = s.hidden_clients[1]
    end
    c.minimized = false
    c:emit_signal('request::activate', 'dovetail.cmd.client.unminimize',
        {raise = true})
end

function cmd.client.toggle_focal()
    ws.toggle_layout(awful.layout.layouts[2])
end

function cmd.client.toggle_max()
    ws.toggle_layout(awful.layout.layouts[3])
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
cmd.menu.capture_task = menu.capture_task

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

local function cmd_audio(func_name)
    return function (v)
        audio[func_name](v or config.options.volume_step)
    end
end

-- Audio.
cmd.audio = {}
cmd.audio.volume = {}
cmd.audio.volume.inc = cmd_audio('inc_volume')
cmd.audio.volume.dec = cmd_audio('dec_volume')
cmd.audio.mute = {}
cmd.audio.mute.toggle = audio.toggle_mute

-- Pomodoro.
cmd.pomodoro = {}
cmd.pomodoro.toggle = pomodoro.toggle
cmd.pomodoro.stop = pomodoro.stop
cmd.pomodoro.restart = pomodoro.restart
cmd.pomodoro.skip = pomodoro.skip

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
