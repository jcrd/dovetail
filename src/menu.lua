local awful = require('awful')

local workspace = require('awesome-launch.workspace')

local menu = {}

local env = os.getenv('WM_LAUNCH_WORKSPACE_FILENAME')

menu.workspace = {}
menu.workspace.search_paths = {}
menu.workspace.filename = env or '.workspace'

function menu.workspace.new()
    if #menu.workspace.search_paths == 0 then
        return
    end
    local paths = table.concat(menu.workspace.search_paths, ' ')
    local cmd = string.format('find %s -maxdepth 2 -name %s', paths,
        menu.workspace.filename)
    cmd = cmd..' -printf "%h\n" | rofi -dmenu -p workspace'
    awful.spawn.easy_async_with_shell(cmd, function (out)
        out = string.gsub(out, '\n', '')
        if out ~= '' then
            awful.spawn('wm-launch -w '..out)
        end
    end)
end

function menu.prompt(text, func)
    local cmd = string.format('rofi -dmenu -lines 0 -p %s', text)
    awful.spawn.easy_async(cmd, func)
end

function menu.run()
    awful.spawn('rofi -show run')
end

return menu
