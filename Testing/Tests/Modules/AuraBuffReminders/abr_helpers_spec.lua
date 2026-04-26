-- AuraBuffReminders label and instance logic tests.
-- Tests ShortLabel and instance-type helpers via source instrumentation.

describe("AuraBuffReminders label helpers", function()
    local modulePath = "EllesmereUIAuraBuffReminders/EllesmereUIAuraBuffReminders.lua"

    local ShortLabel
    local InRealInstancedContent, InMythicZeroDungeonOrMythicRaid
    local InHeroicOrMythicContent, InPvPInstance

    local function replaceExact(source, oldText, newText, label)
        local startIndex = source:find(oldText, 1, true)
        assert.is_truthy(startIndex, "expected exact replacement for " .. label)
        local endIndex = startIndex + #oldText - 1
        return source:sub(1, startIndex - 1) .. newText .. source:sub(endIndex + 1)
    end

    local function loadABR()
        local handle = assert(io.open(modulePath, "rb"))
        local source = assert(handle:read("*a"))
        handle:close()
        source = source:gsub("^\239\187\191", "")
        source = source:gsub("\r\n", "\n")

        -- Export ShortLabel (after the function, before the instance helpers section)
        source = replaceExact(
            source,
            '    return name:match("^(%S+)") or name\nend\n\n----',
            '    return name:match("^(%S+)") or name\nend\n_G._test_ShortLabel = ShortLabel\n\n----',
            "ShortLabel export"
        )

        -- Export InRealInstancedContent
        source = replaceExact(
            source,
            "    return false\nend\n\nlocal function InMythicPlusKey()",
            "    return false\nend\n_G._test_InRealInstancedContent = InRealInstancedContent\n\nlocal function InMythicPlusKey()",
            "InRealInstancedContent export"
        )

        -- Export InMythicZeroDungeonOrMythicRaid
        source = replaceExact(
            source,
            "    return false\nend\n\n-- Heroic+ content",
            "    return false\nend\n_G._test_InMythicZeroDungeonOrMythicRaid = InMythicZeroDungeonOrMythicRaid\n\n-- Heroic+ content",
            "InMythicZeroDungeonOrMythicRaid export"
        )

        -- Export InHeroicOrMythicContent
        source = replaceExact(
            source,
            "    return false\nend\n\nlocal function InPvPInstance()",
            "    return false\nend\n_G._test_InHeroicOrMythicContent = InHeroicOrMythicContent\n\nlocal function InPvPInstance()",
            "InHeroicOrMythicContent export"
        )

        -- Export InPvPInstance
        source = replaceExact(
            source,
            '    return _cachedIType == "pvp" or _cachedIType == "arena"\nend\n\n----',
            '    return _cachedIType == "pvp" or _cachedIType == "arena"\nend\n_G._test_InPvPInstance = InPvPInstance\n\n----',
            "InPvPInstance export"
        )

        -- Also need to export the CacheInstanceInfo setter so we can control cached state
        source = replaceExact(
            source,
            "    _cachedMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit(\"player\") or nil\nend\n\nlocal function InRealInstancedContent",
            '    _cachedMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or nil\nend\n_G._test_CacheInstanceInfo = CacheInstanceInfo\n\nlocal function InRealInstancedContent',
            "CacheInstanceInfo export"
        )

        local chunk, err = loadstring(source, "@" .. modulePath)
        assert.is_nil(err, "loadstring: " .. tostring(err))
        pcall(chunk, "EllesmereUIAuraBuffReminders", {})

        ShortLabel = _G._test_ShortLabel
        InRealInstancedContent = _G._test_InRealInstancedContent
        InMythicZeroDungeonOrMythicRaid = _G._test_InMythicZeroDungeonOrMythicRaid
        InHeroicOrMythicContent = _G._test_InHeroicOrMythicContent
        InPvPInstance = _G._test_InPvPInstance
    end

    local original_EllesmereUI

    before_each(function()
        original_EllesmereUI = _G.EllesmereUI

        _G.issecretvalue = function() return false end
        _G.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
        _G.IsPlayerSpell = function() return false end
        _G.IsSpellKnown = function() return false end
        _G.UnitClass = function() return "Mage", "MAGE" end
        _G.C_ChallengeMode = { IsChallengeModeActive = function() return false end }
        _G.GetInstanceInfo = function() return "TestInstance", "none", 0 end
        _G.C_Map = { GetBestMapForUnit = function() return nil end }
        _G.C_Garrison = { IsOnGarrisonMap = function() return false end }
        _G.C_Timer = { After = function() end, NewTicker = function() return {} end }
        _G.C_Spell = { GetSpellInfo = function() return nil end }
        _G.C_UnitAuras = {
            GetAuraDataBySpellName = function() return nil end,
            GetAuraDataByIndex = function() return nil end,
        }
        _G.GetSpecialization = function() return 1 end
        _G.GetSpecializationInfo = function() return 62 end
        _G.InCombatLockdown = function() return false end

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
            },
            ELLESMERE_GREEN = { r = 0, g = 0.8, b = 0.5 },
            GetFontPath = function() return "Fonts\\FRIZQT__.TTF" end,
            GetFontOutlineFlag = function() return "" end,
            IsInCombat = function() return false end,
            CheckVisibilityOptions = function() return false end,
            EvalVisibility = function() return true end,
            RegisterVisibilityUpdater = function() end,
        }
        _G.EllesmereUIDB = {}

        loadABR()
    end)

    after_each(function()
        _G.EllesmereUI = original_EllesmereUI
        _G._test_ShortLabel = nil
        _G._test_InRealInstancedContent = nil
        _G._test_InMythicZeroDungeonOrMythicRaid = nil
        _G._test_InHeroicOrMythicContent = nil
        _G._test_InPvPInstance = nil
        _G._test_CacheInstanceInfo = nil
    end)

    -- ShortLabel -----------------------------------------------------------
    describe("ShortLabel", function()
        it("shortens Power Word: Fortitude", function()
            assert.equals("Fortitude", ShortLabel("Power Word: Fortitude"))
        end)

        it("shortens Arcane Intellect", function()
            assert.equals("Intellect", ShortLabel("Arcane Intellect"))
        end)

        it("shortens Battle Shout", function()
            assert.equals("Shout", ShortLabel("Battle Shout"))
        end)

        it("shortens Hunter's Mark", function()
            assert.equals("Mark", ShortLabel("Hunter's Mark"))
        end)

        it("shortens Devotion Aura", function()
            assert.equals("Aura", ShortLabel("Devotion Aura"))
        end)

        it("uses class override for ROGUE", function()
            assert.equals("Poison", ShortLabel("Deadly Poison", "ROGUE"))
        end)

        it("uses class override for SHAMAN_IMBUE", function()
            assert.equals("Weapon", ShortLabel("Windfury Weapon", "SHAMAN_IMBUE"))
        end)

        it("falls back to first word for unknown buffs", function()
            assert.equals("SomeRandom", ShortLabel("SomeRandom Long Buff Name"))
        end)

        it("returns the full name if it is a single word", function()
            assert.equals("Retribution", ShortLabel("Retribution"))
        end)
    end)

    -- Instance helpers (require CacheInstanceInfo to set cached state) ------
    describe("InRealInstancedContent", function()
        it("returns true for party instance", function()
            _G.GetInstanceInfo = function() return "Dungeon", "party", 1 end
            _G._test_CacheInstanceInfo()
            assert.is_true(InRealInstancedContent())
        end)

        it("returns true for raid instance", function()
            _G.GetInstanceInfo = function() return "Raid", "raid", 14 end
            _G._test_CacheInstanceInfo()
            assert.is_true(InRealInstancedContent())
        end)

        it("returns false for open world (none)", function()
            _G.GetInstanceInfo = function() return "World", "none", 0 end
            _G._test_CacheInstanceInfo()
            assert.is_false(InRealInstancedContent())
        end)

        it("returns true for arena", function()
            _G.GetInstanceInfo = function() return "Arena", "arena", 0 end
            _G._test_CacheInstanceInfo()
            assert.is_true(InRealInstancedContent())
        end)

        it("returns true for pvp", function()
            _G.GetInstanceInfo = function() return "BG", "pvp", 0 end
            _G._test_CacheInstanceInfo()
            assert.is_true(InRealInstancedContent())
        end)

        it("returns false on garrison map", function()
            _G.GetInstanceInfo = function() return "Garrison", "party", 1 end
            _G.C_Garrison.IsOnGarrisonMap = function() return true end
            _G._test_CacheInstanceInfo()
            assert.is_false(InRealInstancedContent())
        end)
    end)

    describe("InMythicZeroDungeonOrMythicRaid", function()
        it("returns true for M0 dungeon (diff 23)", function()
            _G.GetInstanceInfo = function() return "D", "party", 23 end
            _G._test_CacheInstanceInfo()
            assert.is_true(InMythicZeroDungeonOrMythicRaid())
        end)

        it("returns true for M0 dungeon (diff 8)", function()
            _G.GetInstanceInfo = function() return "D", "party", 8 end
            _G._test_CacheInstanceInfo()
            assert.is_true(InMythicZeroDungeonOrMythicRaid())
        end)

        it("returns true for mythic raid (diff 16)", function()
            _G.GetInstanceInfo = function() return "R", "raid", 16 end
            _G._test_CacheInstanceInfo()
            assert.is_true(InMythicZeroDungeonOrMythicRaid())
        end)

        it("returns false for normal dungeon", function()
            _G.GetInstanceInfo = function() return "D", "party", 1 end
            _G._test_CacheInstanceInfo()
            assert.is_false(InMythicZeroDungeonOrMythicRaid())
        end)

        it("returns false for heroic raid", function()
            _G.GetInstanceInfo = function() return "R", "raid", 15 end
            _G._test_CacheInstanceInfo()
            assert.is_false(InMythicZeroDungeonOrMythicRaid())
        end)
    end)

    describe("InHeroicOrMythicContent", function()
        it("returns true for heroic dungeon (diff 2)", function()
            _G.GetInstanceInfo = function() return "D", "party", 2 end
            _G._test_CacheInstanceInfo()
            assert.is_true(InHeroicOrMythicContent())
        end)

        it("returns true for M0 dungeon (diff 23)", function()
            _G.GetInstanceInfo = function() return "D", "party", 23 end
            _G._test_CacheInstanceInfo()
            assert.is_true(InHeroicOrMythicContent())
        end)

        it("returns true for heroic raid (diff 5)", function()
            _G.GetInstanceInfo = function() return "R", "raid", 5 end
            _G._test_CacheInstanceInfo()
            assert.is_true(InHeroicOrMythicContent())
        end)

        it("returns true for mythic raid (diff 16)", function()
            _G.GetInstanceInfo = function() return "R", "raid", 16 end
            _G._test_CacheInstanceInfo()
            assert.is_true(InHeroicOrMythicContent())
        end)

        it("returns false for normal dungeon (diff 1)", function()
            _G.GetInstanceInfo = function() return "D", "party", 1 end
            _G._test_CacheInstanceInfo()
            assert.is_false(InHeroicOrMythicContent())
        end)

        it("returns false for LFR (diff 17)", function()
            _G.GetInstanceInfo = function() return "R", "raid", 17 end
            _G._test_CacheInstanceInfo()
            assert.is_false(InHeroicOrMythicContent())
        end)
    end)

    describe("InPvPInstance", function()
        it("returns true for pvp", function()
            _G.GetInstanceInfo = function() return "BG", "pvp", 0 end
            _G._test_CacheInstanceInfo()
            assert.is_true(InPvPInstance())
        end)

        it("returns true for arena", function()
            _G.GetInstanceInfo = function() return "Arena", "arena", 0 end
            _G._test_CacheInstanceInfo()
            assert.is_true(InPvPInstance())
        end)

        it("returns false for dungeon", function()
            _G.GetInstanceInfo = function() return "D", "party", 1 end
            _G._test_CacheInstanceInfo()
            assert.is_false(InPvPInstance())
        end)
    end)
end)
