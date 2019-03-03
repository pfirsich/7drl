local util = require("util")

local log = {}

log.levels = {
    "debug", -- regular output that is only relevant for developers
    "info", -- regular output
    "warning", -- something could go wrong soon or might be misconfigured/misused
    "error", -- something went wrong and needs attention (by user or developer)
    "critical", -- the application cannot reasonably continue execution
}

log.logLevel = 0 -- everything

log.handlers = {
    function(level, msg) print(msg) end,
}

local levelAbbrev = {
    debug = "DEBG",
    info = "INFO",
    warning = "WARN",
    error = "ERRO",
    critical = "CRIT",
}

local function assertLevel(level)
    assert(util.inList(level, log.levels), "Invalid log level")
end

function log.setLevel(level)
    assertLevel(level)
    logLevel = util.indexOf(level, log.levels)
end

function log.log(level, msg, ...)
    assertLevel(level)
    msg = levelAbbrev[level] .. msg:format(...)
    local levelNum = util.indexOf(level, log.levels)
    if levelNum >= log.logLevel then
        for _, handler in ipairs(log.handlers) do
            handler(level, msg)
        end
    end
end

for _, level in ipairs(log.levels) do
    log[level] = function(...) log.log(level, ...) end
end

return log
