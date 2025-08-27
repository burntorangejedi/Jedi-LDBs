---@diagnostic disable: undefined-global
-- Jedi-Utils.lua: Shared utility helpers
JEDI_DEBUG = true
JEDI = JEDI or {}
JEDI.Utils = {}

function JEDI.Utils:DebugPrint(...)
    if JEDI_DEBUG then
        print("JEDI:", ...)
    end
end
function JEDI.Utils:ShallowCopy(tbl)
    local t = {}
    for k, v in pairs(tbl) do t[k] = v end
    return t
end

function JEDI.Utils:DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[self:DeepCopy(orig_key)] = self:DeepCopy(orig_value)
        end
        setmetatable(copy, self:DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end
