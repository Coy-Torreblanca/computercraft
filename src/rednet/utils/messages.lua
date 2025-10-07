local M = {}

function M.send_ack(message, protocol, computer_id, timeout)
    -- Sends a message and waits for acknowledgment
    -- Assumes modem is open and protocol is hosted.
    
    local start_time = os.epoch("utc")
    local timeout_ms = timeout * 1000 -- Convert seconds to milliseconds

    while true do
        rednet.send(computer_id, message, protocol)
        
        local remaining_time = (start_time + timeout_ms - os.epoch("utc")) / 1000

        local timeout_time = math.min(remaining_time, 1)

        if remaining_time <= 0 then
            error("Timeout: No acknowledgment received from computer " .. computer_id .. " within " .. timeout .. " seconds")
        end
        
        local ack, id = rednet.receive(protocol, timeout_time)
        if id == computer_id and ack == message .. 'synack' then
            rednet.send(computer_id, message .. 'ack', protocol)
            return ack, id
        end
    end
end

function M.receive_ack(protocol, timeout)
    -- Receives a message and sends acknowledgment back
    -- Assumes modem is open and protocol is hosted
    
    local start_time = os.epoch("utc")
    local timeout_ms = timeout * 1000 -- Convert seconds to milliseconds
    local computer_id = os.computerID()
    
    while true do
        local remaining_time = (start_time + timeout_ms - os.epoch("utc")) / 1000
        if remaining_time <= 0 then
            error("Timeout: No message received within " .. timeout .. " seconds")
        end
        
        local message, id = rednet.receive(protocol, math.min(remaining_time, 1)) -- Check at most every second
        if message and id == computer_id then
            -- Wait for final ack from sender, retrying synack send
            local ack_start_time = os.epoch("utc")
            local ack_timeout_ms = 5000 -- 5 second timeout for final ack
            
            while true do
                -- Send acknowledgment back to sender
                rednet.send(id, message .. 'synack', protocol)
                
                local ack_remaining_time = (ack_start_time + ack_timeout_ms - os.epoch("utc")) / 1000
                
                local ack_timeout_time = math.min(ack_remaining_time, 0.5)
                
                if ack_remaining_time <= 0 then
                    error("Timeout: Sender did not send final acknowledgment")
                end
                
                local ack, ack_id = rednet.receive(protocol, ack_timeout_time)
                if ack and ack_id == computer_id and ack == message .. 'ack' then
                    return message, id
                end
            end
        end
    end
end

return M