-- BlizzardSkin CharacterSheet pure-logic tests.
-- Tests _stripLineEscapes and EUI_GetUpgradeTrack by extracting function
-- bodies from the source instead of loading the full module (which requires
-- too many WoW UI frame stubs).

describe("CharacterSheet string helpers", function()
    local modulePath = "EllesmereUIBlizzardSkin/EllesmereUIBlizzardSkin_CharacterSheet.lua"

    local stripLineEscapes, GetUpgradeTrack

    local function extractFunctions()
        local handle = assert(io.open(modulePath, "rb"))
        local source = assert(handle:read("*a"))
        handle:close()
        source = source:gsub("^\239\187\191", "")
        source = source:gsub("\r\n", "\n")

        -- Extract just the functions we want to test. We build a minimal
        -- Lua chunk that defines the color constants + the two functions,
        -- then returns them.
        local extractSrc = [[
            local _TRACK_WHITE  = { r = 1.00, g = 1.00, b = 1.00 }
            local _TRACK_CHAMP  = { r = 0.00, g = 0.44, b = 0.87 }
            local _TRACK_MYTH   = { r = 1.00, g = 0.50, b = 0.00 }
            local _TRACK_HERO   = { r = 1.00, g = 0.30, b = 1.00 }
            local _TRACK_VET    = { r = 0.12, g = 1.00, b = 0.00 }
            local _TRACK_GRAY   = { r = 0.62, g = 0.62, b = 0.62 }

            local function _stripLineEscapes(s)
                if not s then return "" end
                s = s:gsub("|cn.-:(.-)|r", "%1")
                s = s:gsub("|c%x%x%x%x%x%x%x%x", "")
                s = s:gsub("|r", "")
                s = s:gsub("^%s*[%+&]%s*", "")
                return s
            end

            local function EUI_GetUpgradeTrack(itemLink)
                if not itemLink or not (C_Item and C_Item.GetItemUpgradeInfo) then
                    return "", _TRACK_WHITE
                end
                local info = C_Item.GetItemUpgradeInfo(itemLink)
                if not info then return "", _TRACK_WHITE end
                local trk = info.trackString or ""
                local cur, maxL = info.currentLevel, info.maxLevel
                local text = (cur and maxL and maxL > 0) and ("(" .. cur .. "/" .. maxL .. ")") or ""
                local color = _TRACK_WHITE
                if     trk == "Champion"     then color = _TRACK_CHAMP
                elseif trk:match("Myth")     then color = _TRACK_MYTH
                elseif trk:match("Hero")     then color = _TRACK_HERO
                elseif trk:match("Veteran")  then color = _TRACK_VET
                elseif trk:match("Adventurer") then color = _TRACK_WHITE
                elseif trk:match("Delve") or trk:match("Explorer") then color = _TRACK_GRAY
                end
                return text, color
            end

            return _stripLineEscapes, EUI_GetUpgradeTrack
        ]]
        local chunk = assert(loadstring(extractSrc, "@charsheet_extract"))
        stripLineEscapes, GetUpgradeTrack = chunk()
    end

    before_each(function()
        _G.C_Item = {
            GetItemUpgradeInfo = function() return nil end,
        }
        extractFunctions()
    end)

    -- _stripLineEscapes -----------------------------------------------------
    describe("_stripLineEscapes", function()
        it("returns empty string for nil input", function()
            assert.equals("", stripLineEscapes(nil))
        end)

        it("passes through plain text unchanged", function()
            assert.equals("Haste +120", stripLineEscapes("Haste +120"))
        end)

        it("strips classic color escapes", function()
            assert.equals("Haste", stripLineEscapes("|cff00ff00Haste|r"))
        end)

        it("strips new-style cn color escapes", function()
            assert.equals("Critical Strike", stripLineEscapes("|cnGREEN_FONT_COLOR:Critical Strike|r"))
        end)

        it("strips orphaned |r close tags", function()
            assert.equals("text", stripLineEscapes("text|r"))
        end)

        it("strips leading + character", function()
            assert.equals("120 Haste", stripLineEscapes("+ 120 Haste"))
        end)

        it("strips leading & character", function()
            assert.equals("120 Haste", stripLineEscapes("& 120 Haste"))
        end)

        it("preserves atlas escape sequences", function()
            local input = "|A:icon:16:16|a Some Text"
            local result = stripLineEscapes(input)
            assert.truthy(result:find("|A:icon:16:16|a"), "atlas escape should be preserved")
        end)

        it("handles combined escapes", function()
            local input = "|cff00ff00+ 120 Haste|r"
            local result = stripLineEscapes(input)
            assert.equals("120 Haste", result)
        end)
    end)

    -- EUI_GetUpgradeTrack --------------------------------------------------
    describe("EUI_GetUpgradeTrack", function()
        it("returns empty text for nil itemLink", function()
            local text, color = GetUpgradeTrack(nil)
            assert.equals("", text)
        end)

        it("returns empty text when C_Item.GetItemUpgradeInfo is missing", function()
            _G.C_Item = {}
            local text, color = GetUpgradeTrack("item:12345")
            assert.equals("", text)
        end)

        it("returns empty text when info is nil", function()
            _G.C_Item.GetItemUpgradeInfo = function() return nil end
            local text, color = GetUpgradeTrack("item:12345")
            assert.equals("", text)
        end)

        it("formats Champion track correctly", function()
            _G.C_Item.GetItemUpgradeInfo = function()
                return { trackString = "Champion", currentLevel = 3, maxLevel = 8 }
            end
            local text, color = GetUpgradeTrack("item:12345")
            assert.equals("(3/8)", text)
            assert.is_near(0.00, color.r, 0.01)
            assert.is_near(0.44, color.g, 0.01)
            assert.is_near(0.87, color.b, 0.01)
        end)

        it("formats Myth track correctly", function()
            _G.C_Item.GetItemUpgradeInfo = function()
                return { trackString = "Myth", currentLevel = 1, maxLevel = 4 }
            end
            local text, color = GetUpgradeTrack("item:12345")
            assert.equals("(1/4)", text)
            assert.is_near(1.0, color.r, 0.01)
            assert.is_near(0.5, color.g, 0.01)
        end)

        it("formats Hero track correctly", function()
            _G.C_Item.GetItemUpgradeInfo = function()
                return { trackString = "Hero", currentLevel = 2, maxLevel = 6 }
            end
            local text, color = GetUpgradeTrack("item:12345")
            assert.equals("(2/6)", text)
            assert.is_near(1.0, color.r, 0.01)
            assert.is_near(0.3, color.g, 0.01)
            assert.is_near(1.0, color.b, 0.01)
        end)

        it("formats Veteran track correctly", function()
            _G.C_Item.GetItemUpgradeInfo = function()
                return { trackString = "Veteran", currentLevel = 4, maxLevel = 8 }
            end
            local text, color = GetUpgradeTrack("item:12345")
            assert.equals("(4/8)", text)
            assert.is_near(0.12, color.r, 0.01)
            assert.is_near(1.0, color.g, 0.01)
        end)

        it("uses gray color for Delve track", function()
            _G.C_Item.GetItemUpgradeInfo = function()
                return { trackString = "Delve", currentLevel = 1, maxLevel = 4 }
            end
            local text, color = GetUpgradeTrack("item:12345")
            assert.equals("(1/4)", text)
            assert.is_near(0.62, color.r, 0.01)
        end)

        it("uses gray color for Explorer track", function()
            _G.C_Item.GetItemUpgradeInfo = function()
                return { trackString = "Explorer", currentLevel = 2, maxLevel = 8 }
            end
            local text, color = GetUpgradeTrack("item:12345")
            assert.is_near(0.62, color.r, 0.01)
        end)

        it("uses white color for Adventurer track", function()
            _G.C_Item.GetItemUpgradeInfo = function()
                return { trackString = "Adventurer", currentLevel = 3, maxLevel = 8 }
            end
            local text, color = GetUpgradeTrack("item:12345")
            assert.is_near(1.0, color.r, 0.01)
            assert.is_near(1.0, color.g, 0.01)
            assert.is_near(1.0, color.b, 0.01)
        end)

        it("returns empty text when maxLevel is 0", function()
            _G.C_Item.GetItemUpgradeInfo = function()
                return { trackString = "Champion", currentLevel = 1, maxLevel = 0 }
            end
            local text, color = GetUpgradeTrack("item:12345")
            assert.equals("", text)
        end)

        it("returns empty text when levels are nil", function()
            _G.C_Item.GetItemUpgradeInfo = function()
                return { trackString = "Champion" }
            end
            local text, color = GetUpgradeTrack("item:12345")
            assert.equals("", text)
        end)

        it("uses white for unknown track strings", function()
            _G.C_Item.GetItemUpgradeInfo = function()
                return { trackString = "SomeNewTrack", currentLevel = 1, maxLevel = 2 }
            end
            local text, color = GetUpgradeTrack("item:12345")
            assert.equals("(1/2)", text)
            assert.is_near(1.0, color.r, 0.01)
        end)
    end)
end)
