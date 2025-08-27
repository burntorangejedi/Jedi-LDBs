---@diagnostic disable: undefined-global

if _G["TitanPanelJedi_TalentSetButton"] then
    return -- Already loaded/registered
end

local ADDON_NAME = ...
local L = _G[ADDON_NAME .. "_L"] or {} -- Use loaded localization table

-- Titan Panel plugin name
local PLUGIN_ID = "Jedi_TalentSet"

-- Initialize module config in global DB
JEDI = JEDI or {}
JEDI.db = JEDI.db or {}
JEDI.db.TalentSet = JEDI.db.TalentSet or {
	font = "GameFontNormal",
	color = { r = 1, g = 1, b = 1 },
}

-- Create the Titan Panel plugin frame using the Combo template
local frame = CreateFrame("Button", "TitanPanel" .. PLUGIN_ID .. "Button", UIParent, "TitanPanelComboTemplate")

-- Utility: Get current talent loadout name
local function GetCurrentTalentLoadoutName()
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

local function GetTalentLoadouts()
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

local function SwitchTalentLoadout(id)
	if C_Traits and C_Traits.LoadConfig then
		C_Traits.LoadConfig(id)
	end
end

local function OpenTalentWindow()
	if PlayerTalentFrame then
		ShowUIPanel(PlayerTalentFrame)
	else
		ToggleTalentFrame()
	end
end


-- Titan Panel registry table attached to the frame
frame.registry = {
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
		TitanPanelRightClickMenu_AddCommand(L["Open Talent Window"] or "Open Talent Window", PLUGIN_ID, OpenTalentWindow)
	end,
	-- Required Titan Panel plugin methods
	GetName = function() return PLUGIN_ID end,
	GetMenuText = function() return L["Talent Set"] or "Talent Set" end,
	GetButtonText = function() return GetCurrentTalentLoadoutName() end,
	GetTooltipText = function() return (L["Current Loadout"] or "Current Loadout") .. ": " .. (GetCurrentTalentLoadoutName() or "Unknown") end,
	-- Optionally, add savedVariables for Titan to manage
	-- savedVariables = { ShowIcon = 1, ShowLabelText = 1 },
}


-- Register plugin on PLAYER_LOGIN
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, ...)
	-- Register the plugin frame with Titan Panel
	if TitanPanelButton_OnLoad then
		TitanPanelButton_OnLoad(frame)
	end
	self:UnregisterEvent("PLAYER_LOGIN")
end)
