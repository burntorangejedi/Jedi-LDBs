
-- Use the global JEDI.db.TalentSet
JEDI = JEDI or {}
JEDI.db = JEDI.db or {}
JEDI.db.TalentSet = JEDI.db.TalentSet or {
    font = "GameFontNormal",
    color = { r = 1, g = 1, b = 1 },
}

local panel = CreateFrame("Frame", "TalentSetConfigPanel", InterfaceOptionsFramePanelContainer)
panel.name = "TalentSet"
panel:Hide()

-- Font dropdown
local fontDropdown = CreateFrame("Frame", "TalentSetFontDropdown", panel, "UIDropDownMenuTemplate")
fontDropdown:SetPoint("TOPLEFT", 16, -40)
local fonts = { "GameFontNormal", "GameFontHighlight", "GameFontDisable", "GameFontGreen" }
local function OnFontSelected(self, arg1)
    JEDI.db.TalentSet.font = arg1
    UIDropDownMenu_SetSelectedValue(fontDropdown, arg1)
end
UIDropDownMenu_Initialize(fontDropdown, function(self, level)
    for _, font in ipairs(fonts) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = font
        info.value = font
        info.func = OnFontSelected
        info.arg1 = font
        UIDropDownMenu_AddButton(info, level)
    end
end)
UIDropDownMenu_SetSelectedValue(fontDropdown, JEDI.db.TalentSet.font)
UIDropDownMenu_SetWidth(fontDropdown, 180)
UIDropDownMenu_SetText(fontDropdown, "Font")

-- Color picker
local colorSwatch = CreateFrame("Button", nil, panel)
colorSwatch:SetSize(24, 24)
colorSwatch:SetPoint("TOPLEFT", fontDropdown, "BOTTOMLEFT", 0, -30)
colorSwatch:SetNormalTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
local function UpdateColor()
    local c = JEDI.db.TalentSet.color
    colorSwatch:GetNormalTexture():SetVertexColor(c.r, c.g, c.b)
end
colorSwatch:SetScript("OnClick", function()
    local c = JEDI.db.TalentSet.color
    ColorPickerFrame:SetColorRGB(c.r, c.g, c.b)
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.previousValues = {c.r, c.g, c.b}
    ColorPickerFrame.func = function()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        JEDI.db.TalentSet.color = { r = r, g = g, b = b }
        UpdateColor()
    end
    ColorPickerFrame:Hide() -- workaround
    ColorPickerFrame:Show()
end)
UpdateColor()

-- Title
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("TalentSet Options")

-- Register panel
InterfaceOptions_AddCategory(panel)
