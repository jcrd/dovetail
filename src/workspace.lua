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

tag.connect_signal('request::default_layouts', function ()
    awful.layout.append_default_layouts {
        dovetail.layout.left,
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

local function new_workspace(name, scratch, args)
    local t = workspace.new(name, args)
    t.scratch_workspace = scratch
    return t
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
            local n = name or config.options.scratch_workspace_name
            t = new_workspace(n, name == nil)
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
    local n = args.name or config.options.scratch_workspace_name
    new_workspace(n, args.name == nil, args)
end

config.add_hook(function (opts)
    if opts.rename_scratch_workspaces then
        client.connect_signal('focus', function (c)
            if c.launch_panel then
                return
            end
            local t = c.first_tag
            if t.scratch_workspace then
                t.name = c.class
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
            if #cs == 1 and not cs[1].launch_panel then
                t.name = cs[1].class
            end
        end

        client.connect_signal('tagged', tags_changed)
        client.connect_signal('untagged', tags_changed)
    end
end)

return ws
