-- initialize swarm
-- plant and grow a tree
-- order swarm to refuel
--- decide tree, get bonemeal, get sapling
-- while y of swarm is less then max_y
-- order swarm to perform 1 routine
-- wait for swarm to finish
-- increment y of swarm
-- repeat
-- 

local config = {
    max_y = 100,
    max_x = 100,
    fuel_threshold = 20000,
    modem_direction = "away_x",
    routine_protocol = "tree_farm_coy1"
}

local refuel = require('/repo/src/turtle/move/refuel')
local turtle_nav = require('/repo/src/turtle/move/turtle_nav')
local initiate_swarm = require('/repo/src/rednet/swarm/initiate_swarm')

local function node_start_routine()
    -- assume at starting position.

    local success, msg = refuel.refuel_at_station(turtle_nav.get_current_location(), config.fuel_threshold, config.required_fuel_level)

    if not success then
        error("Failed to refuel: " .. msg)
    end

    success, msg = initiate_swarm.register_drone(config.routine_protocol)

    if not success then
        error("Failed to register drone: " .. msg)
    end

end