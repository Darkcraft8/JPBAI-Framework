behaviorEx = {}
-- A bunch of extra function that arent focused on the behavior logic

-----------------------------------------------------------------------------------

-- Value
function behaviorEx.modValue(parameter, value)
    if not parameter or not value then return end
    if parameter and value then
        if type(config.getParameter(parameter, 0)) == "number" and type(value) == "number" then
            local newValue = config.getParameter(parameter, 0) + value
            activeItem.setInstanceValue(parameter, newValue)
        end
    end
end

function behaviorEx.valueDiff(parameter, value, diffType)
    if not parameter or not value then return false end
    if parameter and value then
        local diffType = args.diffType or "above" -- above, bellow or between
        local currentValue = config.getParameter(parameter, 0)
        
        if type(currentValue) ~= 'number' then sb.logError("[JPBAI Framework] %s ins't a number/value", parameter) return false end

        if diffType == "above" then
            if type(value) == "table" then
                return (currentValue > value[1])
            else
                return (currentValue > value)
            end
        elseif diffType == "bellow" then
            if type(value) == "table" then
                return (currentValue < value[1])
            else
                return (currentValue < value)
            end
        elseif diffType == "between" then
            if type(value) ~= "table" then sb.logError("[JPBAI Framework] %s ins't a table of two value", value) return false end
            if type(value[1]) ~= 'number' or type(value[2]) ~= 'number' then sb.logError("[JPBAI Framework] %s ins't a table of two value", value) return false end

            return ( (currentValue <= value[1]) == (currentValue >= value[2]) )
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
    local _poly = animator.partPoly(hitboxInfo.partName, hitboxInfo.polyName or "damageArea")
    local damageLine, damagePoly
    local knockback = event.knockback or 0
    local damage = event.baseDamage or 0
    if not _poly then
        sb.logError("[JPBAI Framework] behavior_hitbox | poly not found for %s | %s : %s", hitboxInfo, hitboxInfo.partName, hitboxInfo.polyName)
        --if player then if player.say then player.say(string.format("^cyan;[JPBAI Framework] behavior_hitbox | poly not found for %s : %s", hitboxInfo.partName, hitboxInfo.polyName)) end end
    return end
    if #_poly == 2 then damageLine = _poly else damagePoly = _poly end
    if damagePoly then if #damagePoly == 0 then damagePoly = nil damageLine = {{0, 0}, {0, 0}} end end

    if (event.damageScalingFunction or Weapon) and damage then damage = call({callback = (event.damageScalingFunction or "Weapon.basicDamage"), args = event}) end
    if knockback and event.directionalKnockback then knockback = knockbackMomentum(knockback, event.knockbackMode, (self.aimAngle or 0), self.aimDirection or 0) end
    
    local damageSource = {
        priority = event.priority or 0,
        duration = event.duration or event.timeout or 0.1,
        poly = damagePoly,
        line = damageLine,
        damage = damage,
        trackSourceEntity = event.trackSourceEntity,
        sourceEntity = activeItem.ownerEntityId(),
        team = activeItem.ownerTeam(),
        damageSourceKind = event.damageSourceKind,
        statusEffects = event.statusEffects or storage.damageStatusEffects,
        knockback = knockback or 0,
        rayCheck = not event.noRayCheck,
        damageRepeatGroup = damageRepeatGroup(event.timeoutGroup),
        damageRepeatTimeout = event.timeout or 0.1
    }
    if not self.damageSources then self.damageSources = {} end
    if not self.damageSources[behaviorName] then self.damageSources[behaviorName] = {} end
    table.insert(self.damageSources[behaviorName], damageSource)
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
    local monsterId = world.spawnMonster(event.type, pos, monsterCfg)
    --sb.logInfo("%s", pos) sb.logInfo("%s", event.type) sb.logInfo("%s", monsterCfg)
    --sb.logInfo("spawnMonster | %s, %s", status, message)
    if monsterId and event.trackMonster then
        setStorage(event.trackMonster, monsterId)
    else
        return monsterId
    end
    if not message then sb.logError("[JPBAI Framework] monster | %s", message) end
end

function behavior_projectile(event)
    local projectileCfg = event.parameter or {}
    local pos = spawnPosition(event)
    if event.scalingFunction or Weapon then -- Scale based on weapon stat or scaling function
        local callback = call({callback = event.scalingFunction or "Weapon.basicDamage", args = event})
        projectileCfg.power = projectileCfg.power or callback
        projectileCfg.powerMultiplier = projectileCfg.powerMultiplier or activeItem.ownerPowerMultiplier()
    end
    
    for i = 1, (event.count or 1) do
        local direction = event.direction or aimVector((event.inaccuracy or 0), event.aimAngle)
        local projectileId = world.spawnProjectile(event.type, pos, activeItem.ownerEntityId(), direction, event.posRelativeToOwner, projectileCfg)
        
        if event.storage then
            if type(event.storage) == "table" then
                setStorage(event.storage[i], projectileId)
                if i == (event.count or 1) then
                    return projectileId
                end
            else
                setStorage(event.storage, projectileId)
                return projectileId
            end
        end
    end
end

function setItemShieldPolys(partName, propertyName, scale)
    local shieldPoly = animator.partPoly(partName, propertyName)
    if scale then
        shieldPoly = poly.scale(shieldPoly, scale)
    end
    if shieldPoly then
        activeItem.setItemShieldPolys({shieldPoly})
    end
end

function resetItemShieldPolys()
    activeItem.setItemShieldPolys({})
end

function behaviorEx.callEntity(trackedEntity, functionName, variable)
    if trackedEntity then
        local entityId = config.getParameter(trackedEntity)
        if functionName and variable and entityId then
            if world.entityExists(entityId) then
                return world.callScriptedEntity(entityId, functionName, variable)
            end
        end
    end
end

function behaviorEx.entityExists(trackedEntity)
    if trackedEntity then
        local entityId = config.getParameter(trackedEntity)
        if entityId then
            return world.entityExists(entityId)
        end
    end
end

function behaviorEx.sendEntityMessage(trackedEntity, messageType, variable)
    if trackedEntity then
        local entityId = config.getParameter(trackedEntity)
        if messageType and variable and entityId then
            if world.entityExists(entityId) then
                if type(variable) == "table" then
                    world.sendEntityMessage(entityId, messageType, variable[1], variable[2], variable[3], variable[4], variable[5], variable[6], variable[7], variable[8], variable[9], variable[10])
                else
                    world.sendEntityMessage(entityId, messageType, variable)
                end
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
        if knockbackMode == "facing" then
            return {aimDirection * knockback[1], knockback[2]}
        else
            return knockback
        end
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



-----------------------------------------------------------------------------------
-- Math
function damageMath(baseDamage, weaponLevel, multiplier)

end -- Todo 

-----------------------------------------------------------------------------------
-- damageArea Handler

function behaviorEx.damageAreaUpdate(dt)
    local effectiveSources = {}
    for name, _ in pairs(self.damageSources or {}) do
        local remove = true
        for id, source in pairs(self.damageSources[name] or {}) do
            if source.duration > 0 then self.damageSources[name][id]["duration"] = source.duration - dt end
            if source.duration <= 0 then 
                self.damageSources[name][id] = nil 
            else 
                table.insert(effectiveSources, source)
                remove = false
            end
        end
        if remove then
            self.damageSources[name] = nil 
        end
    end
    
    table.sort(effectiveSources, function(a,b)
        return a.priority > b.priority
    end)
    activeItem.setItemDamageSources(jarray(effectiveSources or {}))
end

function behaviorEx.resetDamageArea()
    self.damageSources = {}
    activeItem.setItemDamageSources(jarray(self.damageSources or {}))
end
-----------------------------------------------------------------------------------

-- Other's
function spawnPosition(cfg)
    local originPos = copy(cfg.spawnPos) -- Possible | ownerHandPos, ownerPosFaceDirection, ownerPos, fireOffset, cursor
    local posOffset = (cfg.spawnOffset)
    local aimAngle, aimDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
    local ownerPos = entity.position()
    local handPos = activeItem.handPosition()
    local rotation = mcontroller.rotation()
    
    if originPos == "ownerHandPos" then
        return vec2.add(mcontroller.position(), vec2.rotate(activeItem.handPosition(), rotation))
    elseif originPos == "ownerPosFaceDirection" then
        return vec2.add(ownerPos, vec2.mul(posOffset or {0,0}, {aimDirection, 1}))
    elseif originPos == "ownerPos" then
        return vec2.add(ownerPos, posOffset or {0,0})
    elseif originPos == "fireOffset" then
        return vec2.add(mcontroller.position(), vec2.rotate(activeItem.handPosition(posOffset or {0, 0}), rotation))
    elseif originPos == "cursor" then
        return vec2.add(activeItem.ownerAimPosition(), posOffset or {0,0})
    end
end

function aimVector(inaccuracy, aimShift, aimAngle) -- straight out of gunFire.lua with one change
    local aimVector = vec2.rotate({1, 0}, (aimAngle or self.aimAngle or 0) + sb.nrand(inaccuracy, 0) + (aimShift or 0))
    aimVector[1] = aimVector[1] * mcontroller.facingDirection()
    return aimVector
end