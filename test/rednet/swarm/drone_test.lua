-- Test file for swarm drone registration
-- Run this on each drone computer

local initiate_swarm = require('/repo/src/rednet/swarm/initiate_swarm')

-- Configuration
local PROTOCOL = 'test_swarm'

print("===========================================")
print("  SWARM DRONE REGISTRATION TEST")
print("===========================================")
print("Computer ID: " .. os.computerID())
print("Protocol: " .. PROTOCOL)
print("-------------------------------------------")
print("")

-- Start drone registration
print("Starting drone registration...")
print("Looking for host...")
print("")

local success, error_msg = pcall(function()
    initiate_swarm.register_drone(PROTOCOL)
end)

print("")
print("===========================================")
if success then
    print("  ✓ DRONE REGISTRATION SUCCESSFUL!")
    print("===========================================")
    print("Successfully registered with host.")
    print("Drone is ready for operations.")
else
    print("  ✗ DRONE REGISTRATION FAILED!")
    print("===========================================")
    print("Error: " .. tostring(error_msg))
end
print("")


