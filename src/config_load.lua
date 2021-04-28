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
local config_dir

local data = default

setmetatable(config_env, {__index = function (_, k)
    return function (t)
        data[k] = gears.table.crush(data[k] or {}, t)
    end
end})

local handler = {}

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

local function path_abs(p)
    return string.sub(p, 1, 1) == '/'
end

local function path_combine(p1, p2)
    return string.format('%s/%s', p1, p2)
end

function config_env.include(path)
    if not path_abs(path) then
        path = path_combine(config_dir, path)
    end
    load_file(path, config_env)
end

function handler.keys(t)
    awful.keyboard.append_global_keybindings(ez.keytable(t))
end

function handler.client_keys(t)
    client.connect_signal('request::default_keybindings', function ()
        awful.keyboard.append_client_keybindings(ez.keytable(t))
    end)
end

function handler.buttons(t)
    client.connect_signal('request::default_mousebindings', function ()
        awful.mouse.append_client_mousebindings(ez.btntable(t))
    end)
end

function handler.theme(t)
    t.font_size = dpi(t.font_size)
    t.bar_padding = dpi(t.bar_padding)
    t.info_margins = dpi(t.info_margins)
    t.font = string.format('%s %dpx', t.font_name, t.font_size)
    t.wibar_height = t.font_size + t.bar_padding
    t.master_width_factor = t.master_width

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

    if not beautiful.init(t) then
        log.error('config: error loading theme')
        if t ~= default.theme then
            handler.theme(default.theme)
        end
    end

    launch.widget.color = t.bg_normal_alt
    launch.widget.border_color = t.border_focus
    launch.widget.width = t.wibar_height

    if t.audio_icons then
        require('audio').widget.icons = t.audio_icons
    end
    if t.battery_icons then
        require('battery').widget.icons = t.battery_icons
    end

    if t.desktop_wallpaper then
        screen.connect_signal('request::wallpaper', function (s)
            gears.wallpaper.set(t.desktop_wallpaper)
        end)
    end
end

function handler.options(t)
    config.options = t

    menu.workspace.search_paths = t.workspace_search_paths

    if t.hide_mouse_on_startup then
        awesome.connect_signal('startup', cmd.mouse.hide)
    end
end

function handler.workspace_clients(t)
    t = gears.table.map(function (v)
        if v.systemd ~= false then
            v.systemd = true
        end
        return {v.cmd, v}
    end, t)
    workspace.clients = t
end

function handler.notifications(t)
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

function handler.rules(t)
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

return function (default_config, dir, file)
    config_dir = path_combine(get_config_home(), dir)

    local user_config = path_combine(config_dir, file)

    if not load_file(user_config, config_env) then
        load_file(default_config, config_env)
    end

    for k, t in pairs(data) do
        if handler[k] then
            handler[k](t)
        end
    end
end
