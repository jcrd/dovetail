local default = require('dovetail.default')

local config = {}
local hooks = {}

config.widgets = default._widgets
config.options = {}

function config.add_hook(func)
    table.insert(hooks, func)
end

function config.run_hooks()
    for _, func in ipairs(hooks) do
        func(config.options)
    end
end

return config
