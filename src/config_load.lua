local awful = require('awful')
local beautiful = require('beautiful')
local gears = require('gears')
local ruled = require('ruled')
local dpi = require('beautiful.xresources').apply_dpi

local ez = require('awesome-ez')
local launch = require('awesome-launch')
local session = require('sessiond_dbus')
local uuid = require('uuid')
local workspace = require('awesome-launch.workspace')

local cmd = require('dovetail.cmd')
local config = require('dovetail.config')
local default = require('dovetail.default')
local inhibit = require('dovetail.inhibit')
local log = require('dovetail.log')
local menu = require('dovetail.menu')

uuid.seed()

local config_env = {cmd = cmd}

local function load_file(file, env)
    if not gears.filesystem.file_readable(file) then
        log.warn('config: %s is inaccessible', file)
        return false
    end

    local ce = pcall(load, '') and _G
        or require('dovetail.lib.compat_env')

    log.debug('config: loading %s', file)

    local f, err = ce.loadfile(file, 't', env)
    if not f then
        log.error('config: '..err)
        return false
    end

    local s, err = pcall(f)
    if not s then
        log.error('config: '..err)
        return false
    end

    return true
end

local function get_config_home()
    return os.getenv('XDG_CONFIG_HOME') or os.getenv('HOME')..'/.config'
end

function config_env.keys(t)
    awful.keyboard.append_global_keybindings(ez.keytable(t))
end

function config_env.client_keys(t)
    client.connect_signal('request::default_keybindings', function ()
        awful.keyboard.append_client_keybindings(ez.keytable(t))
    end)
end

function config_env.buttons(t)
    client.connect_signal('request::default_mousebindings', function ()
        awful.mouse.append_client_mousebindings(ez.btntable(t))
    end)
end

function config_env.theme(t)
    if have_theme then
        return
    end

    t = t or {}
    setmetatable(t, {__index = default.theme})

    t.font_size = dpi(t.font_size)
    t.bar_growth = dpi(t.bar_growth)
    t.info_margins = dpi(t.info_margins)
    t.font = string.format('%s %dpx', t.font_name, t.font_size)
    t.wibar_height = t.font_size + t.bar_growth
    t.master_width_factor = t.master_width

    if t.desktop_wallpaper then
        screen.connect_signal('request::wallpaper', function (s)
            gears.wallpaper.set(t.desktop_wallpaper)
        end)
    end

    launch.widget.color = t.bg_normal_alt
    launch.widget.width = t.wibar_height

    local apply_dpi = {
        'useless_gap',
        'border_width',
        'notification_border_width',
    }

    for _, k in ipairs(apply_dpi) do
        local v = t[k]
        if v then
            t[k] = dpi(v)
        end
    end

    t.tasklist_align = 'center'

    if t.audio_icons then
        require('audio').widget.icons = t.audio_icons
    end
    if t.audio_icons then
        require('battery').widget.icons = t.battery_icons
    end

    if beautiful.init(t) then
        have_theme = true
    else
        log.error('config: error loading theme')
    end
end

function config_env.options(t)
    t = t or {}
    setmetatable(t, {__index = default.options})

    config.options = t

    menu.workspace.search_paths = t.workspace_search_paths
    session.backlights.default.brightness_step = t.brightness_step

    if t.hide_mouse_on_startup then
        awesome.connect_signal('startup', cmd.mouse.hide)
    end
end

function config_env.workspace_clients(t)
    t = gears.table.map(function (v)
        v.systemd = true
        return {v.cmd, v}
    end, t)
    workspace.clients = t
end

function config_env.notifications(t)
    ruled.notification.connect_signal('request::rules', function ()
        ruled.notification.append_rule {
            rule = {},
            properties = {
                screen = awful.screen.preferred,
                implicit_timeout = t.timeout or 5,
                position = t.position or 'top_middle',
            },
        }
    end)
end

function config_env.rules(t)
    local function inhibitor_who(rule)
        if rule.who then
            return rule.who
        end
        local who
        for _, v in pairs(rule) do
            if who then
                break
            end
            if type(v) == 'table' then
                for k, n in pairs(v) do
                    if k == 'class' or k == 'instance' then
                        who = n
                        break
                    end
                end
            end
        end
        return who or 'unknown'
    end

    ruled.client.connect_signal('request::rules', function ()
        ruled.client.append_rule {
            id = 'global',
            rule = {},
            properties = {
                focus = awful.client.focus.filter,
                raise = true,
                screen = awful.screen.preferred,
                placement = awful.placement.no_offscreen,
            },
        }

        for _, r in ipairs(t) do
            if r.inhibit then
                r.callback = inhibit.callback(inhibitor_who(r), r.names)
                r.inhibit = nil
                r.names = nil
                r.who = nil
            end
            r.id = uuid()
            ruled.client.append_rule(r)
        end
    end)
end

return function (default_config, user_config)
    user_config = string.format('%s/%s', get_config_home(), user_config)

    if not load_file(user_config, config_env) then
        load_file(default_config, config_env)
    end

    config_env.theme()
end
