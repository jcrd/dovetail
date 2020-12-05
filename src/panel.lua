local panel = require('awesome-launch.panel')

local selected_tag = require('dovetail.util').selected_tag

function panel.toggle_func(c, state)
    local tags = {}
    if state then
        tags = {selected_tag()}
    end
    c:tags(tags)
end

panel.setup_func = nil
