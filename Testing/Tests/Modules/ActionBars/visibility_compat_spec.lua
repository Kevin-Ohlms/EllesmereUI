-- Behavior coverage for action-bar visibility migration helpers.

describe("Action Bars visibility compatibility", function()
    local modulePath = "EllesmereUIActionBars/EllesmereUIActionBars.lua"
    local litePath = "EllesmereUI_Lite.lua"
    local original_RegisterAttributeDriver
    local original_RegisterStateDriver

    local function loadActionBars(ns)
        local eui = _G.EllesmereUI
        local lite = eui and eui.Lite
        if type(lite) ~= "table" or type(lite.NewAddon) ~= "function" then
            local liteChunk, liteErr = loadfile(litePath)
            assert.is_nil(liteErr)
            liteChunk("EllesmereUI", ns)
        end

        local chunk, err = loadfile(modulePath)
        assert.is_nil(err)
        chunk("EllesmereUIActionBars", ns)
        return ns.EAB
    end

    local function buildNamespace()
        return {}
    end

    before_each(function()
        original_RegisterAttributeDriver = _G.RegisterAttributeDriver
        original_RegisterStateDriver = _G.RegisterStateDriver

        _G.RegisterAttributeDriver = function() end
        _G.RegisterStateDriver = function() end
    end)

    after_each(function()
        _G.RegisterAttributeDriver = original_RegisterAttributeDriver
        _G.RegisterStateDriver = original_RegisterStateDriver
    end)

    it("preserves the previous alpha while a bar is in mouseover mode", function()
        local EAB = loadActionBars(buildNamespace())
        local settings = {
            mouseoverAlpha = 0.35,
        }

        EAB.VisibilityCompat.ApplyMode(settings, "mouseover")

        assert.are.equal("mouseover", settings.barVisibility)
        assert.is_true(settings.mouseoverEnabled)
        assert.are.equal(0, settings.mouseoverAlpha)
        assert.are.equal(0.35, settings._savedBarAlpha)
        assert.is_false(settings.alwaysHidden)
        assert.is_false(settings.combatHideEnabled)
        assert.is_false(settings.combatShowEnabled)

        EAB.VisibilityCompat.ApplyMode(settings, "always")

        assert.are.equal("always", settings.barVisibility)
        assert.is_false(settings.mouseoverEnabled)
        assert.are.equal(0.35, settings.mouseoverAlpha)
        assert.is_nil(settings._savedBarAlpha)
    end)

    it("documents the current bug where normalizing legacy mouseover settings drops the saved full alpha", function()
        local EAB = loadActionBars(buildNamespace())
        local settings = {
            mouseoverEnabled = true,
            mouseoverAlpha = 0.6,
            combatHideEnabled = true,
        }

        local mode = EAB.VisibilityCompat.Normalize(settings)

        assert.are.equal("mouseover", mode)
        assert.are.equal("mouseover", settings.barVisibility)
        assert.is_true(settings.mouseoverEnabled)
        assert.are.equal(0, settings.mouseoverAlpha)
        assert(settings._savedBarAlpha == 0.6, "Normalize should preserve the user's previous visible alpha while migrating legacy mouseover settings")
        assert.is_false(settings.combatHideEnabled)
        assert.is_false(settings.combatShowEnabled)
        assert.is_false(settings.alwaysHidden)
    end)

    it("documents the current bug where copying legacy mouseover settings zeroes the saved visible alpha", function()
        local EAB = loadActionBars(buildNamespace())
        local src = {
            mouseoverEnabled = true,
            mouseoverAlpha = 0.25,
        }
        local dst = {
            alwaysHidden = true,
            combatShowEnabled = true,
            mouseoverAlpha = 0.9,
        }

        EAB.VisibilityCompat.Copy(dst, src)

        assert.are.equal("mouseover", dst.barVisibility)
        assert.is_true(dst.mouseoverEnabled)
        assert.are.equal(0, dst.mouseoverAlpha)
        assert(dst._savedBarAlpha == 0.25, "Copy should preserve the source bar's visible alpha so pasted mouseover settings do not become fully transparent")
        assert.is_false(dst.alwaysHidden)
        assert.is_false(dst.combatHideEnabled)
        assert.is_false(dst.combatShowEnabled)
    end)
end)