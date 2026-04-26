-- Behavior coverage for quest tracker QoL flows.

describe("Quest Tracker QoL", function()
    local modulePath = "EllesmereUIQuestTracker/EllesmereUIQuestTracker_QoL.lua"

    local original_CreateFrame
    local original_SplashFrame
    local original_AlertFrame
    local original_C_TalkingHead_SetConversationsDeferred
    local original_ShowUIPanel
    local original_InCombatLockdown
    local original_C_GossipInfo
    local original_UnitGUID
    local original_ShowQuestComplete
    local original_AcceptQuest
    local original_IsShiftKeyDown
    local original_GetNumQuestChoices
    local original_GetQuestReward
    local original_GetBindingKey
    local original_SetBinding
    local original_GetCurrentBindingSet
    local original_SaveBindings
    local original_C_QuestLog
    local original_GetQuestLogSpecialItemInfo
    local original_C_Timer
    local original_geterrorhandler
    local original_GameMenuFrame

    local createdFrames
    local bindings

    local function makeFrame(name)
        local frame = {
            _name = name,
            _events = {},
            _scripts = {},
            _attributes = {},
        }

        function frame:RegisterEvent(event)
            self._events[#self._events + 1] = event
        end

        function frame:SetScript(scriptType, handler)
            self._scripts[scriptType] = handler
        end

        function frame:Trigger(event, ...)
            local handler = self._scripts.OnEvent
            if handler then
                handler(self, event, ...)
            end
        end

        function frame:SetSize(width, height)
            self._size = { width = width, height = height }
        end

        function frame:SetPoint(...)
            self._point = { ... }
        end

        function frame:SetAlpha(alpha)
            self._alpha = alpha
        end

        function frame:EnableMouse(enabled)
            self._mouseEnabled = enabled
        end

        function frame:RegisterForClicks(...)
            self._clicks = { ... }
        end

        function frame:SetAttribute(key, value)
            self._attributes[key] = value
        end

        function frame:GetAttribute(key)
            return self._attributes[key]
        end

        function frame:ClearBindings()
            self._clearedBindings = true
        end

        function frame:SetBindingClick(_, key)
            self._bindingClicks = self._bindingClicks or {}
            self._bindingClicks[#self._bindingClicks + 1] = key
        end

        function frame:UnregisterAllEvents()
            self._events = {}
        end

        return frame
    end

    local function loadQoL(ns)
        local chunk, err = loadfile(modulePath)
        assert.is_nil(err)
        chunk("EllesmereUIQuestTracker", ns)
        return ns.EQT
    end

    local function buildNamespace(config)
        return {
            EQT = {
                Cfg = function(key)
                    return config[key]
                end,
            },
        }
    end

    before_each(function()
        original_CreateFrame = _G.CreateFrame
        original_SplashFrame = _G.SplashFrame
        original_AlertFrame = _G.AlertFrame
        original_C_TalkingHead_SetConversationsDeferred = _G.C_TalkingHead_SetConversationsDeferred
        original_ShowUIPanel = _G.ShowUIPanel
        original_InCombatLockdown = _G.InCombatLockdown
        original_C_GossipInfo = _G.C_GossipInfo
        original_UnitGUID = _G.UnitGUID
        original_ShowQuestComplete = _G.ShowQuestComplete
        original_AcceptQuest = _G.AcceptQuest
        original_IsShiftKeyDown = _G.IsShiftKeyDown
        original_GetNumQuestChoices = _G.GetNumQuestChoices
        original_GetQuestReward = _G.GetQuestReward
        original_GetBindingKey = _G.GetBindingKey
        original_SetBinding = _G.SetBinding
        original_GetCurrentBindingSet = _G.GetCurrentBindingSet
        original_SaveBindings = _G.SaveBindings
        original_C_QuestLog = _G.C_QuestLog
        original_GetQuestLogSpecialItemInfo = _G.GetQuestLogSpecialItemInfo
        original_C_Timer = _G.C_Timer
        original_geterrorhandler = _G.geterrorhandler
        original_GameMenuFrame = _G.GameMenuFrame

        createdFrames = {}
        bindings = {}

        _G.CreateFrame = function(_, name)
            local frame = makeFrame(name)
            createdFrames[#createdFrames + 1] = frame
            return frame
        end

        _G.SplashFrame = makeFrame("SplashFrame")
        _G.AlertFrame = {
            SetAlertsEnabled = function(_, enabled, reason)
                _G._questTrackerAlertState = { enabled = enabled, reason = reason }
            end,
        }
        _G.C_TalkingHead_SetConversationsDeferred = function(value)
            _G._questTrackerTalkingHeadDeferred = value
        end
        _G.ShowUIPanel = function(panel)
            _G._questTrackerShownPanel = panel
        end
        _G.InCombatLockdown = function()
            return false
        end
        _G.C_GossipInfo = nil
        _G.UnitGUID = function()
            return "npc-guid"
        end
        _G.ShowQuestComplete = function(questID)
            _G._questTrackerCompletedQuest = questID
        end
        _G.AcceptQuest = function()
            _G._questTrackerAcceptedQuest = true
        end
        _G.IsShiftKeyDown = function()
            return false
        end
        _G.GetNumQuestChoices = function()
            return 1
        end
        _G.GetQuestReward = function(choice)
            _G._questTrackerRewardChoice = choice
        end
        _G.GetBindingKey = function()
            return bindings[1], bindings[2]
        end
        _G.SetBinding = function(key, command)
            _G._questTrackerSetBindingCalls = _G._questTrackerSetBindingCalls or {}
            _G._questTrackerSetBindingCalls[#_G._questTrackerSetBindingCalls + 1] = { key = key, command = command }
        end
        _G.GetCurrentBindingSet = function()
            return 1
        end
        _G.SaveBindings = function(bindingSet)
            _G._questTrackerSavedBindings = bindingSet
        end
        _G.C_QuestLog = {
            GetNumQuestLogEntries = function()
                return 0
            end,
        }
        _G.GetQuestLogSpecialItemInfo = function()
            return nil
        end
        _G.C_Timer = {
            After = function(_, callback)
                callback()
            end,
        }
        _G.geterrorhandler = function()
            return function(err)
                _G._questTrackerLastError = err
            end
        end
        _G.GameMenuFrame = { _name = "GameMenuFrame" }

        _G._questTrackerAlertState = nil
        _G._questTrackerTalkingHeadDeferred = nil
        _G._questTrackerShownPanel = nil
        _G._questTrackerCompletedQuest = nil
        _G._questTrackerAcceptedQuest = nil
        _G._questTrackerRewardChoice = nil
        _G._questTrackerSelectedActiveQuest = nil
        _G._questTrackerSelectedAvailableQuest = nil
        _G._questTrackerSetBindingCalls = nil
        _G._questTrackerSavedBindings = nil
        _G._questTrackerLastError = nil
    end)

    after_each(function()
        _G.CreateFrame = original_CreateFrame
        _G.SplashFrame = original_SplashFrame
        _G.AlertFrame = original_AlertFrame
        _G.C_TalkingHead_SetConversationsDeferred = original_C_TalkingHead_SetConversationsDeferred
        _G.ShowUIPanel = original_ShowUIPanel
        _G.InCombatLockdown = original_InCombatLockdown
        _G.C_GossipInfo = original_C_GossipInfo
        _G.UnitGUID = original_UnitGUID
        _G.ShowQuestComplete = original_ShowQuestComplete
        _G.AcceptQuest = original_AcceptQuest
        _G.IsShiftKeyDown = original_IsShiftKeyDown
        _G.GetNumQuestChoices = original_GetNumQuestChoices
        _G.GetQuestReward = original_GetQuestReward
        _G.GetBindingKey = original_GetBindingKey
        _G.SetBinding = original_SetBinding
        _G.GetCurrentBindingSet = original_GetCurrentBindingSet
        _G.SaveBindings = original_SaveBindings
        _G.C_QuestLog = original_C_QuestLog
        _G.GetQuestLogSpecialItemInfo = original_GetQuestLogSpecialItemInfo
        _G.C_Timer = original_C_Timer
        _G.geterrorhandler = original_geterrorhandler
        _G.GameMenuFrame = original_GameMenuFrame
    end)

    it("replaces the SplashFrame OnHide handler without re-triggering tracker updates", function()
        local EQT = loadQoL(buildNamespace({ enabled = true }))

        EQT.InitQoL()

        _G.SplashFrame.screenInfo = { gameMenuRequest = true }
        _G.SplashFrame.showingQuestDialog = false
        _G.SplashFrame._scripts.OnHide(_G.SplashFrame)

        assert.are.same({ enabled = true, reason = "splashFrame" }, _G._questTrackerAlertState)
        assert.is_false(_G._questTrackerTalkingHeadDeferred)
        assert.are.same(_G.GameMenuFrame, _G._questTrackerShownPanel)
        assert.is_nil(_G.SplashFrame.screenInfo)
        assert.is_nil(_G.SplashFrame.showingQuestDialog)
    end)

    it("auto-turns in the first completed gossip quest and accepts single available quests", function()
        local EQT = loadQoL(buildNamespace({
            enabled = true,
            autoTurnIn = true,
            autoAccept = true,
            autoAcceptPreventMulti = true,
            questItemHotkey = nil,
        }))

        _G.C_GossipInfo = {
            GetActiveQuests = function()
                return {
                    { questID = 12, isComplete = false },
                    { questID = 34, isComplete = true },
                }
            end,
            SelectActiveQuest = function(questID)
                _G._questTrackerSelectedActiveQuest = questID
            end,
            GetAvailableQuests = function()
                return {
                    { questID = 99 },
                }
            end,
            SelectAvailableQuest = function(questID)
                _G._questTrackerSelectedAvailableQuest = questID
            end,
        }

        EQT.InitQoL()
        createdFrames[1]:Trigger("GOSSIP_SHOW")

        assert.are.equal(34, _G._questTrackerSelectedActiveQuest)

        _G.C_GossipInfo.GetActiveQuests = function()
            return {}
        end
        createdFrames[1]:Trigger("GOSSIP_SHOW")

        assert.are.equal(99, _G._questTrackerSelectedAvailableQuest)
    end)

    it("keeps multi-quest gossip acceptance manual when prevent-multi is enabled", function()
        local EQT = loadQoL(buildNamespace({
            enabled = true,
            autoTurnIn = false,
            autoAccept = true,
            autoAcceptPreventMulti = true,
            questItemHotkey = nil,
        }))

        _G.C_GossipInfo = {
            GetAvailableQuests = function()
                return {
                    { questID = 1 },
                    { questID = 2 },
                }
            end,
            SelectAvailableQuest = function(questID)
                _G._questTrackerSelectedAvailableQuest = questID
            end,
        }

        EQT.InitQoL()
        createdFrames[1]:Trigger("GOSSIP_SHOW")

        assert.is_nil(_G._questTrackerSelectedAvailableQuest)
    end)

    it("documents the current bug where a previous multi-quest gossip blocks later single-quest auto-accepts on the same NPC", function()
        local EQT = loadQoL(buildNamespace({
            enabled = true,
            autoTurnIn = false,
            autoAccept = true,
            autoAcceptPreventMulti = true,
            questItemHotkey = nil,
        }))

        local phase = 1
        _G.UnitGUID = function()
            return "npc-guid-42"
        end
        _G.C_GossipInfo = {
            GetAvailableQuests = function()
                if phase == 1 then
                    return {
                        { questID = 1 },
                        { questID = 2 },
                    }
                end
                return {
                    { questID = 3 },
                }
            end,
            SelectAvailableQuest = function(questID)
                _G._questTrackerSelectedAvailableQuest = questID
            end,
        }

        EQT.InitQoL()

        createdFrames[1]:Trigger("GOSSIP_SHOW")
        assert.is_nil(_G._questTrackerSelectedAvailableQuest)

        phase = 2
        createdFrames[1]:Trigger("GOSSIP_SHOW")

        assert.are.equal(3, _G._questTrackerSelectedAvailableQuest, "After the user manually resolved the earlier multi-quest choice, a later single available quest from the same NPC should auto-accept")
    end)

    it("documents the current bug where missing npc GUIDs disable later single-quest auto-accepts entirely", function()
        local EQT = loadQoL(buildNamespace({
            enabled = true,
            autoTurnIn = false,
            autoAccept = true,
            autoAcceptPreventMulti = true,
            questItemHotkey = nil,
        }))

        local phase = 1
        _G.UnitGUID = function()
            return nil
        end
        _G.C_GossipInfo = {
            GetAvailableQuests = function()
                if phase == 1 then
                    return {
                        { questID = 11 },
                        { questID = 22 },
                    }
                end
                return {
                    { questID = 33 },
                }
            end,
            SelectAvailableQuest = function(questID)
                _G._questTrackerSelectedAvailableQuest = questID
            end,
        }

        EQT.InitQoL()

        createdFrames[1]:Trigger("GOSSIP_SHOW")
        assert.is_nil(_G._questTrackerSelectedAvailableQuest)

        phase = 2
        createdFrames[1]:Trigger("GOSSIP_SHOW")

        assert.are.equal(33, _G._questTrackerSelectedAvailableQuest, "A missing npc GUID should not permanently disable later single-quest auto-accept behavior")
    end)

    it("accepts quest details, opens autocomplete turn-ins, and respects shift-skip on rewards", function()
        local EQT = loadQoL(buildNamespace({
            enabled = true,
            autoAccept = true,
            autoTurnIn = true,
            autoTurnInShiftSkip = true,
            questItemHotkey = nil,
        }))

        EQT.InitQoL()
        createdFrames[1]:Trigger("QUEST_DETAIL")
        createdFrames[1]:Trigger("QUEST_AUTOCOMPLETE", 777)

        assert.is_true(_G._questTrackerAcceptedQuest)
        assert.are.equal(777, _G._questTrackerCompletedQuest)

        _G.IsShiftKeyDown = function()
            return true
        end
        createdFrames[1]:Trigger("QUEST_COMPLETE")
        assert.is_nil(_G._questTrackerRewardChoice)

        _G.IsShiftKeyDown = function()
            return false
        end
        createdFrames[1]:Trigger("QUEST_COMPLETE")
        assert.are.equal(1, _G._questTrackerRewardChoice)
    end)

    it("updates the quest-item hotkey binding and current item attribute from watched quests", function()
        local EQT = loadQoL(buildNamespace({
            enabled = true,
            autoAccept = false,
            autoTurnIn = false,
            questItemHotkey = "CTRL-F",
        }))

        _G.C_QuestLog = {
            GetNumQuestLogEntries = function()
                return 1
            end,
            GetInfo = function(index)
                if index == 1 then
                    return {
                        isHeader = false,
                        questID = 123,
                    }
                end
            end,
            GetQuestWatchType = function(questID)
                return questID == 123 and 1 or nil
            end,
            GetLogIndexForQuestID = function()
                return 7
            end,
        }
        _G.GetQuestLogSpecialItemInfo = function(index)
            if index == 7 then
                return "|cff00ff00|Hitem:1:::::::::|h[Signal Crystal]|h|r", 134400
            end
        end

        EQT.InitQoL()

        assert.are.equal("Signal Crystal", EQT.qItemBtn:GetAttribute("item"))
        assert.is_not_nil(_G._questTrackerSetBindingCalls)
        assert.are.equal("CTRL-F", _G._questTrackerSetBindingCalls[1].key)
        assert.are.equal("EUI_QUESTITEM", _G._questTrackerSetBindingCalls[1].command)
        assert.are.equal(1, _G._questTrackerSavedBindings)
    end)
end)