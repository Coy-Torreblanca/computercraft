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
    routine_protocol = "tree_farm_coy1",
    swarm_count = 22,
}

local refuel = require('/repo/src/turtle/move/refuel')
local turtle_nav = require('/repo/src/turtle/move/turtle_nav')
local initiate_swarm = require('/repo/src/rednet/swarm/initiate_swarm')
local messages = require('/repo/src/rednet/utils/messages')

M = {}

function M.node_refuel()
    while true do
        local success, msg = refuel.refuel_at_station(turtle_nav.get_current_location(), config.fuel_threshold, config.required_fuel_level)
        if success then
            break
        end
    end
end

function M.node_init()
    -- assume at starting position.

    M.node_refuel()

    local success, msg = initiate_swarm.register_drone(config.routine_protocol)

    if not success then
        error("Failed to register drone: " .. msg)
    end

end

function M.host_init()
    local success, msg = initiate_swarm.register_host(config.swarm_count, config.routine_protocol)

    if not success then
        error("Failed to register host: " .. msg)
    end
end