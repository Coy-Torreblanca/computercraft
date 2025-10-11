--[[
Test suite for turtle_nav module

Run this on a turtle with GPS access to test navigation functionality.
Requires at least 3x3x3 clear space around the turtle.
]]

local turtle_nav = require('/repo/src/move/turtle_nav')

local TEST_RESULTS = {
    passed = 0,
    failed = 0,
    errors = {}
}

local function test(name, fn)
    -- Run a single test and track results
    print("\n[TEST] " .. name)
    local success, error_msg = pcall(fn)
    
    if success then
        TEST_RESULTS.passed = TEST_RESULTS.passed + 1
        print("[✓] PASSED: " .. name)
    else
        TEST_RESULTS.failed = TEST_RESULTS.failed + 1
        print("[✗] FAILED: " .. name)
        print("    Error: " .. tostring(error_msg))
        table.insert(TEST_RESULTS.errors, {name = name, error = error_msg})
    end
end

local function assert_not_nil(value, message)
    if value == nil then
        error(message or "Expected non-nil value")
    end
end

local function assert_equals(expected, actual, message)
    print('test assert_equals', expected, actual) -- TODO remove
    if expected ~= actual then
        error(message or ("Expected " .. tostring(expected) .. " but got " .. tostring(actual)))
    end
end

local function assert_true(value, message)
    if not value then
        error(message or "Expected true")
    end
end

print("===========================================")
print("  TURTLE NAVIGATION MODULE TESTS")
print("===========================================")
print("Computer ID: " .. os.computerID())
print("")

-- Test 1: GPS Location
test("get_current_location returns valid coordinates", function()
    turtle_nav.reset_state()
    local loc = turtle_nav.get_current_location()
    assert_not_nil(loc, "Location should not be nil")
    assert_not_nil(loc.x, "X coordinate should not be nil")
    assert_not_nil(loc.y, "Y coordinate should not be nil")
    assert_not_nil(loc.z, "Z coordinate should not be nil")
    print("    Location: " .. loc.x .. ", " .. loc.y .. ", " .. loc.z)
end)

-- Test 2: GPS Caching
test("get_current_location caches result", function()
    turtle_nav.reset_state()
    local loc1 = turtle_nav.get_current_location()
    local loc2 = turtle_nav.get_current_location()
    assert_equals(loc1, loc2, "Cached location should be same table reference")
end)

-- Test 3: State Reset
test("reset_state clears cache", function()
    local loc1 = turtle_nav.get_current_location()
    turtle_nav.reset_state()
    local loc2 = turtle_nav.get_current_location()
    assert_true(loc1 ~= loc2, "After reset, should get new table reference")
end)

-- Test 4: Find Facing
test("find_facing returns valid direction", function()
    turtle_nav.reset_state()
    local direction = turtle_nav.find_facing()
    assert_not_nil(direction, "Direction should not be nil")
    local valid = direction == "north" or direction == "south" or direction == "east" or direction == "west"
    assert_true(valid, "Direction must be north, south, east, or west")
    print("    Facing: " .. direction)
end)

-- Test 5: Get Facing Coordinate Style
test("get_facing_coordinate_style returns coordinate direction", function()
    turtle_nav.reset_state()
    local coord_dir = turtle_nav.get_facing_coordinate_style()
    assert_not_nil(coord_dir, "Coordinate direction should not be nil")
    local valid = coord_dir == "towards_x" or coord_dir == "away_x" or 
                  coord_dir == "towards_z" or coord_dir == "away_z"
    assert_true(valid, "Coordinate direction must be towards_x, away_x, towards_z, or away_z")
    print("    Coordinate Style: " .. coord_dir)
end)

-- Test 6: Turn Right
test("turn_right updates direction", function()
    turtle_nav.reset_state()
    local dir1 = turtle_nav.find_facing()
    local success = turtle_nav.turn_right()
    assert_true(success, "Turn right should succeed")
    local dir2 = turtle_nav.find_facing()
    assert_true(dir1 ~= dir2, "Direction should change after turning")
    print("    Before: " .. dir1 .. ", After: " .. dir2)
    -- Turn back
    turtle_nav.turn_left()
end)

-- Test 7: Turn Left
test("turn_left updates direction", function()
    turtle_nav.reset_state()
    local dir1 = turtle_nav.find_facing()
    local success = turtle_nav.turn_left()
    assert_true(success, "Turn left should succeed")
    local dir2 = turtle_nav.find_facing()
    assert_true(dir1 ~= dir2, "Direction should change after turning")
    print("    Before: " .. dir1 .. ", After: " .. dir2)
    -- Turn back
    turtle_nav.turn_right()
end)

-- Test 8: Full Rotation
test("four right turns returns to original direction", function()
    turtle_nav.reset_state()
    local original_dir = turtle_nav.find_facing()
    
    turtle_nav.turn_right()
    turtle_nav.turn_right()
    turtle_nav.turn_right()
    turtle_nav.turn_right()
    
    local final_dir = turtle_nav.find_facing()
    assert_equals(original_dir, final_dir, "Should face original direction after 4 right turns")
end)

-- Test 9: Turn to Specific Direction (Cardinal)
test("turn_direction with cardinal direction", function()
    turtle_nav.reset_state()
    local success = turtle_nav.turn_direction("north")
    assert_true(success, "Should successfully turn to north")
    assert_equals("north", turtle_nav.find_facing(), "Should be facing north")
end)

-- Test 10: Turn to Specific Direction (Coordinate Style)
test("turn_direction with coordinate style", function()
    turtle_nav.reset_state()
    local success = turtle_nav.turn_direction("towards_x")
    assert_true(success, "Should successfully turn towards_x")
    assert_equals("east", turtle_nav.find_facing(), "towards_x should be east")
end)

-- Test 11: Move Forward
test("move_forward updates location", function()
    turtle_nav.reset_state()
    local loc1 = turtle_nav.get_current_location()
    local success, loc2 = turtle_nav.move_forward()
    
    if success then
        assert_not_nil(loc2, "Should return new location")
        local distance = math.abs(loc2.x - loc1.x) + math.abs(loc2.z - loc1.z)
        print("    Moved from (" .. loc1.x .. "," .. loc1.z .. ") to (" .. loc2.x .. "," .. loc2.z .. ")")
        assert_equals(1, distance, "Should move exactly 1 block horizontally")
        -- Move back
        turtle_nav.move_back()
    else
        print("    [SKIP] Could not move forward (blocked)")
    end
end)

-- Test 12: Move Up/Down
test("move_up and move_down update Y coordinate", function()
    turtle_nav.reset_state()
    local loc1 = turtle_nav.get_current_location()
    local y1 = loc1.y
    
    print('test move_up before up', y1) -- TODO remove

    local up_success, loc2 = turtle_nav.move_up()
    assert_true(up_success, "Should move up successfully")

    local y2 = loc2.y
    print('test move_up after up', loc1.x, loc1.y, loc1.z) -- TODO remove
    assert_equals(y1 + 1, y2, "Y should increase by 1")
    
    local down_success, loc3 = turtle_nav.move_down()
    assert_true(down_success, "Should move down successfully")
    local y3 = loc3.y
    assert_equals(y1, y3, "Y should return to original")
end)

-- Test 13: Move Direction (Coordinate Style)
test("move_direction with coordinate style", function()
    turtle_nav.reset_state()
    turtle_nav.turn_direction("towards_x")  -- Face east
    local loc1 = turtle_nav.get_current_location()
    local x1 = loc1.x
    
    local success, loc2 = turtle_nav.move_direction("towards_x")
    if success then
        assert_true(loc2.x > x1, "X should increase when moving towards_x")
        print("    Moved towards_x: X went from " .. loc1.x .. " to " .. loc2.x)
        -- Move back
        turtle_nav.move_direction("away_x")
    else
        print("    [SKIP] Could not move (blocked)")
    end
end)

-- Test 14: Invalid Direction Error
test("turn_direction rejects invalid direction", function()
    local success, error_msg = pcall(function()
        turtle_nav.turn_direction("northwest")
    end)
    assert_true(not success, "Should throw error for invalid direction")
    print("    Correctly rejected invalid direction")
end)

-- Test 15: Direction Consistency
test("coordinate and cardinal directions are consistent", function()
    turtle_nav.reset_state()
    turtle_nav.turn_direction("towards_x")
    assert_equals("east", turtle_nav.find_facing(), "towards_x should map to east")
    
    turtle_nav.turn_direction("away_x")
    assert_equals("west", turtle_nav.find_facing(), "away_x should map to west")
    
    turtle_nav.turn_direction("towards_z")
    assert_equals("south", turtle_nav.find_facing(), "towards_z should map to south")
    
    turtle_nav.turn_direction("away_z")
    assert_equals("north", turtle_nav.find_facing(), "away_z should map to north")
end)

-- Print Summary
print("\n")
print("===========================================")
print("  TEST SUMMARY")
print("===========================================")
print("Passed: " .. TEST_RESULTS.passed)
print("Failed: " .. TEST_RESULTS.failed)
print("Total:  " .. (TEST_RESULTS.passed + TEST_RESULTS.failed))
print("")

if TEST_RESULTS.failed > 0 then
    print("Failed Tests:")
    for i, err in ipairs(TEST_RESULTS.errors) do
        print("  " .. i .. ". " .. err.name)
        print("     " .. err.error)
    end
    print("")
end

if TEST_RESULTS.failed == 0 then
    print("✓ ALL TESTS PASSED!")
else
    print("✗ SOME TESTS FAILED")
end
print("===========================================")

