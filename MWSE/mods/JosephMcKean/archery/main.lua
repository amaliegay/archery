-- AaarrrcheREEE by JosephMcKean
local mod = "AaarrrcheREEE"

local logging = require("JosephMcKean.archery.logging")
local log = logging.createLogger("main")

-- Initializing our mod
event.register(tes3.event.initialized, function()
	require("JosephMcKean.archery.events")
	log:info("Initialized!")
end)
