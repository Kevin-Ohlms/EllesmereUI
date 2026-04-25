-- Theme helper coverage for pure theme resolution logic.

local function assert_color_close(actualR, actualG, actualB, expectedR, expectedG, expectedB)
    assert.is_true(math.abs(actualR - expectedR) < 1e-9)
    assert.is_true(math.abs(actualG - expectedG) < 1e-9)
    assert.is_true(math.abs(actualB - expectedB) < 1e-9)
end

describe("EllesmereUI theme helpers", function()
    before_each(function()
        _G.EllesmereUIDB = nil
    end)

    it("resolves the auto faction theme from the mocked player faction", function()
        assert.are.equal("Alliance", EllesmereUI._ResolveFactionTheme("Faction (Auto)"))
    end)

    it("keeps explicit theme names unchanged", function()
        assert.are.equal("Horde", EllesmereUI._ResolveFactionTheme("Horde"))
        assert.are.equal("Dark", EllesmereUI._ResolveFactionTheme("Dark"))
    end)

    it("resolves faction-based theme colors", function()
        local r, g, b = EllesmereUI.ResolveThemeColor("Faction (Auto)")

        assert_color_close(r, g, b, 63 / 255, 167 / 255, 1)
    end)

    it("resolves class-colored themes using the mocked player class", function()
        local r, g, b = EllesmereUI.ResolveThemeColor("Class Colored")

        assert_color_close(r, g, b, 0.25, 0.78, 0.92)
    end)

    it("resolves custom accent themes from the saved database", function()
        _G.EllesmereUIDB = { accentColor = { r = 0.2, g = 0.3, b = 0.4 } }
        local r, g, b = EllesmereUI.ResolveThemeColor("Custom Color")

        assert_color_close(r, g, b, 0.2, 0.3, 0.4)
    end)

    it("resolves preset themes and falls back to the default accent", function()
        local r, g, b = EllesmereUI.ResolveThemeColor("Dark")
        assert_color_close(r, g, b, 1, 1, 1)

        r, g, b = EllesmereUI.ResolveThemeColor("Missing Theme")
        assert_color_close(r, g, b, EllesmereUI.DEFAULT_ACCENT_R, EllesmereUI.DEFAULT_ACCENT_G, EllesmereUI.DEFAULT_ACCENT_B)
    end)
end)