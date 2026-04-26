-- Chat module pure-logic helper tests.
-- Tests GetFont, GetOutlineFlag, GetIdleFadeAlpha via source instrumentation.

describe("Chat pure-logic helpers", function()
    local modulePath = "EllesmereUIChat/EllesmereUIChat.lua"

    local original_EllesmereUI
    local original_EllesmereUIDB
    local original_issecretvalue
    local original_C_Timer

    local GetFont, GetOutlineFlag, GetIdleFadeAlpha

    local function replaceExact(source, oldText, newText, label)
        local startIndex = source:find(oldText, 1, true)
        assert.is_truthy(startIndex, "expected exact replacement for " .. label)
        local endIndex = startIndex + #oldText - 1
        return source:sub(1, startIndex - 1) .. newText .. source:sub(endIndex + 1)
    end

    local chatDB  -- reference to the actual DB table used by the module

    local function loadChat()
        local handle = assert(io.open(modulePath, "rb"))
        local source = assert(handle:read("*a"))
        handle:close()
        source = source:gsub("^\239\187\191", "")
        source = source:gsub("\r\n", "\n")

        -- Export GetFont
        source = replaceExact(
            source,
            "    return (EUI.ResolveFontName and EUI.ResolveFontName(fontKey)) or STANDARD_TEXT_FONT\nend\n\nlocal function GetOutlineFlag()",
            "    return (EUI.ResolveFontName and EUI.ResolveFontName(fontKey)) or STANDARD_TEXT_FONT\nend\nns._GetFont = GetFont\n\nlocal function GetOutlineFlag()",
            "GetFont export"
        )

        -- Export GetOutlineFlag
        source = replaceExact(
            source,
            "    return \"\"\nend\n\nlocal _hiddenParent = CreateFrame(\"Frame\")",
            "    return \"\"\nend\nns._GetOutlineFlag = GetOutlineFlag\n\nlocal _hiddenParent = CreateFrame(\"Frame\")",
            "GetOutlineFlag export"
        )

        -- Export GetIdleFadeAlpha
        source = replaceExact(
            source,
            "    return 1 - (strength / 100)\nend\nlocal _idleFadeActive = false",
            "    return 1 - (strength / 100)\nend\nns._GetIdleFadeAlpha = GetIdleFadeAlpha\nlocal _idleFadeActive = false",
            "GetIdleFadeAlpha export"
        )

        local ns = {}
        local chunk, err = loadstring(source, "@" .. modulePath)
        assert.is_nil(err, "loadstring: " .. tostring(err))
        pcall(chunk, "EllesmereUIChat", ns)

        GetFont = ns._GetFont
        GetOutlineFlag = ns._GetOutlineFlag
        GetIdleFadeAlpha = ns._GetIdleFadeAlpha

        -- Force EnsureDB() to initialize the DB by calling one of the exported functions
        if GetFont then pcall(GetFont) end

        -- Get the module's actual DB reference via the global set in EnsureDB
        if _G._ECHAT_DB and _G._ECHAT_DB.profile and _G._ECHAT_DB.profile.chat then
            chatDB = _G._ECHAT_DB.profile.chat
        end
    end

    before_each(function()
        original_EllesmereUI = _G.EllesmereUI
        original_EllesmereUIDB = _G.EllesmereUIDB
        original_issecretvalue = _G.issecretvalue
        original_C_Timer = _G.C_Timer

        _G.issecretvalue = function() return false end
        _G.C_Timer = { After = function() end, NewTicker = function() return {} end }
        _G.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
        _G.GetCursorPosition = function() return 0, 0 end
        _G._ECHAT_DB = nil  -- reset cached DB
        _G.CreateFrame = function()
            return {
                RegisterEvent = function() end,
                UnregisterEvent = function() end,
                UnregisterAllEvents = function() end,
                SetScript = function() end,
                HookScript = function() end,
                Show = function() end,
                Hide = function() end,
                SetPoint = function() end,
                SetSize = function() end,
                SetAlpha = function() end,
                SetParent = function() end,
                IsShown = function() return false end,
            }
        end
        _G.hooksecurefunc = function() end
        _G.min = math.min
        _G.max = math.max

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
            GetFontPath = function() return "Fonts\\Custom.TTF" end,
            GetFontOutlineFlag = function() return "OUTLINE" end,
            ResolveFontName = function(name) return "Fonts\\Resolved_" .. name .. ".TTF" end,
            IsInCombat = function() return false end,
            CheckVisibilityOptions = function() return false end,
            EvalVisibility = function() return true end,
            RegisterVisibilityUpdater = function() end,
            RegisterMouseoverTarget = function() end,
        }
        _G.EllesmereUIDB = {}

        loadChat()
    end)

    after_each(function()
        _G.EllesmereUI = original_EllesmereUI
        _G.EllesmereUIDB = original_EllesmereUIDB
        _G.issecretvalue = original_issecretvalue
        _G.C_Timer = original_C_Timer
    end)

    -- GetFont ---------------------------------------------------------------
    describe("GetFont", function()
        it("returns global font path when set to __global", function()
            chatDB.font = "__global"
            local path = GetFont()
            assert.equals("Fonts\\Custom.TTF", path)
        end)

        it("resolves custom font name via ResolveFontName", function()
            chatDB.font = "MyCustomFont"
            local path = GetFont()
            assert.equals("Fonts\\Resolved_MyCustomFont.TTF", path)
        end)

        it("falls back to STANDARD_TEXT_FONT when ResolveFontName is nil", function()
            _G.EllesmereUI.ResolveFontName = nil
            _G._ECHAT_DB = nil  -- force DB re-init
            loadChat()
            chatDB.font = "SomeFont"
            local path = GetFont()
            assert.equals("Fonts\\FRIZQT__.TTF", path)
        end)
    end)

    -- GetOutlineFlag --------------------------------------------------------
    describe("GetOutlineFlag", function()
        it("returns global flag when set to __global", function()
            chatDB.outlineMode = "__global"
            assert.equals("OUTLINE", GetOutlineFlag())
        end)

        it("returns OUTLINE for 'outline' mode", function()
            chatDB.outlineMode = "outline"
            assert.equals("OUTLINE", GetOutlineFlag())
        end)

        it("returns THICKOUTLINE for 'thick' mode", function()
            chatDB.outlineMode = "thick"
            assert.equals("THICKOUTLINE", GetOutlineFlag())
        end)

        it("returns empty string for 'none' mode", function()
            chatDB.outlineMode = "none"
            assert.equals("", GetOutlineFlag())
        end)

        it("falls back to global when outlineMode is nil", function()
            chatDB.outlineMode = nil
            assert.equals("OUTLINE", GetOutlineFlag())
        end)
    end)

    -- GetIdleFadeAlpha -----------------------------------------------------
    describe("GetIdleFadeAlpha", function()
        it("returns 0.60 for default strength 40", function()
            chatDB.idleFadeStrength = 40
            assert.is_near(0.60, GetIdleFadeAlpha(), 0.001)
        end)

        it("returns 0.01 for maximum strength 99", function()
            chatDB.idleFadeStrength = 99
            assert.is_near(0.01, GetIdleFadeAlpha(), 0.001)
        end)

        it("returns 1.0 for zero strength", function()
            chatDB.idleFadeStrength = 0
            assert.is_near(1.0, GetIdleFadeAlpha(), 0.001)
        end)

        it("clamps strength above 99 to 99", function()
            chatDB.idleFadeStrength = 150
            assert.is_near(0.01, GetIdleFadeAlpha(), 0.001)
        end)

        it("uses default of 40 when idleFadeStrength is nil", function()
            chatDB.idleFadeStrength = nil
            assert.is_near(0.60, GetIdleFadeAlpha(), 0.001)
        end)
    end)
end)
