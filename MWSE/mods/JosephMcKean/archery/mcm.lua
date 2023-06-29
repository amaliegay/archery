local config = require("JosephMcKean.archery.config")

local logging = require("JosephMcKean.archery.logging")

local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "The Art of Archery" })
	template:saveOnClose("The Art of Archery", config)
	local settings = template:createSideBarPage({ label = "Settings" })
	settings:createTextField({
		label = "Headshot Message",
		description = "Default message: GOTTEM! \n\n(imagine VvardenfellStormSage commentary-ing every headshot)",
		variable = mwse.mcm.createTableVariable { id = "headshotMessage", table = config },
	})
	settings:createDropdown({
		label = "Log Level",
		description = "Set the log level.",
		options = {
			{ label = "TRACE", value = "TRACE" },
			{ label = "DEBUG", value = "DEBUG" },
			{ label = "INFO", value = "INFO" },
			{ label = "ERROR", value = "ERROR" },
			{ label = "NONE", value = "NONE" },
		},
		variable = mwse.mcm.createTableVariable { id = "logLevel", table = config },
		callback = function(self) for _, logger in pairs(logging.loggers) do logger:setLogLevel(self.variable.value) end end,
	})
	template:register()
end

event.register("modConfigReady", registerModConfig)
