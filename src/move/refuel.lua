local inv = require('/repo/src/turtle/inv')
local turtle_nav = require('/repo/src/move/turtle_nav')
local chest = require('/repo/src/chest/chest')

M = {}

function M.refuel_at_station(refuel_station_coordinates, target_fuel_level, force_move)
    -- Refuel turtle at a designated refuel station, ensuring round-trip capability.
    --
    -- Smart refueling with safety-first logic:
    -- 1. First tries to refuel from items already in inventory
    -- 2. Checks if current fuel is sufficient for round trip to station (distance × 2)
    -- 3. If sufficient, returns early without traveling
    -- 4. Otherwise, navigates to refuel station
    -- 5. Retrieves fuel from chest and refuels to target_fuel_level
    -- 6. Tries multiple fuel types (coal, charcoal, coal blocks, lava buckets)
    --
    -- This ensures turtle never gets stranded - always maintains enough fuel to
    -- return to the refuel station from current position.
    --
    -- Args:
    --     refuel_station_coordinates: Table with {x, y, z} of chest location with fuel
    --     target_fuel_level: Number, fuel level to reach when at the station
    --     force_move: Boolean, if true will dig through obstacles during navigation
    --
    -- Returns:
    --     success: Boolean, true if has round-trip fuel or reached target level
    --     message: String, status message or error description
    --
    -- Example:
    --     local fuel_station = {x = 100, y = 64, z = 200}
    --     -- Refuel to 10,000 when at station, but only go if needed
    --     local success, msg = refuel.refuel_at_station(fuel_station, 10000, true)
    --     if success then
    --         print("Safe to continue: " .. msg)
    --     else
    --         print("Fuel critical: " .. msg)
    --     end

    inv.refuel(true)

    local number_of_moves_left = turtle_nav.distance_to(refuel_station_coordinates.x, refuel_station_coordinates.y, refuel_station_coordinates.z)

    if turtle.getFuelLevel() >= (number_of_moves_left * 2) then
        return true, "Already have enough fuel"
    end

    local success, location = turtle_nav.goto_location(refuel_station_coordinates.x, refuel_station_coordinates.y, refuel_station_coordinates.z, force_move)

    if not success then
        return false, "Failed to go to refuel station"
    end

    for _, item in ipairs(inv.local_valid_fuel_items) do
        while turtle.getFuelLevel() < target_fuel_level do
            -- Get fuel items from chest
            success, _ = chest.get_item(item, 16)
            
            if not success then
                -- No more of this fuel type available, try next
                break
            end
            
            -- Consume fuel from inventory
            result, msg = inv.refuel(true)
            
            -- Check if reached target
            if turtle.getFuelLevel() >= target_fuel_level then
                return true, "Refueled to " .. turtle.getFuelLevel()
            end
        end
    end
    
    -- Could not reach target with available fuel
    return false, "Could not reach target. Current: " .. turtle.getFuelLevel() .. ", Target: " .. target_fuel_level

end

return M
