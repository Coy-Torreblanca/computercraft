local refuel = require('/repo/src/turtle/move/refuel')
local turtle_nav = require('/repo/src/turtle/move/turtle_nav')
local initiate_swarm = require('/repo/src/rednet/swarm/initiate_swarm')
local messages = require('/repo/src/rednet/utils/messages')
local config = require('/repo/apps/tree_farm/src/config')

M = {}

function M.host_init()
    local success, msg = initiate_swarm.register_host(config.swarm_count, config.routine_protocol)

    if not success then
        error("Failed to register host: " .. msg)
    end
end

return M