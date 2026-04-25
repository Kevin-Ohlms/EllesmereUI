-- Color helper coverage for core data helpers that do not need UI state.

local function assert_close(actual, expected, label)
    assert(
        math.abs(actual - expected) < 1e-9,
        label .. " should be " .. tostring(expected) .. ", got " .. tostring(actual)
    )
end

describe("EllesmereUI color helpers", function()
    before_each(function()
        _G.EllesmereUIDB = nil
    end)

    it("darkens a color by the default fraction", function()
        local r, g, b = EllesmereUI.DarkenColor(1, 0.5, 0.25)

        assert_close(r, 0.9, "red channel after default darkening")
        assert_close(g, 0.45, "green channel after default darkening")
        assert_close(b, 0.225, "blue channel after default darkening")
    end)

    it("darkens a color by a caller-provided fraction", function()
        local r, g, b = EllesmereUI.DarkenColor(0.8, 0.6, 0.4, 0.25)

        assert_close(r, 0.6, "red channel after caller-provided darkening")
        assert_close(g, 0.45, "green channel after caller-provided darkening")
        assert_close(b, 0.3, "blue channel after caller-provided darkening")
    end)

    it("lazy-initializes the custom color database", function()
        local db = EllesmereUI.GetCustomColorsDB()

        assert(db == _G.EllesmereUIDB.customColors, "GetCustomColorsDB should return and persist the same table instance")
        assert.are.same({}, db)
        assert.are.same(db, _G.EllesmereUIDB.customColors)
    end)

    it("returns default class colors when no override exists", function()
        assert.are.same({ r = 0.25, g = 0.78, b = 0.92 }, EllesmereUI.GetClassColor("MAGE"))
    end)

    it("returns class color overrides when present", function()
        _G.EllesmereUIDB = {
            customColors = {
                class = {
                    MAGE = { r = 0.1, g = 0.2, b = 0.3 },
                },
            },
        }

        assert.are.same({ r = 0.1, g = 0.2, b = 0.3 }, EllesmereUI.GetClassColor("MAGE"))
    end)

    it("returns default power and resource colors", function()
        assert.are.same({ r = 0.0, g = 0.55, b = 1.0 }, EllesmereUI.GetPowerColor("MANA"))
        assert.are.same({ r = 0.25, g = 0.78, b = 0.92 }, EllesmereUI.GetResourceColor("MAGE"))
    end)

    it("returns nil for unknown power and resource keys", function()
        assert(EllesmereUI.GetPowerColor("UNKNOWN") == nil, "unknown power keys should not resolve to a fallback color")
        assert.is_nil(EllesmereUI.GetResourceColor("UNKNOWN"))
    end)

    it("resets class and power overrides without touching defaults", function()
        _G.EllesmereUIDB = {
            customColors = {
                class = { MAGE = { r = 0.1, g = 0.2, b = 0.3 } },
                resource = { MAGE = { r = 0.4, g = 0.5, b = 0.6 } },
                power = { MANA = { r = 0.7, g = 0.8, b = 0.9 } },
            },
        }

        EllesmereUI.ResetClassColors("MAGE")
        EllesmereUI.ResetPowerColor("MANA")

        assert.is_nil(_G.EllesmereUIDB.customColors.class.MAGE)
        assert.is_nil(_G.EllesmereUIDB.customColors.resource.MAGE)
        assert.is_nil(_G.EllesmereUIDB.customColors.power.MANA)
        assert.are.same({ r = 0.25, g = 0.78, b = 0.92 }, EllesmereUI.GetClassColor("MAGE"))
    end)

end)