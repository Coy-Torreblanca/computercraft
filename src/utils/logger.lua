--[[
Logger Module - Professional logging utility for ComputerCraft

Provides structured logging with multiple severity levels, timestamps, and
module-specific loggers for better debugging and monitoring.

Features:
  - Multiple log levels: DEBUG, INFO, WARN, ERROR
  - Automatic timestamps
  - Module-specific loggers with prefixes
  - Configurable global AND per-instance log levels
  - Clean, consistent output format

Example:
    local logger = require('/repo/src/utils/logger')
    
    -- Default logger (uses global level)
    local log = logger.new('MyModule')
    log.info("Starting operation")
    
    -- Logger with specific level
    local debug_log = logger.new('Debugger', 'DEBUG')
    debug_log.debug("This will show even if global level is INFO")
    
    -- Change logger level at runtime
    log.set_level('ERROR')  -- Now only shows errors
    log.set_level(nil)      -- Back to using global level
]]

local M = {}

-- Log levels (lower number = higher priority)
local LEVELS = {
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3,
}

-- Global minimum log level (can be changed to filter logs)
M.MIN_LEVEL = LEVELS.INFO

--- Format timestamp for log output
-- Returns: String in format "HH:MM:SS"
local function format_time()
    local time = os.time()
    local hours = math.floor(time)
    local minutes = math.floor((time - hours) * 60)
    local seconds = math.floor(((time - hours) * 60 - minutes) * 60)
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

--- Create log message with timestamp, level, and module prefix
-- Args:
--   level_name - String name of log level (DEBUG, INFO, WARN, ERROR)
--   module_name - String name of module
--   message - String message to log
-- Returns: Formatted log string
local function format_log(level_name, module_name, message)
    return string.format("[%s] [%s] [%s] %s", 
        format_time(),
        level_name,
        module_name,
        message
    )
end

--- Create a new logger for a specific module
-- Args:
--   module_name - String name of the module (used as prefix in logs)
--   min_level - (optional) String: "DEBUG", "INFO", "WARN", or "ERROR". 
--               If provided, this logger will only log at this level or above.
--               If nil, uses global M.MIN_LEVEL.
-- Returns: Table with logging methods (debug, info, warn, error, set_level)
function M.new(module_name, min_level)
    local logger = {}
    
    -- Instance-specific minimum level (overrides global if set)
    local instance_min_level = nil
    if min_level then
        if not LEVELS[min_level] then
            error("Invalid log level: " .. tostring(min_level))
        end
        instance_min_level = LEVELS[min_level]
    end
    
    --- Get effective minimum level (instance level or global)
    -- Returns: Number representing minimum log level
    local function get_min_level()
        return instance_min_level or M.MIN_LEVEL
    end
    
    --- Log a debug message
    -- Args:
    --   message - String message to log
    function logger.debug(message)
        if LEVELS.DEBUG >= get_min_level() then
            print(format_log("DEBUG", module_name, message))
        end
    end
    
    --- Log an info message
    -- Args:
    --   message - String message to log
    function logger.info(message)
        if LEVELS.INFO >= get_min_level() then
            print(format_log("INFO", module_name, message))
        end
    end
    
    --- Log a warning message
    -- Args:
    --   message - String message to log
    function logger.warn(message)
        if LEVELS.WARN >= get_min_level() then
            print(format_log("WARN", module_name, message))
        end
    end
    
    --- Log an error message
    -- Args:
    --   message - String message to log
    function logger.error(message)
        if LEVELS.ERROR >= get_min_level() then
            print(format_log("ERROR", module_name, message))
        end
    end
    
    --- Set this logger's minimum level
    -- Args:
    --   level - String: "DEBUG", "INFO", "WARN", or "ERROR", or nil to use global
    function logger.set_level(level)
        if level == nil then
            instance_min_level = nil
        elseif LEVELS[level] then
            instance_min_level = LEVELS[level]
        else
            error("Invalid log level: " .. tostring(level))
        end
    end
    
    return logger
end

--- Set global minimum log level
-- Args:
--   level - String: "DEBUG", "INFO", "WARN", or "ERROR"
function M.set_level(level)
    if LEVELS[level] then
        M.MIN_LEVEL = LEVELS[level]
    else
        error("Invalid log level: " .. tostring(level))
    end
end

return M

