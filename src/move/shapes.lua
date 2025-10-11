--[[
Shape movement module for executing functions across geometric areas.

Provides functions to move turtles through shapes (rectangles, cubes, etc.)
and execute custom functions at each position.
]]

local turtle_nav = require('/repo/src/move/turtle_nav')

local M = {}

function M.rectangle(corner1, corner2, func, force)
    -- Move through each position in a rectangular volume and execute a function.
    --
    -- Uses efficient serpentine (zigzag) pattern to minimize turns and travel time.
    -- Moves layer by layer (Y axis), then row by row, alternating direction each row.
    --
    -- Args:
    --     corner1: Table with {x, y, z} for first corner
    --     corner2: Table with {x, y, z} for opposite corner
    --     func: Function to execute at each position. Receives (x, y, z, turtle_nav) as args.
    --           Should return true to continue, false to abort early.
    --     force: Optional boolean, if true will dig through obstacles during navigation
    --
    -- Returns:
    --     success: Boolean, true if completed all positions
    --     positions_visited: Number of positions successfully visited
    --     total_positions: Total number of positions in the rectangle
    --
    -- Example:
    --     local corner1 = {x = 0, y = 64, z = 0}
    --     local corner2 = {x = 10, y = 70, z = 10}
    --     
    --     local function dig_block(x, y, z, nav)
    --         turtle.digDown()
    --         return true  -- continue
    --     end
    --     
    --     shapes.rectangle(corner1, corner2, dig_block, true)  -- Force dig through obstacles
    
    assert(corner1 and corner1.x and corner1.y and corner1.z, "corner1 must have x, y, z coordinates")
    assert(corner2 and corner2.x and corner2.y and corner2.z, "corner2 must have x, y, z coordinates")
    assert(type(func) == "function", "func must be a function")
    
    -- Normalize coordinates to ensure min/max are correct
    local min_x = math.min(corner1.x, corner2.x)
    local max_x = math.max(corner1.x, corner2.x)
    local min_y = math.min(corner1.y, corner2.y)
    local max_y = math.max(corner1.y, corner2.y)
    local min_z = math.min(corner1.z, corner2.z)
    local max_z = math.max(corner1.z, corner2.z)
    
    local total_positions = (max_x - min_x + 1) * (max_y - min_y + 1) * (max_z - min_z + 1)
    local positions_visited = 0
    
    print("[RECTANGLE] Starting sweep of " .. total_positions .. " positions")
    print("[RECTANGLE] From (" .. min_x .. "," .. min_y .. "," .. min_z .. ")")
    print("[RECTANGLE]   to (" .. max_x .. "," .. max_y .. "," .. max_z .. ")")
    
    -- Iterate through each Y layer
    for y = min_y, max_y do
        print("[RECTANGLE] Layer Y=" .. y)
        
        -- Iterate through each Z row
        for z = min_z, max_z do
            local z_index = z - min_z
            local reverse = (z_index % 2) == 1  -- Alternate direction each row
            
            -- Determine X iteration direction for serpentine pattern
            local x_start, x_end, x_step
            if reverse then
                x_start, x_end, x_step = max_x, min_x, -1
            else
                x_start, x_end, x_step = min_x, max_x, 1
            end
            
            -- Iterate through each X position in this row
            for x = x_start, x_end, x_step do
                -- Move to position
                local success, location = turtle_nav.goto_location(x, y, z, force)
                
                if not success then
                    print("[RECTANGLE] Failed to reach position (" .. x .. "," .. y .. "," .. z .. ")")
                    print("[RECTANGLE] Visited " .. positions_visited .. "/" .. total_positions .. " positions")
                    return false, positions_visited, total_positions
                end
                
                -- Execute user function at this position
                local continue = func(x, y, z, turtle_nav)
                positions_visited = positions_visited + 1
                
                -- Check if function requested early abort
                if continue == false then
                    print("[RECTANGLE] Function requested abort at (" .. x .. "," .. y .. "," .. z .. ")")
                    print("[RECTANGLE] Visited " .. positions_visited .. "/" .. total_positions .. " positions")
                    return false, positions_visited, total_positions
                end
            end
        end
    end
    
    print("[RECTANGLE] Completed! Visited all " .. positions_visited .. " positions")
    return true, positions_visited, total_positions
end

function M.hollow_rectangle(corner1, corner2, func, force)
    -- Move through only the perimeter/edges of a rectangular volume.
    --
    -- Visits only the outer shell of the rectangle, skipping interior positions.
    -- Useful for building walls, frames, or scanning boundaries.
    --
    -- Args:
    --     corner1: Table with {x, y, z} for first corner
    --     corner2: Table with {x, y, z} for opposite corner
    --     func: Function to execute at each position. Receives (x, y, z, turtle_nav) as args.
    --     force: Optional boolean, if true will dig through obstacles during navigation
    --
    -- Returns:
    --     success: Boolean, true if completed all positions
    --     positions_visited: Number of positions successfully visited
    --     total_positions: Total number of edge positions
    
    assert(corner1 and corner1.x and corner1.y and corner1.z, "corner1 must have x, y, z coordinates")
    assert(corner2 and corner2.x and corner2.y and corner2.z, "corner2 must have x, y, z coordinates")
    assert(type(func) == "function", "func must be a function")
    
    local min_x = math.min(corner1.x, corner2.x)
    local max_x = math.max(corner1.x, corner2.x)
    local min_y = math.min(corner1.y, corner2.y)
    local max_y = math.max(corner1.y, corner2.y)
    local min_z = math.min(corner1.z, corner2.z)
    local max_z = math.max(corner1.z, corner2.z)
    
    local positions_visited = 0
    
    -- Helper to check if position is on edge
    local function is_edge(x, y, z)
        local on_x_edge = (x == min_x or x == max_x)
        local on_y_edge = (y == min_y or y == max_y)
        local on_z_edge = (z == min_z or z == max_z)
        
        -- Position is on edge if it's on any face
        return on_x_edge or on_y_edge or on_z_edge
    end
    
    print("[HOLLOW_RECTANGLE] Starting perimeter sweep")
    
    -- Iterate through all positions but only visit edges
    for y = min_y, max_y do
        for z = min_z, max_z do
            for x = min_x, max_x do
                if is_edge(x, y, z) then
                    local success, location = turtle_nav.goto_location(x, y, z, force)
                    
                    if not success then
                        print("[HOLLOW_RECTANGLE] Failed to reach (" .. x .. "," .. y .. "," .. z .. ")")
                        return false, positions_visited, nil
                    end
                    
                    local continue = func(x, y, z, turtle_nav)
                    positions_visited = positions_visited + 1
                    
                    if continue == false then
                        print("[HOLLOW_RECTANGLE] Aborted at (" .. x .. "," .. y .. "," .. z .. ")")
                        return false, positions_visited, nil
                    end
                end
            end
        end
    end
    
    print("[HOLLOW_RECTANGLE] Completed! Visited " .. positions_visited .. " edge positions")
    return true, positions_visited, positions_visited
end

function M.rectangle_sized(width, depth, height, func, direction_x, direction_z, direction_y, force)
    -- Move through a rectangle defined by size dimensions starting from current position.
    --
    -- More intuitive than specifying corners - just say how big and which direction.
    --
    -- Args:
    --     width: Size in X direction (blocks)
    --     depth: Size in Z direction (blocks)
    --     height: Size in Y direction (blocks, layers)
    --     func: Function to execute at each position
    --     direction_x: Optional, "positive" or "negative" (default: "positive")
    --     direction_z: Optional, "positive" or "negative" (default: "positive")
    --     direction_y: Optional, "positive" (up) or "negative" (down) (default: "positive")
    --     force: Optional boolean, if true will dig through obstacles (default: false)
    --
    -- Returns:
    --     success: Boolean, true if completed
    --     positions_visited: Number of positions visited
    --     total_positions: Total positions
    --
    -- Example:
    --     -- Mine 16x16 area, 3 layers DOWN, force dig through obstacles
    --     shapes.rectangle_sized(16, 16, 3, function(x, y, z, nav)
    --         turtle.digDown()
    --         return true
    --     end, "positive", "positive", "negative", true)
    
    direction_x = direction_x or "positive"
    direction_z = direction_z or "positive"
    direction_y = direction_y or "positive"
    force = force or false
    
    assert(width > 0, "width must be positive")
    assert(depth > 0, "depth must be positive")
    assert(height > 0, "height must be positive")
    assert(direction_x == "positive" or direction_x == "negative", "direction_x must be 'positive' or 'negative'")
    assert(direction_z == "positive" or direction_z == "negative", "direction_z must be 'positive' or 'negative'")
    assert(direction_y == "positive" or direction_y == "negative", "direction_y must be 'positive' or 'negative'")
    
    -- Get current position as starting corner
    local current = turtle_nav.get_current_location()
    local corner1 = {x = current.x, y = current.y, z = current.z}
    
    -- Calculate second corner based on size and direction
    local x_offset = (direction_x == "positive") and (width - 1) or -(width - 1)
    local z_offset = (direction_z == "positive") and (depth - 1) or -(depth - 1)
    local y_offset = (direction_y == "positive") and (height - 1) or -(height - 1)
    
    local corner2 = {
        x = corner1.x + x_offset,
        y = corner1.y + y_offset,
        z = corner1.z + z_offset
    }
    
    print("[RECTANGLE_SIZED] " .. width .. "x" .. depth .. "x" .. height .. 
          " (" .. direction_x .. " X, " .. direction_z .. " Z, " .. direction_y .. " Y)")
    
    return M.rectangle(corner1, corner2, func, force)
end

function M.rectangle_at(x, y, z, width, depth, height, func, direction_x, direction_z, direction_y, force)
    -- Move through a rectangle defined by size dimensions starting from specified position.
    --
    -- Like rectangle_sized but you specify the starting position instead of using current.
    --
    -- Args:
    --     x, y, z: Starting position coordinates
    --     width: Size in X direction (blocks)
    --     depth: Size in Z direction (blocks)
    --     height: Size in Y direction (blocks, layers)
    --     func: Function to execute at each position
    --     direction_x: Optional, "positive" or "negative" (default: "positive")
    --     direction_z: Optional, "positive" or "negative" (default: "positive")
    --     direction_y: Optional, "positive" (up) or "negative" (down) (default: "positive")
    --     force: Optional boolean, if true will dig through obstacles (default: false)
    --
    -- Returns:
    --     success: Boolean, true if completed
    --     positions_visited: Number of positions visited
    --     total_positions: Total positions
    --
    -- Example:
    --     -- Build a 10x10 structure at coordinates, DOWN 5 layers, force dig
    --     shapes.rectangle_at(100, 64, 200, 10, 10, 5, function(x, y, z, nav)
    --         turtle.placeDown()
    --         return true
    --     end, "positive", "positive", "negative", true)
    
    direction_x = direction_x or "positive"
    direction_z = direction_z or "positive"
    direction_y = direction_y or "positive"
    force = force or false
    
    assert(width > 0, "width must be positive")
    assert(depth > 0, "depth must be positive")
    assert(height > 0, "height must be positive")
    
    local corner1 = {x = x, y = y, z = z}
    
    local x_offset = (direction_x == "positive") and (width - 1) or -(width - 1)
    local z_offset = (direction_z == "positive") and (depth - 1) or -(depth - 1)
    local y_offset = (direction_y == "positive") and (height - 1) or -(height - 1)
    
    local corner2 = {
        x = corner1.x + x_offset,
        y = corner1.y + y_offset,
        z = corner1.z + z_offset
    }
    
    print("[RECTANGLE_AT] Starting at (" .. x .. "," .. y .. "," .. z .. ")")
    print("[RECTANGLE_AT] " .. width .. "x" .. depth .. "x" .. height .. 
          " (" .. direction_x .. " X, " .. direction_z .. " Z, " .. direction_y .. " Y)")
    
    return M.rectangle(corner1, corner2, func, force)
end

function M.hollow_rectangle_sized(width, depth, height, func, direction_x, direction_z, direction_y, force)
    -- Move through only the edges of a rectangle defined by size, starting from current position.
    --
    -- Args:
    --     width: Size in X direction (blocks)
    --     depth: Size in Z direction (blocks)
    --     height: Size in Y direction (blocks, layers)
    --     func: Function to execute at each position
    --     direction_x: Optional, "positive" or "negative" (default: "positive")
    --     direction_z: Optional, "positive" or "negative" (default: "positive")
    --     direction_y: Optional, "positive" (up) or "negative" (down) (default: "positive")
    --     force: Optional boolean, if true will dig through obstacles (default: false)
    --
    -- Returns:
    --     success: Boolean, true if completed
    --     positions_visited: Number of edge positions visited
    --     total_positions: Total edge positions
    --
    -- Example:
    --     -- Build walls around 20x20 area, 5 blocks tall, going UP, force dig
    --     shapes.hollow_rectangle_sized(20, 20, 5, function(x, y, z, nav)
    --         turtle.placeDown()
    --         return true
    --     end, "positive", "positive", "positive", true)
    
    direction_x = direction_x or "positive"
    direction_z = direction_z or "positive"
    direction_y = direction_y or "positive"
    force = force or false
    
    assert(width > 0, "width must be positive")
    assert(depth > 0, "depth must be positive")
    assert(height > 0, "height must be positive")
    
    local current = turtle_nav.get_current_location()
    local corner1 = {x = current.x, y = current.y, z = current.z}
    
    local x_offset = (direction_x == "positive") and (width - 1) or -(width - 1)
    local z_offset = (direction_z == "positive") and (depth - 1) or -(depth - 1)
    local y_offset = (direction_y == "positive") and (height - 1) or -(height - 1)
    
    local corner2 = {
        x = corner1.x + x_offset,
        y = corner1.y + y_offset,
        z = corner1.z + z_offset
    }
    
    print("[HOLLOW_RECTANGLE_SIZED] " .. width .. "x" .. depth .. "x" .. height .. 
          " (" .. direction_x .. " X, " .. direction_z .. " Z, " .. direction_y .. " Y)")
    
    return M.hollow_rectangle(corner1, corner2, func, force)
end

function M.hollow_rectangle_at(x, y, z, width, depth, height, func, direction_x, direction_z, direction_y, force)
    -- Move through only the edges of a rectangle, starting from specified position.
    --
    -- Args:
    --     x, y, z: Starting position coordinates
    --     width: Size in X direction (blocks)
    --     depth: Size in Z direction (blocks)
    --     height: Size in Y direction (blocks, layers)
    --     func: Function to execute at each position
    --     direction_x: Optional, "positive" or "negative" (default: "positive")
    --     direction_z: Optional, "positive" or "negative" (default: "positive")
    --     direction_y: Optional, "positive" (up) or "negative" (down) (default: "positive")
    --     force: Optional boolean, if true will dig through obstacles (default: false)
    --
    -- Returns:
    --     success: Boolean, true if completed
    --     positions_visited: Number of edge positions visited
    --     total_positions: Total edge positions
    --
    -- Example:
    --     -- Build hollow structure at coordinates, going DOWN 10 layers, force dig
    --     shapes.hollow_rectangle_at(0, 64, 0, 15, 15, 10, function(x, y, z, nav)
    --         turtle.place()  -- Place wall blocks
    --         return true
    --     end, "positive", "positive", "negative", true)
    
    direction_x = direction_x or "positive"
    direction_z = direction_z or "positive"
    direction_y = direction_y or "positive"
    force = force or false
    
    assert(width > 0, "width must be positive")
    assert(depth > 0, "depth must be positive")
    assert(height > 0, "height must be positive")
    
    local corner1 = {x = x, y = y, z = z}
    
    local x_offset = (direction_x == "positive") and (width - 1) or -(width - 1)
    local z_offset = (direction_z == "positive") and (depth - 1) or -(depth - 1)
    local y_offset = (direction_y == "positive") and (height - 1) or -(height - 1)
    
    local corner2 = {
        x = corner1.x + x_offset,
        y = corner1.y + y_offset,
        z = corner1.z + z_offset
    }
    
    print("[HOLLOW_RECTANGLE_AT] Starting at (" .. x .. "," .. y .. "," .. z .. ")")
    print("[HOLLOW_RECTANGLE_AT] " .. width .. "x" .. depth .. "x" .. height .. 
          " (" .. direction_x .. " X, " .. direction_z .. " Z, " .. direction_y .. " Y)")
    
    return M.hollow_rectangle(corner1, corner2, func, force)
end

return M

