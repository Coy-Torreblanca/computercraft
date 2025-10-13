--[[
Turtle navigation module for GPS-based location tracking and directional movement.

This module provides high-level navigation functions for ComputerCraft turtles,
including GPS location caching, direction finding, and movement with coordinate tracking.

Supports both cardinal directions (north, south, east, west) and coordinate-based
directions (towards_x, away_x, towards_z, away_z).
]]

local inv = require('/repo/src/turtle/inv')

local M = {}

M.current_direction = nil
M.current_location = nil

local VALID_DIRECTIONS = {
    north = true, 
    south = true, 
    east = true, 
    west = true,
    towards_x = true,  -- east (x increases)
    away_x = true,     -- west (x decreases)
    towards_z = true,  -- south (z increases)
    away_z = true      -- north (z decreases)
}

local DIRECTION_ALIASES = {
    towards_x = "east",
    away_x = "west",
    towards_z = "south",
    away_z = "north"
}

local COORDINATE_STYLE = {
    east = "towards_x",
    west = "away_x",
    south = "towards_z",
    north = "away_z"
}

local function normalize_direction(direction)
    -- Convert coordinate-style directions to canonical cardinal directions.
    --
    -- Args:
    --     direction: String direction name (cardinal or coordinate style)
    --
    -- Returns:
    --     Canonical direction name (north, south, east, or west)
    return DIRECTION_ALIASES[direction] or direction
end

function M.reset_state()
    -- Force GPS refresh and clear all cached state.
    --
    -- Use this when external code moves the turtle or when state may be stale.
    -- Next call to get_current_location() or find_facing() will perform fresh GPS lookup.
    M.current_direction = nil
    M.current_location = nil
end

function M.get_current_location()
    -- Get the turtle's current GPS location.
    --
    -- Returns cached location if available, otherwise performs GPS lookup and caches result.
    --
    -- Returns:
    --     Table with keys {x, y, z} representing world coordinates.
    --
    -- Raises:
    --     error: If GPS signal is unavailable.
    if M.current_location then
        return M.current_location
    end
    local x, y, z = gps.locate()

    if not x or not y or not z then
        error("No GPS signal")
    end

    M.current_location = {x = x, y = y, z = z}
    return M.current_location
end

function M.find_facing()
    -- Determine which direction the turtle is facing using GPS.
    --
    -- Returns cached direction if available. Otherwise, moves forward one block,
    -- compares GPS coordinates, and moves back to determine facing direction.
    -- Will try all 4 directions if initially blocked.
    --
    -- Returns:
    --     String direction: "north", "south", "east", or "west"
    --
    -- Raises:
    --     error: If unable to move forward in any direction or unable to move back

    inv.refuel(false)

    if turtle.getFuelLevel() == 0 then
        error("[FIND_FACING] No fuel")
    end

    if M.current_direction then
        return M.current_direction
    end

    local loc1 = M.get_current_location()
    local x1, z1 = loc1.x, loc1.z

    local turn_count = 0
    local moved = turtle.forward()
    
    if not moved then
       for i = 1, 3 do
        turtle.turnRight()
        turn_count = turn_count + 1
        if turtle.forward() then
            moved = true
            break
        end
       end
       
       if not moved then
        -- reset to original direction
        for i = 1, turn_count do
            turtle.turnLeft()
        end
           error("[FIND_FACING] Failed to move forward after trying all directions")
       end
    end

    M.reset_state()
    local loc2 = M.get_current_location()
    local x2, z2 = loc2.x, loc2.z

    if not turtle.back() then
        error("[FIND_FACING] Failed to move back")
    end

    -- reset location after moving back.
    M.current_location= nil
    M.get_current_location()

    local direction = nil

    if x2 > x1 then direction = "east"
    elseif x2 < x1 then direction = "west"
    elseif z2 > z1 then direction = "south"
    elseif z2 < z1 then direction = "north"
    else error("[FIND_FACING] Failed to find facing") end

    M.current_direction = direction

    -- reset to original direction
    for i = 1, turn_count do
        M.turn_left()
    end


    return M.current_direction

end

function M.get_facing_coordinate_style()
    -- Get the turtle's facing direction in coordinate style.
    --
    -- Returns the direction using coordinate-based naming (towards_x, away_x, etc.)
    -- instead of cardinal directions.
    --
    -- Returns:
    --     String direction: "towards_x", "away_x", "towards_z", or "away_z"
    local canonical = M.find_facing()
    return COORDINATE_STYLE[canonical]
end

function M.move_forward(force)
    -- Move the turtle forward one block and update cached location.
    --
    -- Args:
    --     force: Optional boolean, if true will dig through obstacles
    --
    -- Returns:
    --     success: Boolean, true if move succeeded
    --     location: Table with {x, y, z} if succeeded, nil if failed
    --     message: String error message if failed, nil if succeeded

    inv.refuel(false)

    if turtle.getFuelLevel() == 0 then
        error("[MOVE_FORWARD] No fuel")
    end

    local current_direction = M.find_facing()

    if current_direction == nil then
        error("[MOVE_FORWARD] Failed to find facing")
    end

    -- Try to move, or force dig if enabled
    local result, message = turtle.forward()
    if not result then
        if force then
            turtle.dig() -- TODO account for gravel.
            sleep(0.5)  -- Wait for block to break
            
            local result, message = turtle.forward()
            if not result then
                return false, nil, message -- Still blocked (bedrock, entity, etc)
            end
        else
            return false, nil, message
        end
    end

    if current_direction == "east" then
        M.current_location.x = M.current_location.x + 1
    elseif current_direction == "west" then
        M.current_location.x = M.current_location.x - 1
    elseif current_direction == "south" then
        M.current_location.z = M.current_location.z + 1
    elseif current_direction == "north" then
        M.current_location.z = M.current_location.z - 1
    end

    return true, M.current_location, nil
end

function M.move_back(force)
    -- Move the turtle backward one block and update cached location.
    --
    -- Args:
    --     force: Optional boolean, if true will dig through obstacles behind
    --
    -- Returns:
    --     success: Boolean, true if move succeeded
    --     location: Table with {x, y, z} if succeeded, nil if failed
    --     message: String error message if failed, nil if succeeded

    inv.refuel(false)

    if turtle.getFuelLevel() == 0 then
        error("[MOVE_BACK] No fuel")
    end

    local current_direction = M.find_facing()

    if current_direction == nil then
        error("[MOVE_BACK] Failed to find facing")
    end

    -- Try to move back, or force dig behind if enabled
    local result, message = turtle.back()
    if not result then
        if force then
            -- Turn around, dig, move, turn back
            M.turn_right()
            M.turn_right()
            turtle.dig()
            sleep(0.5)
            M.turn_right()
            M.turn_right()
            
            result, message = turtle.back()
            if not result then
                return false, nil, message
            end
        else
            return false, nil, message
        end
    end

    if current_direction == "east" then
        M.current_location.x = M.current_location.x - 1
    elseif current_direction == "west" then
        M.current_location.x = M.current_location.x + 1
    elseif current_direction == "south" then
        M.current_location.z = M.current_location.z - 1
    elseif current_direction == "north" then
        M.current_location.z = M.current_location.z + 1
    end

    return true, M.current_location, nil
end

function M.move_up(force)
    -- Move the turtle up one block and update cached location.
    --
    -- Args:
    --     force: Optional boolean, if true will dig through obstacles above
    --
    -- Returns:
    --     success: Boolean, true if move succeeded
    --     location: Table with {x, y, z} if succeeded, nil if failed
    --     message: String error message if failed, nil if succeeded

    inv.refuel(false)

    if turtle.getFuelLevel() == 0 then
        error("[MOVE_UP] No fuel")
    end

    M.get_current_location()

    -- Try to move up, or force dig if enabled
    local result, message = turtle.up()
    if not result then
        if force then
            turtle.digUp()
            sleep(0.5)  -- Wait for block to break
            
            result, message = turtle.up()
            if not result then
                return false, nil, message  -- Still blocked
            end
        else
            return false, nil, message
        end
    end

    if not M.current_location then
        error("[MOVE_UP] Failed to get current location")
    end

    M.current_location.y = M.current_location.y + 1

    return true, M.current_location, nil
end

function M.move_down(force)
    -- Move the turtle down one block and update cached location.
    --
    -- Args:
    --     force: Optional boolean, if true will dig through obstacles below
    --
    -- Returns:
    --     success: Boolean, true if move succeeded
    --     location: Table with {x, y, z} if succeeded, nil if failed
    --     message: String error message if failed, nil if succeeded

    inv.refuel(false)

    if turtle.getFuelLevel() == 0 then
        error("[MOVE_DOWN] No fuel")
    end

    M.get_current_location()

    -- Try to move down, or force dig if enabled
    local result, message = turtle.down()
    if not result then
        if force then
            turtle.digDown()
            sleep(0.5)  -- Wait for block to break
            
            result, message = turtle.down()
            if not result then
                return false, nil, message  -- Still blocked
            end
        else
            return false, nil, message
        end
    end

    if not M.current_location then
        error("[MOVE_DOWN] Failed to get current location")
    end

    M.current_location.y = M.current_location.y - 1
    return true, M.current_location, nil
end

function M.turn_left()
    -- Turn the turtle 90 degrees to the left and update cached direction.
    --
    -- Returns:
    --     Boolean: true if turn succeeded, false otherwise
    local current_direction = M.find_facing()
    local target_direction

    if current_direction == "east" then
        target_direction = "north"
    elseif current_direction == "west" then
        target_direction = "south"
    elseif current_direction == "south" then
        target_direction = "east"
    elseif current_direction == "north" then
        target_direction = "west"
    end

    if not turtle.turnLeft() then
        return false
    end

    M.current_direction = target_direction

    return true
end

function M.turn_right()
    -- Turn the turtle 90 degrees to the right and update cached direction.
    --
    -- Returns:
    --     Boolean: true if turn succeeded, false otherwise
    local current_direction = M.find_facing()
    local target_direction

    if current_direction == "east" then
        target_direction = "south"
    elseif current_direction == "west" then
        target_direction = "north"
    elseif current_direction == "south" then
        target_direction = "west"
    elseif current_direction == "north" then
        target_direction = "east"
    end

    if not turtle.turnRight() then
        return false
    end

    M.current_direction = target_direction

    return true
end

function M.turn_direction(direction)
    -- Turn the turtle to face a specific direction using minimum turns.
    --
    -- Calculates whether turning left or right is shorter and uses that path.
    -- Accepts both cardinal (north, south, east, west) and coordinate-based
    -- (towards_x, away_x, towards_z, away_z) direction names.
    --
    -- Args:
    --     direction: Target direction string
    --
    -- Returns:
    --     Boolean: true if successfully turned to face direction, false if turn failed
    --
    -- Raises:
    --     error: If direction is invalid
    assert(VALID_DIRECTIONS[direction], "Invalid direction: " .. tostring(direction) .. ". Must be north, south, east, west, towards_x, away_x, towards_z, or away_z")
    
    local canonical_direction = normalize_direction(direction)
    local current_direction = M.find_facing()
    
    if current_direction == canonical_direction then
        return true
    end
    
    -- Map directions to numbers: north=0, east=1, south=2, west=3
    local direction_to_num = {north = 0, east = 1, south = 2, west = 3}
    local current_num = direction_to_num[current_direction]
    local target_num = direction_to_num[canonical_direction]
    
    -- Calculate turns needed for each direction
    local right_turns = (target_num - current_num) % 4
    local left_turns = (current_num - target_num) % 4
    
    -- Use whichever requires fewer turns
    if right_turns <= left_turns then
        for i = 1, right_turns do
            if not M.turn_right() then
                return false
            end
        end
    else
        for i = 1, left_turns do
            if not M.turn_left() then
                return false
            end
        end
    end

    return true
end

function M.move_direction(direction, force)
    -- Turn to face a direction and move forward one block.
    --
    -- Convenience function that combines turn_direction() and move_forward().
    -- Accepts both cardinal and coordinate-based direction names.
    --
    -- Args:
    --     direction: Target direction string (cardinal or coordinate style)
    --     force: Optional boolean, if true will dig through obstacles
    --
    -- Returns:
    --     success: Boolean, true if both turn and move succeeded
    --     location: Table with {x, y, z} if succeeded, nil if failed
    --     message: String error message if failed, nil if succeeded
    --
    -- Raises:
    --     error: If direction is invalid
    assert(VALID_DIRECTIONS[direction], "Invalid direction: " .. tostring(direction) .. ". Must be north, south, east, west, towards_x, away_x, towards_z, or away_z")

    if not M.turn_direction(direction) then
        return false, nil, "Failed to turn to direction"
    end

    local success, location, message = M.move_forward(force)
    if not success then
        return false, nil, message
    end

    return true, location, nil

end

function M.goto_location(x, y, z, force)
    -- Navigate turtle to target location using simple axis-by-axis pathfinding.
    --
    -- Algorithm: Try to move along each axis (x, y, z) in sequence. If blocked on one
    -- axis, try another. If blocked on all axes that still need movement, fail.
    --
    -- Args:
    --     x: Target X coordinate
    --     y: Target Y coordinate  
    --     z: Target Z coordinate
    --     force: Optional boolean, if true will dig through obstacles
    --
    -- Returns:
    --     success: Boolean, true if reached target location
    --     location: Current location table {x, y, z}
    M.get_current_location()
    local target = {x = x, y = y, z = z}
    
    local function get_delta()
        -- Calculate remaining distance on each axis
        return {
            x = target.x - M.current_location.x,
            y = target.y - M.current_location.y,
            z = target.z - M.current_location.z
        }
    end
    
    local function try_move_axis(axis)
        -- Attempt to move one block along the specified axis toward target
        local delta = get_delta()
        
        if axis == "x" then
            if delta.x > 0 then
                return M.move_direction("towards_x", force)
            elseif delta.x < 0 then
                return M.move_direction("away_x", force)
            end
        elseif axis == "z" then
            if delta.z > 0 then
                return M.move_direction("towards_z", force)
            elseif delta.z < 0 then
                return M.move_direction("away_z", force)
            end
        elseif axis == "y" then
            if delta.y > 0 then
                return M.move_up(force)
            elseif delta.y < 0 then
                return M.move_down(force)
            end
        end
        
        -- No movement needed on this axis
        return false, nil
    end
    
    -- Check if already at target before entering loop
    local initial_delta = get_delta()
    if initial_delta.x == 0 and initial_delta.y == 0 and initial_delta.z == 0 then
        return true, M.current_location
    end
    
    -- Navigate to target
    local max_iterations = 10000  -- Safety limit to prevent infinite loops
    local iterations = 0
    
    local axes = {"x", "y", "z"}
    while iterations < max_iterations do
        iterations = iterations + 1
        local delta = get_delta()
        
        -- Check if we've reached target
        if delta.x == 0 and delta.y == 0 and delta.z == 0 then
            return true, M.current_location
        end
        
        -- Try each axis that still needs movement
        local moved = false
        
        for _, axis in ipairs(axes) do
            local current_delta = get_delta()
            local needs_movement = (axis == "x" and current_delta.x ~= 0) or 
                                  (axis == "y" and current_delta.y ~= 0) or
                                  (axis == "z" and current_delta.z ~= 0)
            
            if needs_movement then
                local success, location = try_move_axis(axis)
                if success then
                    moved = true
                    break  -- Successfully moved, start next iteration
                end
            end
        end
        
        -- If we couldn't move on any axis, we're blocked
        if not moved then
            local current_delta = get_delta()
            print("[GOTO_LOCATION] Blocked on all axes.")
            print("  Current: (" .. M.current_location.x .. "," .. M.current_location.y .. "," .. M.current_location.z .. ")")
            print("  Target:  (" .. target.x .. "," .. target.y .. "," .. target.z .. ")")
            print("  Delta:   (" .. current_delta.x .. "," .. current_delta.y .. "," .. current_delta.z .. ")")
            return false, M.current_location
        end
    end
    
    -- Hit iteration limit (should never happen in normal operation)
    error("[GOTO_LOCATION] Exceeded maximum iterations. Possible infinite loop.")
end

function M.distance_between(pos1, pos2)
    -- Calculate the Manhattan distance (number of moves) between two positions.
    --
    -- Returns the total number of moves required to get from pos1 to pos2,
    -- assuming no obstructions. This is the sum of absolute differences on
    -- each axis (|dx| + |dy| + |dz|).
    --
    -- Args:
    --     pos1: Table with {x, y, z} for first position
    --     pos2: Table with {x, y, z} for second position
    --
    -- Returns:
    --     distance: Number, total moves required (minimum, no obstacles)
    --
    -- Example:
    --     local home = {x = 0, y = 64, z = 0}
    --     local mine = {x = 100, y = 50, z = 200}
    --     local moves = turtle_nav.distance_between(home, mine)
    --     print("Mining site is " .. moves .. " moves away")  -- Output: 314 moves
    
    assert(pos1 and pos1.x and pos1.y and pos1.z, "pos1 must have x, y, z coordinates")
    assert(pos2 and pos2.x and pos2.y and pos2.z, "pos2 must have x, y, z coordinates")
    
    local dx = math.abs(pos2.x - pos1.x)
    local dy = math.abs(pos2.y - pos1.y)
    local dz = math.abs(pos2.z - pos1.z)
    
    return dx + dy + dz
end

function M.distance_to(x, y, z)
    -- Calculate distance from current position to target coordinates.
    --
    -- Convenience wrapper around distance_between using current location.
    --
    -- Args:
    --     x: Target X coordinate
    --     y: Target Y coordinate
    --     z: Target Z coordinate
    --
    -- Returns:
    --     distance: Number, total moves required from current position
    --
    -- Example:
    --     local moves = turtle_nav.distance_to(100, 64, 200)
    --     print("Destination is " .. moves .. " moves away")
    --     
    --     if moves > turtle.getFuelLevel() then
    --         print("Not enough fuel!")
    --     end
    
    local current = M.get_current_location()
    return M.distance_between(current, {x = x, y = y, z = z})
end

function M.look_for_block(block_name)
    -- Scan all six directions looking for a specific block.
    --
    -- Checks all four cardinal directions (north, south, east, west), then up, then down.
    -- Rotates the turtle to inspect each direction, then returns to original facing.
    --
    -- Args:
    --     block_name: String, full block name to search for (e.g. "minecraft:chest", "minecraft:lava")
    --
    -- Returns:
    --     found: Boolean, true if block was found in any direction
    --     direction: String or nil, direction where block was found
    --                - Cardinal: "north", "south", "east", "west"
    --                - Vertical: "up", "down"
    --                - Returns nil if not found
    --
    -- Example:
    --     local found, direction = turtle_nav.look_for_block("minecraft:lava")
    --     if found then
    --         print("Found lava to the " .. direction)
    --         if direction == "up" or direction == "down" then
    --             print("Block is vertical")
    --         else
    --             turtle_nav.turn_direction(direction)  -- Face the block
    --         end
    --     end
    
    -- Save starting direction to restore later
    local starting_direction = M.find_facing()
    
    -- Check all 4 cardinal directions (horizontal)
    for i = 1, 4 do
        -- Inspect block in front of turtle
        local has_block, block_data = turtle.inspect()
        
        if has_block and block_data.name == block_name then
            -- Found the target block!
            local direction_block_found = M.find_facing()
            
            -- Return to original facing direction
            M.turn_direction(starting_direction)
            
            -- Return success and the direction where block was found
            return true, direction_block_found
        end
        
        -- Turn right to check next direction
        M.turn_right()
    end
    
    -- Check above
    local has_block_up, block_data_up = turtle.inspectUp()
    if has_block_up and block_data_up.name == block_name then
        -- Return to original facing direction
        M.turn_direction(starting_direction)
        return true, "up"
    end
    
    -- Check below
    local has_block_down, block_data_down = turtle.inspectDown()
    if has_block_down and block_data_down.name == block_name then
        -- Return to original facing direction  
        M.turn_direction(starting_direction)
        return true, "down"
    end
    
    -- Block not found in any direction, return to starting direction
    M.turn_direction(starting_direction)
    
    return false, nil
end

return M