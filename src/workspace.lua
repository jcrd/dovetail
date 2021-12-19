local awful = require('awful')
local beautiful = require('beautiful')
local gears = require('gears')

local dovetail = require('awesome-dovetail')
local selected_tag = require('dovetail.util').selected_tag
local workspace = require('awesome-launch.workspace')

local config = require('dovetail.config')
local menu = require('dovetail.menu')

local ws = {}

local history = {2, 1}

local function get_layout()
    local lo = dovetail.layout[config.options.stack_position]
    if not lo then
        local default = require('dovetail.default')
        return dovetail.layout[default.options.stack_position]
    end
    return lo
end

tag.connect_signal('request::default_layouts', function ()
    awful.layout.append_default_layouts {
        get_layout(),
        require('dovetail.layout.focal'),
        awful.layout.suit.max,
    }
end)

screen.connect_signal('tag::history::update', function (s)
    gears.timer.delayed_call(function ()
        local t = selected_tag(s)
        if not t then
            return
        end
        local i = gears.table.hasitem(history, t.index)
        if i then
            table.remove(history, i)
        end
        table.insert(history, t.index)
    end)
end)

local function new_workspace(name, args)
    local n = name or config.options.scratch_workspace_name
    local t = workspace.new(n, args)
    t.scratch_workspace = name == nil
    t.focal_width = config.options.focal_width
    return t
end

local function client_tag_name(c)
    return c.class or c.name or "unknown"
end

function ws.recreate(clients_per_tag)
    if #clients_per_tag == 0 then
        return
    end

    local default = table.remove(clients_per_tag, 1)
    for _, c in ipairs(default) do
        local s = awful.screen.preferred(c)
        c:tags({s.tags[1]})
    end

    for i, cs in ipairs(clients_per_tag) do
        for _, c in ipairs(cs) do
            local s = awful.screen.preferred(c)
            local t = s.tags[i + 1] or new_workspace(nil,
                {props = {screen = s}})
            c:tags({t})
        end
    end
end

function ws.restore()
    local tag = selected_tag()
    for index=#history,1,-1 do
        local i = history[index]
        if i ~= tag.index then
            ws.with(i, nil, function (t)
                t:view_only()
            end)
            break
        end
    end
end

function ws.emptyp(tag)
    tag = tag or selected_tag()
    if not (tag and tag.scratch_workspace) then
        return false
    end
    local c = tag:clients()
    return #c == 0 or (#c == 1 and c[1].launch_panel)
end

function ws.with(index, prompt, func, name)
    local s = awful.screen.focused()
    index = index or #s.tags + 1
    if index > #s.tags + 1 then
        return
    end
    local t = s.tags[index]
    if not t then
        if ws.emptyp(s.tags[index - 1]) then
            t = s.tags[1]
        else
            if not name and prompt then
                menu.prompt('name', function (n) ws.with(index, func, n) end)
                return
            end
            if name == '' then
                return
            end
            t = new_workspace(name)
        end
    end
    func(t)
end

function ws.next(i, prompt, func)
    local v = selected_tag()
    index = v.index + i
    if index < 1 then
        index = #v.screen.tags + 1
    end
    ws.with(index, prompt, function (t)
        if func then
            func(t)
        end
        t:view_only()
    end)
end

function ws.new(args)
    args.callback = function (t)
        t:view_only()
    end
    new_workspace(args.name, args)
end

function ws.toggle_layout(lo)
    local t = selected_tag()
    if t.layout.name == lo.name then
        lo = awful.layout.layouts[1]
    end
    awful.layout.set(lo, t)
end

config.add_hook(function (opts)
    if opts.rename_scratch_workspaces then
        client.connect_signal('focus', function (c)
            if c.launch_panel then
                return
            end
            local t = c.first_tag
            if t.scratch_workspace then
                t.name = client_tag_name(c)
            end
        end)

        client.connect_signal('unfocus', function (c)
            if c.launch_panel then
                return
            end
            local t = c.first_tag
            if not (t and t.selected and t.scratch_workspace) then
                return
            end
            if not (client.focus and client.focus.first_tag == t) then
                t.name = opts.scratch_workspace_name
            end
        end)

        local function tags_changed(_, t)
            if not t.scratch_workspace then
                return
            end
            local cs = t:clients()
            local c = cs[#cs]
            if not c then
                t.name = opts.scratch_workspace_name
            elseif not c.launch_panel then
                t.name = client_tag_name(c)
            end
        end

        client.connect_signal('tagged', tags_changed)
        client.connect_signal('untagged', tags_changed)
    end
end)

return ws
