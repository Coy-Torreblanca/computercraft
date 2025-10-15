local refuel = require('/repo/src/turtle/move/refuel')
local turtle_nav = require('/repo/src/turtle/move/turtle_nav')
local initiate_swarm = require('/repo/src/rednet/swarm/initiate_swarm')
local messages = require('/repo/src/rednet/utils/messages')
local config = require('/repo/apps/tree_farm/src/config')
local logger = require('/repo/src/utils/logger')

M = {}

local log = logger.new('TreeFarmHost')

function M.host_init()
    log.info("Initializing tree farm host")
    log.info("Configuration - swarm_count: " .. config.swarm_count .. ", protocol: " .. config.routine_protocol)
    
    local success, msg, swarm_inv = initiate_swarm.register_host(config.swarm_count, config.routine_protocol)

    if not success then
        log.error("Host initialization failed: " .. msg)
        error("Failed to register host: " .. msg)
    end
    
    log.info("Host initialization complete - swarm ready with " .. #swarm_inv .. " drones")
end

return M