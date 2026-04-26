-- Glow geometry helper tests.
-- Tests _EdgeAndOffset, _EdgeLen, and _OrbitXY which are pure math functions
-- powering the procedural ants and auto-cast shine animations.

describe("EllesmereUI Glow geometry helpers", function()
    local modulePath = "EllesmereUI_Glows.lua"

    local EdgeAndOffset, EdgeLen, OrbitXY

    local function replaceExact(source, oldText, newText, label)
        local startIndex = source:find(oldText, 1, true)
        assert.is_truthy(startIndex, "expected exact replacement for " .. label)
        local endIndex = startIndex + #oldText - 1
        return source:sub(1, startIndex - 1) .. newText .. source:sub(endIndex + 1)
    end

    local function loadGlows()
        local handle = assert(io.open(modulePath, "rb"))
        local source = assert(handle:read("*a"))
        handle:close()
        source = source:gsub("^\239\187\191", "")
        source = source:gsub("\r\n", "\n")

        -- Export _EdgeAndOffset: appears right before _PlaceOnEdge
        source = replaceExact(
            source,
            "    return 3, dist - w\nend\n\nlocal function _PlaceOnEdge",
            "    return 3, dist - w\nend\n_G._test_EdgeAndOffset = _EdgeAndOffset\n\nlocal function _PlaceOnEdge",
            "_EdgeAndOffset export"
        )

        -- Export _EdgeLen: appears right before _AntsOnUpdate
        source = replaceExact(
            source,
            "    return (edge == 0 or edge == 2) and w or h\nend\n\nlocal function _AntsOnUpdate",
            "    return (edge == 0 or edge == 2) and w or h\nend\n_G._test_EdgeLen = _EdgeLen\n\nlocal function _AntsOnUpdate",
            "_EdgeLen export"
        )

        -- Export _OrbitXY: appears right before _AutoCastOnUpdate
        source = replaceExact(
            source,
            "    return 0, -(h - (dist - w))\nend\n\nlocal function _AutoCastOnUpdate",
            "    return 0, -(h - (dist - w))\nend\n_G._test_OrbitXY = _OrbitXY\n\nlocal function _AutoCastOnUpdate",
            "_OrbitXY export"
        )

        local chunk, err = loadstring(source, "@" .. modulePath)
        assert.is_nil(err, "loadstring: " .. tostring(err))
        pcall(chunk, "EllesmereUI_Glows", {})

        EdgeAndOffset = _G._test_EdgeAndOffset
        EdgeLen = _G._test_EdgeLen
        OrbitXY = _G._test_OrbitXY
    end

    local original_EllesmereUI

    before_each(function()
        original_EllesmereUI = _G.EllesmereUI
        _G.EllesmereUI = _G.EllesmereUI or {}
        _G.EllesmereUI.Glows = nil  -- force re-init
        _G.EllesmereUI.PP = { perfect = 1, Scale = function(x) return x end }
        _G.AnimateTexCoords = function() end
        _G.CreateFrame = function()
            return {
                SetSize = function() end,
                SetPoint = function() end,
                Show = function() end,
                Hide = function() end,
                SetScript = function() end,
                CreateTexture = function()
                    return {
                        SetTexture = function() end,
                        SetTexCoord = function() end,
                        SetBlendMode = function() end,
                        SetPoint = function() end,
                        SetSize = function() end,
                        SetVertexColor = function() end,
                        SetAlpha = function() end,
                        SetDesaturated = function() end,
                        Show = function() end,
                        Hide = function() end,
                        ClearAllPoints = function() end,
                        SetColorTexture = function() end,
                        SetSnapToPixelGrid = function() end,
                        SetTexelSnappingBias = function() end,
                    }
                end,
            }
        end

        loadGlows()
    end)

    after_each(function()
        _G.EllesmereUI = original_EllesmereUI
        _G._test_EdgeAndOffset = nil
        _G._test_EdgeLen = nil
        _G._test_OrbitXY = nil
    end)

    -- _EdgeAndOffset -------------------------------------------------------
    describe("_EdgeAndOffset", function()
        -- w=100, h=60 → perimeter = 320
        -- Edge 0: [0, 100)  → top edge
        -- Edge 1: [100, 160) → right edge
        -- Edge 2: [160, 260) → bottom edge
        -- Edge 3: [260, 320) → left edge

        it("maps distance on top edge correctly", function()
            local edge, off = EdgeAndOffset(30, 100, 60)
            assert.equals(0, edge)
            assert.equals(30, off)
        end)

        it("maps distance at start of right edge", function()
            local edge, off = EdgeAndOffset(100, 100, 60)
            assert.equals(1, edge)
            assert.equals(0, off)
        end)

        it("maps distance on right edge", function()
            local edge, off = EdgeAndOffset(130, 100, 60)
            assert.equals(1, edge)
            assert.equals(30, off)
        end)

        it("maps distance at start of bottom edge", function()
            local edge, off = EdgeAndOffset(160, 100, 60)
            assert.equals(2, edge)
            assert.equals(0, off)
        end)

        it("maps distance on bottom edge", function()
            local edge, off = EdgeAndOffset(200, 100, 60)
            assert.equals(2, edge)
            assert.equals(40, off)
        end)

        it("maps distance at start of left edge", function()
            local edge, off = EdgeAndOffset(260, 100, 60)
            assert.equals(3, edge)
            assert.equals(0, off)
        end)

        it("maps distance on left edge", function()
            local edge, off = EdgeAndOffset(280, 100, 60)
            assert.equals(3, edge)
            assert.equals(20, off)
        end)

        it("handles zero distance (top-left corner)", function()
            local edge, off = EdgeAndOffset(0, 100, 60)
            assert.equals(0, edge)
            assert.equals(0, off)
        end)

        it("handles square frame", function()
            local edge, off = EdgeAndOffset(50, 50, 50)
            assert.equals(1, edge)
            assert.equals(0, off)
        end)
    end)

    -- _EdgeLen -------------------------------------------------------------
    describe("_EdgeLen", function()
        it("returns width for top edge (0)", function()
            assert.equals(100, EdgeLen(0, 100, 60))
        end)

        it("returns height for right edge (1)", function()
            assert.equals(60, EdgeLen(1, 100, 60))
        end)

        it("returns width for bottom edge (2)", function()
            assert.equals(100, EdgeLen(2, 100, 60))
        end)

        it("returns height for left edge (3)", function()
            assert.equals(60, EdgeLen(3, 100, 60))
        end)
    end)

    -- _OrbitXY -------------------------------------------------------------
    describe("_OrbitXY", function()
        -- Same perimeter logic as EdgeAndOffset but returns (x,y) coordinates

        it("returns (dist, 0) on top edge", function()
            local x, y = OrbitXY(30, 100, 60)
            assert.equals(30, x)
            assert.equals(0, y)
        end)

        it("returns (w, -dist) on right edge", function()
            local x, y = OrbitXY(120, 100, 60)
            assert.equals(100, x)
            assert.equals(-20, y)
        end)

        it("returns (w-dist, -h) on bottom edge", function()
            local x, y = OrbitXY(180, 100, 60)
            assert.equals(80, x)
            assert.equals(-60, y)
        end)

        it("returns (0, -(h-remaining)) on left edge", function()
            local x, y = OrbitXY(280, 100, 60)
            assert.equals(0, x)
            -- dist after subtracting w+h+w = 280-100-60-100 = 20
            -- y = -(h - (dist - w)) = -(60 - (20)) = -40
            assert.equals(-40, y)
        end)
    end)
end)
