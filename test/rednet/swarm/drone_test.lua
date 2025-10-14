-- Test file for swarm drone registration
-- Run this on each drone computer

local initiate_swarm = require('/repo/src/rednet/swarm/initiate_swarm')

-- Configuration
local PROTOCOL = 'test_swarm'
local LOOKUP_TIMEOUT = 300  -- 5 minutes (optional, will use default if nil)

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

local success, message = initiate_swarm.register_drone(PROTOCOL, LOOKUP_TIMEOUT)

print("")
print("===========================================")
if success then
    print("  ✓ DRONE REGISTRATION SUCCESSFUL!")
    print("===========================================")
    print("Message: " .. message)
    print("Drone is ready for operations.")
else
    print("  ✗ DRONE REGISTRATION FAILED!")
    print("===========================================")
    print("Error: " .. message)
end
print("")


