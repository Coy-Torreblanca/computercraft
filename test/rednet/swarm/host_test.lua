-- Test file for swarm host registration
-- Run this on the host computer

local initiate_swarm = require('/repo/src/rednet/swarm/initiate_swarm')

-- Configuration
local SWARM_COUNT = 3  -- Number of drones (change based on your test setup)
local PROTOCOL = 'test_swarm'
local LOOKUP_TIMEOUT = 300  -- 5 minutes (optional, will use default if nil)
local REGISTRATION_TIMEOUT = 600  -- 10 minutes (optional, will use default if nil)

print("===========================================")
print("  SWARM HOST REGISTRATION TEST")
print("===========================================")
print("Computer ID: " .. os.computerID())
print("Protocol: " .. PROTOCOL)
print("Expected drones: " .. SWARM_COUNT)
print("-------------------------------------------")
print("")

-- Start host registration
print("Starting host registration...")
print("Waiting for " .. SWARM_COUNT .. " drone(s) to register...")
print("")

local success, message, swarm_inv = initiate_swarm.register_host(
    SWARM_COUNT, 
    PROTOCOL, 
    LOOKUP_TIMEOUT, 
    REGISTRATION_TIMEOUT
)

print("")
print("===========================================")
if success then
    print("  ✓ HOST REGISTRATION SUCCESSFUL!")
    print("===========================================")
    print("Message: " .. message)
    print("Registered drones:")
    for i, drone_id in ipairs(swarm_inv) do
        print("  " .. i .. ". Computer ID: " .. drone_id)
    end
    print("")
    print("Swarm is ready for operations.")
else
    print("  ✗ HOST REGISTRATION FAILED!")
    print("===========================================")
    print("Error: " .. message)
end
print("")


