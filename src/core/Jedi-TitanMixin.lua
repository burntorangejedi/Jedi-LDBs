---@diagnostic disable: undefined-global
-- Jedi-TitanMixin.lua: Shared Titan Panel plugin helpers
JEDI = JEDI or {}
JEDI.TitanMixin = {}

-- Helper to register a Titan Panel plugin
function JEDI.TitanMixin:Register(plugin)
    if TitanPanelButton_OnLoad then
        TitanPanelButton_OnLoad(plugin)
    end
end

-- Helper to update Titan Panel button text
function JEDI.TitanMixin:UpdateButton(id, text)
    if TitanPanelButton_UpdateButton then
        TitanPanelButton_UpdateButton(id)
    end
end

-- Add more shared Titan Panel helpers as needed
