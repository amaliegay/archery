local controller = {}

local config = require("JosephMcKean.archery.config")

local logging = require("JosephMcKean.archery.logging")
local log = logging.createLogger("controller")

---@class ArcheryTweaks.uiids
local uiids = { menuMulti = tes3ui.registerID("MenuMulti"), weaponBorder = tes3ui.registerID("MenuMulti_weapon_border") }

---@return boolean
---@return number
local function getMarksmanEquipment()
	if tes3.mobilePlayer.readiedAmmo then
		if tes3.mobilePlayer.readiedAmmo.object.type == tes3.weaponType.marksmanThrown then
			return true, tes3.mobilePlayer.readiedAmmoCount
		elseif tes3.mobilePlayer.readiedAmmo.object.type == tes3.weaponType.arrow then
			if tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon, type = tes3.weaponType.marksmanBow }) then
				return true, tes3.mobilePlayer.readiedAmmoCount
			elseif tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon, type = tes3.weaponType.marksmanCrossbow }) then
				return true, 0
			end
		elseif tes3.mobilePlayer.readiedAmmo.object.type == tes3.weaponType.bolt then
			if tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon, type = tes3.weaponType.marksmanCrossbow }) then
				return true, tes3.mobilePlayer.readiedAmmoCount
			elseif tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon, type = tes3.weaponType.marksmanBow }) then
				return true, 0
			end
		end
	elseif tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon, type = tes3.weaponType.marksmanBow }) then
		return true, 0
	elseif tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon, type = tes3.weaponType.marksmanCrossbow }) then
		return true, 0
	end
	return false, 0
end

local function createAmmoCountLabel()
	local menuMulti = tes3ui.findMenu(uiids.menuMulti)
	if not menuMulti then return end
	local ammoCountLabel = menuMulti:findChild(uiids.weaponBorder):createLabel({ id = "MenuMulti_ammo_count_label" })
	ammoCountLabel.absolutePosAlignX = 0.9
	ammoCountLabel.absolutePosAlignY = 0.95
	ammoCountLabel.color = { 0.875, 0.788, 0.624, 1.000 }
	timer.start({
		iterations = -1,
		duration = 0.5,
		callback = function()
			local hasMarksmanWeaponEquipped, ammoCount = getMarksmanEquipment()
			ammoCountLabel.visible = hasMarksmanWeaponEquipped
			ammoCountLabel.text = tostring(ammoCount)
		end,
	})
end

function controller.loaded(e) createAmmoCountLabel() end

---Check if helmet is a closed helmet
---@param helmet tes3armor
---@return boolean
local function getIfClosed(helmet)
	for _, part in ipairs(helmet.parts) do if part.type == tes3.activeBodyPart.head then return true end end
	return false
end

---@param actor tes3mobileActor|any
---@return number multi
local function helmetProtection(actor)
	log:trace("helmetProtection(%s)", actor.reference.id)
	local rating = 0
	local helmetStack = tes3.getEquippedItem({ actor = actor, objectType = tes3.objectType.armor, slot = tes3.armorSlot.helmet })
	if helmetStack then
		local helmet = helmetStack.object ---@cast helmet tes3armor
		local weightMax = 8
		local armorRatingMax = 45
		local isClosed = getIfClosed(helmet) and 1 or 0
		local weight = math.clamp(helmet.weight, 0, weightMax) / weightMax
		local weightClass = (helmet.weightClass + 1) / table.size(tes3.armorWeightClass)
		local armorRating = math.clamp(helmet.armorRating, 0, armorRatingMax) / armorRatingMax
		rating = isClosed + weight + weightClass + armorRating
		-- x-intercept at (2.195, 0)
		-- wearing anything better than a Chuzei Bonemold Helm
		-- which is a Closed Medium helmet with AR 17
		-- takes no additional headshot damage
		--
		-- Glass Helm, which is an Open Light helmet with AR 40
		-- has rating 1.41. Wearing it takes 3.41 times damage
		--
		-- y-intercept at (0, 18.685)
		-- not wearing helmet takes additional 18.685 times damage
	end
	return math.clamp(16.4 * math.exp(-0.8 * (rating - 0.4)) - 3.9, 0, math.huge) ---@type number
end

---@param actor tes3mobileActor|any
---@param equipment tes3equipmentStack?
local function disarm(actor, equipment)
	if not equipment then return end

	local reference = actor.reference
	if reference.baseObject.objectType ~= tes3.objectType.npc then return end

	local equipmentItemData = equipment.itemData

	-- Drop the equipment
	if equipmentItemData then
		log:trace("disarming %s", equipment.object.id)
		local createdReference = tes3.dropItem({ reference = reference, item = equipment.object, itemData = equipmentItemData, count = equipmentItemData.count })
		log:trace("dropped %s", createdReference)
	end
end

---@param actor tes3mobileActor|any
local function drainAttack(actor)
	actor.attackBonus = actor.attackBonus - 15
	timer.start({ duration = 15, callback = function() actor.attackBonus = actor.attackBonus + 15 end })
	log:trace("drainAttack(%s)", actor.reference.id)
end

---@param actor tes3mobileActor|any
local function sound(actor)
	tes3.applyMagicSource({ reference = actor, name = "Shot in the Hand", effects = { { id = tes3.effect.sound, duration = 15, min = 15, max = 15 } } })
	log:trace("sound(%s)", actor.reference.id)
end

---@param actor tes3mobileActor|any
---@return number duration
local function greavesProtection(actor)
	log:trace("greavesProtection(%s)", actor.reference.id)
	local rating = 0
	local greavesStack = tes3.getEquippedItem({ actor = actor, objectType = tes3.objectType.armor, slot = tes3.armorSlot.greaves })
	if greavesStack then
		local greaves = greavesStack.object ---@cast greaves tes3armor
		local armorRatingMin = 40
		local armorRating = math.clamp(greaves.armorRating, 0, armorRatingMin) / armorRatingMin
		rating = armorRating
		-- x-intercept at (1, 0)
		-- wearing anything better than a Glass Greaves
		-- which is with AR 40
		-- takes no additional knee shot damage
		--
		-- y-intercept at (0, 5)
		-- not wearing greaves takes additional 5 times damage
	end
	return math.clamp(-0.5 * math.exp(1.3 * (rating + 1)) + 6.8, 0, math.huge) ---@type number
end

---@param actor tes3mobileActor|any
local function slowdown(actor)
	local duration = math.ceil(greavesProtection(actor) * 2)
	if duration == 0 then return end
	local speed = actor.speed.current
	tes3.modStatistic({ reference = actor, attribute = tes3.attribute.speed, current = -speed })
	log:trace("slowdown %s at %s to %s for %s seconds", actor.reference.id, speed, actor.speed.current, duration)
	timer.start({
		duration = 1,
		callback = function()
			tes3.modStatistic({ reference = actor, attribute = tes3.attribute.speed, current = speed / duration })
			log:trace("recover speed to %s", actor.speed.current)
		end,
		iterations = duration - 1,
	})
end

local bipNodeNames = {}
local bipNodesData = {
	["Head"] = { damageMultiFormula = helmetProtection, nodeOffset = tes3vector3.new(0, 0, 1), radiusApproxi = 1, message = config.headshotMessage },
	["Neck"] = { damageMultiBase = 1.5, message = "A shot in the neck!" },
	["Weapon"] = {
		damageMultiBase = 1.0,
		radiusNode = "Bip01 R Hand",
		radius = 7.86,
		additionalEffectChance = 1,
		---@param actor tes3mobileActor
		additionalEffect = function(actor)
			-- log:trace("apply disarm weapon effect")
			-- disarm(actor, actor.readiedWeapon)
			drainAttack(actor)
		end,
		message = "A shot in the hand!",
	},
	["Bip01 L Finger1"] = {
		damageMultiBase = 1.0,
		radiusNode = "Bip01 L Hand",
		radius = 7.86,
		additionalEffectChance = 1,
		---@param actor tes3mobileActor
		additionalEffect = function(actor)
			-- disarm(actor, actor.torchSlot) 
			sound(actor)
		end,
		message = "A shot in the hand!",
	},
	["Left Knee"] = {
		damageMultiFormula = greavesProtection,
		nodeOffset = tes3vector3.new(0, 0, 6),
		radius = 6,
		additionalEffectChance = 1,
		additionalEffect = slowdown,
		message = "An arrow to the knee!",
	},
	["Right Knee"] = {
		damageMultiFormula = greavesProtection,
		nodeOffset = tes3vector3.new(0, 0, 6),
		radius = 6,
		additionalEffectChance = 1,
		additionalEffect = slowdown,
		message = "An arrow to the knee!",
	},
}
for bipNodeName, _ in pairs(bipNodesData) do table.bininsert(bipNodeNames, bipNodeName) end

---@class archery.calcDistPointToLine.params
---@field point tes3vector3
---@field lineInit tes3vector3 a point of the line
---@field lineDirection tes3vector3 the unit vector in the direction of the line

-- Calculate the distance from a point to a line,
--
-- which is represented in vector form: x = a + t * n,
--
-- where x gives the locus of the line, a is the `lineInit`, t is the scalar, n is `lineDirection`.
---@param e archery.calcDistPointToLine.params
---@return number distance
local function calcDistPointToLine(e)
	log:trace("calcDistPointToLine({ point = %s, lineInit = %s, lineDirection = %s })", e.point, e.lineInit, e.lineDirection)
	-- The distance of `point` to line x is denoted as `distance`
	local distance ---@type number
	-- `point - lineInit` is a vector from `point` to point `lineInit`
	--
	-- Then `(point - lineInit) * lineDirection` is the projected length onto the line
	local projectedLength = (e.point - e.lineInit):dot(e.lineDirection)
	-- So `lineInit + projectedLength * lineDirection` is a vector that is the projection of `point - lineInit` onto the line
	--
	-- and represents the point on the line closest to point
	local closestPoint = e.lineInit + e.lineDirection * projectedLength
	-- Thus, `point - closestPoint` is the component of `point - lineInit` perpendicular to the line
	local shortestVector = e.point - closestPoint
	distance = shortestVector:length()

	return distance
end

---Calculate which node is the clocest to the line the arrow is on
---@param e projectileHitActorEventData
---@return string closestBipNodeName 
---@return number closestDistance 
local function getClosestBipNode(e)
	log:trace("getClosestBipNode(e)")
	local closestBipNodeName = ""
	local closestDistance = math.huge
	for _, bipNodeName in ipairs(bipNodeNames) do
		local bipNode = e.target.sceneNode:getObjectByName(bipNodeName) ---@cast bipNode niNode
		log:trace("local bipNode = e.target.sceneNode:getObjectByName(%s)", bipNodeName)
		if bipNode then
			local offset = bipNodesData[bipNodeName].nodeOffset or tes3vector3.new()
			local distance = calcDistPointToLine({ point = bipNode.worldBoundOrigin + offset, lineInit = e.collisionPoint, lineDirection = e.mobile.velocity:normalized() })
			if distance < closestDistance then
				closestBipNodeName = bipNodeName
				closestDistance = distance
			end
		end
	end
	return closestBipNodeName, closestDistance
end

-- Get the worldBoundRadius of bip node of reference
---@param ref tes3reference
---@param bipNodeName string
---@return number
local function getBipNodeRadius(ref, bipNodeName)
	log:trace("getBipNodeRadius(%s, %s)", ref, bipNodeName)
	if not ref.data.bipNodesWorldBoundRadius then
		ref.data.bipNodesWorldBoundRadius = {}
		for bnName, bipNodeData in pairs(bipNodesData) do
			if not bipNodeData.radius then
				local name = bipNodeData.radiusNode or bnName
				local bp = ref.sceneNode:getObjectByName(name)
				log:trace("bp = %s", bp)
				log:trace("bp.worldBoundRadius = %s", bp and bp.worldBoundRadius)
				ref.data.bipNodesWorldBoundRadius[name] = bp and bp.worldBoundRadius
			end
		end
	end
	bipNodeName = bipNodesData[bipNodeName] and bipNodesData[bipNodeName].radiusNode or bipNodeName
	return ref.data.bipNodesWorldBoundRadius[bipNodeName]
end

---@param actor tes3mobileActor
---@param bipNodeName string
---@return number
local function getDamageMulti(actor, bipNodeName)
	log:trace("getDamageMulti(%s, %s)", actor.reference.id, bipNodeName)
	local multi = 0
	local bipNodeData = bipNodesData[bipNodeName]
	local damageMultiBase = bipNodeData.damageMultiBase or 1
	multi = damageMultiBase - 1
	local damageMultiFormula = bipNodeData.damageMultiFormula
	if damageMultiFormula then multi = damageMultiFormula(actor) end
	log:trace("damage multiplier = %s", multi)
	return multi
end

-- Apply additional damage
---@param e projectileHitActorEventData
---@param bipNodeName string
local function applyDamage(e, bipNodeName)
	log:trace("applyDamage(e, %s)", bipNodeName)
	local actor = e.target.mobile ---@cast actor tes3mobileActor|any
	if actor.isDead then return end
	if not e.target.data.archeryDamage then return end
	local multi = getDamageMulti(actor, bipNodeName)
	if multi > 0 then
		local damage = multi * e.target.data.archeryDamage ---@type number
		local playerAttack = e.firingReference == tes3.player
		timer.delayOneFrame(function()
			local results = actor:applyDamage({ damage = damage, applyDifficulty = true, playerAttack = playerAttack })
			log:trace("additional %s damage: %s", multi, results)
			log:trace("after damage apply, health: %s", e.target.mobile.health.current)
		end, timer.real)
	end
end

-- Apply additional effect
---@param e projectileHitActorEventData
---@param bipNodeName string
local function applyEffect(e, bipNodeName)
	local actor = e.target.mobile ---@cast actor tes3mobileActor|any
	if actor.isDead then return end
	local additionalEffect = bipNodesData[bipNodeName].additionalEffect
	if not additionalEffect then return end
	local additionalEffectChance = bipNodesData[bipNodeName].additionalEffectChance
	local roll = math.random()
	log:trace("rolled %s, %sapply effect", roll, roll > additionalEffectChance and "skip " or "")
	if not additionalEffectChance or roll > additionalEffectChance then return end
	timer.delayOneFrame(function() additionalEffect(actor) end, timer.real)
end

---Check if the distance from closest bip node to the arrow line is shorter than bip node radius.
---If so, apply additional damage
---@param e projectileHitActorEventData
function controller.projectileHitActor(e)
	log:debug("projectileHit %s", e.target)
	local closestBipNodeName, closestDistance = getClosestBipNode(e)
	if closestBipNodeName == "" then return end
	local bipNodeData = bipNodesData[closestBipNodeName]
	--- Compatibility with Pincushion which attach arrow to body parts therefore changing worldBoundRadius
	local bipNodeWorldBoundRadius = getBipNodeRadius(e.target, closestBipNodeName)
	local radius = bipNodeData.radius
	if not radius then
		local radiusApproxi = bipNodeData.radiusApproxi or 0
		radius = bipNodeWorldBoundRadius + radiusApproxi
	end
	log:trace("closest distance to %s = %s", closestBipNodeName, closestDistance)
	log:trace("%s radius = %s", closestBipNodeName, radius)
	if closestDistance <= radius then
		local message = bipNodeData.message
		log:debug(message)
		tes3.messageBox(message)
		applyDamage(e, closestBipNodeName)
		applyEffect(e, closestBipNodeName)
	end
end

---This is a hack and not reliable
---@param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
local function getIfMoving(mobile) return mobile.isFalling or mobile.isJumping or mobile.isMovingBack or mobile.isMovingForward or mobile.isMovingLeft or mobile.isMovingRight or mobile.isRunning end

-- Store the damage value in reference data
---@param e damageEventData
function controller.damage(e)
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

local function getBowDrawFatigueCost() return 10 end

local function ArcherSim(e)
	local mobilePlayer = tes3.mobilePlayer
	local actionData = mobilePlayer.actionData
	if actionData.animationAttackState ~= 2 then return end
	if mobilePlayer.fatigue.current > getBowDrawFatigueCost() then return end
	actionData.animationAttackState = tes3.animationState.hit
	tes3.messageBox({ message = "You are too fatigued to draw a bow!" })
end

---@param e mouseButtonDownEventData
function controller.mouseButtonDown(e)
	if tes3ui.menuMode() then return end
	if e.button ~= 0 then return end
	if not tes3.mobilePlayer.weaponDrawn then return end
	local readiedWeapon = tes3.mobilePlayer.readiedWeapon
	if not readiedWeapon then return end
	if readiedWeapon.object.type ~= tes3.weaponType.marksmanBow then return end
	-- event.register("simulate", ArcherSim)
end
-- event.register("mouseButtonDown", controller.mouseButtonDown)

return controller
