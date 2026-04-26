describe("Resource Bars exported helpers", function()
    local modulePath = "EllesmereUIResourceBars/EllesmereUIResourceBars.lua"

    local original_EllesmereUI
    local original_UnitClass
    local original_GetSpecialization
    local original_GetShapeshiftFormID
    local original_UnitPowerMax
    local original_UnitHealthMax
    local original_C_SpecializationInfo
    local original_CreateColor
    local original_issecretvalue
    local original__ERB_CalcPipGeometry
    local original__ERB_GetPrimaryPowerType
    local original__ERB_GetSecondaryResource
    local original__ERB_PowerColors

    local currentClass
    local currentSpec
    local currentSpecID
    local currentForm
    local powerMaxByType
    local healthMax

    local function loadModule()
        local ns = {}
        local file = assert(io.open(modulePath, "rb"))
        local source = file:read("*a")
        file:close()
        source = source:gsub("^\239\187\191", "")
        local chunk, err = loadstring(source, "@" .. modulePath)
        assert.is_nil(err)
        chunk("EllesmereUIResourceBars", ns)
        ns.ERB:OnInitialize()
        return ns.ERB
    end

    before_each(function()
        original_EllesmereUI = _G.EllesmereUI
        original_UnitClass = _G.UnitClass
        original_GetSpecialization = _G.GetSpecialization
        original_GetShapeshiftFormID = _G.GetShapeshiftFormID
        original_UnitPowerMax = _G.UnitPowerMax
        original_UnitHealthMax = _G.UnitHealthMax
        original_C_SpecializationInfo = _G.C_SpecializationInfo
        original_CreateColor = _G.CreateColor
        original_issecretvalue = _G.issecretvalue
        original__ERB_CalcPipGeometry = _G._ERB_CalcPipGeometry
        original__ERB_GetPrimaryPowerType = _G._ERB_GetPrimaryPowerType
        original__ERB_GetSecondaryResource = _G._ERB_GetSecondaryResource
        original__ERB_PowerColors = _G._ERB_PowerColors

        currentClass = "HUNTER"
        currentSpec = 1
        currentSpecID = nil
        currentForm = nil
        powerMaxByType = {}
        healthMax = 250000

        _G.EllesmereUI = {
            Lite = {
                NewAddon = function()
                    return {}
                end,
                NewDB = function()
                    return {
                        profile = {},
                    }
                end,
            },
            PP = {
                perfect = 1,
            },
            RESOURCE_BAR_ANCHOR_KEYS = {},
            GetClassColor = function()
                return { r = 0.2, g = 0.4, b = 0.6 }
            end,
            GetPowerColor = function(powerKey)
                if powerKey == "FOCUS" then
                    return { r = 0.9, g = 0.5, b = 0.1 }
                end
                if powerKey == "LUNAR_POWER" then
                    return { r = 0.7, g = 0.2, b = 0.9 }
                end
                if powerKey == "MANA" then
                    return { r = 0.1, g = 0.3, b = 0.9 }
                end
                return nil
            end,
        }

        _G.UnitClass = function()
            return "Player", currentClass
        end
        _G.GetSpecialization = function()
            return currentSpec
        end
        _G.GetShapeshiftFormID = function()
            return currentForm
        end
        _G.UnitPowerMax = function(_, powerType)
            return powerMaxByType[powerType] or 0
        end
        _G.UnitHealthMax = function()
            return healthMax
        end
        _G.C_SpecializationInfo = {
            GetSpecializationInfo = function(spec)
                if spec == currentSpec and currentSpecID ~= nil then
                    return currentSpecID
                end
                return spec
            end,
        }
        _G.CreateColor = function(r, g, b, a)
            return {
                r = r,
                g = g,
                b = b,
                a = a,
                GetRGBA = function(self)
                    return self.r, self.g, self.b, self.a
                end,
            }
        end
        _G.issecretvalue = function(value)
            return value == "secret"
        end
    end)

    after_each(function()
        _G.EllesmereUI = original_EllesmereUI
        _G.UnitClass = original_UnitClass
        _G.GetSpecialization = original_GetSpecialization
        _G.GetShapeshiftFormID = original_GetShapeshiftFormID
        _G.UnitPowerMax = original_UnitPowerMax
        _G.UnitHealthMax = original_UnitHealthMax
        _G.C_SpecializationInfo = original_C_SpecializationInfo
        _G.CreateColor = original_CreateColor
        _G.issecretvalue = original_issecretvalue
        _G._ERB_CalcPipGeometry = original__ERB_CalcPipGeometry
        _G._ERB_GetPrimaryPowerType = original__ERB_GetPrimaryPowerType
        _G._ERB_GetSecondaryResource = original__ERB_GetSecondaryResource
        _G._ERB_PowerColors = original__ERB_PowerColors
    end)

    it("routes BM and MM hunters to the secondary focus bar instead of the primary power bar", function()
        powerMaxByType[2] = 120
        loadModule()

        local primary = _G._ERB_GetPrimaryPowerType()
        local secondary = _G._ERB_GetSecondaryResource()

        assert.is_nil(primary)
        assert.are.same({ power = "FOCUS_BAR", max = 120, type = "bar" }, secondary)
    end)

    it("keeps Havoc demon hunters on fury and without a secondary resource", function()
        currentClass = "DEMONHUNTER"
        currentSpec = 1
        currentSpecID = 577
        loadModule()

        local primary = _G._ERB_GetPrimaryPowerType()
        local secondary = _G._ERB_GetSecondaryResource()

        assert.are.equal(17, primary)
        assert.is_nil(secondary)
    end)

    it("BUG: uses pain as the primary resource for Vengeance demon hunters", function()
        currentClass = "DEMONHUNTER"
        currentSpec = 2
        currentSpecID = 581
        loadModule()

        local primary = _G._ERB_GetPrimaryPowerType()
        local secondary = _G._ERB_GetSecondaryResource()

        assert.are.equal(18, primary)
        assert.are.same({ power = "SOUL_FRAGMENTS_VENGEANCE", max = 6, type = "custom" }, secondary)
    end)

    it("resolves secondary bar aliases through the shared power-color table", function()
        loadModule()

        local color = _G._ERB_PowerColors["LUNAR_POWER_BAR"]

        assert.are.same({ 0.7, 0.2, 0.9 }, color)
    end)

    it("falls back to the class color when a resource key has no dedicated power color", function()
        currentClass = "DEMONHUNTER"
        loadModule()

        local color = _G._ERB_PowerColors["SOUL_FRAGMENTS_DEVOURER"]

        assert.are.same({ 0.2, 0.4, 0.6 }, color)
    end)

    it("keeps exact snapped gaps between pips when there is enough room", function()
        loadModule()

        local frame = {
            GetEffectiveScale = function()
                return 1
            end,
        }

        local slots, snappedGap = _G._ERB_CalcPipGeometry(40, 4, 2, frame)

        assert.are.equal(4, #slots)
        assert.are.equal(2, snappedGap)
        assert.are.equal(slots[2].x0 - slots[1].x1, snappedGap)
        assert.are.equal(slots[3].x0 - slots[2].x1, snappedGap)
        assert.are.equal(slots[4].x0 - slots[3].x1, snappedGap)
        assert.is_true(slots[4].x1 <= 40)
    end)

    it("BUG: does not emit inverted pip slots when the bar is narrower than the configured spacing", function()
        loadModule()

        local frame = {
            GetEffectiveScale = function()
                return 1
            end,
        }

        local slots = _G._ERB_CalcPipGeometry(5, 6, 2, frame)

        for i = 1, #slots do
            assert.is_true(
                slots[i].x1 >= slots[i].x0,
                string.format("pip %d should have a non-negative width, got x0=%s x1=%s", i, tostring(slots[i].x0), tostring(slots[i].x1))
            )
        end
    end)
end)