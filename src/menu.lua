local awful = require('awful')

local workspace = require('awesome-launch.workspace')

local menu = {}

menu.workspace = {}
menu.workspace.search_paths = {}

function menu.workspace.new()
    if #menu.workspace.search_paths == 0 then
        return
    end
    local paths = table.concat(menu.workspace.search_paths, ' ')
    local cmd = string.format('find %s -maxdepth 2 -name %s', paths,
        workspace.filename)
    cmd = cmd..' -printf "%h\n" | rofi -dmenu -p workspace'
    awful.spawn.easy_async_with_shell(cmd, function (out)
        out = string.gsub(out, '\n', '')
        if out == '' then
            return
        end
        local t = workspace.new(out:match('([^/]+)$'), {
            props = {layout = awful.layout.layouts[1]},
            load_workspace = out,
        })
        t:view_only()
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
