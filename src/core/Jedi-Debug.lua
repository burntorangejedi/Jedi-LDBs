-- Jedi-Debug.lua: centralized debug/logger for the project
JEDI = JEDI or {}
JEDI.Debug = JEDI.Debug or {}

-- Levels: none(0), basic(1), detailed(2), error(3)
local _LEVELS = { none = 0, basic = 1, detailed = 2, error = 3 }
local _logger = {
    level = _LEVELS.basic,
    name = "basic",
    handler = function(...) print(...) end,
}

local function _format(...)
    local t = {}
    for i = 1, select('#', ...) do
        t[#t + 1] = tostring(select(i, ...))
    end
    return table.concat(t, " ")
end

function JEDI.Debug.SetLogLevel(name)
    name = tostring(name or "basic")
    if _LEVELS[name] then
        _logger.level = _LEVELS[name]
        _logger.name = name
    end
end

function JEDI.Debug.GetLogLevel()
    return _logger.name
end

function JEDI.Debug.SetLogHandler(fn)
    if type(fn) == "function" then _logger.handler = fn end
end

function JEDI.Debug.Log(levelName, ...)
    local lvl = _LEVELS[levelName] or _LEVELS.basic
    if _logger.level == _LEVELS.none then return end
    if lvl >= _logger.level then
        pcall(_logger.handler, _format(...))
    end
end

function JEDI.Debug.Info(...)
    JEDI.Debug.Log("basic", ...)
end

function JEDI.Debug.Debug(...)
    JEDI.Debug.Log("detailed", ...)
end

function JEDI.Debug.Error(...)
    JEDI.Debug.Log("error", ...)
end

-- ensure defaults
JEDI.Debug.SetLogLevel(JEDI.Debug.GetLogLevel() or "basic")

-- Slash command to control debug level from chat
local function _jedidebug_usage()
    print("JEDI Debug - usage: /jedidebug <level|next|cycle|show|help>")
    print("Levels: none, basic, detailed, error")
end

SLASH_JEDIDEBUG1 = "/jedidebug"
SLASH_JEDIDEBUG2 = "/jddebug"
SlashCmdList["JEDIDEBUG"] = function(msg)
    local cmd = (msg or ""):match("%S+") or ""
    cmd = cmd:lower()
    if cmd == "" or cmd == "show" or cmd == "help" then
        print("JEDI Debug level:", JEDI.Debug.GetLogLevel())
        _jedidebug_usage()
        return
    end

    if cmd == "next" or cmd == "cycle" or cmd == "toggle" then
        local order = { "none", "basic", "detailed", "error" }
        local cur = JEDI.Debug.GetLogLevel() or "basic"
        local idx = 1
        for i, v in ipairs(order) do if v == cur then
                idx = i
                break
            end end
        local nextv = order[(idx % #order) + 1]
        JEDI.Debug.SetLogLevel(nextv)
        print("JEDI Debug level set to:", nextv)
        if JEDI and JEDI.Debug then JEDI.Debug.Info("Log level changed to:", nextv) end
        return
    end

    if _LEVELS[cmd] then
        JEDI.Debug.SetLogLevel(cmd)
        print("JEDI Debug level set to:", cmd)
        if JEDI and JEDI.Debug then JEDI.Debug.Info("Log level changed to:", cmd) end
        return
    end

    _jedidebug_usage()
end
