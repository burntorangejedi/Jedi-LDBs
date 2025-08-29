-- Jedi-Utils.lua: Shared utility helpers
JEDI = JEDI or {}
JEDI.Utils = JEDI.Utils or {}
-- Provide thin compatibility forwarders to the centralized debug module (JEDI.Debug)
-- so existing code that called JEDI.Utils.Info/Debug/Error keeps working.

-- Utility helpers (kept as methods for backward compatibility)








-- function JEDI.Utils:ShallowCopy(tbl)
--     local t = {}
--     for k, v in pairs(tbl) do t[k] = v end
--     return t
-- end

-- function JEDI.Utils:DeepCopy(orig)
--     local orig_type = type(orig)
--     local copy
--     if orig_type == 'table' then
--         copy = {}
--         for orig_key, orig_value in next, orig, nil do
--             copy[self:DeepCopy(orig_key)] = self:DeepCopy(orig_value)
--         end
--         setmetatable(copy, self:DeepCopy(getmetatable(orig)))
--     else
--         copy = orig
--     end
--     return copy
-- end


-- Safe debug forwarders. These call into JEDI.Debug if it exists and provides the
-- named function; otherwise they fall back to printing to the default output so
-- callers don't error during early load ordering.
local function safeConcatArgs(...)
	local t = {}
	for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
	return table.concat(t, " ")
end

function JEDI.Utils.SetLogLevel(name)
	if JEDI and JEDI.Debug and type(JEDI.Debug.SetLogLevel) == "function" then
		return JEDI.Debug.SetLogLevel(name)
	end
end

function JEDI.Utils.GetLogLevel()
	if JEDI and JEDI.Debug and type(JEDI.Debug.GetLogLevel) == "function" then
		return JEDI.Debug.GetLogLevel()
	end
	return nil
end

function JEDI.Utils.SetLogHandler(fn)
	if JEDI and JEDI.Debug and type(JEDI.Debug.SetLogHandler) == "function" then
		return JEDI.Debug.SetLogHandler(fn)
	end
end

function JEDI.Utils.Log(levelName, ...)
	if JEDI and JEDI.Debug and type(JEDI.Debug.Log) == "function" then
		return JEDI.Debug.Log(levelName, ...)
	end
	print(safeConcatArgs(...))
end

function JEDI.Utils.Info(...)
	if JEDI and JEDI.Debug and type(JEDI.Debug.Info) == "function" then
		return JEDI.Debug.Info(...)
	end
	print(safeConcatArgs(...))
end

function JEDI.Utils.Debug(...)
	if JEDI and JEDI.Debug and type(JEDI.Debug.Debug) == "function" then
		return JEDI.Debug.Debug(...)
	end
	print(safeConcatArgs(...))
end

function JEDI.Utils.Error(...)
	if JEDI and JEDI.Debug and type(JEDI.Debug.Error) == "function" then
		return JEDI.Debug.Error(...)
	end
	print("ERROR:", safeConcatArgs(...))
end
