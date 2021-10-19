local gears = require('gears')

local assets = {}

local function load_image(path, file)
    return gears.surface(string.format('%s/%s', path, file))
end

function assets.load(path)
    assets.pomodoro = {
        working = load_image(path, 'pomodoro/ticking.png'),
        short_break = load_image(path, 'pomodoro/short_break.png'),
        long_break = load_image(path, 'pomodoro/long_break.png'),
    }
end

return assets
