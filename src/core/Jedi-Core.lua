-- Jedi-Core.lua: Addon initialization and module loader

local ADDON_NAME = ...
JEDI = JEDI or {}
JEDI.Debug = JEDI.Debug or {}

if JEDI and JEDI.Debug then JEDI.Debug.Info("Jedi-Core running") end
