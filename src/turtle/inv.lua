local M = {}

function M.find_item(item_name)
    -- check current item slot return slot number with item or nil.

    -- Check if current slot has target item.
    local item = turtle.getItemDetail()

    if (item and item.name == item_name) then
        return turtle.getSelectedSlot()
    end

    -- Check all slots for target item.
    for i = 1, 16 do

        item = turtle.getItemDetail(i)

        if (item and item.name == item_name) then
            return i
        end
    end
end

function M.find_space_for_item(item_name)

    -- First check to see if you can find stack of item with enough space.

    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if (item and item.name == item_name) then
            if turtle.getItemSpace(i) ~= 0 then
                return i
            end
        end
    end

    -- If no stack with enough space, find an empty slot.
    return M.find_empty_slot()
end

function M.find_empty_slot()
    -- Find an empty inventory slot.
    -- Returns slot number or nill if no nexist.

    if (not turtle.getItemDetail()) then
        return turtle.getSelectedSlot()
    end

    for i = 1, 16 do

        item = turtle.getItemDetail(i)

        if (not item) then
            return i
        end

    end
end

function M.ensure_attached(peripheral_name, side)
    -- Ensure that the peripheral is attached at target side.
    -- Returns: Boolean depending on success.

    local equipTargetSide, getEquippedTargetSide
    local equipNonTargetSide, getEquippedNonTargetSide
    local result, error_msg

    -- Abstract target side functions.
    if (string.lower(side) == 'left') then
        equipTargetSide = turtle.equipLeft
        getEquippedTargetSide = turtle.getEquippedLeft

        equipNonTargetSide = turtle.equipRight
        getEquippedNonTargetSide = turtle.getEquippedRight
        
    elseif (string.lower(side) == 'right') then
        equipTargetSide = turtle.equipRight
        getEquippedTargetSide = turtle.getEquippedRight

        equipNonTargetSide = turtle.equipLeft
        getEquippedNonTargetSide = turtle.getEquippedLeft

    else

        return false, 'Incorrect Input. You must input "left" or "right"'
        
    end
    
    -- Check if already attached at target side.
    local item_attached_on_target_side = getEquippedTargetSide()
    if (item_attached_on_target_side and item_attached_on_target_side.name == peripheral_name) then
        return true
    end

    -- Check if attached on other side.
    local item_attached_on_non_target_side = getEquippedNonTargetSide()
    if (item_attached_on_non_target_side and item_attached_on_non_target_side.name == peripheral_name) then

        -- detach item from incorrect side and reattach to correct side.

        local empty_slot = M.find_empty_slot()

        if (not empty_slot) then
            return false, "No empty slot found."
        end

        turtle.select(empty_slot)

        -- detach incorrect side.
        result, error_msg = equipNonTargetSide()

        if (not result) then
            return result, error_msg
        end

        -- attach to correct side.
        result, error_msg = equipTargetSide()

        if (not result) then
            return result, error_msg
        end

        -- reattach other peripheral to correct side.
        result, error_msg = equipNonTargetSide()

        if (not result) then
            return result, error_msg
        end

        return true

    end

    -- Find peripheral and attach if possible.
    local slot_with_peripheral = M.find_item(peripheral_name)

    if (not slot_with_peripheral) then
        return false, "Target peripheral not in inventory"
    end

    turtle.select(slot_with_peripheral)

    result, error_msg = equipTargetSide()

    if (not result) then
        return result, error_msg
    end

    return true

end

M.local_valid_fuel_items = {
    'minecraft:coal',
    'minecraft:charcoal',
    'minecraft:coal_block',
    'minecraft:charcoal_block',
}

function M.count_item(item_name)
    -- Count total number of a specific item across all inventory slots.
    --
    -- Args:
    --     item_name: String, full item name to count
    --
    -- Returns:
    --     count: Number, total count across all slots
    --
    -- Example:
    --     local cobble_count = inv.count_item("minecraft:cobblestone")
    
    assert(type(item_name) == "string", "item_name must be a string")
    
    local total = 0
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == item_name then
            total = total + item.count
        end
    end
    
    return total
end

function M.get_empty_slots()
    -- Count number of empty slots in turtle's inventory.
    --
    -- Returns:
    --     count: Number of empty slots (0-16)
    --
    -- Example:
    --     local empty = inv.get_empty_slots()
    --     if empty < 3 then
    --         print("Inventory almost full!")
    --     end
    
    local empty = 0
    for slot = 1, 16 do
        if not turtle.getItemDetail(slot) then
            empty = empty + 1
        end
    end
    
    return empty
end

function M.refuel(force)
    -- Refuel the turtle.
    -- Force is optional and defaults to true.
    -- Returns: Boolean depending on success.

    if force == nil then
        force = true
    end

    if not force and turtle.getFuelLevel() > 0 then
        return true
    end

    local current_slot = turtle.getSelectedSlot()
    for _, item in ipairs(M.local_valid_fuel_items) do
        local slot = M.find_item(item)
        if (slot) then
            turtle.select(slot)
            return turtle.refuel()
        end
    end
    turtle.select(current_slot)
    return false, "No valid fuel items found."
end

return M