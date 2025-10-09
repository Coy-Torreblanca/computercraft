-- Test file for swarm host registration
-- Run this on the host computer

local initiate_swarm = require('/repo/src/rednet/swarm/initiate_swarm')

-- Configuration
local SWARM_COUNT = 2  -- Number of drones (change based on your test setup)
local PROTOCOL = 'test_swarm'

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

local success, error_msg = pcall(function()
    initiate_swarm.register_host(SWARM_COUNT, PROTOCOL)
end)

print("")
print("===========================================")
if success then
    print("  ✓ HOST REGISTRATION SUCCESSFUL!")
    print("===========================================")
    print("All drones have been registered.")
    print("Swarm is ready for operations.")
else
    print("  ✗ HOST REGISTRATION FAILED!")
    print("===========================================")
    print("Error: " .. tostring(error_msg))
end
print("")


