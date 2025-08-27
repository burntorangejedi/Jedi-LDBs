---@diagnostic disable: undefined-global
-- ModuleTemplate.lua: Template for new Titan Panel modules
local ADDON_NAME = ...
local L = _G[ADDON_NAME .. "_L"] or {}
local PLUGIN_ID = "YourPluginID"

local plugin = {
    id = PLUGIN_ID,
    -- Add other required Titan fields and functions here
}

local function RegisterPlugin()
    JEDI.Utils.DebugPrint("In RegisterPlugin")
    JEDI.Utils.DebugPrint("JEDI table in RegisterPlugin:", JEDI)
    if JEDI and JEDI.TitanMixin and JEDI.TitanMixin.Register then
        JEDI.Utils.DebugPrint("Calling JEDI.TitanMixin:Register")
        JEDI.TitanMixin:Register(plugin)
    elseif TitanPanelButton_OnLoad then
        JEDI.Utils.DebugPrint("Calling TitanPanelButton_OnLoad")
        TitanPanelButton_OnLoad(plugin)
    else
        JEDI.Utils.DebugPrint("No registration method available")
    end
end

if IsAddOnLoaded and IsAddOnLoaded("Titan") then
    JEDI.Utils.DebugPrint("Titan is loaded, registering plugin")
    RegisterPlugin()
else
    JEDI.Utils.DebugPrint("Titan not loaded, waiting for ADDON_LOADED")
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, event, arg1)
        JEDI.Utils.DebugPrint("ADDON_LOADED event:", arg1)
        if arg1 == "Titan" then
            RegisterPlugin()
            self:UnregisterEvent("ADDON_LOADED")
        end
    end)
end