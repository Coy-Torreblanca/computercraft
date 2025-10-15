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

### Global Log Level

```lua
local logger = require('/repo/src/utils/logger')

-- Show only warnings and errors globally
logger.set_level("WARN")

-- Show everything including debug messages
logger.set_level("DEBUG")

-- Default: show INFO and above
logger.set_level("INFO")
```

All loggers in your application will use the global level.

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

### Example 2: Multiple Module Loggers

```lua
-- main.lua
local logger = require('/repo/src/utils/logger')

-- Create loggers for different modules
local app_log = logger.new('App')
local net_log = logger.new('Network')
local file_log = logger.new('FileOps')

function main()
    app_log.info("Application starting")
    
    net_log.debug("Opening connection to computer 15")
    net_log.debug("Sending handshake packet")
    net_log.info("Connection established")
    
    file_log.debug("Reading config file")
    file_log.error("Failed to open config.txt")
    
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
        logger.set_level('DEBUG')
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
    if enable_debug then
        logger.set_level('INFO')
    end
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
- ✅ Easy filtering with global log level
- ✅ Clear module identification
- ✅ Timestamps for debugging timing issues
- ✅ Zero configuration needed for basic use
- ✅ Familiar API pattern
- ✅ Simple, predictable behavior
- ✅ Lightweight with minimal performance overhead

**Cons:**
- ❌ No log persistence (prints only)
- ❌ No log rotation or file output
- ❌ Timestamp precision limited to game time
- ❌ No structured data (JSON) support
- ❌ No per-module log level control

## Advanced Usage

### Conditional Logging Based on Config

```lua
local logger = require('/repo/src/utils/logger')
local config = {
    debug_mode = true
}

-- Set log level based on configuration
if config.debug_mode then
    logger.set_level('DEBUG')
else
    logger.set_level('INFO')
end

local nav_log = logger.new('Navigation')
local net_log = logger.new('Network')

nav_log.debug("Detailed navigation info")  -- Shows if debug_mode is true
net_log.info("Network connected")  -- Always shows
```

## Future Enhancements

Potential additions:
- File output support
- Remote logging to central server
- Log buffering for network transmission
- Structured logging (key-value pairs)
- Color-coded output (if terminal supports it)

