---@diagnostic disable: undefined-global
print("ModuleTemplate loaded")

-- ModuleTemplate Titan Panel Plugin
local ADDON_NAME = ...
local L = _G[ADDON_NAME .. "_L"] or {} -- Use loaded localization table

-- Titan Panel plugin name
local PLUGIN_ID = "YourPluginID"

-- Example utility function (replace or remove as needed)
local function ExampleFunction()
    return "Example Output"
end

-- Titan Panel plugin definition
local plugin = {
    registry = {
        id = PLUGIN_ID,
        category = "Information",
        version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")) or "1.0",
        menuText = L["Module Template"] or "Module Template",
        buttonTextFunction = function()
            return ExampleFunction()
        end,
        tooltipTitle = L["Module Template"] or "Module Template",
        tooltipTextFunction = function()
            return (L["Tooltip"] or "Tooltip") .. ": " .. (ExampleFunction() or "Unknown")
        end,
        OnClick = function(self, button)
            if button == "LeftButton" then
                print("ModuleTemplate: Left click!")
            end
        end,
        PrepareRightClickMenu = function(self)
            TitanPanelRightClickMenu_AddTitle(L["Module Template"] or "Module Template")
            TitanPanelRightClickMenu_AddCommand(L["Example Action"] or "Example Action", PLUGIN_ID, function()
                print("ModuleTemplate: Example Action!")
            end)
        end,
        -- Required Titan Panel plugin methods
        GetName = function() return PLUGIN_ID end,
        GetMenuText = function() return L["Module Template"] or "Module Template" end,
        GetButtonText = function() return ExampleFunction() end,
        GetTooltipText = function() return (L["Tooltip"] or "Tooltip") .. ": " .. (ExampleFunction() or "Unknown") end,
    }
}

-- Register with Titan Panel, ensuring Titan is loaded
local function RegisterPlugin()
    print("ModuleTemplate: RegisterPlugin")
    if JEDI and JEDI.TitanMixin and JEDI.TitanMixin.Register then
        print("ModuleTemplate: Calling JEDI.TitanMixin:Register(", plugin.registry, ")")
        JEDI.TitanMixin:Register(plugin.registry)
    elseif TitanPanelButton_OnLoad then
        print("ModuleTemplate: Fallback for Safety(", plugin.registry, ")")
        TitanPanelButton_OnLoad(plugin.registry)
    end
end

-- Register plugin on PLAYER_LOGIN for maximum reliability
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, ...)
    print("ModuleTemplate: PLAYER_LOGIN event fired, registering plugin")
    RegisterPlugin()
    self:UnregisterEvent("PLAYER_LOGIN")
end)