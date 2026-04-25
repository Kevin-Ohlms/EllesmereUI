-- Reset helper coverage for SavedVariables migration and wipe behavior.

local function reset_global_saved_variables()
    _G.EllesmereUIDB = nil
    _G.EllesmereUIActionBarsDB = nil
    _G.EllesmereUIAuraBuffRemindersDB = nil
    _G.EllesmereUIBasicsDB = nil
    _G.EllesmereUICooldownManagerDB = nil
    _G.EllesmereUINameplatesDB = nil
    _G.EllesmereUIResourceBarsDB = nil
    _G.EllesmereUIUnitFramesDB = nil
end

describe("EllesmereUI reset helpers", function()
    before_each(function()
        reset_global_saved_variables()
        EllesmereUI._showResetPopup = nil
    end)

    it("does not require a beta reset when no database exists", function()
        assert(EllesmereUI.NeedsBetaReset() == false, "fresh installs without a DB should not prompt for a beta reset")
    end)

    it("requires a beta reset for old reset versions only", function()
        _G.EllesmereUIDB = { _resetVersion = 8 }
        assert.is_true(EllesmereUI.NeedsBetaReset())

        _G.EllesmereUIDB._resetVersion = 9
        assert.is_false(EllesmereUI.NeedsBetaReset())
    end)

    it("stamps fresh installs with the required reset version", function()
        EllesmereUI.StampResetVersion()

        assert(_G.EllesmereUIDB ~= nil, "StampResetVersion should create the root saved-variable table on fresh installs")
        assert.are.equal(9, _G.EllesmereUIDB._resetVersion)
    end)

    it("does not stamp installs that already have child addon databases", function()
        _G.EllesmereUIActionBarsDB = { some = "data" }

        EllesmereUI.StampResetVersion()

        assert.is_nil(_G.EllesmereUIDB and _G.EllesmereUIDB._resetVersion)
    end)

    it("does nothing when no reset is needed", function()
        _G.EllesmereUIDB = { _resetVersion = 9 }

        assert(EllesmereUI.PerformResetWipe() == false, "PerformResetWipe should be a no-op when the reset version is already current")
        assert.is_nil(EllesmereUI._showResetPopup)
    end)

    it("wipes child databases, preserves scale, and flags the popup", function()
        _G.EllesmereUIDB = { _resetVersion = 8, ppUIScale = 0.9, ppUIScaleAuto = true }
        _G.EllesmereUIActionBarsDB = { layout = 1 }
        _G.EllesmereUIAuraBuffRemindersDB = { enabled = true }
        _G.EllesmereUIBasicsDB = { enabled = true }
        _G.EllesmereUICooldownManagerDB = { enabled = true }
        _G.EllesmereUINameplatesDB = { enabled = true }
        _G.EllesmereUIResourceBarsDB = { enabled = true }
        _G.EllesmereUIUnitFramesDB = { enabled = true }

        assert(EllesmereUI.PerformResetWipe() == true, "PerformResetWipe should report that it wiped outdated saved variables")
        assert.are.equal(9, _G.EllesmereUIDB._resetVersion)
        assert.are.equal(0.9, _G.EllesmereUIDB.ppUIScale)
        assert.is_true(_G.EllesmereUIDB.ppUIScaleAuto)
        assert.are.same({}, _G.EllesmereUIActionBarsDB)
        assert.are.same({}, _G.EllesmereUIAuraBuffRemindersDB)
        assert.are.same({}, _G.EllesmereUIBasicsDB)
        assert.are.same({}, _G.EllesmereUICooldownManagerDB)
        assert.are.same({}, _G.EllesmereUINameplatesDB)
        assert.are.same({}, _G.EllesmereUIResourceBarsDB)
        assert.are.same({}, _G.EllesmereUIUnitFramesDB)
        assert.is_true(EllesmereUI._showResetPopup)
    end)

    it("protects installs with profiles but missing reset stamps from being wiped", function()
        _G.EllesmereUIDB = { profiles = { Default = {} } }

        assert(EllesmereUI.PerformResetWipe() == false, "profile-bearing installs without a reset stamp should be stamped, not wiped")
        assert.are.equal(9, _G.EllesmereUIDB._resetVersion)
    end)
end)