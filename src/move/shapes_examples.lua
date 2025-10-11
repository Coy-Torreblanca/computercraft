--[[
Practical examples of using the shapes module for common tasks.

These are ready-to-use functions for mining, building, farming, and more.
]]

local shapes = require('/repo/src/move/shapes')
local turtle_nav = require('/repo/src/move/turtle_nav')

local M = {}

function M.mine_area_sized(width, depth, height)
    -- Mine a rectangular area by size, starting from current position.
    --
    -- Simple wrapper - just specify how big you want to mine.
    --
    -- Args:
    --     width: Blocks in X direction (default: 16)
    --     depth: Blocks in Z direction (default: 16)
    --     height: Layers in Y direction (default: 1)
    --
    -- Returns:
    --     success: Boolean, true if completed
    --     blocks_mined: Number of blocks successfully mined
    --
    -- Example:
    --     mine_area_sized(16, 16, 3)  -- Mine 16x16 area, 3 layers deep
    
    width = width or 16
    depth = depth or 16
    height = height or 1
    
    local blocks_mined = 0
    
    local function mine_block(x, y, z, nav)
        if turtle.digDown() then
            blocks_mined = blocks_mined + 1
        end
        turtle.digUp()  -- Also clear above
        return true
    end
    
    print("[MINE_AREA_SIZED] Mining " .. width .. "x" .. depth .. "x" .. height .. " area...")
    local success, visited, total = shapes.rectangle_sized(width, depth, height, mine_block)
    
    print("[MINE_AREA_SIZED] Mined " .. blocks_mined .. " blocks")
    return success, blocks_mined
end

function M.mine_area(corner1, corner2)
    -- Mine out an entire rectangular area using corner coordinates (advanced).
    --
    -- For simpler usage, see mine_area_sized() instead.
    --
    -- Args:
    --     corner1: First corner {x, y, z}
    --     corner2: Opposite corner {x, y, z}
    --
    -- Returns:
    --     success: Boolean, true if completed
    --     blocks_mined: Number of blocks successfully mined
    
    local blocks_mined = 0
    
    local function mine_block(x, y, z, nav)
        if turtle.digDown() then
            blocks_mined = blocks_mined + 1
        end
        turtle.digUp()
        return true
    end
    
    print("[MINE_AREA] Starting mining operation...")
    local success, visited, total = shapes.rectangle(corner1, corner2, mine_block)
    
    print("[MINE_AREA] Mined " .. blocks_mined .. " blocks across " .. visited .. " positions")
    return success, blocks_mined
end

function M.build_floor_sized(width, depth, block_slot)
    -- Build a floor by size, starting from current position.
    --
    -- Args:
    --     width: Blocks in X direction (default: 10)
    --     depth: Blocks in Z direction (default: 10)
    --     block_slot: Inventory slot with building blocks (default: 1)
    --
    -- Returns:
    --     success: Boolean, true if completed
    --     blocks_placed: Number of blocks placed
    --
    -- Example:
    --     build_floor_sized(20, 20, 1)  -- Build 20x20 floor using slot 1
    
    width = width or 10
    depth = depth or 10
    block_slot = block_slot or 1
    
    local blocks_placed = 0
    turtle.select(block_slot)
    
    local function place_block(x, y, z, nav)
        if turtle.placeDown() then
            blocks_placed = blocks_placed + 1
        end
        
        if turtle.getFuelLevel() < 100 then
            local inv = require('/repo/src/turtle/inv')
            inv.refuel(false)
        end
        
        return true
    end
    
    print("[BUILD_FLOOR_SIZED] Building " .. width .. "x" .. depth .. " floor...")
    local success, visited, total = shapes.rectangle_sized(width, depth, 1, place_block)
    
    print("[BUILD_FLOOR_SIZED] Placed " .. blocks_placed .. " blocks")
    return success, blocks_placed
end

function M.build_floor(corner1, corner2, block_slot)
    -- Place blocks below the turtle to build a floor using corner coordinates (advanced).
    --
    -- For simpler usage, see build_floor_sized() instead.
    --
    -- Args:
    --     corner1: First corner {x, y, z}
    --     corner2: Opposite corner {x, y, z}
    --     block_slot: Inventory slot number containing building blocks
    --
    -- Returns:
    --     success: Boolean, true if completed
    --     blocks_placed: Number of blocks successfully placed
    
    local blocks_placed = 0
    turtle.select(block_slot)
    
    local function place_block(x, y, z, nav)
        if turtle.placeDown() then
            blocks_placed = blocks_placed + 1
        end
        
        if turtle.getFuelLevel() < 100 then
            local inv = require('/repo/src/turtle/inv')
            inv.refuel(false)
        end
        
        return true
    end
    
    print("[BUILD_FLOOR] Starting floor construction...")
    local success, visited, total = shapes.rectangle(corner1, corner2, place_block)
    
    print("[BUILD_FLOOR] Placed " .. blocks_placed .. " blocks")
    return success, blocks_placed
end

function M.build_walls_sized(width, depth, height, block_slot)
    -- Build walls by size, starting from current position.
    --
    -- Creates hollow structure (walls only, no interior).
    --
    -- Args:
    --     width: Blocks in X direction (default: 10)
    --     depth: Blocks in Z direction (default: 10)
    --     height: Layers tall (default: 5)
    --     block_slot: Inventory slot with blocks (default: 1)
    --
    -- Returns:
    --     success: Boolean, true if completed
    --     blocks_placed: Number of blocks placed
    --
    -- Example:
    --     build_walls_sized(20, 20, 10, 1)  -- Build 20x20 walls, 10 blocks tall
    
    width = width or 10
    depth = depth or 10
    height = height or 5
    block_slot = block_slot or 1
    
    local blocks_placed = 0
    turtle.select(block_slot)
    
    local function place_block(x, y, z, nav)
        if turtle.placeDown() then
            blocks_placed = blocks_placed + 1
        end
        return true
    end
    
    print("[BUILD_WALLS_SIZED] Building " .. width .. "x" .. depth .. "x" .. height .. " walls...")
    local success, visited = shapes.hollow_rectangle_sized(width, depth, height, place_block)
    
    print("[BUILD_WALLS_SIZED] Placed " .. blocks_placed .. " blocks")
    return success, blocks_placed
end

function M.build_walls(corner1, corner2, block_slot)
    -- Build walls around the perimeter using corner coordinates (advanced).
    --
    -- For simpler usage, see build_walls_sized() instead.
    --
    -- Args:
    --     corner1: First corner {x, y, z}
    --     corner2: Opposite corner {x, y, z}
    --     block_slot: Inventory slot number containing building blocks
    --
    -- Returns:
    --     success: Boolean, true if completed
    --     blocks_placed: Number of blocks placed
    
    local blocks_placed = 0
    turtle.select(block_slot)
    
    local function place_block(x, y, z, nav)
        if turtle.placeDown() then
            blocks_placed = blocks_placed + 1
        end
        return true
    end
    
    print("[BUILD_WALLS] Starting wall construction...")
    local success, visited = shapes.hollow_rectangle(corner1, corner2, place_block)
    
    print("[BUILD_WALLS] Placed " .. blocks_placed .. " blocks")
    return success, blocks_placed
end

function M.scan_area(corner1, corner2)
    -- Scan an area and detect all blocks, creating a 3D map.
    --
    -- Returns a table of all non-air blocks found in the area.
    --
    -- Args:
    --     corner1: First corner {x, y, z}
    --     corner2: Opposite corner {x, y, z}
    --
    -- Returns:
    --     blocks: Table of detected blocks with positions and types
    
    local blocks = {}
    
    local function scan_block(x, y, z, nav)
        local has_block_down, data_down = turtle.inspectDown()
        local has_block_up, data_up = turtle.inspectUp()
        
        if has_block_down then
            table.insert(blocks, {
                x = x,
                y = y - 1,
                z = z,
                name = data_down.name,
                tags = data_down.tags
            })
        end
        
        if has_block_up then
            table.insert(blocks, {
                x = x,
                y = y + 1,
                z = z,
                name = data_up.name,
                tags = data_up.tags
            })
        end
        
        return true
    end
    
    print("[SCAN_AREA] Starting area scan...")
    shapes.rectangle(corner1, corner2, scan_block)
    
    print("[SCAN_AREA] Found " .. #blocks .. " blocks")
    return blocks
end

function M.harvest_crops(corner1, corner2)
    -- Harvest crops in a rectangular farm area.
    --
    -- Digs down at each position (harvesting crops) and replants seeds if available.
    --
    -- Args:
    --     corner1: First corner {x, y, z}
    --     corner2: Opposite corner {x, y, z}
    --
    -- Returns:
    --     success: Boolean, true if completed
    --     harvested: Number of blocks harvested
    
    local harvested = 0
    
    local function harvest_block(x, y, z, nav)
        local has_block, data = turtle.inspectDown()
        
        -- Check if it's a crop (you can customize this list)
        if has_block and (
            string.find(data.name, "wheat") or
            string.find(data.name, "carrot") or
            string.find(data.name, "potato") or
            string.find(data.name, "beetroot")
        ) then
            if turtle.digDown() then
                harvested = harvested + 1
                -- Try to replant if we have seeds
                turtle.placeDown()
            end
        end
        
        return true
    end
    
    print("[HARVEST_CROPS] Starting harvest...")
    local success, visited, total = shapes.rectangle(corner1, corner2, harvest_block)
    
    print("[HARVEST_CROPS] Harvested " .. harvested .. " crops")
    return success, harvested
end

function M.light_area(corner1, corner2, torch_slot, spacing)
    -- Place torches in a grid pattern across an area for lighting.
    --
    -- Args:
    --     corner1: First corner {x, y, z}
    --     corner2: Opposite corner {x, y, z}
    --     torch_slot: Inventory slot containing torches
    --     spacing: Number of blocks between torches (default 8)
    --
    -- Returns:
    --     success: Boolean, true if completed
    --     torches_placed: Number of torches placed
    
    spacing = spacing or 8
    local torches_placed = 0
    turtle.select(torch_slot)
    
    local min_x = math.min(corner1.x, corner2.x)
    local min_z = math.min(corner1.z, corner2.z)
    
    local function place_torch(x, y, z, nav)
        -- Calculate if this position should have a torch
        local x_offset = (x - min_x) % spacing
        local z_offset = (z - min_z) % spacing
        
        if x_offset == 0 and z_offset == 0 then
            if turtle.placeDown() then
                torches_placed = torches_placed + 1
                print("  Placed torch at (" .. x .. "," .. y .. "," .. z .. ")")
            end
        end
        
        return true
    end
    
    print("[LIGHT_AREA] Placing torches with " .. spacing .. " block spacing...")
    local success, visited, total = shapes.rectangle(corner1, corner2, place_torch)
    
    print("[LIGHT_AREA] Placed " .. torches_placed .. " torches")
    return success, torches_placed
end

return M

