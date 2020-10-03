local awful = require('awful')

local util = {}

function util.selected_tag(s)
    s = s or awful.screen.focused()
    return s.selected_tag
end

return util
