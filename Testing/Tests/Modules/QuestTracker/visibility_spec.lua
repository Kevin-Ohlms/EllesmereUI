-- Behavior coverage for quest tracker visibility decisions.

describe("Quest Tracker visibility", function()
    local modulePath = "EllesmereUIQuestTracker/EllesmereUIQuestTracker_Visibility.lua"
    local original_CreateFrame
    local original_ObjectiveTrackerFrame
    local original_GetInstanceInfo
    local original_hooksecurefunc
    local original_C_Timer
    local original_C_ChallengeMode
    local original_ScenarioObjectiveTracker

    local createdFrames
    local deferredCallbacks

    local function makeFrame(options)
        options = options or {}

        local frame = {
            _shown = options.shown ~= false,
            _alpha = options.alpha,
            _parent = options.parent,
            _hooks = {},
            _secureHooks = {},
            _strata = options.strata or "MEDIUM",
            _frameLevel = options.frameLevel or 2,
            _top = options.top,
            _bottom = options.bottom,
            _mouseOver = options.mouseOver,
        }

        local function makeTexture()
            local texture = {
                _shown = true,
            }

            function texture:SetAllPoints()
                self._allPoints = true
            end

            function texture:SetPoint(...)
                self._point = { ... }
            end

            function texture:SetHeight(height)
                self._height = height
            end

            function texture:SetColorTexture(r, g, b, a)
                self._color = { r, g, b, a }
            end

            function texture:Show()
                self._shown = true
            end

            function texture:Hide()
                self._shown = false
            end

            return texture
        end

        function frame:SetParent(parent)
            self._parent = parent
        end

        function frame:GetParent()
            return self._parent
        end

        function frame:Hide()
            self._shown = false
            local hooks = self._hooks.OnHide or {}
            for index = 1, #hooks do
                hooks[index](self)
            end
        end

        function frame:Show()
            self._shown = true
            local secureHooks = self._secureHooks.Show or {}
            for index = 1, #secureHooks do
                secureHooks[index](self)
            end
            local hooks = self._hooks.OnShow or {}
            for index = 1, #hooks do
                hooks[index](self)
            end
        end

        function frame:IsShown()
            return self._shown
        end

        function frame:SetAlpha(alpha)
            self._alpha = alpha
        end

        function frame:RegisterEvent(event)
            self._events = self._events or {}
            self._events[#self._events + 1] = event
        end

        function frame:SetScript(scriptType, handler)
            self._scripts = self._scripts or {}
            self._scripts[scriptType] = handler
        end

        function frame:SetFrameStrata(strata)
            self._strata = strata
        end

        function frame:GetFrameStrata()
            return self._strata
        end

        function frame:SetFrameLevel(level)
            self._frameLevel = level
        end

        function frame:GetFrameLevel()
            return self._frameLevel
        end

        function frame:SetPoint(...)
            self._lastPoint = { ... }
            self._points = self._points or {}
            self._points[#self._points + 1] = { ... }
        end

        function frame:ClearAllPoints()
            self._points = {}
            self._clearedPoints = true
        end

        function frame:SetHeight(height)
            self._height = height
        end

        function frame:GetTop()
            return self._top
        end

        function frame:GetBottom()
            return self._bottom
        end

        function frame:GetEffectiveScale()
            return 1
        end

        function frame:IsMouseOver()
            return self._mouseOver or false
        end

        function frame:GetObjectType()
            return "Frame"
        end

        function frame:CreateTexture()
            local texture = makeTexture()
            self._textures = self._textures or {}
            self._textures[#self._textures + 1] = texture
            return texture
        end

        function frame:HookScript(event, handler)
            local hooks = self._hooks[event]
            if not hooks then
                hooks = {}
                self._hooks[event] = hooks
            end
            hooks[#hooks + 1] = handler
        end

        return frame
    end

    local function flushDeferredCallbacks()
        local pending = deferredCallbacks
        deferredCallbacks = {}
        for index = 1, #pending do
            pending[index]()
        end
    end

    local function loadVisibility(ns)
        local chunk, err = loadfile(modulePath)
        assert.is_nil(err)
        chunk("EllesmereUIQuestTracker", ns)
        return ns.EQT
    end

    local function buildNamespace(config)
        local eqt = {
            DB = function()
                return config
            end,
            Cfg = function(key)
                return config[key]
            end,
        }

        return {
            EQT = eqt,
        }
    end

    before_each(function()
        original_CreateFrame = _G.CreateFrame
        original_ObjectiveTrackerFrame = _G.ObjectiveTrackerFrame
        original_GetInstanceInfo = _G.GetInstanceInfo
        original_hooksecurefunc = _G.hooksecurefunc
        original_C_Timer = _G.C_Timer
        original_C_ChallengeMode = _G.C_ChallengeMode
        original_ScenarioObjectiveTracker = _G.ScenarioObjectiveTracker

        createdFrames = {}
        deferredCallbacks = {}

        _G.CreateFrame = function(_, name)
            local frame = makeFrame({ shown = false })
            frame._name = name
            createdFrames[#createdFrames + 1] = frame
            return frame
        end

        _G.ObjectiveTrackerFrame = makeFrame({ shown = true, top = 500, frameLevel = 4, strata = "HIGH" })
        _G.GetInstanceInfo = function()
            return nil, "none"
        end
        _G.hooksecurefunc = function(target, methodName, handler)
            local hooks = target._secureHooks[methodName]
            if not hooks then
                hooks = {}
                target._secureHooks[methodName] = hooks
            end
            hooks[#hooks + 1] = handler
        end

        EllesmereUI.EvalVisibility = function()
            return true
        end
        EllesmereUI.PP = { perfect = 1 }
        EllesmereUI.PanelPP = {
            mult = 1,
            DisablePixelSnap = function(texture)
                texture._pixelSnapDisabled = true
            end,
        }
        EllesmereUI.ELLESMERE_GREEN = { r = 0.1, g = 0.8, b = 0.6 }
        EllesmereUI.RegAccent = nil
        EllesmereUI.RegisterVisibilityUpdater = nil
        EllesmereUI.RegisterMouseoverTarget = nil

        _G.C_Timer = {
            After = function(_, callback)
                deferredCallbacks[#deferredCallbacks + 1] = callback
            end,
        }
        _G.C_ChallengeMode = nil
        _G.ScenarioObjectiveTracker = nil
    end)

    after_each(function()
        _G.CreateFrame = original_CreateFrame
        _G.ObjectiveTrackerFrame = original_ObjectiveTrackerFrame
        _G.GetInstanceInfo = original_GetInstanceInfo
        _G.hooksecurefunc = original_hooksecurefunc
        _G.C_Timer = original_C_Timer
        _G.C_ChallengeMode = original_C_ChallengeMode
        _G.ScenarioObjectiveTracker = original_ScenarioObjectiveTracker
        EllesmereUI.EvalVisibility = nil
        EllesmereUI.PP = nil
        EllesmereUI.PanelPP = nil
        EllesmereUI.ELLESMERE_GREEN = nil
        EllesmereUI.RegAccent = nil
        EllesmereUI.RegisterVisibilityUpdater = nil
        EllesmereUI.RegisterMouseoverTarget = nil
    end)

    it("hard-hides the tracker in raid content regardless of user visibility mode", function()
        local config = { visibility = "always" }
        local EQT = loadVisibility(buildNamespace(config))

        _G.GetInstanceInfo = function()
            return nil, "raid"
        end

        EQT.UpdateVisibility()

        assert.is_false(_G.ObjectiveTrackerFrame:IsShown())
    end)

    it("fades the tracker out when another module suppresses it", function()
        local config = { visibility = "always" }
        local EQT = loadVisibility(buildNamespace(config))

        EQT.ApplySuppression(true)

        assert.is_true(_G.ObjectiveTrackerFrame:IsShown())
        assert.are.equal(0, _G.ObjectiveTrackerFrame._alpha)
    end)

    it("switches between always-visible and mouseover-only alpha states", function()
        local config = { visibility = "always" }
        local EQT = loadVisibility(buildNamespace(config))

        local currentVisibility = true
        EllesmereUI.EvalVisibility = function()
            return currentVisibility
        end

        EQT.UpdateVisibility()
        assert.are.equal(1, _G.ObjectiveTrackerFrame._alpha)

        currentVisibility = "mouseover"
        EQT.UpdateVisibility()

        assert.are.equal(0, _G.ObjectiveTrackerFrame._alpha)
    end)

    it("sizes the background to the lowest visible tracker content and applies themed colors", function()
        local config = {
            visibility = "always",
            bgR = 0.2,
            bgG = 0.3,
            bgB = 0.4,
            bgAlpha = 0.7,
            showTopLine = true,
        }
        local EQT = loadVisibility(buildNamespace(config))
        local lowestBlock = makeFrame({ shown = true, bottom = 410 })
        local header = makeFrame({ shown = true, bottom = 440 })
        _G.ObjectiveTrackerFrame.modules = {
            {
                usedBlocks = { quest = lowestBlock },
                hasContents = true,
                Header = header,
            },
        }

        EQT.ApplyBackground()

        local bg = createdFrames[2]
        assert.is_not_nil(bg)
        assert.are.same({ 0.2, 0.3, 0.4, 0.7 }, bg._tex._color)
        assert.are.equal(75, bg._height)
        assert.is_true(bg._shown)
        assert.are.equal(1, bg._divider._height)
        assert.are.same({ 0.1, 0.8, 0.6, 1 }, bg._divider._color)
        assert.is_true(bg._divider._shown)
        assert.is_true(bg._divider._pixelSnapDisabled)
    end)

    it("hides the background during challenge mode and when no content remains after initialization", function()
        local config = {
            visibility = "always",
            bgR = 0.2,
            bgG = 0.3,
            bgB = 0.4,
            bgAlpha = 0.7,
            showTopLine = false,
        }
        local EQT = loadVisibility(buildNamespace(config))
        local lowestBlock = makeFrame({ shown = true, bottom = 390 })
        _G.ObjectiveTrackerFrame.modules = {
            {
                usedBlocks = { quest = lowestBlock },
                hasContents = false,
            },
        }

        EQT.ApplyBackground()
        local bg = createdFrames[2]

        _G.C_ChallengeMode = {
            IsChallengeModeActive = function()
                return true
            end,
        }
        EQT.ResizeBGToContent()
        assert.is_false(bg._shown)

        _G.C_ChallengeMode = nil
        _G.ObjectiveTrackerFrame.modules = {
            {
                usedBlocks = {},
                hasContents = false,
            },
        }
        EQT.ResizeBGToContent()

        assert.is_true(bg._hideCheck)
        assert.is_false(bg._shown)
        assert.is_false(bg._divider._shown)
    end)

    it("registers accent, visibility, and mouseover callbacks during initialization", function()
        local config = {
            visibility = "mouseover",
            bgR = 0.1,
            bgG = 0.1,
            bgB = 0.1,
            bgAlpha = 0.5,
            showTopLine = true,
        }
        local EQT = loadVisibility(buildNamespace(config))
        local accentRegistration
        local visibilityUpdater
        local mouseoverProxy
        local mouseoverPredicate
        _G.ObjectiveTrackerFrame.modules = {
            {
                usedBlocks = { quest = makeFrame({ shown = true, bottom = 420 }) },
                hasContents = false,
            },
        }

        EllesmereUI.RegAccent = function(registration)
            accentRegistration = registration
        end
        EllesmereUI.RegisterVisibilityUpdater = function(fn)
            visibilityUpdater = fn
        end
        EllesmereUI.RegisterMouseoverTarget = function(proxy, predicate)
            mouseoverProxy = proxy
            mouseoverPredicate = predicate
        end

        EQT.InitVisibility()
        flushDeferredCallbacks()

        assert.are.equal("callback", accentRegistration.type)
        assert.is_function(accentRegistration.fn)
        assert.is_function(visibilityUpdater)
        assert.is_function(mouseoverProxy.IsShown)
        assert.is_function(mouseoverProxy.IsMouseOver)
        assert.is_true(mouseoverPredicate())

        _G.ObjectiveTrackerFrame._mouseOver = true
        assert.is_true(mouseoverProxy.IsShown())
        assert.is_true(mouseoverProxy.IsMouseOver())

        mouseoverProxy.SetAlpha(nil, 0.25)
        assert.are.equal(0.25, _G.ObjectiveTrackerFrame._alpha)
        assert.are.equal(0.25, createdFrames[2]._alpha)

        assert.are.equal(2, #createdFrames[3]._events)
    end)

    -- FALSE POSITIVE: the visibility field tested here was removed in v6.3.5.
    -- The scenario can no longer occur in production.
    pending("disabled mouseover tracker opting into shared mouseover — field removed in v6.3.5")
end)