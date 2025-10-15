local refuel = require('/repo/src/turtle/move/refuel')
local turtle_nav = require('/repo/src/turtle/move/turtle_nav')
local initiate_swarm = require('/repo/src/rednet/swarm/initiate_swarm')
local messages = require('/repo/src/rednet/utils/messages')
local config = require('/repo/apps/tree_farm/src/config')
local logger = require('/repo/src/utils/logger')

M = {}

local log = logger.new('TreeFarmDrone')

function M.node_refuel()
    local starting_position = M.read_starting_position()
    log.info("Starting refuel cycle at position (" .. starting_position.x .. ", " .. starting_position.y .. ", " .. starting_position.z .. ")")
    log.debug("Fuel threshold: " .. config.fuel_threshold)
    
    while true do
        local success, msg = refuel.refuel_at_station(starting_position, config.fuel_threshold, config.required_fuel_level)
        if success then
            log.info("Refuel complete")
            break
        else
            log.warn("Refuel attempt failed: " .. tostring(msg) .. ", retrying...")
        end
    end
end

function M.write_starting_position()
    local current_pos = turtle_nav.get_current_location()
    local filename = config.routine_protocol .. '_starting_position.txt'
    
    log.debug("Writing starting position to " .. filename)
    log.debug("Position: (" .. current_pos.x .. ", " .. current_pos.y .. ", " .. current_pos.z .. ")")
    
    local f = io.open(filename, 'w')
    f:write(current_pos.x .. '\n')
    f:write(current_pos.y .. '\n')
    f:write(current_pos.z .. '\n')
    f:close()
    
    log.info("Starting position saved")
end

function M.read_starting_position()
    if M.starting_position then
        log.debug("Using cached starting position")
        return M.starting_position
    end

    local filename = config.routine_protocol .. '_starting_position.txt'
    log.debug("Reading starting position from " .. filename)
    
    local f = io.open(filename, 'r')
    if not f then
        log.error("Failed to open starting position file: " .. filename)
        error("Could not read starting position file")
    end
    
    local x = tonumber(f:read())
    local y = tonumber(f:read())
    local z = tonumber(f:read())
    f:close()
    
    M.starting_position = {x = x, y = y, z = z}
    log.info("Starting position loaded: (" .. x .. ", " .. y .. ", " .. z .. ")")
    
    return M.starting_position
end

function M.node_init()
    log.info("Initializing tree farm drone")
    log.info("Computer ID: " .. os.getComputerID() .. ", Protocol: " .. config.routine_protocol)
    
    -- Assume at starting position
    log.debug("Recording starting position")
    M.write_starting_position()

    log.debug("Initiating refuel sequence")
    M.node_refuel()

    log.info("Registering with swarm host")
    local success, msg = initiate_swarm.register_drone(config.routine_protocol)

    if not success then
        log.error("Drone registration failed: " .. msg)
        error("Failed to register drone: " .. msg)
    end
    
    log.info("Drone initialization complete - ready for operations")
end

return M