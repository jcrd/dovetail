local log = {}

local debug = os.getenv('DOVETAIL_DEBUG')

local function stderr(header, msg, ...)
    local s = string.format('%s %s\n', header, msg)
    io.stderr:write(string.format(s, ...))
end

setmetatable(log, {__call = function (_, msg, ...)
    print(string.format(msg, ...))
end})

function log.debug(msg, ...)
    if debug then
        log('[debug] '..msg, ...)
    end
end

function log.warn(...)
    stderr('[warn]', ...)
end

function log.error(...)
    stderr('[error]', ...)
end

return log
