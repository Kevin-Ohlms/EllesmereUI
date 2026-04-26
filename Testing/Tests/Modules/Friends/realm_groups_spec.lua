-- Behavior coverage for friend-region detection helpers.

describe("Friends realm region helpers", function()
    local modulePath = "EllesmereUIFriends/EllesmereUIFriends_RealmGroups.lua"
    local original_GetCurrentRegion
    local original_EllesmereUIFunctions

    local function loadRealmGroups()
        local chunk, err = loadfile(modulePath)
        assert.is_nil(err)
        chunk()
    end

    before_each(function()
        original_GetCurrentRegion = _G.GetCurrentRegion
        original_EllesmereUIFunctions = {
            GetRealmMiniRegion = EllesmereUI.GetRealmMiniRegion,
            GetFriendMiniRegion = EllesmereUI.GetFriendMiniRegion,
            GetFullRegion = EllesmereUI.GetFullRegion,
            GetMyFullRegion = EllesmereUI.GetMyFullRegion,
            GetRegionIcon = EllesmereUI.GetRegionIcon,
            MINI_TO_FULL = EllesmereUI.MINI_TO_FULL,
        }

        _G.GetCurrentRegion = function()
            return 1
        end
    end)

    after_each(function()
        _G.GetCurrentRegion = original_GetCurrentRegion
        EllesmereUI.GetRealmMiniRegion = original_EllesmereUIFunctions.GetRealmMiniRegion
        EllesmereUI.GetFriendMiniRegion = original_EllesmereUIFunctions.GetFriendMiniRegion
        EllesmereUI.GetFullRegion = original_EllesmereUIFunctions.GetFullRegion
        EllesmereUI.GetMyFullRegion = original_EllesmereUIFunctions.GetMyFullRegion
        EllesmereUI.GetRegionIcon = original_EllesmereUIFunctions.GetRegionIcon
        EllesmereUI.MINI_TO_FULL = original_EllesmereUIFunctions.MINI_TO_FULL
    end)

    it("prefers the player's region when a realm name exists in multiple region tables", function()
        loadRealmGroups()

        assert.are.equal("namerica", EllesmereUI.GetRealmMiniRegion("Aegwynn"))

        _G.GetCurrentRegion = function()
            return 3
        end

        assert.are.equal("europe", EllesmereUI.GetRealmMiniRegion("Aegwynn"))
    end)

    it("normalizes spaces in realm names from friend data", function()
        loadRealmGroups()

        assert.are.equal("namerica", EllesmereUI.GetRealmMiniRegion("Aerie Peak"))
    end)

    it("falls back to rich presence for cross-region battle.net friends", function()
        loadRealmGroups()

        local region = EllesmereUI.GetFriendMiniRegion({
            realmName = "",
            richPresence = "Dornogal - Kazzak",
        })

        assert.are.equal("europe", region)
    end)

    it("exposes full-region and icon helpers for UI rendering", function()
        loadRealmGroups()

        assert.are.equal("EU", EllesmereUI.GetFullRegion("russia"))

        _G.GetCurrentRegion = function()
            return 4
        end

        assert.are.equal("TW", EllesmereUI.GetMyFullRegion())
        assert.are.equal("Interface\\AddOns\\EllesmereUIFriends\\Media\\regions\\europe.png", EllesmereUI.GetRegionIcon("europe"))
    end)
end)