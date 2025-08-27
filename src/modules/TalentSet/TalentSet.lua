---@diagnostic disable: undefined-global
-- TalentSet Titan Panel Plugin
local ADDON_NAME = ...
local L = _G[ADDON_NAME .. "_L"] or {} -- Use loaded localization table

-- Titan Panel plugin name
local PLUGIN_ID = "Jedi_TalentSet"

-- Utility: Get current talent loadout name
local function GetCurrentTalentLoadoutName()
	JEDI.Utils.DebugPrint("In GetCurrentTalentLoadoutName")
	if C_Traits and C_Traits.GetActiveConfigID and C_Traits.GetConfigInfo then
		local configID = C_Traits.GetActiveConfigID()
		if configID then
			local info = C_Traits.GetConfigInfo(configID)
			if info and info.name then
				return info.name
			end
		end
	end
	return L["No Loadout"] or "No Loadout"
end

-- Utility: Get all available loadouts
local function GetTalentLoadouts()
	JEDI.Utils.DebugPrint("In GetTalentLoadouts")
	local sets = {}
	if C_Traits and C_Traits.GetConfigIDsByType and C_Traits.GetConfigInfo then
		local configIDs = C_Traits.GetConfigIDsByType(Enum.ConfigType.Trait)
		for _, id in ipairs(configIDs or {}) do
			local info = C_Traits.GetConfigInfo(id)
			if info and info.name then
				table.insert(sets, { id = id, name = info.name })
			end
		end
	end
	return sets
end

-- Switch to a talent loadout
local function SwitchTalentLoadout(id)
	JEDI.Utils.DebugPrint("In SwitchTalentLoadout", id)
	if C_Traits and C_Traits.LoadConfig then
		C_Traits.LoadConfig(id)
	end
end

-- Open the Talent window
local function OpenTalentWindow()
	JEDI.Utils.DebugPrint("In OpenTalentWindow")
	if PlayerTalentFrame then
		ShowUIPanel(PlayerTalentFrame)
	else
		ToggleTalentFrame()
	end
end

local plugin = {
	registry = {
		id = PLUGIN_ID,
		category = "Information",
		version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")) or "1.0",
		menuText = L["Talent Set"] or "Talent Set",
		buttonTextFunction = function()
			return GetCurrentTalentLoadoutName()
		end,
		tooltipTitle = L["Talent Set"] or "Talent Set",
		tooltipTextFunction = function()
			return (L["Current Loadout"] or "Current Loadout") .. ": " .. (GetCurrentTalentLoadoutName() or "Unknown")
		end,
		OnClick = function(self, button)
			JEDI.utils.DebugPrint("Button Pressed:", button)
			if button == "LeftButton" then
				OpenTalentWindow()
			end
		end,
		PrepareRightClickMenu = function(self)
			TitanPanelRightClickMenu_AddTitle(L["Talent Sets"] or "Talent Sets")
			for _, set in ipairs(GetTalentLoadouts()) do
				TitanPanelRightClickMenu_AddCommand(set.name, PLUGIN_ID, function()
					SwitchTalentLoadout(set.id)
				end)
			end
			TitanPanelRightClickMenu_AddSpacer()
			TitanPanelRightClickMenu_AddCommand(L["Open Talent Window"] or "Open Talent Window", PLUGIN_ID,
				OpenTalentWindow)
		end,
		-- Required Titan Panel plugin methods
		GetName = function() return PLUGIN_ID end,
		GetMenuText = function() return L["Talent Set"] or "Talent Set" end,
		GetButtonText = function() return GetCurrentTalentLoadoutName() end,
		GetTooltipText = function() return (L["Current Loadout"] or "Current Loadout") ..
			": " .. (GetCurrentTalentLoadoutName() or "Unknown") end,
	}
}


-- Register with Titan Panel, ensuring Titan is loaded
local function RegisterPlugin()
	JEDI.Utils.DebugPrint("TalentSet: In RegisterPlugin")
	if JEDI and JEDI.TitanMixin and JEDI.TitanMixin.Register then
		JEDI.Utils.DebugPrint("TalentSet: Calling JEDI.TitanMixin:Register()")
		JEDI.TitanMixin:Register(plugin.registry)
	elseif TitanPanelButton_OnLoad then
		JEDI.Utils.DebugPrint("TalentSet: Fallback for Safety()")
		TitanPanelButton_OnLoad(plugin.registry)
	end
end


local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, ...)
	JEDI.Utils.DebugPrint("TalentSet: PLAYER_LOGIN event fired, registering plugin")
	RegisterPlugin()
	self:UnregisterEvent("PLAYER_LOGIN")
end)
