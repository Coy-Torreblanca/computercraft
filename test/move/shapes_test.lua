--[[
Test suite for shapes module

Run this on a turtle with GPS access to test shape movement functionality.
Requires sufficient clear space for the test patterns.
]]

local shapes = require('/repo/src/move/shapes')
local turtle_nav = require('/repo/src/move/turtle_nav')

print("===========================================")
print("  SHAPES MODULE TESTS")
print("===========================================")
print("Computer ID: " .. os.computerID())
print("")

-- Get starting position
turtle_nav.reset_state()
local start_pos = turtle_nav.get_current_location()
print("Starting position: (" .. start_pos.x .. "," .. start_pos.y .. "," .. start_pos.z .. ")")
print("")

-- Test 1: Small 3x3x1 rectangle with counter
print("\n[TEST 1] 3x3x1 Rectangle - Count positions")
local visit_count = 0
local corner1 = {x = start_pos.x, y = start_pos.y, z = start_pos.z}
local corner2 = {x = start_pos.x + 2, y = start_pos.y, z = start_pos.z + 2}

local function count_visits(x, y, z, nav)
    visit_count = visit_count + 1
    print("  Position #" .. visit_count .. ": (" .. x .. "," .. y .. "," .. z .. ")")
    return true  -- Continue
end

local success, visited, total = shapes.rectangle(corner1, corner2, count_visits)

if success then
    print("✓ SUCCESS: Visited all " .. visited .. "/" .. total .. " positions")
else
    print("✗ FAILED: Only visited " .. visited .. "/" .. total .. " positions")
end

-- Return to start
print("\nReturning to start position...")
turtle_nav.goto_location(start_pos.x, start_pos.y, start_pos.z)

-- Test 2: Early abort test
print("\n[TEST 2] Early Abort - Stop after 5 positions")
local abort_count = 0

local function abort_after_5(x, y, z, nav)
    abort_count = abort_count + 1
    print("  Position #" .. abort_count .. ": (" .. x .. "," .. y .. "," .. z .. ")")
    
    if abort_count >= 5 then
        print("  Requesting abort!")
        return false  -- Abort
    end
    
    return true
end

local success2, visited2, total2 = shapes.rectangle(corner1, corner2, abort_after_5)

if not success2 and visited2 == 5 then
    print("✓ SUCCESS: Correctly aborted after " .. visited2 .. " positions")
else
    print("✗ FAILED: Expected abort after 5, got " .. visited2)
end

-- Return to start
print("\nReturning to start position...")
turtle_nav.goto_location(start_pos.x, start_pos.y, start_pos.z)

-- Test 3: Multi-layer test
print("\n[TEST 3] 2x2x2 Cube - Multi-layer")
local layer_counts = {}

local corner3 = {x = start_pos.x, y = start_pos.y, z = start_pos.z}
local corner4 = {x = start_pos.x + 1, y = start_pos.y + 1, z = start_pos.z + 1}

local function count_by_layer(x, y, z, nav)
    layer_counts[y] = (layer_counts[y] or 0) + 1
    return true
end

local success3, visited3, total3 = shapes.rectangle(corner3, corner4, count_by_layer)

if success3 then
    print("✓ SUCCESS: Visited all " .. visited3 .. "/" .. total3 .. " positions")
    print("  Layer breakdown:")
    for y, count in pairs(layer_counts) do
        print("    Y=" .. y .. ": " .. count .. " positions")
    end
else
    print("✗ FAILED: Only visited " .. visited3 .. "/" .. total3)
end

-- Return to start
print("\nReturning to start position...")
turtle_nav.goto_location(start_pos.x, start_pos.y, start_pos.z)

-- Test 4: Hollow rectangle test
print("\n[TEST 4] Hollow Rectangle - Edges only")
local edge_count = 0

local function count_edges(x, y, z, nav)
    edge_count = edge_count + 1
    print("  Edge #" .. edge_count .. ": (" .. x .. "," .. y .. "," .. z .. ")")
    return true
end

local success4, visited4 = shapes.hollow_rectangle(corner1, corner2, count_edges)

if success4 then
    print("✓ SUCCESS: Visited " .. visited4 .. " edge positions")
else
    print("✗ FAILED: Only visited " .. visited4 .. " edges")
end

-- Return to start
print("\nReturning to start position...")
turtle_nav.goto_location(start_pos.x, start_pos.y, start_pos.z)

-- Print final summary
print("\n")
print("===========================================")
print("  TEST SUMMARY")
print("===========================================")
print("All shape tests completed!")
print("Final position: " .. turtle_nav.get_current_location().x .. "," .. 
      turtle_nav.get_current_location().y .. "," .. turtle_nav.get_current_location().z)
print("===========================================")

