-- This project is licensed under the MIT License (see LICENSE).

--- Manage tags based on viewports.
--
-- Once connected to a screen via `viewport.connect(screen)`, selecting a single
-- tag will make that tag the new viewport. This tag will remember any other
-- selected tags when the viewport changes, so that when it is re-selected,
-- all previously selected tags are viewed.
--
-- @author James Reed &lt;jcrd@tuta.io&gt;
-- @copyright 2019 James Reed
-- @module awesome-viewport

local awful = require("awful")
local gtable = require("gears.table")

local viewport = {}

local function update(s)
    local selected = s.viewport and s.viewport.selected
    if #s.selected_tags == 1 then
        if selected then
            s.viewport.scene = nil
            return
        end
        s.viewport = s.selected_tag
        if s.viewport.scene then
            awful.tag.viewmore(s.viewport.scene, s)
        end
    elseif selected then
        s.viewport.scene = s.selected_tags
    end
end

--- Get the viewport of a given screen.
--
-- @param s The screen, defaults to `awful.screen.focused().selected_tag`.
-- @return The viewport tag.
-- @function viewport
local function get_viewport(s)
    s = s or awful.screen.focused()
    return s.viewport or s.selected_tag
end

local function tag(c)
    if not c.first_tag then
        c:toggle_tag(get_viewport(c.screen))
    end
end

--- Begin managing the tags on a given screen.
--
-- @param s The screen.
function viewport.connect(s)
    s:connect_signal("tag::history::update", update)
    client.connect_signal("request::tag", tag)
end

--- Stop managing the tags on a given screen.
--
-- @param s The screen.
function viewport.disconnect(s)
    s:disconnect_signal("tag::history::update", update)
    client.disconnect_signal("request::tag", tag)
end

setmetatable(viewport, {__call = function (_, s) return get_viewport(s) end})

return viewport
