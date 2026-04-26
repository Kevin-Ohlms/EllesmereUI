-- ResourceBars additional helper tests.
-- Tests FormatNumber, Lerp, IsVerticalOrientation, GetEmpowerStageColor,
-- OrientedSize, ParseTickValues, and ResolvePowerKey via source instrumentation.

describe("ResourceBars helper functions", function()
    local modulePath = "EllesmereUIResourceBars/EllesmereUIResourceBars.lua"

    local FormatNumber, Lerp, IsVerticalOrientation
    local GetEmpowerStageColor, OrientedSize, ParseTickValues, ResolvePowerKey

    local function replaceExact(source, oldText, newText, label)
        local startIndex = source:find(oldText, 1, true)
        assert.is_truthy(startIndex, "expected exact replacement for " .. label)
        local endIndex = startIndex + #oldText - 1
        return source:sub(1, startIndex - 1) .. newText .. source:sub(endIndex + 1)
    end

    local function loadResourceBars()
        local handle = assert(io.open(modulePath, "rb"))
        local source = assert(handle:read("*a"))
        handle:close()
        source = source:gsub("^\239\187\191", "")
        source = source:gsub("\r\n", "\n")

        -- Export FormatNumber (after "return tostring(floor(n))\nend")
        source = replaceExact(
            source,
            "    return tostring(floor(n))\nend\n\nlocal function IsVerticalOrientation",
            "    return tostring(floor(n))\nend\n_G._test_FormatNumber = FormatNumber\n\nlocal function IsVerticalOrientation",
            "FormatNumber export"
        )

        -- Export Lerp
        source = replaceExact(
            source,
            "    return a + (b - a) * t\nend\n\nlocal function FormatNumber",
            "    return a + (b - a) * t\nend\n_G._test_Lerp = Lerp\n\nlocal function FormatNumber",
            "Lerp export"
        )

        -- Export IsVerticalOrientation
        source = replaceExact(
            source,
            '    return ori == "VERTICAL_UP" or ori == "VERTICAL_DOWN"\nend\n\n-- Cached empower stage thresholds',
            '    return ori == "VERTICAL_UP" or ori == "VERTICAL_DOWN"\nend\n_G._test_IsVerticalOrientation = IsVerticalOrientation\n\n-- Cached empower stage thresholds',
            "IsVerticalOrientation export"
        )

        -- Export GetEmpowerStageColor
        source = replaceExact(
            source,
            "        return 1 - (t - 0.5) * 2, 1, 0\n    end\nend\n\nlocal function OrientedSize",
            "        return 1 - (t - 0.5) * 2, 1, 0\n    end\nend\n_G._test_GetEmpowerStageColor = GetEmpowerStageColor\n\nlocal function OrientedSize",
            "GetEmpowerStageColor export"
        )

        -- Export OrientedSize
        source = replaceExact(
            source,
            "    return w, h\nend\n\nlocal function ApplyBarOrientation",
            "    return w, h\nend\n_G._test_OrientedSize = OrientedSize\n\nlocal function ApplyBarOrientation",
            "OrientedSize export"
        )

        -- Export ParseTickValues
        source = replaceExact(
            source,
            "    if #vals == 0 then return nil end\n    return vals\nend\n\n-- Apply tick marks",
            "    if #vals == 0 then return nil end\n    return vals\nend\n_G._test_ParseTickValues = ParseTickValues\n\n-- Apply tick marks",
            "ParseTickValues export"
        )

        -- Export ResolvePowerKey
        source = replaceExact(
            source,
            "    return POWER_KEY_ALIAS[powerKey] or powerKey\nend\n\n-- Power color lookup:",
            "    return POWER_KEY_ALIAS[powerKey] or powerKey\nend\n_G._test_ResolvePowerKey = ResolvePowerKey\n\n-- Power color lookup:",
            "ResolvePowerKey export"
        )

        local chunk, err = loadstring(source, "@" .. modulePath)
        assert.is_nil(err, "loadstring: " .. tostring(err))
        pcall(chunk, "EllesmereUIResourceBars", {})

        FormatNumber = _G._test_FormatNumber
        Lerp = _G._test_Lerp
        IsVerticalOrientation = _G._test_IsVerticalOrientation
        GetEmpowerStageColor = _G._test_GetEmpowerStageColor
        OrientedSize = _G._test_OrientedSize
        ParseTickValues = _G._test_ParseTickValues
        ResolvePowerKey = _G._test_ResolvePowerKey
    end

    local original_EllesmereUI
    local original_EllesmereUIDB

    before_each(function()
        original_EllesmereUI = _G.EllesmereUI
        original_EllesmereUIDB = _G.EllesmereUIDB

        _G.issecretvalue = function() return false end
        _G.UnitClass = function() return "Mage", "MAGE" end
        _G.UnitPower = function() return 100 end
        _G.UnitPowerMax = function() return 100 end
        _G.UnitHealth = function() return 1000 end
        _G.UnitHealthMax = function() return 1000 end
        _G.GetSpecialization = function() return 1 end
        _G.GetShapeshiftFormID = function() return nil end
        _G.UnitBuff = function() return nil end
        _G.InCombatLockdown = function() return false end
        _G.GetTime = function() return 100 end
        _G.C_Timer = { After = function() end, NewTicker = function() return {} end }
        _G.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
        _G.C_Spell = _G.C_Spell or { GetSpellInfo = function() return nil end }

        _G.EllesmereUI = {
            Lite = {
                NewAddon = function(name)
                    local a = {}
                    function a:RegisterEvent() end
                    function a:UnregisterEvent() end
                    function a:OnEnable() end
                    return a
                end,
                NewDB = function(name, defs)
                    return { profile = defs and defs.profile or {} }
                end,
            },
            PP = {
                CreateBorder = function() end,
                SetBorderColor = function() end,
                Scale = function(x) return x end,
                perfect = 1,
            },
            ELLESMERE_GREEN = { r = 0, g = 0.8, b = 0.5 },
            GetFontPath = function() return "Fonts\\FRIZQT__.TTF" end,
            GetFontOutlineFlag = function() return "" end,
            GetFontUseShadow = function() return true end,
            GetClassColor = function(c) return { r = 0.25, g = 0.78, b = 0.92 } end,
            GetPowerColor = function(k)
                if k == "MANA" then return { r = 0, g = 0.55, b = 1 } end
                return nil
            end,
            IsInCombat = function() return false end,
            CheckVisibilityOptions = function() return false end,
            EvalVisibility = function() return true end,
            RegisterVisibilityUpdater = function() end,
        }
        _G.EllesmereUIDB = {}
        _G.CreateColor = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end

        loadResourceBars()
    end)

    after_each(function()
        _G.EllesmereUI = original_EllesmereUI
        _G.EllesmereUIDB = original_EllesmereUIDB
        _G._test_FormatNumber = nil
        _G._test_Lerp = nil
        _G._test_IsVerticalOrientation = nil
        _G._test_GetEmpowerStageColor = nil
        _G._test_OrientedSize = nil
        _G._test_ParseTickValues = nil
        _G._test_ResolvePowerKey = nil
    end)

    -- FormatNumber ---------------------------------------------------------
    describe("FormatNumber", function()
        it("formats millions", function()
            assert.equals("1.5M", FormatNumber(1500000))
        end)

        it("formats thousands", function()
            assert.equals("3.4K", FormatNumber(3400))
        end)

        it("formats small numbers as integers", function()
            assert.equals("42", FormatNumber(42))
        end)

        it("formats exactly 1 million", function()
            assert.equals("1.0M", FormatNumber(1e6))
        end)

        it("formats exactly 1 thousand", function()
            assert.equals("1.0K", FormatNumber(1000))
        end)

        it("formats zero", function()
            assert.equals("0", FormatNumber(0))
        end)

        it("floors fractional small numbers", function()
            assert.equals("99", FormatNumber(99.7))
        end)
    end)

    -- Lerp -----------------------------------------------------------------
    describe("Lerp", function()
        it("returns a at t=0", function()
            assert.equals(10, Lerp(10, 20, 0))
        end)

        it("returns b at t=1", function()
            assert.equals(20, Lerp(10, 20, 1))
        end)

        it("returns midpoint at t=0.5", function()
            assert.equals(15, Lerp(10, 20, 0.5))
        end)

        it("extrapolates beyond t=1", function()
            assert.equals(30, Lerp(10, 20, 2))
        end)
    end)

    -- IsVerticalOrientation ------------------------------------------------
    describe("IsVerticalOrientation", function()
        it("returns true for VERTICAL_UP", function()
            assert.is_true(IsVerticalOrientation("VERTICAL_UP"))
        end)

        it("returns true for VERTICAL_DOWN", function()
            assert.is_true(IsVerticalOrientation("VERTICAL_DOWN"))
        end)

        it("returns false for HORIZONTAL", function()
            assert.is_falsy(IsVerticalOrientation("HORIZONTAL"))
        end)

        it("returns false for nil", function()
            assert.is_falsy(IsVerticalOrientation(nil))
        end)
    end)

    -- GetEmpowerStageColor -------------------------------------------------
    describe("GetEmpowerStageColor", function()
        it("returns green for single-stage", function()
            local r, g, b = GetEmpowerStageColor(0, 1)
            assert.equals(0, r)
            assert.equals(1, g)
            assert.equals(0, b)
        end)

        it("returns red at stage 0 of 4", function()
            local r, g, b = GetEmpowerStageColor(0, 4)
            assert.equals(1, r)
            assert.equals(0, g)
            assert.equals(0, b)
        end)

        it("returns yellow at midpoint", function()
            local r, g, b = GetEmpowerStageColor(2, 4)
            assert.equals(1, r)
            assert.equals(1, g)
            assert.equals(0, b)
        end)

        it("returns green at max stage", function()
            local r, g, b = GetEmpowerStageColor(4, 4)
            assert.equals(0, r)
            assert.equals(1, g)
            assert.equals(0, b)
        end)
    end)

    -- OrientedSize ---------------------------------------------------------
    describe("OrientedSize", function()
        it("returns w,h for horizontal", function()
            local w, h = OrientedSize(200, 30, "HORIZONTAL")
            assert.equals(200, w)
            assert.equals(30, h)
        end)

        it("swaps for VERTICAL_UP", function()
            local w, h = OrientedSize(200, 30, "VERTICAL_UP")
            assert.equals(30, w)
            assert.equals(200, h)
        end)

        it("swaps for VERTICAL_DOWN", function()
            local w, h = OrientedSize(200, 30, "VERTICAL_DOWN")
            assert.equals(30, w)
            assert.equals(200, h)
        end)
    end)

    -- ParseTickValues ------------------------------------------------------
    describe("ParseTickValues", function()
        it("returns nil for empty string", function()
            assert.is_nil(ParseTickValues(""))
        end)

        it("returns nil for nil input", function()
            assert.is_nil(ParseTickValues(nil))
        end)

        it("parses single value", function()
            assert.are.same({ 30 }, ParseTickValues("30"))
        end)

        it("parses comma-separated values", function()
            assert.are.same({ 10, 20, 30 }, ParseTickValues("10,20,30"))
        end)

        it("trims whitespace around values", function()
            assert.are.same({ 10, 20 }, ParseTickValues(" 10 , 20 "))
        end)

        it("ignores zero and negative values", function()
            assert.are.same({ 10, 30 }, ParseTickValues("10,0,-5,30"))
        end)

        it("ignores non-numeric entries", function()
            assert.are.same({ 10, 30 }, ParseTickValues("10,abc,30"))
        end)

        it("returns nil when all entries are invalid", function()
            assert.is_nil(ParseTickValues("abc,def"))
        end)
    end)

    -- ResolvePowerKey ------------------------------------------------------
    describe("ResolvePowerKey", function()
        it("passes through canonical string keys", function()
            assert.equals("MANA", ResolvePowerKey("MANA"))
        end)

        it("resolves _BAR alias", function()
            assert.equals("FOCUS", ResolvePowerKey("FOCUS_BAR"))
        end)

        it("resolves MAELSTROM_WEAPON alias", function()
            assert.equals("MAELSTROM", ResolvePowerKey("MAELSTROM_WEAPON"))
        end)

        it("resolves LUNAR_POWER_BAR alias", function()
            assert.equals("LUNAR_POWER", ResolvePowerKey("LUNAR_POWER_BAR"))
        end)
    end)
end)
