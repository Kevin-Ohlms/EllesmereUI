-- Bootstrap for running EllesmereUI unit tests outside of World of Warcraft.
--
-- This file provides a minimal set of WoW globals and frame stubs so the
-- core addon file can be loaded in a plain Lua environment.
--
-- The test suite should remain focused on pure logic and helpers while
-- avoiding real UI rendering or runtime-only Blizzard APIs.

-- Required global for addon path
EUI_HOST_ADDON = "EllesmereUI"

-- Minimal parent frame placeholder used by CreateFrame.
UIParent = {}

-- Minimal stub for LibStub so the addon can safely try to resolve libraries.
-- If a bundle is not available, LibStub returns nil and the addon falls back.
LibStub = function(name, quiet)
    return nil
end

-- Build a generic frame-like table with a lenient method stub.
-- Methods generally return the frame itself so chained calls do not error.
local function makeFrame()
    local frame = {}
    local mt = {
        __index = function(self, key)
            if key == "GetObjectType" then
                return function() return "Frame" end
            elseif key == "CreateTexture" or key == "CreateFontString" or key == "CreateMaskTexture" then
                return function() return makeFrame() end
            end
            return function(...) return self end
        end,
    }
    return setmetatable(frame, mt)
end

-- CreateFrame stub used by the addon during load and by tests.
CreateFrame = function(...)
    return makeFrame()
end

-- Locale and player state stubs.
GetLocale = function()
    return "enUS"
end

UnitClass = function()
    return "player", "MAGE"
end

UnitFactionGroup = function()
    return "Alliance"
end

UnitName = function()
    return "TestPlayer"
end

GetNumGroupMembers = function()
    return 0
end

-- SavedVariables and addon metadata stubs.
GetAddOnMetadata = function(...)
    return nil
end

GetCVar = function(...)
    return nil
end

SetCVar = function(...)
    return nil
end

-- Time and scheduling.
GetTime = function()
    return 0
end

C_Timer = {
    After = function(_, callback)
        callback()
    end,
}

-- Addon loading helpers.
IsAddOnLoaded = function(...)
    return false
end

hooksecurefunc = function(...) end
LoadAddOn = function(...) return true end

-- Keep the standard print behavior in the test environment.
print = print

-- Load the main addon file once for tests. This is the only production file
-- required by the current test suite.
local chunk, err = loadfile("EllesmereUI.lua")
if not chunk then
    error("Failed to load EllesmereUI.lua: " .. tostring(err))
end
chunk("EllesmereUI")
