--[[
Test suite for chest module

Run this on a turtle positioned next to a chest.
The chest should contain some test items for get operations.
]]

local chest = require('/repo/src/chest/chest')
local inv = require('/repo/src/turtle/inv')

print("===========================================")
print("  CHEST MODULE TESTS")
print("===========================================")
print("Computer ID: " .. os.computerID())
print("")

-- Test setup
print("TEST SETUP:")
print("- Turtle must have a wired modem attached")
print("- Chest must have a wired modem attached")
print("- Both must be connected via network cable")
print("- Chest should contain some test items (cobblestone recommended)")
print("- Press Enter to continue or Ctrl+T to cancel")
read()

-- List available peripherals
print("\nAvailable peripherals on network:")
local peripherals = peripheral.getNames()
for _, name in ipairs(peripherals) do
    print("  - " .. name)
end
print("")

local TEST_RESULTS = {
    passed = 0,
    failed = 0,
    errors = {}
}

local function test(name, fn)
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

-- Test 1: Auto-detect chest
test("auto-detect finds adjacent chest", function()
    -- Clear inventory first by depositing all
    local slots = chest.deposit_all()  -- No direction = auto-detect
    print("    Deposited " .. slots .. " slots (auto-detect)")
    
    local count = inv.count_item("minecraft:cobblestone")
    print("    Cobblestone count after clear: " .. count)
    assert(count == 0, "Should have 0 cobblestone after clearing")
end)

-- Test 2: Get item from chest
test("get_item retrieves items from chest with auto-detect", function()
    -- Try to get 16 of any common item (adjust item name as needed)
    local success, count = chest.get_item("minecraft:cobblestone", 16)  -- Auto-detect
    
    if success then
        print("    Successfully retrieved " .. count .. " cobblestone")
        assert(count == 16, "Should retrieve exactly 16 items")
    else
        print("    [SKIP] No cobblestone in chest, got: " .. count)
    end
end)

-- Test 3: Deposit specific item with auto-detect
test("deposit_item deposits specific items with auto-detect", function()
    -- Get some cobblestone first
    chest.get_item("minecraft:cobblestone", 32)  -- Auto-detect
    
    local cobble_count = inv.count_item("minecraft:cobblestone")
    
    if cobble_count == 0 then
        print("    [SKIP] No cobblestone retrieved")
        return
    end
    
    -- Deposit half of them
    local to_deposit = math.floor(cobble_count / 2)
    if to_deposit > 0 then
        local success, count = chest.deposit_item("minecraft:cobblestone", to_deposit)  -- Auto-detect
        print("    Deposited " .. count .. "/" .. to_deposit .. " cobblestone")
        assert(count == to_deposit, "Should deposit requested amount")
    else
        print("    [SKIP] Not enough items to test partial deposit")
    end
end)

-- Test 4: Deposit all items
test("deposit_all empties inventory", function()
    -- Get some items first
    chest.get_item("minecraft:cobblestone", 32)  -- Auto-detect
    
    -- Deposit everything
    local slots = chest.deposit_all()  -- Auto-detect
    print("    Deposited " .. slots .. " slots")
    
    -- Verify inventory is empty
    local empty_slots = inv.get_empty_slots()
    print("    Empty slots after deposit_all: " .. empty_slots)
    
    assert(empty_slots == 16, "Inventory should be empty after deposit_all")
end)

-- Test 5: Inventory checking with inv module
test("inv module correctly checks inventory", function()
    -- Clear inventory
    chest.deposit_all()
    
    -- Should not have cobblestone
    local count = inv.count_item("minecraft:cobblestone")
    assert(count == 0, "Should have 0 cobblestone in empty inventory")
    print("    Count after clear: " .. count)
    
    -- Get some cobblestone
    chest.get_item("minecraft:cobblestone", 20)  -- Auto-detect
    
    -- Should have cobblestone now
    local count2 = inv.count_item("minecraft:cobblestone")
    print("    Count after getting items: " .. count2)
    assert(count2 >= 20, "Should have at least 20 cobblestone")
end)

-- Test 6: Get partial amount
test("get_item handles partial retrieval", function()
    -- Clear inventory
    chest.deposit_all()
    
    -- Try to get more than what might be available
    local success, count = chest.get_item("minecraft:cobblestone", 1000)  -- Auto-detect
    print("    Retrieved " .. count .. " cobblestone (requested 1000)")
    
    if count > 0 then
        print("    Got partial amount as expected")
    else
        print("    [SKIP] No items in chest to test")
    end
end)

-- Test 7: Explicit peripheral names
test("chest operations work with explicit peripheral names", function()
    chest.deposit_all()  -- Clear first
    
    -- Find first chest on network
    local chest_periph = peripheral.find("minecraft:chest")
    if not chest_periph then
        print("    [SKIP] No chest found on network")
        return
    end
    
    local chest_name = peripheral.getName(chest_periph)
    print("    Testing explicit peripheral name: " .. chest_name)
    
    local success, count = chest.get_item("minecraft:cobblestone", 5, chest_name)
    print("    Retrieved " .. count .. " using explicit peripheral name")
    
    if count > 0 then
        -- Deposit back
        chest.deposit_item("minecraft:cobblestone", count, chest_name)
        print("    Successfully used explicit peripheral name")
    else
        print("    [SKIP] No items in chest")
    end
end)

-- Test 8: Deposit all available of an item
test("deposit_item without count deposits all available", function()
    -- Get some items
    chest.get_item("minecraft:cobblestone", 64)
    chest.get_item("minecraft:cobblestone", 32)  -- Get more, might go to different slots
    
    local before_count = inv.count_item("minecraft:cobblestone")
    print("    Have " .. before_count .. " cobblestone before deposit")
    
    if before_count == 0 then
        print("    [SKIP] No cobblestone retrieved")
        return
    end
    
    -- Deposit all cobblestone (no count specified)
    local success, count = chest.deposit_item("minecraft:cobblestone")  -- No count = all
    print("    Deposited " .. count .. " cobblestone (all)")
    
    local after_count = inv.count_item("minecraft:cobblestone")
    assert(after_count == 0, "Should have 0 cobblestone after depositing all")
    assert(count == before_count, "Should deposit all available items")
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

