local logging = require("JosephMcKean.archery.logging")
local log = logging.createLogger("damage")

---This is a hack and not reliable
---@param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
local function getIfMoving(mobile) return mobile.isFalling or mobile.isJumping or mobile.isMovingBack or mobile.isMovingForward or mobile.isMovingLeft or mobile.isMovingRight or mobile.isRunning end

-- Store the damage value in reference data
---@param e damageEventData
local function damage(e)
	-- Check if the damage was caused by attack
	if not e.source == tes3.damageSource.attack then return end

	-- Check if the damage was caused by a projectile, but not by a spell, so it must be an arrow or a bolt
	if not e.projectile or e.magicSourceInstance then return end

	log:trace("before damage apply, health: %s", e.reference.mobile.health.current)
	log:trace("damage: %s", e.damage)

	-- if you're moving, you'll do 20% less damage.
	local isMoving = getIfMoving(e.attacker)
	if isMoving then
		e.damage = (1 - 0.2) * e.damage
		log:trace("after moving damage reduction: %s", e.damage)
	end

	-- Log the damage instead of double the damage since damage is before projectileHitActor
	e.reference.data.archeryDamage = e.damage
end

return damage
