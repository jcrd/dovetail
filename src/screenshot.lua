local awful = require('awful')

local config = require('dovetail.config')

local ss = {}
ss.on_command_error = function () end

local directory = '~/screenshots'
local extension = 'png'

local function spawn(region)
    local dir = string.gsub(directory, '~', os.getenv('HOME'))
    local path = string.format('%s/%s.%s', dir, os.date('%F-%H-%M-%S'),
        extension)
    awful.spawn.with_shell(string.format('mkdir -p %s && import %s %s',
        dir,
        region and '' or '-window root',
        path))
end

function ss.take(region)
    awful.spawn.easy_async_with_shell(
        'command -v import',
        function (_, _, _, code)
            if code == 0 then
                spawn(region)
            else
                ss.on_command_error("'import' command not found")
            end
        end)
end

config.add_hook(function (opts)
    directory = opts.screenshot_directory
end)

return ss
