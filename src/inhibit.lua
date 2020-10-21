local session = require('sessiond_dbus')

local inhibit = {}

local function uninhibit(c)
    if c.inhibit_id then
        session.uninhibit(c.inhibit_id)
        c.inhibit_id = nil
    end
end

local function toggle_inhibit(who, names)
    return function (c)
        if not c.active then
            uninhibit(c)
            return
        end
        if #names == 0 then
            c.inhibit_id = session.inhibit(who)
            return
        end
        local found
        for _, name in ipairs(names) do
            if string.find(c.name, name) == 1 then
                if not c.inhibit_id then
                    c.inhibit_id = session.inhibit(who, name)
                end
                found = true
                break
            end
        end
        if not found then
            uninhibit(c)
        end
    end
end

function inhibit.callback(who, names)
    return function (c)
        c.toggle_inhibit = toggle_inhibit(who, names)
        if #names > 0 then
            c:connect_signal('property::name', c.toggle_inhibit)
        end
        c:connect_signal('property::active', c.toggle_inhibit)
        c:connect_signal('request::unmanage', uninhibit)
    end
end

return inhibit
