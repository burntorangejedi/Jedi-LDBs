---@diagnostic disable: undefined-global
local ADDON_NAME = ...
local L = _G[ADDON_NAME .. "_L"] or {}
local Elib = _G.Elib

-- Local Blizzard API references for performance and safety
local C_Traits = C_Traits
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local ToggleTalentFrame = ToggleTalentFrame
local UIErrorsFrame = UIErrorsFrame

-- Utility: Get current talent loadout name
local AceEvent = LibStub and LibStub("AceEvent-3.0", true)
-- Use AceEvent to update the button after PLAYER_LOGIN
if AceEvent then
	local TalentSetLoader = {}
	AceEvent:Embed(TalentSetLoader)
	function TalentSetLoader:PLAYER_LOGIN()
		if _G.TitanPanelButton_UpdateButton then
			_G.TitanPanelButton_UpdateButton("Jedi_TalentSet")
		end
	end
	TalentSetLoader:RegisterEvent("PLAYER_LOGIN")
end

local playerLoggedIn = false
if AceEvent then
	local TalentSetLoader = {}
	AceEvent:Embed(TalentSetLoader)
	function TalentSetLoader:PLAYER_LOGIN()
		playerLoggedIn = true
		if _G.TitanPanelButton_UpdateButton then
			_G.TitanPanelButton_UpdateButton("Jedi_TalentSet")
		end
	end
	TalentSetLoader:RegisterEvent("PLAYER_LOGIN")
end

local function GetCurrentTalentLoadoutName()
	if not playerLoggedIn or not C_Traits or not GetSpecialization or not GetSpecializationInfo or not C_Traits.GetLastSelectedSavedConfigID then
		return L["Loading..."] or "Loading..."
	end
	local specIndex = GetSpecialization()
	if not specIndex then
		return L["No Loadout"] or "No Loadout"
	end
	local specID = GetSpecializationInfo(specIndex)
	if not specID then
		return L["No Loadout"] or "No Loadout"
	end
	local configID = C_Traits.GetLastSelectedSavedConfigID(specID)
	if not configID then
		return L["No Loadout"] or "No Loadout"
	end
	local info = C_Traits.GetConfigInfo(configID)
	if info and info.name then
		return info.name
	end
	return L["No Loadout"] or "No Loadout"
end

local function GetTalentLoadouts()
	if not C_Traits or not GetSpecialization or not GetSpecializationInfo or not C_Traits.GetSavedConfigIDs then
		return {}
	end
	local sets = {}
	local specIndex = GetSpecialization()
	if not specIndex then return sets end
	local specID = GetSpecializationInfo(specIndex)
	if not specID then return sets end
	local savedConfigs = C_Traits.GetSavedConfigIDs(specID) or {}
	for _, configID in ipairs(savedConfigs) do
		local configInfo = C_Traits.GetConfigInfo(configID)
		if configInfo and configInfo.name then
			table.insert(sets, { id = configID, name = configInfo.name })
		end
	end
	return sets
end

local function SwitchTalentLoadout(id)
	if C_Traits and C_Traits.LoadConfig then
		C_Traits.LoadConfig(id)
	else
		UIErrorsFrame:AddMessage(L["No talents in this expansion"] or "No talents in this expansion", 1, 0, 0, 1)
	end
end

local function OpenTalentWindow()
	if not C_Traits or not ToggleTalentFrame then
		UIErrorsFrame:AddMessage(L["No talents in this expansion"] or "No talents in this expansion", 1, 0, 0, 1)
		return
	end
	ToggleTalentFrame()
end


Elib({
	id = "Jedi_TalentSet",
	name = L["Talent Set"] or "Talent Set",
	tooltip = L["Talent Set"] or "Talent Set",
	icon = "https://static.wikia.nocookie.net/wowpedia/images/4/4e/Trainergossipicon.png/revision/latest?cb=20070607020315", -- You can set an icon path here if desired
	category = "Information",
	version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")) or "1.0",
	getButtonText = function(self, id)
		return GetCurrentTalentLoadoutName()
	end,
	getTooltipText = function(self, id)
		local t = (L["Current Loadout"] or "Current Loadout") .. ": " .. (GetCurrentTalentLoadoutName() or "Unknown")
		if not C_Traits or not C_Traits.GetActiveConfigID or not C_Traits.GetConfigInfo then
			t = t .. "\n\n" .. (L["No talents in this expansion"] or "No talents in this expansion")
		else
			t = t .. "\n\nLeft-click: Open Talent Window\nRight-click: Change Loadout"
		end
		return t
	end,
	onClick = function(self, button)
		if not C_Traits or not C_Traits.GetActiveConfigID or not C_Traits.GetConfigInfo then
			UIErrorsFrame:AddMessage(L["No talents in this expansion"] or "No talents in this expansion", 1, 0, 0, 1)
			return
		end
		if button == "LeftButton" then
			OpenTalentWindow()
		end
	end,
	menus = {
		{ type = "space" },
		{
			type = "button",
			text = L["Open Talent Window"] or "Open Talent Window",
			func = OpenTalentWindow
		},
		{ type = "space" },
		-- Dynamically add talent sets
		{
			type = "button",
			text = "Switch to...",
			func = function()
				-- This is just a label, actual sets are added below
			end,
			notCheckable = true
		},
		-- The following will be added dynamically in prepareMenu
	},
	prepareMenu = function(frame, id, ...)
		if not C_Traits or not C_Traits.GetConfigIDsByType or not C_Traits.GetConfigInfo then
			TitanPanelRightClickMenu_AddTitle(L["No talents in this expansion"] or "No talents in this expansion")
			return
		end
		TitanPanelRightClickMenu_AddTitle(L["Talent Sets"] or "Talent Sets")
		for _, set in ipairs(GetTalentLoadouts()) do
			TitanPanelRightClickMenu_AddCommand(set.name, id, function()
				SwitchTalentLoadout(set.id)
			end)
		end
		TitanPanelRightClickMenu_AddSpacer()
		TitanPanelRightClickMenu_AddCommand(L["Open Talent Window"] or "Open Talent Window", id, OpenTalentWindow)
	end,
	savedVariables = {
		ShowIcon = 1,
		ShowLabelText = 1,
	},
})
