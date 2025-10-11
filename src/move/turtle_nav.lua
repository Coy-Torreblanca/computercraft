--[[
Turtle navigation module for GPS-based location tracking and directional movement.

This module provides high-level navigation functions for ComputerCraft turtles,
including GPS location caching, direction finding, and movement with coordinate tracking.

Supports both cardinal directions (north, south, east, west) and coordinate-based
directions (towards_x, away_x, towards_z, away_z).
]]

local inv = require('/repo/src/turtle/inv')

M = {}

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

    inv.refuel()

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
        m.turn_left()
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

function M.move_forward()
    -- Move the turtle forward one block and update cached location.
    --
    -- Returns:
    --     success: Boolean, true if move succeeded
    --     location: Table with {x, y, z} if succeeded, nil if failed

    inv.refuel()

    if turtle.getFuelLevel() == 0 then
        error("[FIND_FACING] No fuel")
    end

    local current_direction = M.find_facing()

    if current_direction == nil then
        error("[MOVE_FORWARD] Failed to find facing")
    end

    if not turtle.forward() then
        return false, nil
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

    return true, M.current_location
end

function M.move_back()
    -- Move the turtle backward one block and update cached location.
    --
    -- Returns:
    --     success: Boolean, true if move succeeded
    --     location: Table with {x, y, z} if succeeded, nil if failed

    inv.refuel()

    if turtle.getFuelLevel() == 0 then
        error("[FIND_FACING] No fuel")
    end

    local current_direction = M.find_facing()

    if current_direction == nil then
        error("[MOVE_BACK] Failed to find facing")
    end

    if not turtle.back() then
        return false, nil
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

    return true, M.current_location
end

function M.move_up()
    -- Move the turtle up one block and update cached location.
    --
    -- Returns:
    --     success: Boolean, true if move succeeded
    --     location: Table with {x, y, z} if succeeded, nil if failed

    inv.refuel()

    if turtle.getFuelLevel() == 0 then
        error("[FIND_FACING] No fuel")
    end

    M.get_current_location()


    if not turtle.up() then
        return false, nil
    end


    if not M.current_location then
        error("[MOVE_UP] Failed to get current location")
    end

    M.current_location.y = M.current_location.y + 1


    return true, M.current_location
end

function M.move_down()
    -- Move the turtle down one block and update cached location.
    --
    -- Returns:
    --     success: Boolean, true if move succeeded
    --     location: Table with {x, y, z} if succeeded, nil if failed

    inv.refuel()

    if turtle.getFuelLevel() == 0 then
        error("[FIND_FACING] No fuel")
    end

    M.get_current_location()

    if not turtle.down() then
        return false, nil
    end

    if not M.current_location then
        error("[MOVE_DOWN] Failed to get current location")
    end

    M.current_location.y = M.current_location.y - 1
    return true, M.current_location
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
    -- Turn the turtle to face a specific direction.
    --
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
    
    while M.find_facing() ~= canonical_direction do
        if not M.turn_right() then
            return false
        end
    end

    return true
end

function M.move_direction(direction)
    -- Turn to face a direction and move forward one block.
    --
    -- Convenience function that combines turn_direction() and move_forward().
    -- Accepts both cardinal and coordinate-based direction names.
    --
    -- Args:
    --     direction: Target direction string (cardinal or coordinate style)
    --
    -- Returns:
    --     success: Boolean, true if both turn and move succeeded
    --     location: Table with {x, y, z} if succeeded, nil if failed
    --
    -- Raises:
    --     error: If direction is invalid
    assert(VALID_DIRECTIONS[direction], "Invalid direction: " .. tostring(direction) .. ". Must be north, south, east, west, towards_x, away_x, towards_z, or away_z")

    if not M.turn_direction(direction) then
        return false, nil
    end

    local success, location = M.move_forward()
    if not success then
        return false, nil
    end

    return true, location

end

function M.goto_location(x, y, z)
    -- Navigate turtle to target location using simple axis-by-axis pathfinding.
    --
    -- Algorithm: Try to move along each axis (x, y, z) in sequence. If blocked on one
    -- axis, try another. If blocked on all axes that still need movement, fail.
    --
    -- Args:
    --     x: Target X coordinate
    --     y: Target Y coordinate  
    --     z: Target Z coordinate
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
                return M.move_direction("towards_x")
            elseif delta.x < 0 then
                return M.move_direction("away_x")
            end
        elseif axis == "z" then
            if delta.z > 0 then
                return M.move_direction("towards_z")
            elseif delta.z < 0 then
                return M.move_direction("away_z")
            end
        elseif axis == "y" then
            if delta.y > 0 then
                return M.move_up()
            elseif delta.y < 0 then
                return M.move_down()
            end
        end
        
        -- No movement needed on this axis
        return false, nil
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
            print("[GOTO_LOCATION] Blocked on all axes. Current: (" .. 
                  M.current_location.x .. "," .. M.current_location.y .. "," .. M.current_location.z .. 
                  ") Target: (" .. target.x .. "," .. target.y .. "," .. target.z .. ")")
            return false, M.current_location
        end
    end
    
    -- Hit iteration limit (should never happen in normal operation)
    error("[GOTO_LOCATION] Exceeded maximum iterations. Possible infinite loop.")
end

return M