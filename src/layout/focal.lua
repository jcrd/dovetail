-- Modified magnifier layout

local focal = {}

focal.name = 'focal'

-- This layout handles the currently focused client specially and needs to be
-- called again when the focus changes.
focal.need_focus_update = true

local function get_screen(s)
    return s and screen[s]
end

function focal.arrange(p)
    local area = p.workarea
    local cls = p.clients
    local focus = p.focus or client.focus
    local t = p.tag or screen[p.screen].selected_tag
    local fidx

    -- Check that the focused window is on the right screen
    if focus and focus.screen ~= get_screen(p.screen) then focus = nil end

    -- If no window is focused or focused window is not tiled, take the first tiled one.
    if not focus or focus.floating then
        focus = cls[1]
        fidx = 1
    end

    -- Abort if no clients are present
    if not focus then return end

    local geometry = {}
    geometry.width = area.width * t.focal_width
    geometry.height = area.height
    geometry.x = area.x + (area.width - geometry.width) / 2
    geometry.y = area.y + (area.height - geometry.height) / 2

    local g = {
        x = geometry.x,
        y = geometry.y,
        width = geometry.width,
        height = geometry.height
    }
    p.geometries[focus] = g

    if #cls > 1 then
        geometry.x = area.x
        geometry.y = area.y
        geometry.height = area.height
        geometry.width = area.width

        -- We don't know the focus window index. Try to find it.
        if not fidx then
            for k, c in ipairs(cls) do
                if c == focus then
                    fidx = k
                    break
                end
            end
        end

        -- First move clients that are before focused client.
        for k = fidx + 1, #cls do
            p.geometries[cls[k]] = {
                x = geometry.x,
                y = geometry.y,
                width = geometry.width,
                height = geometry.height
            }
        end

        -- Then move clients that are after focused client.
        -- So the next focused window will be the one at the top of the screen.
        for k = 1, fidx - 1 do
            p.geometries[cls[k]] = {
                x = geometry.x,
                y = geometry.y,
                width = geometry.width,
                height = geometry.height
            }
        end
    end
end

return focal
