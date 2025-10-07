local M = {}

inv = require('/repo/src/turtle/inv')

function M.register_host(swarm_count, protocol)
    -- Begin hosting protocol, register the swarm, and broadcast host register message.
    -- Args:
    --- swarm_count - Number of other computers in the swarm.
    ---- Does not include host.
    ---- Registration will not complete until all nodes ack.
    --- protocol - String of protocol under which swarm will communicate.
    

    inv.ensureAttached('computercraft:wireless_modem_normal', 'left')
    rednet.open('left')
    rednet.host(protocol, 'host')
    rednet.host(protocol .. '_host_ack')

    while true do
        SwarmInv = {rednet.lookup(protocol)}
        if SwarmInv and #SwarmInv == swarm_count then
            break
        end
        sleep(1)
    end

    for _, computer in pairs(SwarmInv) do
        rednet.send(computer, 'host registerid - id:' .. id, protocol)
    end

    for _, computer in pairs(SwarmInv) do
        ack, id = rednet.recieve(protocol .. '_host_ack', 5)
    end

end

function M.register_drone(protocol)

return M