local M = {}

inv = require('/repo/src/turtle/inv')
messages = require('/repo/src/rednet/utils/messages')

function _validate_swarm(swarm_validation_table)

    for _, computer_id in pairs(swarm_inv) do
        if not swarm_validation_table[computer_id] then
            return false
        end
    end

    return true
end

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
    rednet.host(protocol .. '_host_ack', 'host')
    local swarm_inv 

    while true do
        print("[REGISTER_HOST] Looking up swarm inventory...")
        swarm_inv = {rednet.lookup(protocol)}
        if swarm_inv and #swarm_inv == swarm_count then
            print("[REGISTER_HOST] Found " .. #swarm_inv .. " nodes in swarm")
            break
        end
        if #swarm_inv > 0 then
            print("[REGISTER_HOST] Found " .. #swarm_inv .. " nodes in swarm")
        end
        print("[REGISTER_HOST] Still looking for nodes... (elapsed: " .. string.format("%.1f", elapsed_time) .. "s)")
        sleep(1)
    end

    local swarm_validation = {}
    
    local start_time = os.epoch("utc")
    local total_timeout_ms = 600000 -- 10 minutes total timeout for all registrations
    local attempt_count = 0

    while true do
        attempt_count = attempt_count + 1
        local elapsed_time = (os.epoch("utc") - start_time) / 1000
        
        if elapsed_time >= total_timeout_ms / 1000 then
            print("[REGISTER_HOST] ERROR - Registration timeout after " .. attempt_count .. " attempts and " .. string.format("%.1f", elapsed_time) .. "s")
            error("Swarm registration timeout: Not all nodes registered within timeout period")
        end
        
        print("[REGISTER_HOST] Attempt #" .. attempt_count .. " - Waiting for registration (elapsed: " .. string.format("%.1f", elapsed_time) .. "s)")
        message, sender_id = messages.receive_ack(protocol .. '_host_ack', 30) -- 30s per attempt

        if message == 'host register' and not swarm_validation[sender_id] then
            swarm_validation[sender_id] = true
            print("[REGISTER_HOST] Registered computer " .. sender_id .. " - Total registered: " .. tostring(#swarm_validation) .. "/" .. swarm_count)
        end

        if _validate_swarm(swarm_validation) then
            print("[REGISTER_HOST] SUCCESS - All " .. swarm_count .. " nodes registered!")
            break
        end

    end

    return swarm_inv

end

function M.register_drone(protocol)
    -- Register as a drone in the swarm by looking up and connecting to host.
    -- Args:
    --- protocol - String of protocol under which swarm communicates.
    
    print("[REGISTER_DRONE] Starting registration for protocol: " .. protocol)
    
    inv.ensureAttached('computercraft:wireless_modem_normal', 'left')
    rednet.open('left')

    id = os.computerID()
    
    -- Announce this drone is available
    rednet.host(protocol, 'drone-' .. id)
    rednet.host(protocol .. '_host_ack', 'drone-' .. id)
    
    local start_time = os.epoch("utc")
    local lookup_timeout_ms = 300000 -- 5 minutes to find host
    local host_id = nil
    
    -- Wait for host to be available
    print("[REGISTER_DRONE] Looking up host...")
    while true do
        local elapsed_time = (os.epoch("utc") - start_time) / 1000
        
        if elapsed_time >= lookup_timeout_ms / 1000 then
            print("[REGISTER_DRONE] ERROR - Host lookup timeout after " .. string.format("%.1f", elapsed_time) .. "s")
            error("Failed to find host within timeout period")
        end
        
        host_id = rednet.lookup(protocol, 'host')
        
        if host_id then
            print("[REGISTER_DRONE] Found host at computer " .. host_id)
            break
        end
        
        if elapsed_time > 0 and math.floor(elapsed_time) % 10 == 0 then
            print("[REGISTER_DRONE] Still looking for host... (elapsed: " .. string.format("%.1f", elapsed_time) .. "s)")
        end
        
        sleep(1)
    end
    
    -- Send registration message to host
    print("[REGISTER_DRONE] Sending registration to host " .. host_id)
    local ack, sender_id = messages.send_ack('host register', protocol .. '_host_ack', host_id, 30)
    
    if sender_id == host_id then
        print("[REGISTER_DRONE] SUCCESS - Registered with host " .. host_id)
    else
        print("[REGISTER_DRONE] ERROR - Unexpected response from computer " .. sender_id)
        error("Registration failed: response from wrong computer")
    end
end

return M