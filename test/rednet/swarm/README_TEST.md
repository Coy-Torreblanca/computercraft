# Swarm Registration Tests

Test files for validating swarm host and drone registration functionality.

## Files

- `host_test.lua` - Run on the host computer
- `drone_test.lua` - Run on each drone computer

## Setup Instructions

### 1. Configure Test Parameters

Edit the `SWARM_COUNT` in `host_test.lua` to match the number of drones you'll test with:

```lua
local SWARM_COUNT = 2  -- Change this to your number of drones
```

Both files use `PROTOCOL = 'test_swarm'` - ensure they match if you change it.

### 2. Running the Tests

**Order matters!** Follow these steps:

1. **Start the host first:**
   ```lua
   -- On host computer
   shell.run('/repo/test/rednet/swarm/host_test.lua')
   ```

2. **Start each drone:**
   ```lua
   -- On each drone computer
   shell.run('/repo/test/rednet/swarm/drone_test.lua')
   ```

### 3. Expected Behavior

**Host output:**
- Waits for drones to announce themselves via `rednet.host()`
- Waits for registration messages from each drone
- Shows progress as drones register
- Success when all drones registered

**Drone output:**
- Announces itself to the network
- Searches for host
- Sends registration message
- Success when host acknowledges registration

### 4. Timeouts

- **Host lookup timeout:** 5 minutes (drones looking for host)
- **Registration timeout:** 10 minutes (host waiting for all drones)
- **Per-message timeout:** 30 seconds

### 5. Troubleshooting

**"Host lookup timeout"**
- Ensure host computer is running first
- Check that wireless modems are enabled on both computers
- Verify both are in range (80 blocks for normal modems)

**"Registration timeout"**
- Check that correct number of drones are running
- Verify all drones are using same protocol name
- Check for network interference or out-of-range computers

**"Failed to send message"**
- Modem might not be attached properly
- Check modem is on correct side ('left' by default)
- Verify modem has power/redstone signal if needed

## Example Test Run

### Terminal 1 (Host - Computer ID 5)
```
===========================================
  SWARM HOST REGISTRATION TEST
===========================================
Computer ID: 5
Protocol: test_swarm
Expected drones: 2
-------------------------------------------

Starting host registration...
Waiting for 2 drone(s) to register...

[REGISTER_HOST] Attempt #1 - Waiting for registration (elapsed: 0.0s)
[REGISTER_HOST] Registered computer 7 - Total registered: 1/2
[REGISTER_HOST] Registered computer 12 - Total registered: 2/2
[REGISTER_HOST] SUCCESS - All 2 nodes registered!

===========================================
  ✓ HOST REGISTRATION SUCCESSFUL!
===========================================
All drones have been registered.
Swarm is ready for operations.
```

### Terminal 2 (Drone - Computer ID 7)
```
===========================================
  SWARM DRONE REGISTRATION TEST
===========================================
Computer ID: 7
Protocol: test_swarm
-------------------------------------------

Starting drone registration...
Looking for host...

[REGISTER_DRONE] Starting registration for protocol: test_swarm
[REGISTER_DRONE] Looking up host...
[REGISTER_DRONE] Found host at computer 5
[REGISTER_DRONE] Sending registration to host 5
[REGISTER_DRONE] SUCCESS - Registered with host 5

===========================================
  ✓ DRONE REGISTRATION SUCCESSFUL!
===========================================
Successfully registered with host.
Drone is ready for operations.
```


