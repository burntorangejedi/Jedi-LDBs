-- Jedi-Core.lua: Addon initialization and module loader

local ADDON_NAME = ...
JEDI = JEDI or {}

-- Simple addon core: saved-variables init, module registry, and a small cache layer.
-- NOTE: Saved variables must be declared in the .toc for persistent storage. This code
-- will look for global `JEDI_DB` and populate `JEDI.db` with defaults if missing.

if JEDI and JEDI.Utils and type(JEDI.Utils.Info) == "function" then
	JEDI.Utils.Info("Jedi-Core running")
else
	print("Jedi-Core running")
end

-- Default configuration shape
local _DEFAULTS = {
	profile = {
		debugLevel = "basic",
		hearth = { preferredToy = nil },
		modules = {},
	}
}

-- Lightweight table merge (merge missing keys from src into dst)
local function merge_defaults(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then dst[k] = {} end
			merge_defaults(dst[k], v)
		else
			if dst[k] == nil then dst[k] = v end
		end
	end
end

-- Ensure saved-variables object exists and populate JEDI.db
function JEDI.InitSavedVars()
	-- Global saved table (declare in TOC as SavedVariables: JEDI_DB)
	if _G.JEDI_DB == nil then _G.JEDI_DB = {} end
	JEDI.db = _G.JEDI_DB
	if type(JEDI.db) ~= "table" then JEDI.db = {} end
	if type(JEDI.db.profile) ~= "table" then JEDI.db.profile = {} end
	-- Merge defaults without overwriting existing user values
	merge_defaults(JEDI.db, _DEFAULTS)
	-- Apply debug level if debug module present
	if JEDI.Debug and type(JEDI.Debug.SetLogLevel) == "function" then
		pcall(JEDI.Debug.SetLogLevel, JEDI.db.profile.debugLevel or "basic")
	end
end

-- Module registry: other modules can register themselves to be tracked
JEDI._modules = JEDI._modules or {}
function JEDI.RegisterModule(name, moduleTable)
	if not name or type(name) ~= "string" then return end
	JEDI._modules[name] = moduleTable or true
	if JEDI and JEDI.Debug then JEDI.Debug.Info("Registered module:", name) end
	-- If module has Initialize, call it now if we've already initialized saved vars
	if JEDI.db and moduleTable and type(moduleTable.Initialize) == "function" then
		pcall(moduleTable.Initialize, moduleTable)
	end
end

-- Small, persistent runtime cache for computed values
JEDI.cache = JEDI.cache or {}
function JEDI.CacheGet(key)
	return JEDI.cache and JEDI.cache[key]
end
function JEDI.CacheSet(key, value)
	JEDI.cache = JEDI.cache or {}
	JEDI.cache[key] = value
end

-- Initialization sequence hooked to ADDON_LOADED / PLAYER_LOGIN
local coreFrame = CreateFrame("Frame", "JediCoreFrame")
coreFrame:RegisterEvent("ADDON_LOADED")
coreFrame:RegisterEvent("PLAYER_LOGIN")
coreFrame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
		-- Prepare saved vars and run any module Initialize
		JEDI.InitSavedVars()
		-- Call optional global Init function on modules
		for name, mod in pairs(JEDI._modules) do
			if type(mod) == "table" and type(mod.Initialize) == "function" then
				pcall(mod.Initialize, mod)
			end
		end
		if JEDI and JEDI.Debug then JEDI.Debug.Info("Jedi-Core initialized") end
	elseif event == "PLAYER_LOGIN" then
		-- Player-specific cache warm-up can go here
		JEDI.CacheSet("playerName", UnitName("player"))
		JEDI.CacheSet("playerRealm", GetRealmName())
		if JEDI and JEDI.Debug then JEDI.Debug.Debug("Player login cache populated") end
	end
end)

-- Small helper to get the live DB
function JEDI.GetDB()
	return JEDI.db
end

