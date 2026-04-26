-- Behavior coverage for the quest tracker loader and slash-command entrypoints.

describe("Quest Tracker loader and commands", function()
    local modulePath = "EllesmereUIQuestTracker/EllesmereUIQuestTracker.lua"

    local original_CreateFrame
    local original_C_AddOns
    local original_IsAddOnLoaded
    local original_ObjectiveTrackerFrame
    local original_SlashCmdList
    local original_EllesmereUIQuestTracker
    local original__EQT_DB
    local original__EQT_RefreshAll
    local original__EQT_SetSuppressed
    local original_SLASH_EQT1

    local createdFrames

    local function makeFrame()
        local frame = {
            _events = {},
        }

        function frame:RegisterEvent(event)
            self._events[#self._events + 1] = event
        end

        function frame:SetScript(scriptType, handler)
            if scriptType == "OnEvent" then
                self._onEvent = handler
            end
        end

        function frame:UnregisterAllEvents()
            self._unregistered = true
        end

        return frame
    end

    local function loadModule()
        local ns = {}
        local chunk, err = loadfile(modulePath)
        assert.is_nil(err)
        chunk("EllesmereUIQuestTracker", ns)
        return ns.EQT, createdFrames[1]
    end

    before_each(function()
        original_CreateFrame = _G.CreateFrame
        original_C_AddOns = _G.C_AddOns
        original_IsAddOnLoaded = _G.IsAddOnLoaded
        original_ObjectiveTrackerFrame = _G.ObjectiveTrackerFrame
        original_SlashCmdList = _G.SlashCmdList
        original_EllesmereUIQuestTracker = _G.EllesmereUIQuestTracker
        original__EQT_DB = _G._EQT_DB
        original__EQT_RefreshAll = _G._EQT_RefreshAll
        original__EQT_SetSuppressed = _G._EQT_SetSuppressed
        original_SLASH_EQT1 = _G.SLASH_EQT1

        createdFrames = {}
        _G.CreateFrame = function()
            local frame = makeFrame()
            createdFrames[#createdFrames + 1] = frame
            return frame
        end

        _G.C_AddOns = {
            IsAddOnLoaded = function()
                return false
            end,
        }
        _G.IsAddOnLoaded = function()
            return false
        end
        _G.ObjectiveTrackerFrame = nil
        _G.SlashCmdList = {}

        EllesmereUI.ShowModule = function() end
        EllesmereUI.Lite = nil
        _G._EQT_DB = nil
        _G._EQT_RefreshAll = nil
        _G._EQT_SetSuppressed = nil
        _G.SLASH_EQT1 = nil
    end)

    after_each(function()
        _G.CreateFrame = original_CreateFrame
        _G.C_AddOns = original_C_AddOns
        _G.IsAddOnLoaded = original_IsAddOnLoaded
        _G.ObjectiveTrackerFrame = original_ObjectiveTrackerFrame
        _G.SlashCmdList = original_SlashCmdList
        _G.EllesmereUIQuestTracker = original_EllesmereUIQuestTracker
        _G._EQT_DB = original__EQT_DB
        _G._EQT_RefreshAll = original__EQT_RefreshAll
        _G._EQT_SetSuppressed = original__EQT_SetSuppressed
        _G.SLASH_EQT1 = original_SLASH_EQT1
    end)

    it("returns a safe temporary config before the persistent database is ready", function()
        local EQT = loadModule()

        local cfg = EQT.DB()

        assert.is_true(cfg.enabled)
        assert.are.equal("always", cfg.visibility)

        EQT.Set("enabled", false)
        assert.is_false(EQT.Cfg("enabled"))
    end)

    it("creates and caches the persistent database through EllesmereUI.Lite when available", function()
        local calls = {}
        EllesmereUI.Lite = {
            NewDB = function(name, defaults)
                calls[#calls + 1] = { name = name, defaults = defaults }
                return {
                    profile = {
                        questTracker = {
                            enabled = false,
                            visibility = "mouseover",
                        },
                    },
                }
            end,
        }

        local EQT = loadModule()

        local first = EQT.DB()
        local second = EQT.DB()

        assert.are.equal(1, #calls)
        assert.are.equal("EllesmereUIQuestTrackerDB", calls[1].name)
        assert.are.same(first, second)
        assert.is_false(first.enabled)
        assert.are.equal("mouseover", first.visibility)
        assert.is_not_nil(_G._EQT_DB)
    end)

    it("waits for self addon, objective tracker, and player login before initializing", function()
        local initCalls = {}
        local dbCalls = 0
        EllesmereUI.Lite = {
            NewDB = function()
                dbCalls = dbCalls + 1
                return {
                    profile = {
                        questTracker = {
                            enabled = true,
                            visibility = "always",
                        },
                    },
                }
            end,
        }

        local EQT, loader = loadModule()
        EQT.InitSkin = function()
            initCalls[#initCalls + 1] = "skin"
        end
        EQT.InitVisibility = function()
            initCalls[#initCalls + 1] = "visibility"
        end
        EQT.InitQoL = function()
            initCalls[#initCalls + 1] = "qol"
        end

        loader._onEvent(nil, "ADDON_LOADED", "EllesmereUIQuestTracker")
        assert.are.equal(0, #initCalls)

        loader._onEvent(nil, "PLAYER_LOGIN")
        assert.are.equal(0, #initCalls)

        loader._onEvent(nil, "ADDON_LOADED", "Blizzard_ObjectiveTracker")

        assert.are.same({ "skin", "visibility", "qol" }, initCalls)
        assert.are.equal(1, dbCalls)
        assert.is_true(loader._unregistered)
    end)

    it("initializes on player login when the objective tracker is already present", function()
        local dbCalls = 0
        _G.ObjectiveTrackerFrame = {}
        EllesmereUI.Lite = {
            NewDB = function()
                dbCalls = dbCalls + 1
                return {
                    profile = {
                        questTracker = {
                            enabled = true,
                            visibility = "always",
                        },
                    },
                }
            end,
        }

        local EQT, loader = loadModule()
        local initCount = 0
        EQT.InitVisibility = function()
            initCount = initCount + 1
        end

        loader._onEvent(nil, "ADDON_LOADED", "EllesmereUIQuestTracker")
        loader._onEvent(nil, "PLAYER_LOGIN")

        assert.are.equal(1, initCount)
        assert.are.equal(1, dbCalls)
        assert.is_true(loader._unregistered)
    end)

    it("stacks suppression across multiple callers and updates the visible state only on transitions", function()
        local EQT = loadModule()
        local suppressionStates = {}
        EQT.ApplySuppression = function(on)
            suppressionStates[#suppressionStates + 1] = on
        end

        _G._EQT_SetSuppressed("preview", true)
        _G._EQT_SetSuppressed("mouseover", true)
        _G._EQT_SetSuppressed("preview", false)
        _G._EQT_SetSuppressed("mouseover", false)

        assert.are.same({ true, true, true, false }, suppressionStates)
        assert.is_false(EQT.IsSuppressed())
    end)

    it("refreshes all registered visual entrypoints after a profile swap", function()
        local EQT = loadModule()
        local calls = {}
        EQT.RefreshFonts = function()
            calls[#calls + 1] = "fonts"
        end
        EQT.UpdateVisibility = function()
            calls[#calls + 1] = "visibility"
        end
        EQT.RestyleAll = function()
            calls[#calls + 1] = "restyle"
        end
        EQT.ApplyBackground = function()
            calls[#calls + 1] = "background"
        end

        _G._EQT_RefreshAll()

        assert.are.same({ "fonts", "visibility", "restyle", "background" }, calls)
    end)

    it("supports show hide toggle and module-open slash commands", function()
        local shownModules = {}
        EllesmereUI.ShowModule = function(_, moduleName)
            shownModules[#shownModules + 1] = moduleName
        end

        local EQT = loadModule()
        local updates = 0
        EQT.UpdateVisibility = function()
            updates = updates + 1
        end

        SlashCmdList.EQT("hide")
        assert.is_false(EQT.Cfg("enabled"))

        SlashCmdList.EQT("show")
        assert.is_true(EQT.Cfg("enabled"))

        SlashCmdList.EQT("toggle")
        assert.is_false(EQT.Cfg("enabled"))

        SlashCmdList.EQT("  ")

        assert.are.equal(3, updates)
        assert.are.same({ "EllesmereUIQuestTracker" }, shownModules)
        assert.are.equal("/eqt", _G.SLASH_EQT1)
    end)
end)