local ADDON_NAME = ...
local L = _G[ADDON_NAME .. "_L"] or {}
JEDI = JEDI or {}
JEDI.Utils = JEDI.Utils or {}

if JEDI and JEDI.Debug then JEDI.Debug.Info("Hearthstone module loading") end

local function GetHearthLocationName()
    -- GetBindLocation returns the inn/zone name where the character's hearth is set
    if type(GetBindLocation) == "function" then
        local ok, loc = pcall(GetBindLocation)
        if ok and loc and loc ~= "" then
            return loc
        end
    end
    return L["Unknown"] or "Unknown"
end

-- Return a list of owned toys that appear to be hearthstones (defensive, works if toy APIs are present)
local function GetHearthstones()
    local results = {}
    -- Helper to check a name for hearth keywords
    local function looks_like_hearth(s)
        if not s or type(s) ~= "string" then return false end
        s = s:lower()
        if s:find("hearth") or s:find("hearthstone") then return true end
        return false
    end

    -- 1) Try ToyBox APIs if available
    if type(C_ToyBox) == "table" and type(C_ToyBox.GetNumToys) == "function" then
        local ok, n = pcall(C_ToyBox.GetNumToys)
        if ok and type(n) == "number" and n > 0 then
            for i = 1, n do
                local ok2, a, b, c, d, e = pcall(C_ToyBox.GetToyInfo, i)
                if ok2 then
                    -- Examine returned varargs for names or spell IDs
                    local nameFound
                    local toySpellId
                    for _, v in ipairs({a, b, c, d, e}) do
                        if type(v) == "string" and not nameFound then nameFound = v end
                        if type(v) == "number" and not toySpellId then toySpellId = v end
                    end
                    if looks_like_hearth(nameFound) then
                        tinsert(results, { type = "toy", name = nameFound, index = i, spellId = toySpellId })
                    elseif toySpellId and type(GetSpellInfo) == "function" then
                        local ok3, sname = pcall(GetSpellInfo, toySpellId)
                        if ok3 and looks_like_hearth(sname) then
                            tinsert(results, { type = "toy", name = sname or nameFound, index = i, spellId = toySpellId })
                        end
                    end
                end
            end
        end
    end

    -- 2) If nothing found, attempt a broader fallback: scan toys by toyID API (safer to avoid heavy bag scans)
    -- Note: we avoid scanning all bags here; return whatever we found.

    return results
end

-- Attempt to use a random hearth toy from the player's collection.
local function UseRandomHearthstone()
    local toys = GetHearthstones()
    if not toys or #toys == 0 then
        if JEDI and JEDI.Debug then JEDI.Debug.Info("No hearth toys found to use") end
        return false
    end

    -- Pick one at random
    local idx = math.random(#toys)
    local entry = toys[idx]
    if not entry then return false end

    if JEDI and JEDI.Debug then JEDI.Debug.Info("Using hearth toy:", entry.name or "<unknown>") end

    -- Try CastSpellByID first if we have a spell id
    if entry.spellId and type(CastSpellByID) == "function" then
        local ok, err = pcall(CastSpellByID, entry.spellId)
        if ok then return true end
        if JEDI and JEDI.Debug then JEDI.Debug.Debug("CastSpellByID failed:", tostring(err)) end
    end

    -- Try the ToyBox use API if available (defensive)
    if type(C_ToyBox) == "table" and type(C_ToyBox.UseToy) == "function" and entry.index then
        local ok2, err2 = pcall(C_ToyBox.UseToy, entry.index)
        if ok2 then return true end
        if JEDI and JEDI.Debug then JEDI.Debug.Debug("C_ToyBox.UseToy failed:", tostring(err2)) end
    end

    -- Fallback: try using by item/name if available
    if entry.name and type(UseItemByName) == "function" then
        local ok3, err3 = pcall(UseItemByName, entry.name)
        if ok3 then return true end
        if JEDI and JEDI.Debug then JEDI.Debug.Debug("UseItemByName failed:", tostring(err3)) end
    end

    -- As last resort, try casting by spell name if GetSpellInfo available
    if entry.spellId and type(GetSpellInfo) == "function" then
        local ok4, sname = pcall(GetSpellInfo, entry.spellId)
        if ok4 and sname and type(CastSpellByName) == "function" then
            local ok5, err5 = pcall(CastSpellByName, sname)
            if ok5 then return true end
            if JEDI and JEDI.Debug then JEDI.Debug.Debug("CastSpellByName failed:", tostring(err5)) end
        end
    end

    if JEDI and JEDI.Debug then JEDI.Debug.Error("Failed to use hearth toy:", entry.name or "<unknown>") end
    return false
end

local function TitanPanelJediHearthButton_GetButtonText(self, id)
    if JEDI and JEDI.Debug then JEDI.Debug.Debug("Hearth GetButtonText") end
    return GetHearthLocationName()
end

local function TitanPanelJediHearthButton_GetTooltipText(self, id)
    if JEDI and JEDI.Debug then JEDI.Debug.Debug("Hearth GetTooltipText") end
    return (L["Hearthbound to:"] or "Hearthbound to:") .. " " .. (GetHearthLocationName() or "?")
end

local function TitanPanelJediHearthButton_OnClick(self, ...)
    -- Normalize button argument
    local button
    for i = 1, select('#', ...) do
        local v = select(i, ...)
        if type(v) == 'string' then button = v; break end
    end
    if not button then button = select(1, ...) end

    if JEDI and JEDI.Debug then JEDI.Debug.Debug("Hearth OnClick:", tostring(button)) end

    if button == "LeftButton" then
        -- Try opening the world map so user can see the hearth location roughly
        if type(ToggleWorldMap) == "function" then
            pcall(ToggleWorldMap)
        elseif _G.WorldMapFrame and type(ShowUIPanel) == "function" then
            pcall(ShowUIPanel, _G.WorldMapFrame)
        else
            if JEDI and JEDI.Debug then JEDI.Debug.Info("No world map API available to open") end
        end
        return
    elseif button == "RightButton" then
    -- Right-click: attempt to use a random hearth toy
    if JEDI and JEDI.Debug then JEDI.Debug.Info("Attempting to use random hearth toy") end
    UseRandomHearthstone()
    return
    end
end

local version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")) or "1.0"

local plugin = {
    id = "Jedi_Hearthstone",
    version = version,
    menuText = L["Hearth"] or "Hearth",
    buttonTextFunction = TitanPanelJediHearthButton_GetButtonText,
    tooltipTitle = L["Hearthstone"] or "Hearthstone",
    tooltipTextFunction = TitanPanelJediHearthButton_GetTooltipText,
    icon = "Interface\\ICONS\\INV_Misc_Rune_01", -- placeholder
    category = "Information",
    OnClick = TitanPanelJediHearthButton_OnClick,
    savedVariables = { ShowIcon = 1, ShowLabelText = 1 },
}

local function UpdateHearthButton()
    if _G.TitanPanelButton_UpdateButton then
        if JEDI and JEDI.Debug then JEDI.Debug.Debug("Updating TitanPanelJedi_HearthstoneButton") end
        pcall(_G.TitanPanelButton_UpdateButton, "Jedi_Hearthstone")
    end
end

local frame = CreateFrame("Button", "TitanPanelJedi_HearthstoneButton", UIParent, "TitanPanelComboTemplate")
frame.registry = plugin
frame:EnableMouse(true)
frame:RegisterForClicks("AnyUp")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        if JEDI and JEDI.Debug then JEDI.Debug.Debug("Hearth event fired:", event) end
        UpdateHearthButton()
    end
end)

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- If Titan is already loaded, try to let it hook our frame now
if type(_G.TitanPanelButton_OnLoad) == "function" then
    pcall(_G.TitanPanelButton_OnLoad, frame)
end

-- Export for potential use
JEDI = JEDI or {}
JEDI.Hearth = JEDI.Hearth or {}
JEDI.Hearth.GetLocation = GetHearthLocationName
JEDI.Hearth.GetHearthstones = GetHearthstones
JEDI.Hearth.UseRandomHearthstone = UseRandomHearthstone
