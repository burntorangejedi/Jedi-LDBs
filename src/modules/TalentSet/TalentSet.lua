local ADDON_NAME = ...
local L = _G[ADDON_NAME .. "_L"] or {}
if JEDI and JEDI.Debug then JEDI.Debug.Info("TalentSet running") end

local function GetCurrentTalentLoadoutName()
	-- Prefer saved-config name when available (retail/TWW saved-loadouts), otherwise use spec name
	-- This makes the button show the loadout name when possible.
	-- Try saved-config API first (C_Traits or C_ClassTalents)
	local savedAPI = nil
	if C_Traits and type(C_Traits.GetConfigInfo) == "function" and type(C_Traits.GetLastSelectedSavedConfigID) == "function" then
		savedAPI = C_Traits
	elseif _G.C_ClassTalents and type(_G.C_ClassTalents.GetLastSelectedSavedConfigID) == "function" and type(_G.C_Traits) == "table" then
		-- Some clients expose C_ClassTalents
		savedAPI = _G.C_ClassTalents
	end
	if savedAPI and type(GetSpecialization) == "function" then
		local ok, specIndex = pcall(GetSpecialization)
		if ok and specIndex then
			local ok2, specID = pcall(GetSpecializationInfo, specIndex)
			if ok2 and specID then
				-- Try the available saved API
				local ok3, configID = pcall(savedAPI.GetLastSelectedSavedConfigID, savedAPI, specID)
				if ok3 and configID then
					local ok4, info = pcall(savedAPI.GetConfigInfo or savedAPI.GetTalentConfigInfo or savedAPI.GetConfigInfoByID, savedAPI, configID)
					if ok4 and info and info.name and info.name ~= "" then
						return info.name
					end
				end
			end
		end
	end

	-- Fallback to specialization name
	if type(GetSpecialization) == "function" and type(GetSpecializationInfo) == "function" then
		local ok, specIndex = pcall(GetSpecialization)
		if ok and specIndex then
			local ok2, specID, specName = pcall(GetSpecializationInfo, specIndex)
			if ok2 and specName and specName ~= "" then
				return specName
			end
		end
	end

	return L["Loading..."] or "Loading..."
end

-- Build a simple flyout menu anchored to the Titan button. Shows spec/loadout choices.
local function BuildLoadoutFlyout()
	if _G.TitanPanelJedi_TalentSetFlyout then return _G.TitanPanelJedi_TalentSetFlyout end

	local fly = CreateFrame("Frame", "TitanPanelJedi_TalentSetFlyout", UIParent)
	fly:SetFrameStrata("DIALOG")
	fly.buttons = {}

	fly.HideFlyout = function(self)
		for _, b in ipairs(self.buttons) do b:Hide() end
		self:Hide()
	end

	fly.ShowFlyout = function(self, anchor)
		-- Prepare entries
		for _, b in ipairs(self.buttons) do b:Hide() end
		wipe(self.buttons)

		local specs = {}
		-- Determine number of spec/loadout entries: prefer GetNumTalentGroups if available
		local numGroups = 2
		if type(GetNumTalentGroups) == "function" then
			local ok, n = pcall(GetNumTalentGroups)
			if ok and n and n >= 1 then numGroups = n end
		end

		for i = 1, numGroups do
			local name = (i == 1) and (L["Spec 1"] or "Spec 1") or (L["Spec 2"] or "Spec 2")
			table.insert(specs, { id = i, name = name })
		end

		-- Create buttons
		local height = 18
	for i, info in ipairs(specs) do
			local btn = CreateFrame("Button", "TitanPanelJedi_TalentSetFlyoutButton" .. i, fly, "UIPanelButtonTemplate")
			btn:SetSize(140, height)
			btn:SetText(info.name)
			btn:SetPoint("TOP", fly, "TOP", 0, -((i - 1) * (height + 2)) - 6)
			btn:SetScript("OnClick", function()
				-- If dual-spec switching is supported, use SetActiveTalentGroup when id is numeric group
				if type(SetActiveTalentGroup) == "function" and type(GetNumTalentGroups) == "function" then
					local ok, num = pcall(GetNumTalentGroups)
					if ok and num and tonumber(info.id) and tonumber(info.id) <= num then
						pcall(SetActiveTalentGroup, info.id)
						fly:HideFlyout()
						return
					end
				end

				-- Fallback: print instruction and open talent window
				if JEDI and JEDI.Debug then JEDI.Debug.Info("Switching loadouts not supported on this client. Opening talent UI instead.") end
				OpenTalentWindow()
				fly:HideFlyout()
			end)
			tinsert(fly.buttons, btn)
			btn:Hide()
		end

	-- Size and show; anchor to cursor so it appears reliably
	local totalH = (#self.buttons) * (height + 2) + 10
	fly:SetSize(148, totalH)
	local x, y = GetCursorPosition()
	local scale = UIParent and UIParent:GetEffectiveScale() or 1
	fly:ClearAllPoints()
	fly:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
	for _, b in ipairs(fly.buttons) do b:Show() end
	if JEDI and JEDI.Debug then JEDI.Debug.Debug("TalentSet: showing loadout flyout with", #self.buttons, "entries") end
	fly:Show()
	end

	-- Hide when clicking elsewhere
	fly:SetScript("OnHide", function(self) for _, b in ipairs(self.buttons) do b:Hide() end end)

	return fly
end

local function ShowLoadoutFlyout(anchor)
	local fly = BuildLoadoutFlyout()
	fly:ShowFlyout(anchor)
end

local function OpenTalentWindow()
	if JEDI and JEDI.Debug then JEDI.Debug.Debug("Inside OpenTalentWindow") end
	-- Try several common APIs to open the talent UI; retail/TWW/Classic differ.
	local tried = {}
	-- 1) Preferred global ToggleTalentFrame
	if type(ToggleTalentFrame) == "function" then
		local ok, err = pcall(ToggleTalentFrame)
		tinsert(tried, { name = "ToggleTalentFrame", ok = ok, err = err })
		if ok then return end
	end

	-- 2) Show PlayerTalentFrame if present (classic/other clients)
	if _G.PlayerTalentFrame and type(ShowUIPanel) == "function" then
		local ok, err = pcall(ShowUIPanel, _G.PlayerTalentFrame)
		tinsert(tried, { name = "ShowUIPanel PlayerTalentFrame", ok = ok, err = err })
		if ok then return end
	end

	-- 3) Try opening the talent frame via ToggleTalentFrame legacy alias or using Frame name
	if _G.ToggleTalentUI and type(_G.ToggleTalentUI) == "function" then
		local ok, err = pcall(_G.ToggleTalentUI)
		tinsert(tried, { name = "ToggleTalentUI", ok = ok, err = err })
		if ok then return end
	end

	-- If none succeeded, show an error and diagnostics
	local msg = L["No talents in this expansion"] or "No talents in this expansion"
	if UIErrorsFrame and type(UIErrorsFrame.AddMessage) == "function" then
		UIErrorsFrame:AddMessage(msg, 1, 0, 0, 1)
	else
	if JEDI and JEDI.Debug then JEDI.Debug.Error(msg) end
	end

	-- Print diagnostics for why opening failed
	for _, r in ipairs(tried) do
	if JEDI and JEDI.Debug then JEDI.Debug.Debug("OpenTalentWindow tried:", r.name, "success:", tostring(r.ok), "err:", tostring(r.err)) end
	end
	-- Print types of known globals to help diagnose missing APIs
	if JEDI and JEDI.Debug then
		JEDI.Debug.Debug("ToggleTalentFrame:", type(_G.ToggleTalentFrame))
		JEDI.Debug.Debug("PlayerTalentFrame:", type(_G.PlayerTalentFrame))
		JEDI.Debug.Debug("ToggleTalentUI:", type(_G.ToggleTalentUI))
		JEDI.Debug.Debug("C_Traits:", type(_G.C_Traits))
		JEDI.Debug.Debug("C_ClassTalents:", type(_G.C_ClassTalents))
		JEDI.Debug.Debug("SetActiveTalentGroup:", type(_G.SetActiveTalentGroup))
	end
end

local function TitanPanelJediTalentSetButton_OnClick(self, ...)
	-- Titan / Titan-like callers sometimes pass (self, button) or (self, id, button).
	-- Find the first string arg that looks like a mouse button identifier.
	local button
	for i = 1, select('#', ...) do
		local v = select(i, ...)
		if type(v) == 'string' and (v == 'LeftButton' or v == 'RightButton' or v == 'MiddleButton') then
			button = v
			break
		end
	end

	-- If not found, try common positions
	if not button then
		local maybe = select(1, ...)
		if type(maybe) == 'string' then button = maybe end
	end

	-- Diagnostic
	if JEDI and JEDI.Debug then JEDI.Debug.Debug("TalentSet OnClick detected button:", tostring(button)) end

	if button == "LeftButton" then
		OpenTalentWindow()
		return
	elseif button == "RightButton" then
		-- Show flyout to choose loadout/spec
		pcall(ShowLoadoutFlyout, self)
		return
	end
	-- Unknown button: no-op
end

local function TitanPanelJediTalentSetButton_GetButtonText(self, id)
	if JEDI and JEDI.Debug then JEDI.Debug.Debug("Inside TitanPanelJediTalentSetButton_GetButtonText") end
	return GetCurrentTalentLoadoutName()
end

local function TitanPanelJediTalentSetButton_GetTooltipText(self, id)
	if JEDI and JEDI.Debug then JEDI.Debug.Debug("Inside TitanPanelJediTalentSetButton_GetTooltipText") end
	return (GetCurrentTalentLoadoutName() or "Unknown")
end

local function TitanPanelJediTalentSetButton_PrepareMenu(frame, id, ...)
	-- Only call Titan Panel menu helpers if they exist (Titan may not be loaded yet)
	if type(TitanPanelRightClickMenu_AddTitle) == "function" then
		TitanPanelRightClickMenu_AddTitle(L["Talent Set"] or "Talent Set")
	end
	if type(TitanPanelRightClickMenu_AddCommand) == "function" then
		TitanPanelRightClickMenu_AddCommand(L["Open Talent Window"] or "Open Talent Window", id, OpenTalentWindow)
	end
end

local version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")) or "1.0"
-- print("Version", version) -- Do not call at top-level before PLAYER_LOGIN

local plugin = {
	id = "Jedi_TalentSet",
	version = version,
	menuText = L["Talent Set"] or "Talent Set",
	buttonTextFunction = TitanPanelJediTalentSetButton_GetButtonText,
	tooltipTitle = L["Talent Set"] or "Talent Set",
	tooltipTextFunction = TitanPanelJediTalentSetButton_GetTooltipText,
	icon = "Interface\\ICONS\\Ability_Marksmanship", -- Example icon
	category = "Information",
	OnClick = TitanPanelJediTalentSetButton_OnClick,
	PrepareMenu = TitanPanelJediTalentSetButton_PrepareMenu,
	savedVariables = {
		ShowIcon = 1,
		ShowLabelText = 1,
	},
}


-- Ensure Blizzard APIs are available after PLAYER_LOGIN
local function UpdateTalentSetButton()
	if _G.TitanPanelButton_UpdateButton then
		if JEDI and JEDI.Debug then JEDI.Debug.Debug("Updating TitanPanelJedi_TalentSetButton") end
		_G.TitanPanelButton_UpdateButton("Jedi_TalentSet")
	end
end

local function OnPlayerLogin(frame)
	if JEDI and JEDI.Debug then JEDI.Debug.Debug("Inside OnPlayerLogin()", frame) end

	-- Retry initializer: poll for Blizzard talent APIs if they're not yet exposed.
	local maxAttempts = 20
	local attempt = 0

	local function TryInitBlizzard()
		attempt = attempt + 1
		C_Traits = _G.C_Traits
		GetSpecialization = _G.GetSpecialization
		GetSpecializationInfo = _G.GetSpecializationInfo
		ToggleTalentFrame = _G.ToggleTalentFrame
		UIErrorsFrame = _G.UIErrorsFrame
		-- Additional talent group APIs (Wrath / Classic / retail differences)
		SetActiveTalentGroup = _G.SetActiveTalentGroup
		GetActiveTalentGroup = _G.GetActiveTalentGroup
		GetNumTalentGroups = _G.GetNumTalentGroups

		if C_Traits and type(C_Traits.GetLastSelectedSavedConfigID) == "function" and type(GetSpecialization) == "function" then
				if JEDI and JEDI.Debug then JEDI.Debug.Info("Blizzard talent APIs available (attempt " .. attempt .. ")") end
				-- Diagnostic logs: show what the APIs/reportable values are
				if JEDI and JEDI.Debug then
					JEDI.Debug.Debug("C_Traits:", tostring(C_Traits))
					JEDI.Debug.Debug("C_Traits.GetLastSelectedSavedConfigID:", type(C_Traits.GetLastSelectedSavedConfigID))
					JEDI.Debug.Debug("C_Traits.GetConfigInfo:", type(C_Traits.GetConfigInfo))
					JEDI.Debug.Debug("GetSpecialization:", type(GetSpecialization))
					JEDI.Debug.Debug("GetSpecializationInfo:", type(GetSpecializationInfo))
				end
				if type(GetSpecialization) == "function" then
					local ok, specIndex = pcall(GetSpecialization)
					if JEDI and JEDI.Debug then JEDI.Debug.Debug("GetSpecialization pcall:", ok, specIndex) end
					if ok and specIndex then
						local ok2, specID = pcall(GetSpecializationInfo, specIndex)
						if JEDI and JEDI.Debug then JEDI.Debug.Debug("GetSpecializationInfo pcall:", ok2, specID) end
						if ok2 and specID and type(C_Traits.GetLastSelectedSavedConfigID) == "function" then
							local ok3, configID = pcall(C_Traits.GetLastSelectedSavedConfigID, C_Traits, specID)
							if JEDI and JEDI.Debug then JEDI.Debug.Debug("GetLastSelectedSavedConfigID pcall:", ok3, configID) end
							if ok3 and configID then
								local ok4, info = pcall(C_Traits.GetConfigInfo, C_Traits, configID)
								if JEDI and JEDI.Debug then JEDI.Debug.Debug("GetConfigInfo pcall:", ok4, type(info), info and info.name) end
							end
						end
					end
				end
				if JEDI and JEDI.Debug then JEDI.Debug.Debug("TitanPanelButton_UpdateButton available:", type(_G.TitanPanelButton_UpdateButton)) end
				-- Register for talent-related events
				frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
				frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
				frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
				-- Update button now that APIs are ready
				UpdateTalentSetButton()
				-- If Titan Panel is loaded and provides an OnLoad hook, call it so Titan will hook our frame.
				if type(_G.TitanPanelButton_OnLoad) == "function" then
					pcall(_G.TitanPanelButton_OnLoad, frame)
				end
				-- Try to find and hook Titan's real button after a short delay
				ScheduleHookAttempt()
			return
		end

		if attempt < maxAttempts then
			-- Schedule another try in 1s
			if C_Timer and C_Timer.After then
				C_Timer.After(1, TryInitBlizzard)
			else
				-- Fallback: use frame OnUpdate if C_Timer is missing
				local elapsed = 0
				local onUpdate
				onUpdate = function(self, dt)
					elapsed = elapsed + dt
					if elapsed >= 1 then
						self:SetScript("OnUpdate", nil)
						TryInitBlizzard()
					end
				end
				frame:SetScript("OnUpdate", onUpdate)
			end
		else
			if JEDI and JEDI.Debug then JEDI.Debug.Info("Giving up trying to find Blizzard talent APIs after " .. attempt .. " attempts") end
			-- Still try to update button once more; guard in GetCurrentTalentLoadoutName prevents errors
			UpdateTalentSetButton()
		end
	end

	-- start initial attempt
	TryInitBlizzard()
end

-- Best practice: Register plugin with a real frame for Titan Panel
local frame = CreateFrame("Button", "TitanPanelJedi_TalentSetButton", UIParent, "TitanPanelComboTemplate")
frame.registry = plugin

-- Ensure the frame can receive clicks before Titan hooks it
frame:EnableMouse(true)
frame:RegisterForClicks("AnyUp")

-- Hook scripts so our handlers always run (even if Titan overwrites OnClick)
frame:HookScript("OnClick", function(self, button, ...)
	-- Normalize possible Titan signatures where button may be second or third arg
	local b = button
	if not b then
		-- try to find the button in varargs
		for i = 1, select('#', ...) do
			local v = select(i, ...)
			if type(v) == 'string' then b = v; break end
		end
	end
	if JEDI and JEDI.Debug then JEDI.Debug.Debug("TalentSet hook detected click:", tostring(b)) end
	-- Call our main click handler (it tolerates varargs)
	pcall(TitanPanelJediTalentSetButton_OnClick, self, b)
end)

-- Small debug OnMouseDown so clicks are obvious in chat if nothing else fires
frame:HookScript("OnMouseDown", function(self, button)
	if JEDI and JEDI.Debug then JEDI.Debug.Debug("TalentSet OnMouseDown:", tostring(button)) end
end)

-- Also listen for OnMouseUp and forward to our click handler (covers more Titan calling styles)
frame:HookScript("OnMouseUp", function(self, button, ...)
	if JEDI and JEDI.Debug then JEDI.Debug.Debug("TalentSet OnMouseUp:", tostring(button)) end
	pcall(TitanPanelJediTalentSetButton_OnClick, self, button, ...)
end)

-- Fallback click handler so clicks do something even if Titan Panel hasn't hooked the button yet
frame:SetScript("OnClick", function(self, button)
	if button == "LeftButton" then
		TitanPanelJediTalentSetButton_OnClick(self, button)
	elseif button == "RightButton" then
		-- Prefer plugin's PrepareMenu if present on the plugin table
		if type(plugin.PrepareMenu) == "function" then
			pcall(plugin.PrepareMenu, frame, plugin.id)
			return
		end

		-- If Titan has already set a PrepareMenu on the frame, use it
		if self and type(self.PrepareMenu) == "function" then
			pcall(self.PrepareMenu, self, plugin.id)
			return
		end
	end
end)

frame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		if JEDI and JEDI.Debug then JEDI.Debug.Debug("Calling OnPlayerLogin() from SetScript()") end
		OnPlayerLogin(self)
	elseif event == "ADDON_LOADED" then
		local addonName = ...
		-- If Titan panel is loaded later, let it hook our frame
		if addonName and (addonName == "Titan" or addonName == "TitanPanel" or type(_G.TitanPanelButton_OnLoad) == "function") then
			if type(_G.TitanPanelButton_OnLoad) == "function" then
				pcall(_G.TitanPanelButton_OnLoad, self)
			end
		end
	elseif event == "TRAIT_CONFIG_UPDATED" or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
		if JEDI and JEDI.Debug then JEDI.Debug.Debug("Talent event fired: " .. event) end
		UpdateTalentSetButton()
	end
end)
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")

-- If Titan is already loaded by the time this file runs, ensure it hooks our frame now
if type(_G.TitanPanelButton_OnLoad) == "function" then
	pcall(_G.TitanPanelButton_OnLoad, frame)
end

-- Try to find Titan's actual button/frame and hook its click handler so our logic runs.
local function FindAndHookTitanButton()
	-- Helper to hook a frame safely
	local function hookFrame(f)
		if not f or type(f) ~= "table" then return false end
		if f._TalentSetHooked then return true end
		-- Hook click to forward to our handler
		f:HookScript("OnClick", function(self, ...)
			pcall(TitanPanelJediTalentSetButton_OnClick, self, ...)
		end)
		f:HookScript("OnMouseDown", function(self, button)
			-- lightweight debug
			print("Titan button hooked click:", tostring(button), "frame:", tostring(self:GetName()))
		end)
		f._TalentSetHooked = true
		return true
	end

	-- 1) Named frame we created earlier
	local f = _G["TitanPanelJedi_TalentSetButton"]
	if hookFrame(f) then return true end

	-- 2) Look through TitanPanelButtons list if present
	if type(_G.TitanPanelButtons) == "table" then
		for _, id in ipairs(_G.TitanPanelButtons) do
			local fname = "TitanPanel" .. id .. "Button"
			local fb = _G[fname]
			if hookFrame(fb) then return true end
		end
	end

	-- 3) Fallback: scan globals for TitanPanel prefixed frames and check registry.id
	for k, v in pairs(_G) do
		if type(k) == "string" and k:match("^TitanPanel") and type(v) == "table" and v.registry and v.registry.id == plugin.id then
			if hookFrame(v) then return true end
		end
	end

	return false
end

-- Schedule a delayed hook attempt to let Titan initialize if it's loaded shortly after us
local function ScheduleHookAttempt()
	if C_Timer and C_Timer.After then
		C_Timer.After(0.5, FindAndHookTitanButton)
	else
		-- fallback immediate
		FindAndHookTitanButton()
	end
end

-- Register plugin with Titan Panel
--if _G.TitanPanelButton_OnLoad then
--    print("TitanPanelButton_OnLoad from _G.TitanPanelButton_OnLoad")
--        _G.TitanPanelButton_OnLoad(frame)
--end
