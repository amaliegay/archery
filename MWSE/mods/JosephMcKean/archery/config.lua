local defaults = { logLevel = "INFO", showMessages = true, headshotMessage = "GOTTEM!", onlyHeadshotMessage = false }
---@class archery.config
---@field logLevel mwseLoggerLogLevel
---@field showMessages boolean
---@field headshotMessage string
---@field onlyHeadshotMessage boolean
local config = mwse.loadConfig("The Art of Archery", defaults)
return config
