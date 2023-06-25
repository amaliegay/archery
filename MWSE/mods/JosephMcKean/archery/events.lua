-- This is where we define all our events.
local controller = require("JosephMcKean.archery.controller")

event.register(tes3.event.damage, controller.damage)
event.register(tes3.event.loaded, controller.loaded)
event.register(tes3.event.projectileHitActor, controller.projectileHitActor, { priority = 36 }) -- before Pincushion
