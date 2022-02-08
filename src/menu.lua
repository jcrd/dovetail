local awful = require('awful')
local gears = require('gears')

local workspace = require('awesome-launch.workspace')

local config = require('dovetail.config')
local selected_tag = require('dovetail.util').selected_tag

local menu = {}

local filename = os.getenv('WM_LAUNCH_WORKSPACE_FILENAME') or '.workspace'
local search_paths = {}

menu.workspace = {}

menu.on_spawn_error = function () end

local function with_output(cmd, func)
    awful.spawn.easy_async_with_shell(cmd, function (out)
        out = string.gsub(out, '\n', '')
        if out ~= '' then
            func(out)
        end
    end)
end

function menu.workspace.new()
    if #search_paths == 0 then
        return
    end
    local paths = table.concat(search_paths, ' ')
    local cmd = string.format('find %s -maxdepth 2 -name %s', paths, filename)
    cmd = cmd..' -printf "%h\n" | rofi -dmenu -p workspace'
    with_output(cmd, function (out)
        awful.spawn('wm-launch -w '..out)
    end)
end

function menu.workspace.run()
    local cmd = "rofi -show run -run-command 'echo {cmd}'"
    with_output(cmd, function (out)
        workspace.new(out, {
            clients = {out},
            callback = function (t)
                t:view_only()
            end,
        })
    end)
end

function menu.workspace.rename()
    menu.prompt('rename', function (out)
        local t = selected_tag()
        if t and out ~= '' then
            t.name = out
            t.scratch_workspace = false
        end
    end)
end

function menu.prompt(text, func)
    local cmd = string.format('rofi -dmenu -l 0 -p %s', text)
    awful.spawn.easy_async(cmd, func)
end

function menu.run()
    awful.spawn('rofi -show run')
end

function menu.capture_task()
    menu.prompt('task', function (n)
        if not n:find('project:') then
            local t = selected_tag()
            if not (t.index == 1 or t.scratch_workspace) then
                n = string.format('%s project:%s', n, t.name)
            end
        end
        local r = awful.spawn(string.format('task add %s', n))
        if type(r) == 'string' then
            menu.on_spawn_error("Failed to spawn: " .. r)
        end
    end)
end

config.add_hook(function (opts)
    search_paths = opts.workspace_search_paths
end)

return menu
