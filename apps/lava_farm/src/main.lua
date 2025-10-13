--[[
Lava Farm Automation System

Automates the collection of lava from cauldrons using iron buckets.
The turtle moves through a rectangular grid of cauldrons, attempts to fill
iron buckets with lava, and deposits full lava buckets into a chest system.

Architecture:
  1. Fetch iron buckets from chest via modem
  2. Navigate to cauldron grid starting position
  3. Traverse all cauldrons in a serpentine pattern
  4. At each cauldron: place iron bucket above (turtle.placeUp)
  5. If successful, iron bucket is replaced with lava bucket in inventory
  6. If unsuccessful (cauldron empty/not full), simply continue to next position
  7. Deposit all lava buckets into output chest
  8. Wait for cauldrons to refill, then repeat

Dependencies:
  - turtle/inv: Inventory management and refueling
  - chest/chest: Remote chest access via modem
  - move/shapes: Geometric traversal patterns
  - move/turtle_nav: GPS-based navigation system

Configuration:
  Set coordinates for chest modems and cauldron area boundaries in config table.
]]

local inv = require('/repo/src/turtle/inv')
local chest = require('/repo/src/chest/chest')
local move_shapes = require('/repo/src/move/shapes')
local turtle_nav = require('/repo/src/move/turtle_nav')


-- Configuration for lava farm operation
-- All coordinates are absolute GPS coordinates
local config = {
    -- Position next to modem connecting chest with iron bucket supply (turtle should be adjacent to modem)
    iron_bucket_modem = {x = 16509, y = 154, z = 15786},
    
    -- Position next to modem connecting chest for depositing filled lava buckets
    lava_bucket_modem = {x = 16509, y = 154, z = 15784},
    
    -- Rectangular area containing cauldrons (turtle will be UNDER cauldrons)
    -- Cauldrons should be 1 block above these coordinates
    cauldron_area = {
        corner_start = {x = 16510, y = 154, z = 15786},
        corner_end = {x = 16513, y = 154, z = 15783}
    },
    
    -- Time to wait between collection cycles (in seconds)
    -- Default: 1200 seconds = 20 minutes (cauldron refill time in Minecraft)
    refill_wait_time = 1200,
    
    -- Number of iron buckets to request per trip
    bucket_batch_size = 16
}

--- Retrieves iron buckets from the supply chest
-- Navigates to the iron bucket chest and requests a batch of empty buckets.
-- Uses config.iron_bucket_modem for location and config.bucket_batch_size for quantity.
--
-- Raises:
--     error: If no iron buckets are available in the chest
local function get_iron_buckets()
    local coords = config.iron_bucket_modem
    turtle_nav.goto_location(coords.x, coords.y, coords.z)
    local result, count = chest.get_item("minecraft:bucket", config.bucket_batch_size)
    if count == 0 then
        error("No iron buckets found in supply chest")
    end
end

--- Deposits all lava buckets into the output chest
-- Navigates to the lava bucket chest and deposits all filled buckets from inventory.
-- Uses config.lava_bucket_modem for location.
local function deposit_lava_buckets()
    local coords = config.lava_bucket_modem
    turtle_nav.goto_location(coords.x, coords.y, coords.z)
    chest.deposit_item("minecraft:lava_bucket")
end

--- Attempts to collect lava from a single cauldron
-- This function is called by shapes.rectangle() at each cauldron position.
-- Uses config.iron_bucket_modem and config.lava_bucket_modem for chest locations.
-- 
-- Process:
--   1. Check if we have iron buckets, if not: deposit lava buckets and get more iron buckets
--   2. Select iron bucket in inventory
--   3. Place bucket upward (turtle.placeUp) into cauldron
--   4. If successful, iron bucket is automatically replaced with lava bucket
--   5. If unsuccessful (cauldron not full), operation silently fails and we continue
--   6. Opportunistically refuel if fuel is low
--
-- Args:
--     x, y, z: Current position coordinates (provided by shapes.rectangle)
--     nav: turtle_nav module reference (provided by shapes.rectangle)
--
-- Returns:
--     true: Always returns true to continue traversing cauldrons
local function empty_cauldron(x, y, z, nav)
    local iron_bucket_slot = inv.find_item("minecraft:bucket")

    -- If out of iron buckets, deposit lava and resupply
    if iron_bucket_slot == nil then
        local start_position = turtle_nav.get_current_location()
        local starting_direction = turtle_nav.find_facing()
        deposit_lava_buckets()
        get_iron_buckets()
        
        local success, _ = turtle_nav.goto_location(start_position.x, start_position.y, start_position.z)
        if not success then
            error("Failed to return to position after resupplying buckets")
        end

        turtle_nav.turn_direction(starting_direction)
        
        iron_bucket_slot = inv.find_item("minecraft:bucket")
    end

    -- Attempt to fill bucket from cauldron above
    turtle.select(iron_bucket_slot)
    turtle.placeUp()  -- If successful, iron bucket becomes lava bucket in inventory
    
    -- Refuel with lava buckets if fuel is low
    inv.refuel(false)
    
    return true  -- Continue to next cauldron
end

--- Executes one complete lava collection cycle
-- Orchestrates the full workflow: get buckets -> traverse cauldrons -> deposit lava
-- Uses config.cauldron_area for grid boundaries and config chest locations.
--
-- Raises:
--     error: If unable to reach starting position or resupply buckets
local function routine()

    -- Navigate to first cauldron position
    local start_corner = config.cauldron_area.corner_start
    local success, _ = turtle_nav.goto_location(start_corner.x, start_corner.y, start_corner.z)
    if not success then
        error("Failed to reach cauldron grid starting position")
    end

    -- Traverse all cauldrons using serpentine pattern
    move_shapes.rectangle(
        config.cauldron_area.corner_start,
        config.cauldron_area.corner_end,
        empty_cauldron
    )

    -- Deposit all collected lava buckets
    deposit_lava_buckets()
end

--- Main control loop for lava farm automation
-- Continuously runs collection cycles with configurable wait time between cycles.
-- This function runs indefinitely until manually stopped or an error occurs.
-- Uses all values from config table.
local function main()
    print("Lava Farm Automation Starting...")
    print(string.format("Cauldron area: (%d,%d,%d) to (%d,%d,%d)",
        config.cauldron_area.corner_start.x,
        config.cauldron_area.corner_start.y,
        config.cauldron_area.corner_start.z,
        config.cauldron_area.corner_end.x,
        config.cauldron_area.corner_end.y,
        config.cauldron_area.corner_end.z
    ))
    print(string.format("Wait time between cycles: %d seconds\n", config.refill_wait_time))
    
    while true do
        print("Starting collection cycle...")
        routine()
        print(string.format("Cycle complete. Waiting %d seconds for cauldrons to refill...", config.refill_wait_time))
        sleep(config.refill_wait_time)
    end
end

-- Start the automation
main()