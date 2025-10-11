--[[
Chest interaction module for turtles using CC: Tweaked peripheral API.

Provides functions to get and deposit items from/to chests with precise
count control and item type filtering.

Uses the modern peripheral.call inventory API for chest interactions.
Requires chest to be wrapped as a peripheral (on same wired network or adjacent).

References:
- https://tweaked.cc/generic_peripheral/inventory.html
]]

inv = require('/repo/src/turtle/inv')

local M = {}

local function get_chest_peripheral(direction)
    -- Get a chest peripheral by direction, name, or auto-detect.
    --
    -- If direction is nil, automatically finds the first available chest
    -- peripheral touching the turtle.
    --
    -- Args:
    --     direction: String or nil
    --                - Peripheral direction: "front", "back", "left", "right", "top", "bottom"
    --                - Peripheral name: "minecraft:chest_0" (for networked chests)
    --                - nil: Auto-detect any adjacent chest
    --
    -- Returns:
    --     chest: Peripheral wrapper for the chest, or nil if not found
    --     error_msg: String error message if chest not found
    
    local chest = nil
    if not direction then
        local chests = { peripheral.find("minecraft:chest") }
        if #chests == 0 then
            return nil, "No chests found"
        end
        chest = chests[1]
    else
        -- Try to wrap the peripheral
        chest = peripheral.wrap(direction)

    end
    
    if not chest then
        return nil, "No peripheral found at '" .. direction .. "'"
    end
    
    -- Verify it has inventory methods
    if not chest.list or not chest.pullItems or not chest.pushItems then
        return nil, "Peripheral at '" .. direction .. "' is not an inventory"
    end
    
    return chest, nil
end

local function get_turtle_name()
    local modem = peripheral.find("modem")
    if not modem then
        return nil, "No modem found"
    end
    return modem.getNameLocal()
end

function M.get_item(item_name, count, direction)
    -- Get a specific item from a chest into turtle's inventory using peripheral API.
    --
    -- Searches for the specified item in the chest and pushes it to the turtle.
    -- Uses CC: Tweaked's peripheral inventory API.
    --
    -- Args:
    --     item_name: String, full item name (e.g. "minecraft:stone", "minecraft:oak_log")
    --     count: Number of items to get (optional, default: 64)
    --     direction: String or nil, chest location (optional, default: nil for auto-detect)
    --                - Direction: "front", "back", "left", "right", "top", "bottom"
    --                - Peripheral name: "minecraft:chest_0" (for networked chests)
    --                - nil: Auto-detect any adjacent chest
    --
    -- Returns:
    --     success: Boolean, true if got all requested items
    --     actual_count: Number of items actually retrieved
    --
    -- Example:
    --     -- Get 32 cobblestone from any adjacent chest
    --     local success, count = chest.get_item("minecraft:cobblestone", 32)
    --     
    --     -- Or specify direction
    --     local success, count = chest.get_item("minecraft:cobblestone", 32, "front")
    
    count = count or 1
    -- direction can be nil for auto-detect
    
    assert(type(item_name) == "string", "item_name must be a string")
    assert(type(count) == "number" and count > 0, "count must be a positive number")
    
    -- Get the chest peripheral
    local chest_inv, err = get_chest_peripheral(direction)
    if not chest_inv then
        print("[GET_ITEM] " .. err)
        return false, 0
    end
    
    -- Get turtle's inventory name for peripheral operations
    local turtle_name = get_turtle_name()
    
    local items_retrieved = 0
    
    -- Search chest for the item
    local chest_items = chest_inv.list()
    
    for slot, item in pairs(chest_items) do
        if item.name == item_name and items_retrieved < count then
            -- Find an empty slot in turtle or one with the same item
            local target_slot = inv.find_space_for_item(item_name)
            
            if not target_slot then
                print("[GET_ITEM] No available inventory space")
                break
            end

            local space_available = turtle.getItemSpace(target_slot)
            
            -- Calculate how much to transfer from this slot
            local needed = count - items_retrieved
            local to_transfer = math.min(needed, item.count, space_available)
            
            -- Push items from chest to turtle
            local transferred = chest_inv.pushItems(turtle_name, slot, to_transfer, target_slot)
            items_retrieved = items_retrieved + transferred
            
            if items_retrieved >= count then
                break
            end
        end
    end
    
    local success = items_retrieved >= count
    if success then
        print("[GET_ITEM] Retrieved " .. items_retrieved .. "x " .. item_name)
    else
        print("[GET_ITEM] Only retrieved " .. items_retrieved .. "/" .. count .. " of " .. item_name)
    end
    
    return success, items_retrieved
end

function M.deposit_item(item_name, count, direction)
    -- Deposit a specific item from turtle's inventory into a chest using peripheral API.
    --
    -- Searches turtle's inventory for the specified item and pulls it into the chest.
    -- Automatically finds all stacks of the item and deposits until count is reached.
    -- Uses CC: Tweaked's peripheral inventory API.
    --
    -- Args:
    --     item_name: String, full item name (e.g. "minecraft:stone", "minecraft:cobblestone")
    --     count: Number of items to deposit (optional, default: all available)
    --     direction: String or nil, chest location (optional, default: nil for auto-detect)
    --                - Direction: "front", "back", "left", "right", "top", "bottom"
    --                - Peripheral name: "minecraft:chest_0"
    --                - nil: Auto-detect any adjacent chest
    --
    -- Returns:
    --     success: Boolean, true if deposited all requested items
    --     actual_count: Number of items actually deposited
    --
    -- Example:
    --     -- Deposit 32 cobblestone into any adjacent chest
    --     local success, count = chest.deposit_item("minecraft:cobblestone", 32)
    --     
    --     -- Deposit all dirt (no count = all available)
    --     local success, count = chest.deposit_item("minecraft:dirt")
    --     
    --     -- Specify direction
    --     local success, count = chest.deposit_item("minecraft:gravel", 64, "bottom")
    
    
    if not item_name then
        error("item_name must be a string")
    end
    if count then
        assert(type(count) == "number" and count > 0, "count must be a positive number or nil")
    end
    
    -- Get the chest peripheral
    local chest_inv, err = get_chest_peripheral(direction)
    if not chest_inv then
        print("[DEPOSIT_ITEM] " .. err)
        return false, 0
    end
    
    -- Get turtle's inventory name for peripheral operations
    local turtle_name = get_turtle_name()
    
    local items_deposited = 0
    
    -- Search turtle inventory for the specified item
    local target_count = count or math.huge

    while true do
        local target_slot = inv.find_item(item_name)

        if not target_slot then
            print("[DEPOSIT_ITEM] No item in inventory")
            return false, items_deposited
        end

        local item_count = turtle.getItemCount(target_slot)

        local to_deposit = math.min(target_count - items_deposited, item_count)

        local transferred = chest_inv.pullItems(turtle_name, target_slot, to_deposit)

        if transferred == 0 then
            print("[DEPOSIT_ITEM] Chest may be full")
            break
        end

        items_deposited = items_deposited + transferred

        if items_deposited >= target_count then
            break
        end
    end

    local success = items_deposited >= target_count
    if success then
        print("[DEPOSIT_ITEM] Deposited " .. items_deposited .. "x " .. item_name)
    else
        print("[DEPOSIT_ITEM] Only deposited " .. items_deposited .. "/" .. target_count .. " of " .. item_name)
    end
    
    return success, items_deposited
    end
    
function M.deposit_all(direction)
    -- Deposit all items from turtle's inventory into a chest using peripheral API.
    --
    -- Args:
    --     direction: String or nil, chest location (optional, default: nil for auto-detect)
    --                - Direction: "front", "back", "left", "right", "top", "bottom"
    --                - Peripheral name: "minecraft:chest_0"
    --                - nil: Auto-detect any adjacent chest
    --
    -- Returns:
    --     total_deposited: Number of slots deposited
    --
    -- Example:
    --     chest.deposit_all()           -- Auto-detect chest
    --     chest.deposit_all("bottom")   -- Empty entire inventory into chest below
    
    -- Get the chest peripheral
    local chest_inv, err = get_chest_peripheral(direction)
    if not chest_inv then
        print("[DEPOSIT_ALL] " .. err)
        return 0
    end
    
    local turtle_name = get_turtle_name()
    local slots_deposited = 0
    
    for slot = 1, 16 do
        local item_detail = turtle.getItemDetail(slot)
        if item_detail then
            -- Pull all items from this turtle slot into chest
            local transferred = chest_inv.pullItems(turtle_name, slot)
            if transferred > 0 then
                slots_deposited = slots_deposited + 1
            end
        end
    end
    
    print("[DEPOSIT_ALL] Deposited " .. slots_deposited .. " slots")
    return slots_deposited
end

return M

