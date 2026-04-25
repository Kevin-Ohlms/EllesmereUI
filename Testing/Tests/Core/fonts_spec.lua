-- Font-related unit tests for the core addon file.

describe("EllesmereUI font helpers", function()
    before_each(function()
        _G.EllesmereUIDB = nil
    end)

    it("resolves a bundled font path", function()
        local path = EllesmereUI.ResolveFontName("Expressway")

        assert.is_string(path)
        assert.is_truthy(path:find("Expressway", 1, true))
    end)

    it("resolves Blizzard-managed fonts to Blizzard paths", function()
        assert.are.equal("Fonts\\FRIZQT__.TTF", EllesmereUI.ResolveFontName("Friz Quadrata"))
    end)

    it("falls back to Expressway for unknown fonts", function()
        local path = EllesmereUI.ResolveFontName("Nonexistent Font")

        assert.are.equal("Interface\\AddOns\\EllesmereUI\\media\\fonts\\Expressway.TTF", path)
    end)

    it("returns the configured global font name", function()
        _G.EllesmereUIDB = { fonts = { global = "Expressway", outlineMode = "shadow" } }

        assert.are.equal("Expressway", EllesmereUI.GetFontName("EllesmereUI"))
    end)

    it("returns the configured global font path", function()
        _G.EllesmereUIDB = { fonts = { global = "Arial", outlineMode = "shadow" } }

        assert.are.equal("Fonts\\ARIALN.TTF", EllesmereUI.GetFontPath("EllesmereUI"))
    end)

    it("lazy-initializes the font database defaults", function()
        local db = EllesmereUI.GetFontsDB()

        assert.are.same({
            global = "Expressway",
            outlineMode = "shadow",
        }, db)
        assert.are.same(db, _G.EllesmereUIDB.fonts)
    end)

    it("maps outline modes to WoW font flags", function()
        _G.EllesmereUIDB = { fonts = { global = "Expressway", outlineMode = "outline" } }
        assert.are.equal("OUTLINE", EllesmereUI.GetFontOutlineFlag())

        _G.EllesmereUIDB.fonts.outlineMode = "thick"
        assert.are.equal("THICKOUTLINE", EllesmereUI.GetFontOutlineFlag())

        _G.EllesmereUIDB.fonts.outlineMode = "shadow"
        assert.are.equal("", EllesmereUI.GetFontOutlineFlag())
    end)

    it("knows when shadow rendering should be enabled", function()
        _G.EllesmereUIDB = { fonts = { global = "Expressway", outlineMode = "shadow" } }
        assert.is_true(EllesmereUI.GetFontUseShadow())

        _G.EllesmereUIDB.fonts.outlineMode = "none"
        assert.is_true(EllesmereUI.GetFontUseShadow())

        _G.EllesmereUIDB.fonts.outlineMode = "outline"
        assert.is_false(EllesmereUI.GetFontUseShadow())
    end)

    it("builds the font dropdown with the global option at the top", function()
        local values, order = EllesmereUI.BuildFontDropdownData()

        assert.are.equal("__global", order[1])
        assert.are.equal("---", order[2])
        assert.are.equal("EUI Global Font", values.__global.text)
        assert.are.equal("Avant Garde (Naowh)", values["Avant Garde"].text)
        assert.is_truthy(values["Expressway"].font:find("Expressway", 1, true))
    end)
end)