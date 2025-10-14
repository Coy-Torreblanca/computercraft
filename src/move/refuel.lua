local inv = require('/repo/src/turtle/inv')
local turtle_nav = require('/repo/src/turtle/move/turtle_nav')
local chest = require('/repo/src/chest/chest')

local M = {}

function M.refuel_at_station(refuel_station_coordinates, station_refuel_amount, min_fuel_for_task, force_move)
    -- Refuel turtle at a designated refuel station with configurable requirements.
    --
    -- Smart refueling with safety-first logic:
    -- 1. First tries to refuel from items already in inventory
    -- 2. Calculates fuel requirements:
    --    a) Roundtrip cost: Distance to station and back
    --    b) Task requirement: Minimum fuel needed after returning from station
    -- 3. Checks if current fuel meets BOTH conditions (made explicit):
    --    - Has enough fuel to get to station AND back
    --    - Will have enough fuel for task AFTER accounting for station trip
    -- 4. If both conditions met, returns early without traveling
    -- 5. Otherwise, navigates to refuel station
    -- 6. Retrieves fuel from chest and refuels to station_refuel_amount
    -- 7. Tries multiple fuel types (coal, charcoal, coal blocks, lava buckets)
    --
    -- This ensures turtle never gets stranded and has enough fuel for its task.
    --
    -- Args:
    --     refuel_station_coordinates: Table with {x, y, z} of chest location with fuel
    --     station_refuel_amount: Number, fuel level to reach when at the station
    --     min_fuel_for_task: Number, optional minimum fuel needed for task after station trip (defaults to 0)
    --     force_move: Boolean, if true will dig through obstacles during navigation
    --
    -- Returns:
    --     success: Boolean, true if has sufficient fuel or reached target level
    --     message: String, status message or error description
    --
    -- Example:
    --     local fuel_station = {x = 100, y = 64, z = 200}
    --     
    --     -- Example 1: Refuel to 10,000 when at station, need 5,000 for task
    --     local success, msg = refuel.refuel_at_station(fuel_station, 10000, 5000, true)
    --     if success then
    --         print("Ready: " .. msg)
    --     end
    --     
    --     -- Example 2: Just ensure round-trip capability (no task requirement)
    --     local success, msg = refuel.refuel_at_station(fuel_station, 10000, nil, true)

    -- Try to refuel from inventory first
    inv.refuel(true)

    -- Default task requirement to 0 (no task, just ensure roundtrip)
    if min_fuel_for_task == nil then
        min_fuel_for_task = 0
    end

    -- Calculate distances and fuel needs
    local distance_to_station = turtle_nav.distance_to(
        refuel_station_coordinates.x,
        refuel_station_coordinates.y,
        refuel_station_coordinates.z
    )
    local roundtrip_fuel_cost = distance_to_station * 2
    local current_fuel = turtle.getFuelLevel()
    
    -- Fuel we'd have after making the trip to station and back
    local fuel_after_station_trip = current_fuel - roundtrip_fuel_cost
    
    -- Check both conditions explicitly
    local has_roundtrip_fuel = current_fuel >= roundtrip_fuel_cost
    local has_task_fuel_after_trip = fuel_after_station_trip >= min_fuel_for_task
    
    if has_roundtrip_fuel and has_task_fuel_after_trip then
        return true, string.format(
            "Fuel sufficient (current: %d, after station trip: %d, task needs: %d)",
            current_fuel,
            fuel_after_station_trip,
            min_fuel_for_task
        )
    end
    
    -- Need to refuel - travel to station
    print(string.format(
        "[REFUEL] Going to station (current: %d, roundtrip cost: %d, task needs: %d)",
        current_fuel,
        roundtrip_fuel_cost,
        min_fuel_for_task
    ))

    local success, location, message = turtle_nav.goto_location(refuel_station_coordinates.x, refuel_station_coordinates.y, refuel_station_coordinates.z, force_move)

    if not success then
        return false, "Failed to reach refuel station: " .. (message or "unknown error")
    end

    -- At the station - refuel to target amount
    for _, item in ipairs(inv.local_valid_fuel_items) do
        while turtle.getFuelLevel() < station_refuel_amount do
            -- Get fuel items from chest
            success, _ = chest.get_item(item, 16)
            
            if not success then
                -- No more of this fuel type available, try next
                break
            end
            
            -- Consume fuel from inventory
            result, msg = inv.refuel(true)
            
            -- Check if reached target
            if turtle.getFuelLevel() >= station_refuel_amount then
                return true, string.format(
                    "Refueled to %d (enough for task requiring %d)",
                    turtle.getFuelLevel(),
                    min_fuel_for_task
                )
            end
        end
    end
    
    -- Could not reach target with available fuel
    local current = turtle.getFuelLevel()
    return false, string.format(
        "Could not reach target. Current: %d, Target: %d, Task needs: %d",
        current,
        station_refuel_amount,
        min_fuel_for_task
    )

end

return M
