# Turtle Navigation Tests

Comprehensive test suite for the `turtle_nav` module.

## Prerequisites

- **GPS Setup:** Turtle must have access to GPS signal (requires GPS hosts in the world)
- **Clear Space:** At least 3x3x3 blocks of clear space around the turtle
- **Wireless Modem:** Not required for basic nav tests (only for swarm features)

## Running the Tests

```lua
shell.run('/repo/test/move/turtle_nav_test.lua')
```

## Test Coverage

### Core Location Tests
1. **GPS Location** - Validates GPS coordinate retrieval
2. **GPS Caching** - Verifies location caching works correctly
3. **State Reset** - Confirms reset clears cache

### Direction Finding Tests
4. **Find Facing** - Tests cardinal direction detection
5. **Coordinate Style** - Tests coordinate-based direction names
6. **Direction Consistency** - Validates cardinal ↔ coordinate mapping

### Turning Tests
7. **Turn Right** - Tests 90° right turn
8. **Turn Left** - Tests 90° left turn  
9. **Full Rotation** - Validates 4 right turns = full circle
10. **Turn to Direction (Cardinal)** - Tests turning to "north", etc.
11. **Turn to Direction (Coordinate)** - Tests turning to "towards_x", etc.

### Movement Tests
12. **Move Forward** - Tests forward movement and location update
13. **Move Up/Down** - Tests vertical movement
14. **Move Direction** - Tests combined turn + move
15. **Error Handling** - Tests invalid direction rejection

## Expected Output

```
===========================================
  TURTLE NAVIGATION MODULE TESTS
===========================================
Computer ID: 5

[TEST] get_current_location returns valid coordinates
    Location: 100, 64, 250
[✓] PASSED

[TEST] find_facing returns valid direction
    Facing: east
[✓] PASSED

... (more tests)

===========================================
  TEST SUMMARY
===========================================
Passed: 15
Failed: 0
Total:  15

✓ ALL TESTS PASSED!
===========================================
```

## Troubleshooting

### "No GPS signal"
- Ensure GPS hosts are set up in your world
- GPS requires at least 4 computers running `gps host` at different locations
- Check turtle is within range of GPS hosts

### Movement tests fail
- Ensure 3x3x3 clear space around turtle
- Tests will skip blocked movements and note in output
- Some tests move turtle and return it to original position

### Direction inconsistencies
- If turtle was moved externally, call `turtle_nav.reset_state()` first
- Tests automatically reset state between test groups

## Test Structure

Each test follows this pattern:
```lua
test("description", function()
    -- Arrange
    turtle_nav.reset_state()
    
    -- Act
    local result = turtle_nav.some_function()
    
    -- Assert
    assert_not_nil(result)
    assert_equals(expected, result)
end)
```

## Integration with CI/CD

These tests can be automated if you have:
1. GPS infrastructure in test world
2. Known starting position for turtle
3. Clear space guarantee

Example automation:
```lua
-- setup_test_env.lua
turtle.select(1)
turtle.refuel()

-- Clear space
for i = 1, 3 do
    turtle.dig()
    turtle.forward()
end
turtle.back()
turtle.back()
turtle.back()

-- Run tests
shell.run('/repo/test/move/turtle_nav_test.lua')
```

## Adding New Tests

To add a new test:

```lua
test("your test name", function()
    -- Setup
    turtle_nav.reset_state()
    
    -- Test logic
    local result = turtle_nav.your_function()
    
    -- Assertions
    assert_true(result, "Should succeed")
    
    -- Cleanup (if needed)
    turtle_nav.reset_state()
end)
```

## Known Limitations

- Tests assume unobstructed movement in some cases
- GPS signal quality affects test reliability
- Tests may take 30-60 seconds to complete due to GPS calls
- Some tests skip if movement is blocked (non-fatal)

