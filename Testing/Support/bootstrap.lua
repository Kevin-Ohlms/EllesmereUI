-- Bootstrap for running EllesmereUI unit tests outside of World of Warcraft.
--
-- This file provides the minimal WoW API surface needed to load the addon in a
-- plain Lua environment. Keep it small: add stubs only when a real test needs
-- to execute one step further into WoW-specific code.

-- Required global expected by the addon's top-level file.
EUI_HOST_ADDON = "EllesmereUI"
EllesmereUI = {}

-- Minimal stub for LibStub so the addon can safely try to resolve libraries.
-- If a bundle is not available, LibStub returns nil and the addon falls back.
LibStub = function(name, quiet)
    return nil
end

-- Build a generic frame-like table with a lenient method stub.
-- Methods generally return the frame itself so chained calls do not error.
local function makeFrame()
    local frame = {}
    local methods = {
        GetObjectType = function()
            return "Frame"
        end,
        GetScale = function()
            return 1
        end,
        GetEffectiveScale = function()
            return 1
        end,
        GetWidth = function()
            return 1920
        end,
        GetHeight = function()
            return 1080
        end,
        CreateTexture = function()
            return makeFrame()
        end,
        CreateFontString = function()
            return makeFrame()
        end,
        CreateMaskTexture = function()
            return makeFrame()
        end,
    }

    setmetatable(methods, {
        __index = function()
            return function()
                return frame
            end
        end,
    })

    return setmetatable(frame, {
        __index = methods,
    })
end

UIParent = makeFrame()

CreateFrame = function(...)
    return makeFrame()
end

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

GetPhysicalScreenSize = function()
    return 1920, 1080
end

GetScreenWidth = function()
    return 1920
end

GetScreenHeight = function()
    return 1080
end

InCombatLockdown = function()
    return false
end

SlashCmdList = {}

C_AddOns = {
    IsAddOnLoaded = function()
        return false
    end,
    GetNumAddOns = function()
        return 0
    end,
    GetAddOnInfo = function()
        return nil
    end,
}

UpdateAddOnMemoryUsage = function()
    return nil
end

GetAddOnMemoryUsage = function()
    return 0
end

EnumerateFrames = function()
    return nil
end

issecrettable = function()
    return false
end

min = math.min
max = math.max

GetAddOnMetadata = function(...)
    return nil
end

GetCVar = function(...)
    return nil
end

SetCVar = function(...)
    return nil
end

GetTime = function()
    return 0
end

C_Timer = {
    After = function(_, callback)
        callback()
    end,
    NewTicker = function(_, callback)
        callback()
        return {
            Cancel = function() end,
        }
    end,
}

IsAddOnLoaded = function(...)
    return false
end

hooksecurefunc = function(...) end
LoadAddOn = function(...) return true end

print = print

local chunk, err = loadfile("EllesmereUI.lua")
if not chunk then
    error("Failed to load EllesmereUI.lua: " .. tostring(err))
end
chunk("EllesmereUI")