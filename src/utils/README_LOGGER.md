# Logger Module

Professional logging utility for ComputerCraft with structured output and multiple severity levels.

## Features

- **Multiple log levels**: DEBUG, INFO, WARN, ERROR
- **Automatic timestamps**: HH:MM:SS format
- **Module-specific loggers**: Clear prefixes for each module
- **Configurable filtering**: Set global minimum log level
- **Clean output format**: Consistent, readable logs

## Basic Usage

```lua
local logger = require('/repo/src/utils/logger')
local log = logger.new('MyModule')

-- Log at different levels
log.info("Operation started")
log.debug("Processing item: " .. item_name)
log.warn("Low fuel detected")
log.error("Failed to connect to host")
```

## Output Format

```
[HH:MM:SS] [LEVEL] [MODULE] message
```

Example:
```
[14:23:45] [INFO] [SwarmInit] Starting host registration - expecting 3 drones
[14:23:46] [DEBUG] [SwarmInit] Still looking for nodes... (elapsed: 1.2s)
[14:23:50] [INFO] [SwarmInit] Found 3 nodes in swarm
[14:24:15] [ERROR] [SwarmInit] Lookup timeout after 300.0s
```

## Log Levels

Levels from highest to lowest priority:

| Level | Use Case |
|-------|----------|
| `ERROR` | Critical failures, operations that cannot continue |
| `WARN` | Warning conditions, degraded functionality |
| `INFO` | Important state changes, milestones (default) |
| `DEBUG` | Detailed diagnostic information |

## Configuration

### Per-Instance Log Level (Recommended)

Set the log level when creating a logger for fine-grained control:

```lua
local logger = require('/repo/src/utils/logger')

-- Create logger with DEBUG level (shows everything)
local debug_log = logger.new('Navigation', 'DEBUG')

-- Create logger with ERROR level (only critical errors)
local error_log = logger.new('Network', 'ERROR')

-- Default logger (uses global level)
local info_log = logger.new('MainApp')

debug_log.debug("Detailed trace")  -- Shows
error_log.debug("Network detail")  -- Hidden
info_log.info("Application start") -- Shows (if global is INFO)
```

### Change Logger Level at Runtime

```lua
local log = logger.new('MyModule')

-- Initially uses global level
log.info("Starting")

-- Set specific level for this logger
log.set_level('ERROR')
log.info("This won't show")   -- Hidden
log.error("This will show")   -- Shows

-- Revert to using global level
log.set_level(nil)
log.info("Back to normal")  -- Shows if global is INFO
```

### Global Log Level (Affects All Loggers Without Instance Level)

```lua
local logger = require('/repo/src/utils/logger')

-- Show only warnings and errors globally
logger.set_level("WARN")

-- Show everything including debug messages
logger.set_level("DEBUG")

-- Default: show INFO and above
logger.set_level("INFO")
```

**Note:** Instance-level settings override global settings. This allows you to debug specific modules without flooding output from others.

### Multiple Module Loggers with Different Levels

```lua
local logger = require('/repo/src/utils/logger')

-- Navigation needs detailed debugging
local nav_log = logger.new('Navigation', 'DEBUG')

-- Refuel only needs important info
local fuel_log = logger.new('Refuel', 'WARN')

-- ChestOps uses global level
local chest_log = logger.new('ChestOps')

nav_log.debug("Current position: (10, 64, 20)")  -- Shows
nav_log.info("Moving to coordinates (15, 65, 25)")  -- Shows
fuel_log.info("Refueling complete")  -- Hidden (WARN level)
fuel_log.warn("Fuel level below threshold: " .. turtle.getFuelLevel())  -- Shows
chest_log.info("Depositing items")  -- Shows if global is INFO
```

Output (assuming global is INFO):
```
[14:30:12] [DEBUG] [Navigation] Current position: (10, 64, 20)
[14:30:12] [INFO] [Navigation] Moving to coordinates (15, 65, 25)
[14:30:15] [WARN] [Refuel] Fuel level below threshold: 450
[14:30:18] [INFO] [ChestOps] Depositing items
```

## Best Practices

### 1. Use Appropriate Log Levels

```lua
-- ✅ Good: Informative messages at correct levels
log.info("Starting swarm registration")
log.debug("Attempt #5 - waiting for response")
log.error("Timeout: no response after 300s")

-- ❌ Bad: Wrong levels
log.error("Processing item")  -- Not an error
log.debug("System crashed!")  -- Should be ERROR
```

### 2. Include Context

```lua
-- ✅ Good: Provides useful context
log.error("Failed to connect to computer " .. computer_id .. " after " .. attempts .. " attempts")
log.info("Registered " .. #swarm_inv .. "/" .. swarm_count .. " drones")

-- ❌ Bad: Vague messages
log.error("Failed")
log.info("Done")
```

### 3. One Logger Per Module

```lua
-- ✅ Good: Create once at module level
local M = {}
local logger = require('/repo/src/utils/logger')
local log = logger.new('ModuleName')

function M.some_function()
    log.info("Function called")
end

-- ✅ Also good: Set level during development
local log = logger.new('ModuleName', 'DEBUG')  -- Temporary for debugging

-- ❌ Bad: Creating logger in every function
function M.some_function()
    local log = logger.new('ModuleName')  -- Wasteful
    log.info("Function called")
end
```

### 4. Format Numbers Consistently

```lua
-- ✅ Good: Formatted for readability
log.info("Position: (" .. x .. ", " .. y .. ", " .. z .. ")")
log.debug("Elapsed time: " .. string.format("%.1f", elapsed) .. "s")

-- ❌ Bad: Raw floats
log.debug("Elapsed time: " .. elapsed)  -- Could be 123.456789012s
```

## Integration Examples

### Example 1: Basic Module Logging

Here's how `initiate_swarm.lua` uses the logger:

```lua
local M = {}
local logger = require('/repo/src/utils/logger')
local log = logger.new('SwarmInit')

function M.register_host(swarm_count, protocol)
    log.info("Starting host registration - expecting " .. swarm_count .. " drones")
    
    -- ... setup code ...
    
    while looking_for_nodes do
        if timeout then
            log.error("Lookup timeout after " .. string.format("%.1f", elapsed) .. "s")
            return false, "Timeout"
        end
        
        log.debug("Still looking for nodes... (elapsed: " .. elapsed .. "s)")
        sleep(1)
    end
    
    log.info("Found " .. #swarm_inv .. " nodes in swarm")
    return true, "Success", swarm_inv
end
```

### Example 2: Different Levels for Different Modules

```lua
-- main.lua
local logger = require('/repo/src/utils/logger')

-- Core app logic only needs INFO+
local app_log = logger.new('App', 'INFO')

-- Network operations need detailed debugging
local net_log = logger.new('Network', 'DEBUG')

-- File operations only show errors
local file_log = logger.new('FileOps', 'ERROR')

function main()
    app_log.info("Application starting")
    
    net_log.debug("Opening connection to computer 15")
    net_log.debug("Sending handshake packet")
    net_log.info("Connection established")
    
    file_log.debug("Reading config file")  -- Won't show (ERROR only)
    file_log.error("Failed to open config.txt")  -- Shows
    
    app_log.info("Application ready")
end
```

### Example 3: Runtime Level Changes

```lua
local logger = require('/repo/src/utils/logger')
local log = logger.new('MiningOp')

function mine_with_diagnostics(enable_debug)
    -- Enable debug logging if requested
    if enable_debug then
        log.set_level('DEBUG')
        log.debug("Debug mode enabled")
    end
    
    log.info("Starting mining operation")
    
    for i = 1, 100 do
        log.debug("Mining block " .. i)  -- Only shows if debug enabled
        turtle.dig()
        turtle.forward()
    end
    
    log.info("Mining complete")
    
    -- Restore normal logging
    log.set_level(nil)
end
```

## When to Use Each Level

### ERROR
- Timeout conditions
- Failed connections
- Missing required resources
- Operations that cannot complete

### WARN
- Degraded performance
- Unexpected but recoverable conditions
- Resource constraints
- Retry operations

### INFO (default)
- Major state transitions
- Successful completions
- Important milestones
- Configuration changes

### DEBUG
- Loop iterations
- Intermediate states
- Detailed progress updates
- Diagnostic information

## Performance Notes

- Logging is lightweight (simple string formatting + print)
- Filtered logs (below MIN_LEVEL) have minimal overhead
- No file I/O or network calls
- Safe for tight loops with DEBUG level filtering

## Pros & Cons

**Pros:**
- ✅ Consistent, professional output
- ✅ Easy filtering with log levels (global AND per-instance)
- ✅ Clear module identification
- ✅ Timestamps for debugging timing issues
- ✅ Zero configuration needed for basic use
- ✅ Familiar API pattern
- ✅ Runtime level changes for targeted debugging
- ✅ Lightweight with minimal performance overhead

**Cons:**
- ❌ No log persistence (prints only)
- ❌ No log rotation or file output
- ❌ Timestamp precision limited to game time
- ❌ No structured data (JSON) support

## Advanced Usage

### Selective Debugging

Debug only one problematic module while keeping others quiet:

```lua
-- Set global level to INFO (minimal output)
logger.set_level('INFO')

-- But enable DEBUG for the module you're troubleshooting
local problem_log = logger.new('ProblematicModule', 'DEBUG')
local normal_log = logger.new('NormalModule')  -- Uses INFO

-- Now only ProblematicModule will show debug messages
problem_log.debug("Detailed diagnostic info")  -- Shows
normal_log.debug("This won't clutter output")  -- Hidden
```

### Conditional Logging Based on Config

```lua
local config = {
    debug_navigation = true,
    debug_network = false
}

local nav_log = logger.new('Navigation', config.debug_navigation and 'DEBUG' or 'INFO')
local net_log = logger.new('Network', config.debug_network and 'DEBUG' or 'INFO')
```

## Future Enhancements

Potential additions:
- File output support
- Remote logging to central server
- Log buffering for network transmission
- Structured logging (key-value pairs)
- Color-coded output (if terminal supports it)

