--[[
    Test Suite for rednet/utils/messages.lua
    
    This file tests the acknowledgment protocol functions for reliable message passing
    between ComputerCraft computers using rednet.
    
    PREREQUISITES:
    ============
    1. You need at least TWO computers (or turtles) in ComputerCraft
    2. Both computers must have wireless modems attached
    3. The modems must be within range of each other (default: 64 blocks for regular, 384 for ender)
    4. Both computers must be running and have the messages.lua module available
    
    SETUP INSTRUCTIONS:
    ==================
    
    Step 1: Open modems and host protocol on BOTH computers
    -------------------------------------------------------
    Run this on BOTH computers before testing:
    
        peripheral.find("modem", rednet.open)  -- Opens all attached modems
        rednet.host("test", "test_protocol")    -- Host the test protocol
    
    Step 2: Check Computer IDs
    --------------------------
    On each computer, run:
    
        print(os.computerID())
    
    Note these IDs - you'll need them for testing.
    
    RUNNING THE TESTS:
    ==================
    
    Test 1: Basic Sender/Receiver Test
    -----------------------------------
    Computer A (Sender - ID: 1):
        messages = require('/repo/src/rednet/utils/messages')
        messages.send_ack('hello', 'test', 2, 10)  -- Send to computer 2 with 10s timeout
    
    Computer B (Receiver - ID: 2):
        messages = require('/repo/src/rednet/utils/messages')
        local msg, sender_id = messages.receive_ack('test', 10)
        print("Received: " .. msg .. " from " .. sender_id)
    
    IMPORTANT: Start the RECEIVER first, then run the SENDER within the timeout period.
    
    Test 2: Using the Test Functions Below
    ---------------------------------------
    On Computer B (Receiver):
        dofile('/repo/test/rednet/utils/messages.lua')
        test_receive_ack()
    
    On Computer A (Sender):
        dofile('/repo/test/rednet/utils/messages.lua')
        test_send_ack()  -- Make sure to edit computer_id to match receiver
    
    Test 3: Timeout Testing
    -----------------------
    To test timeout behavior, run ONLY the receiver or sender (not both):
    
        messages.send_ack('test', 'test', 999, 5)  -- Will timeout after 5s (computer 999 doesn't exist)
    
    EXPECTED BEHAVIOR:
    ==================
    - Successful test: Both functions return without error
    - Sender returns: (synack_message, receiver_id)
    - Receiver returns: (original_message, sender_id)
    - Timeout test: Raises error with descriptive message
    
    TROUBLESHOOTING:
    ===============
    - "Timeout error": Check that both computers have modems open and are in range
    - "No acknowledgment": Ensure receiver is running BEFORE sender
    - "Protocol not found": Run rednet.host("test", "test_protocol") on both computers
    - "Require error": Check the file path matches your directory structure
    
    PROTOCOL FLOW:
    ==============
    1. Sender: sends 'message' → Receiver
    2. Receiver: receives 'message', sends 'message' + 'synack' → Sender
    3. Sender: receives 'messagesynack', sends 'message' + 'ack' → Receiver
    4. Receiver: receives 'messageack', returns success
    
    Both sender and receiver will retry their messages periodically if not acknowledged.
]]--

messages = require('/repo/src/rednet/utils/messages')

function test_send_ack()
    -- IMPORTANT: Update computer_id to match your receiver's ID
    -- Check receiver ID by running: print(os.computerID())
    local message = 'test'
    local protocol = 'test'
    local computer_id = 2  -- *** CHANGE THIS to your receiver's computer ID ***
    local timeout = 10  -- 10 second timeout
    
    print("Starting sender test...")
    print("Sending message to computer " .. computer_id)
    
    local ack, id = messages.send_ack(message, protocol, computer_id, timeout)
    
    print("SUCCESS! Received acknowledgment: " .. ack .. " from computer " .. id)
end

function test_receive_ack()
    local protocol = 'test'
    local timeout = 30  -- 30 second timeout (gives you time to start sender)
    
    print("Starting receiver test...")
    print("Waiting for message on protocol '" .. protocol .. "'...")
    print("This computer ID: " .. os.computerID())
    print("You have " .. timeout .. " seconds to start the sender.")
    
    local message, sender_id = messages.receive_ack(protocol, timeout)
    
    print("SUCCESS! Received message: '" .. message .. "' from computer " .. sender_id)
end

-- Uncomment one of these to run a test directly:
-- test_send_ack()
-- test_receive_ack()
