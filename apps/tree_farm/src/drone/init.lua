local refuel = require('/repo/src/turtle/move/refuel')
local turtle_nav = require('/repo/src/turtle/move/turtle_nav')
local initiate_swarm = require('/repo/src/rednet/swarm/initiate_swarm')
local messages = require('/repo/src/rednet/utils/messages')
local config = require('/repo/apps/tree_farm/src/config')

M = {}

function M.node_refuel()
    local starting_position = M.read_starting_position()
    while true do
        local success, msg = refuel.refuel_at_station(starting_position, config.fuel_threshold, config.required_fuel_level)
        if success then
            break
        end
    end
end

function M.write_starting_position()
    local filename = config.routine_protocol .. '_starting_position.txt'
    local f = io.open(filename, 'w')
    f:write(turtle_nav.get_current_location().x)
    f:write(turtle_nav.get_current_location().y)
    f:write(turtle_nav.get_current_location().z)
    f:close()
end

function M.read_starting_position()
    if M.starting_position then
        return M.starting_position
    end

    local filename = config.routine_protocol .. '_starting_position.txt'
    local f = io.open(filename, 'r')
    local x = f:read('*number')
    local y = f:read('*number')
    local z = f:read('*number')
    f:close()
    M.starting_position = {x = x, y = y, z = z}
    return M.starting_position
end

function M.node_init()
    -- assume at starting position.
    M.write_starting_position()

    M.node_refuel()

    local success, msg = initiate_swarm.register_drone(config.routine_protocol)

    if not success then
        error("Failed to register drone: " .. msg)
    end

end

return M