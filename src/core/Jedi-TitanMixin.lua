---@diagnostic disable: undefined-global
-- Jedi-TitanMixin.lua: Shared Titan Panel plugin helpers
JEDI = JEDI or {}
JEDI.TitanMixin = {}

JEDI.Utils.DebugPrint("Jedi-TitalMixin Loaded")

-- Helper to register a Titan Panel plugin
function JEDI.TitanMixin:Register(plugin)
    JEDI.Utils.DebugPrint("Registering Titan Panel plugin:", plugin.id)
    if TitanPanelButton_OnLoad then
        JEDI.Utils.DebugPrint("Calling TitanPanelButton_OnLoad for plugin:", plugin.id)
        TitanPanelButton_OnLoad(plugin)
    end
end

-- Helper to update Titan Panel button text
function JEDI.TitanMixin:UpdateButton(id, text)
    JEDI.Utils.DebugPrint("Updating Titan Panel button:", id, "with text:", text)
    if TitanPanelButton_UpdateButton then
        JEDI.Utils.DebugPrint("Calling TitanPanelButton_UpdateButton for button:", id)
        TitanPanelButton_UpdateButton(id)
    end
end

-- Add more shared Titan Panel helpers as needed
