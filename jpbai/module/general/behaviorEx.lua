behaviorEx = {}
-- A bunch of extra function that arent focused on the behavior logic

-----------------------------------------------------------------------------------

function behaviorEx.getParameter(args) -- bridge for getParameter/getInstanceValue
    if not args then return end
    if args.parameter ~= nil then return config.getParameter(args.parameter, args.defaultValue) end
end

function behaviorEx.setParameter(args) -- bridge for setParameter/setInstanceValue
    if not args then return end
    if args.parameter ~= nil and args.value ~= nil then activeItem.setInstanceValue(args.parameter, args.value) end
end

-----------------------------------------------------------------------------------

-- Value
function behaviorEx.modValue(args)
    if not args then return end
    if args.parameter and args.value then
        if type(config.getParameter(args.parameter, 0)) == "number" and type(args.value) == "number" then
            local newValue = config.getParameter(args.parameter, 0) + args.value
            activeItem.setInstanceValue(args.parameter, newValue)
        end
    end
end

function behaviorEx.valueDiff(args)
    if not args then return false end
    if args.parameter and args.value then
        local diffType = args.diffType or "above" -- above, bellow or between
        local currentValue = config.getParameter(args.parameter, 0)
        if type(currentValue) ~= 'number' then sb.logError("[JPBAI Framework] %s ins't a number/value", args.parameter) return false end
        if diffType == "above" then
            if type(args.value) == "table" then
                return (currentValue > args.value[1])
            else
                return (currentValue > args.value)
            end
        elseif diffType == "bellow" then
            if type(args.value) == "table" then
                return (currentValue < args.value[1])
            else
                return (currentValue < args.value)
            end
        elseif diffType == "between" then
            if type(args.value) ~= "table" then sb.logError("[JPBAI Framework] %s ins't a table of two value", args.value) return false end
            if type(args.value[1]) ~= 'number' or type(args.value[2]) ~= 'number' then sb.logError("[JPBAI Framework] %s ins't a table of two value", args.value) return false end

            return ( (currentValue <= args.value[1]) == (currentValue >= args.value[2]) )
        end
    end
end

-----------------------------------------------------------------------------------

function behaviorEx.emptyTable(args) -- Todo
end

function behaviorEx.setDamageStatusEffects(args)
    if args then
        storage.damageStatusEffects = args
    else
        storage.damageStatusEffects = {}
    end
end
-----------------------------------------------------------------------------------
-- Events
function behavior_hitbox(event) -- todo
    local hitboxInfo = event.hitbox or {}
    local poly = animator.partPoly(hitboxInfo.partName, hitboxInfo.polyName or "damageArea")
    local damageLine, damagePoly
    local knockback = event.knockback or 0
    local damage = event.baseDamage or 0
    if not poly then sb.logError("[JPBAI Framework] behavior_hitbox | poly not found for %s : %s", hitboxInfo.partName, hitboxInfo.polyName) return end
    if #poly == 2 then damageLine = poly else damagePoly = poly end
    if (event.damageScalingFunction or Weapon) and damage then damage = call({callback = (event.damageScalingFunction or "Weapon.basicDamage"), args = event}) end    
    if knockback and event.directionalKnockback then knockback = knockbackMomentum(knockback, event.knockbackMode, self.aimAngle or 0, self.aimDirection or 0) end
    local damageSource = {
        poly = damagePoly,
        line = damageLine,
        damage = damage,
        trackSourceEntity = event.trackSourceEntity,
        sourceEntity = activeItem.ownerEntityId(),
        team = activeItem.ownerTeam(),
        damageSourceKind = event.damageSourceKind,
        statusEffects = event.statusEffects or storage.damageStatusEffects,
        knockback = knockback or 0,
        rayCheck = true,
        damageRepeatGroup = damageRepeatGroup(event.timeoutGroup),
        damageRepeatTimeout = event.timeout or 0.1
    }
    if not self.damageSources then self.damageSources = {} end
    if not self.damageSourcesTimer then self.damageSourcesTimer = {} end
    self.damageSources[behaviorName] = damageSource
    self.damageSourcesTimer[behaviorName] = event.duration or event.timeout or 0.1
end

function behavior_monster(event) -- function to spawn monster based on weapon level or scaling function
    local monsterCfg = event.parameter or {}
    if event.level then 
        monsterCfg.level = event.level
    else 
        monsterCfg.level = 1
        if event.scalingFunction then -- Scale based on weapon stat or scaling function
            monsterCfg.level = call({callback = event.scalingFunction, args = event})
        elseif Weapon then
            monsterCfg.level = Weapon.level
        end
    end
    local pos = spawnPosition(event)

    monsterCfg.parentEntity = entity.id()
    local monsterId, message = pcall(world.spawnMonster(event.type, pos, monsterCfg))
    --sb.logInfo("%s", pos) sb.logInfo("%s", event.type) sb.logInfo("%s", monsterCfg)
    --sb.logInfo("spawnMonster | %s, %s", status, message)
    if monsterId and event.trackMonster then
        activeItem.setInstanceValue(event.trackMonster, monsterId)
    end
    if not message then sb.logError("[JPBAI Framework] monster | %s", message) end
end

function behavior_projectile(event)
    local projectileCfg = event.parameter or {}
    local pos = spawnPosition(event)
    if event.scalingFunction or Weapon then -- Scale based on weapon stat or scaling function
        local callback = call({callback = event.scalingFunction or "Weapon.basicDamage", args = event})
        projectileCfg.power = callback
        projectileCfg.powerMultiplier = activeItem.ownerPowerMultiplier()
    end
    for i = 1, (event.count or 1) do
        local direction = aimVector((event.inaccuracy or 0))
        local projectileId = world.spawnProjectile(event.type, pos, activeItem.ownerEntityId(), direction, event.posRelativeToOwner, projectileCfg)
    end
end

function behaviorEx.velocity(event)

end

function behaviorEx.callEntity(event)
    if event.trackedEntity then
        local functionName, variable = event.functionName, event.variable
        local entityId = config.getParameter(event.trackedEntity)
        if functionName and variable and entityId then
            if world.entityExists(entityId) then
                world.callScriptedEntity(entityId, functionName, variable)
            end
        end
    end
end

function behaviorEx.sendEntityMessage(event)
    if event.trackedEntity then
        local functionName, variable = event.messageType, event.variable
        local entityId = config.getParameter(event.trackedEntity)
        if functionName and variable and entityId then
            if world.entityExists(entityId) then
                world.sendEntityMessage(entityId, messageType, variable)
            end
        end
    end
end

-- used to force a behavior change for things that require it
-- ex: a parry that change the next few attack when succesfull
-- eventOnDamageTaken -> eventOnInit -> setBehavior "secondaryStance" or "heal"
function behaviorEx.setBehavior(event) 
    setBehavior(event.behaviorName)
end
-----------------------------------------------------------------------------------

-- Weapon.Lua Func
function damageRepeatGroup(mode)
    mode = mode or ""
    return activeItem.ownerEntityId() .. config.getParameter("itemName") .. activeItem.hand() .. mode
end

function knockbackMomentum(knockback, knockbackMode, aimAngle, aimDirection)
    knockbackMode = knockbackMode or "aim"
  
    if type(knockback) == "table" then
      return knockback
    end
  
    if knockbackMode == "facing" then
      return {aimDirection * knockback, 0}
    elseif knockbackMode == "aim" then
      local aimVector = vec2.rotate({knockback, 0}, aimAngle)
      aimVector[1] = aimDirection * aimVector[1]
      return aimVector
    end
    return knockback
end

-----------------------------------------------------------------------------------
-- Math
function damageMath(baseDamage, weaponLevel, multiplier)

end -- Todo 

-----------------------------------------------------------------------------------
-- damageArea Handler

function behaviorEx.damageAreaUpdate(dt)
    local effectiveSources = {}
    for name, timer in pairs(self.damageSourcesTimer or {}) do 
        if timer > 0 then self.damageSourcesTimer[name] = timer - dt end
        if timer <= 0 then self.damageSourcesTimer[name] = nil self.damageSources[name] = nil else table.insert(effectiveSources, self.damageSources[name]) end
    end
    activeItem.setItemDamageSources(effectiveSources or {})
end
-----------------------------------------------------------------------------------

-- Other's
function spawnPosition(cfg)
    local originPos = cfg.spawnPos -- Possible | ownerHandPos, ownerPosFaceDirection, ownerPos
    local posOffset = cfg.spawnOffset
    local aimAngle, aimDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
    local ownerPos = entity.position()
    local handPos = activeItem.handPosition()

    if originPos == "ownerHandPos" then
        return vec2.add(mcontroller.position(), activeItem.handPosition())
    elseif originPos == "ownerPosFaceDirection" then
        return vec2.mul(vec2.add(ownerPos, posOffset or {0,0}), {aimDirection, 1})
    elseif originPos == "ownerPos" then
        return vec2.add(ownerPos, posOffset or {0,0})
    elseif originPos == "fireOffset" then
        if posOffset then
            return vec2.add(mcontroller.position(), activeItem.handPosition(posOffset))
        else
            return firePosition()
        end
    elseif originPos == "cursor" then
        return vec2.add(activeItem.ownerAimPosition(), posOffset or {0,0})
    end
end

function aimVector(inaccuracy) -- straight out of gunFire.lua with one change
    local aimVector = vec2.rotate({1, 0}, (self.aimAngle or 0) + sb.nrand(inaccuracy, 0))
    aimVector[1] = aimVector[1] * mcontroller.facingDirection()
    return aimVector
end