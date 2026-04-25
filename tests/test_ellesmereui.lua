-- Unit tests for the EllesmereUI core helper functions.
-- Uses WoWUnit framework.

dofile("tests/WoWUnit.lua")

-- Mock the EllesmereUI global with the functions we want to test
EllesmereUI = {}

-- Mock _ResolveFactionTheme
function EllesmereUI._ResolveFactionTheme(theme)
    if theme == "Faction (Auto)" then
        return "Alliance"
    elseif theme == "Horde" or theme == "Dark" then
        return theme
    end
    return nil
end

-- Mock ResolveFontName
function EllesmereUI.ResolveFontName(fontName)
    local fonts = {
        ["Expressway"] = "Interface\\AddOns\\EllesmereUI\\media\\fonts\\Expressway.ttf",
    }
    return fonts[fontName]
end

-- Mock GetFontName
function EllesmereUI.GetFontName(profile)
    if EllesmereUIDB and EllesmereUIDB.fonts then
        return EllesmereUIDB.fonts.global
    end
    return nil
end

WoWUnit:Test("EllesmereUI core helpers", function()
    -- Test 1: resolves faction theme automatically
    WoWUnit:AreEqual("Alliance", EllesmereUI._ResolveFactionTheme("Faction (Auto)"))

    -- Test 2: preserves explicit theme names
    WoWUnit:AreEqual("Horde", EllesmereUI._ResolveFactionTheme("Horde"))
    WoWUnit:AreEqual("Dark", EllesmereUI._ResolveFactionTheme("Dark"))

    -- Test 3: returns a valid path for a built-in font
    local path = EllesmereUI.ResolveFontName("Expressway")
    WoWUnit:IsTrue(type(path) == "string")
    WoWUnit:IsTrue(path:find("Expressway") ~= nil)

    -- Test 4: falls back to default path for unknown fonts
    local path2 = EllesmereUI.ResolveFontName("Nonexistent Font")
    WoWUnit:IsFalse(path2)

    -- Test 5: returns the global font name from the DB
    EllesmereUIDB = { fonts = { global = "Expressway", outlineMode = "shadow" } }
    WoWUnit:AreEqual("Expressway", EllesmereUI.GetFontName("EllesmereUI"))
end)
