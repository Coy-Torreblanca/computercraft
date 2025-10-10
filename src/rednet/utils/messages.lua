local M = {}

function M.send_ack(message, protocol, computer_id, timeout)
    -- Sends a message and waits for acknowledgment
    -- Assumes modem is open and protocol is hosted.
    
    print("[SEND_ACK] Starting - Target: " .. computer_id .. ", Protocol: " .. protocol .. ", Timeout: " .. timeout .. "s")
    print("[SEND_ACK] Message: '" .. message .. "'")
    
    local start_time = os.epoch("utc")
    local timeout_ms = timeout * 1000 -- Convert seconds to milliseconds
    local retry_count = 0

    while true do
        retry_count = retry_count + 1
        print("[SEND_ACK] Attempt #" .. retry_count .. " - Sending message to computer " .. computer_id)
        
        local send_success = rednet.send(computer_id, message, protocol)

        if not send_success then
            print("[SEND_ACK] ERROR - Failed to send message to computer " .. computer_id)
            error("Failed to send message to computer " .. computer_id)
        end
        
        local remaining_time = (start_time + timeout_ms - os.epoch("utc")) / 1000

        local timeout_time = math.min(remaining_time, 1)

        if remaining_time <= 0 then
            print("[SEND_ACK] ERROR - Timeout after " .. retry_count .. " attempts")
            error("Timeout: No acknowledgment received from computer " .. computer_id .. " within " .. timeout .. " seconds")
        end
        
        print("[SEND_ACK] Waiting for synack (timeout: " .. string.format("%.1f", timeout_time) .. "s, remaining: " .. string.format("%.1f", remaining_time) .. "s)")
        local  sender_id, ack, _ = rednet.receive(protocol, timeout_time)
        
        if ack then
            print("[SEND_ACK] Received: '" .. ack .. "' from computer " .. sender_id)
        end
        
        if sender_id == computer_id and ack == message .. 'synack' then
            print("[SEND_ACK] Valid synack received! Sending final ack...")
            local send_success = rednet.send(computer_id, message .. 'ack', protocol)
            
            if not send_success then
                print("[SEND_ACK] ERROR - Failed to send final ack to computer " .. computer_id)
                error("Failed to send final ack to computer " .. computer_id)
            end
            
            print("[SEND_ACK] SUCCESS - Handshake complete after " .. retry_count .. " attempts")
            return ack, sender_id
        elseif ack then
            print("[SEND_ACK] Invalid acknowledgment - Expected: '" .. message .. "synack', Got: '" .. ack .. "'")
        end
    end
end

function M.receive_ack(protocol, timeout)
    -- Receives a message and sends acknowledgment back
    -- Assumes modem is open and protocol is hosted
    
    local computer_id = os.computerID()
    print("[RECEIVE_ACK] Starting - Computer ID: " .. computer_id .. ", Protocol: " .. protocol .. ", Timeout: " .. timeout .. "s")
    
    local start_time = os.epoch("utc")
    local timeout_ms = timeout * 1000 -- Convert seconds to milliseconds
    local wait_count = 0
    
    while true do
        wait_count = wait_count + 1
        local remaining_time = (start_time + timeout_ms - os.epoch("utc")) / 1000
        
        if remaining_time <= 0 then
            print("[RECEIVE_ACK] ERROR - No message received after " .. wait_count .. " attempts")
            error("Timeout: No message received within " .. timeout .. " seconds")
        end
        
        if wait_count == 1 or wait_count % 5 == 0 then
            print("[RECEIVE_ACK] Attempt #" .. wait_count .. " - Waiting for message (remaining: " .. string.format("%.1f", remaining_time) .. "s)")
        end
        
        local sender_id, message, _ = rednet.receive(protocol, math.min(remaining_time, 1)) -- Check at most every second
        
        if message then
            print("[RECEIVE_ACK] Received message: '" .. message .. "' from computer " .. sender_id)
        end
        
        if message then
            print("[RECEIVE_ACK] Valid message received! Starting synack handshake...")
            
            -- Wait for final ack from sender, retrying synack send
            local ack_start_time = os.epoch("utc")
            local ack_timeout_ms = 5000 -- 5 second timeout for final ack
            local synack_count = 0
            
            while true do
                synack_count = synack_count + 1
                -- Send acknowledgment back to sender
                print("[RECEIVE_ACK] Attempt #" .. synack_count .. " - Sending synack to computer " .. sender_id)
                local send_success = rednet.send(sender_id, message .. 'synack', protocol)
                
                if not send_success then
                    print("[RECEIVE_ACK] ERROR - Failed to send synack to computer " .. sender_id)
                    error("Failed to send synack to computer " .. sender_id)
                end
                
                local ack_remaining_time = (ack_start_time + ack_timeout_ms - os.epoch("utc")) / 1000
                
                local ack_timeout_time = math.min(ack_remaining_time, 0.5)
                
                if ack_remaining_time <= 0 then
                    print("[RECEIVE_ACK] ERROR - Sender did not send final ack after " .. synack_count .. " attempts")
                    error("Timeout: Sender did not send final acknowledgment")
                end
                
                print("[RECEIVE_ACK] Waiting for final ack (timeout: " .. string.format("%.1f", ack_timeout_time) .. "s)")
                local ack_id, ack, _ = rednet.receive(protocol, ack_timeout_time)
                
                if ack then
                    print("[RECEIVE_ACK] Received: '" .. ack .. "' from computer " .. ack_id)
                end
                
                if ack and ack_id == sender_id and ack == message .. 'ack' then
                    print("[RECEIVE_ACK] SUCCESS - Handshake complete! Returning message.")
                    return message, sender_id
                elseif ack then
                    print("[RECEIVE_ACK] Invalid ack - Expected: '" .. message .. "ack' from computer " .. sender_id .. ", Got: '" .. ack .. "' from computer " .. ack_id)
                end
            end
        elseif message then
            print("[RECEIVE_ACK] Ignoring message from ourselves (computer " .. computer_id .. ")")
        end
    end
end

return M