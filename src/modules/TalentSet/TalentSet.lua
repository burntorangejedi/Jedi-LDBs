---@diagnostic disable: undefined-global


local ADDON_NAME = ...
local L = _G[ADDON_NAME .. "_L"] or {}
local Elib = L.Elib or _G.Elib

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

Elib({
	id = "Jedi_TalentSet",
	name = L["Talent Set"] or "Talent Set",
	tooltip = L["Talent Set"] or "Talent Set",
	icon = nil, -- You can set an icon path here if desired
	category = "Information",
	version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")) or "1.0",
	getButtonText = function(self, id)
		return GetCurrentTalentLoadoutName()
	end,
	getTooltipText = function(self, id)
		local t = (L["Current Loadout"] or "Current Loadout") .. ": " .. (GetCurrentTalentLoadoutName() or "Unknown")
		t = t .. "\n\nLeft-click: Open Talent Window\nRight-click: Change Loadout"
		return t
	end,
	onClick = function(self, button)
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
