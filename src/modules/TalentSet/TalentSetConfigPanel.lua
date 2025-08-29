-- Ace3 config panel for Jedi-TalentSet
JEDI = JEDI or {}
JEDI.db = JEDI.db or {}
JEDI.db.TalentSet = JEDI.db.TalentSet or {
    font = "GameFontNormal",
    color = { r = 1, g = 1, b = 1 },
}
if JEDI and JEDI.Debug then JEDI.Debug.Info("TalentSet config running") end

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local fonts = { "GameFontNormal", "GameFontHighlight", "GameFontDisable", "GameFontGreen" }

local options = {
    name = "Jedi-TalentSet Options",
    type = "group",
    args = {
        font = {
            type = "select",
            name = "Font",
            desc = "Select the font for TalentSet text.",
            values = function()
                local t = {}
                for _, v in ipairs(fonts) do t[v] = v end
                return t
            end,
            get = function() return JEDI.db.TalentSet.font end,
            set = function(_, val) JEDI.db.TalentSet.font = val end,
            order = 1,
        },
        color = {
            type = "color",
            name = "Color",
            desc = "Select the color for TalentSet text.",
            get = function()
                local c = JEDI.db.TalentSet.color
                return c.r, c.g, c.b
            end,
            set = function(_, r, g, b)
                JEDI.db.TalentSet.color = { r = r, g = g, b = b }
            end,
            order = 2,
        },
    },
}

AceConfig:RegisterOptionsTable("Jedi-TalentSet", options)
AceConfigDialog:AddToBlizOptions("Jedi-TalentSet", "Jedi-TalentSet")
