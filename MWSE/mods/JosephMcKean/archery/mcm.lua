local config = require("JosephMcKean.archery.config")

local logging = require("JosephMcKean.archery.logging")

local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "The Art of Archery" })
	template:saveOnClose("The Art of Archery", config)
	local settings = template:createSideBarPage({ label = "Settings" })
	local categoryMessages = settings:createCategory({ label = "Messages" })
	categoryMessages:createYesNoButton({
		label = "Show messages?",
		description = "Do you want a message box to popup every time you headshot?",
		variable = mwse.mcm.createTableVariable { id = "showMessages", table = config },
	})
	categoryMessages:createYesNoButton({
		label = "Only show headshot message?",
		description = "Do you want a message box to popup only when you headshot, and not a shot in the neck and arrow to the knee?",
		variable = mwse.mcm.createTableVariable { id = "onlyHeadshotMessage", table = config },
	})
	categoryMessages:createTextField({
		label = "Headshot Message",
		description = "Default message: GOTTEM! \n\n(imagine VvardenfellStormSage commentary-ing every headshot)",
		variable = mwse.mcm.createTableVariable { id = "headshotMessage", table = config },
	})
	local categoryLogLevel = settings:createCategory({ label = "Log Level" })
	categoryLogLevel:createDropdown({
		label = "Set the log level",
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
