-- general function for weapon's --
Weapon = {}
local debugHitScan = {}
function Weapon.init()
    -- Usual Culprit
    Weapon.damageLevelMultiplier = config.getParameter("damageLevelMultiplier", root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1)))
    Weapon.level = config.getParameter("level", 1)
    Weapon.inaccuracy = 0
    animator.setGlobalTag("elementalType", Weapon.elementalType or "")
    table.insert(updateFunc, "Weapon.update")
end

function Weapon_uninit() end

function Weapon.update(dt) 
    if debugHitScan then
        for i, pos in pairs(debugHitScan or {}) do 
            world.debugLine(pos[1], pos[2], {255 * (i / #debugHitScan), 0, 0})
        end
    end
end

function Weapon.hitscan(projectileType, projectileParameters, range, spawnPos, inaccuracy)
    --[[
        maybe calculate range by the projectile timeToLive and Speed
    ]]
    local physicsConfig = root.assetJson("/projectiles/physics.config")
    local projectileConfig = root.projectileConfig(projectileType)
    local configParam = function(paramName, defaultValue)
        return projectileParameters[paramName] or projectileConfig[paramName] or defaultValue
    end

    local offset = offset or {0, 0}
    local bounces = configParam("bounces", 0)
    local movementSettings = util.mergeTable(configParam("movementSettings", {}), physicsConfig[configParam("physics", "default")])
    local movementCalulationStep = 0.25
    local calRange = function(speed, timeToLive)
        return (speed * timeToLive)
    end
    local range = (range or calRange(configParam("speed", 250), configParam("timeToLive", 5)))
    local stepRange = range * movementCalulationStep
    local stepAmount = math.min(range / stepRange)
    sb.logInfo("%s, %s, %s", stepAmount, stepRange, (range or calRange(configParam("speed", 250), configParam("timeToLive", 5))))
    local prevHitPos
    for i = 1, stepAmount do
        local range = copy(stepRange) / 8
        local direction = aimVector((inaccuracy or 0))
        local startPos = copy(prevHitPos or spawnPos)
        local grav = world.gravity(startPos)
        local endPos = vec2.add(startPos, vec2.rotate({range, 0}, vec2.angle(direction)))
        if grav > 0 then
            local p = i / stepAmount
            endPos[2] = endPos[2] + ( (range * (-grav * script.updateDt())) * p)
        end
        local validTarget = function(startPos, endPos)
            local entList = world.entityLineQuery(startPos, endPos, {
                withoutEntityId = entity.id(),
                order = "nearest"
            })
            local target
            for i = 1, #entList do 
                if world.entityCanDamage(activeItem.ownerEntityId(), entList[i]) then --need to find a way to reduce the lenght
                    local hitpos = world.entityPosition(entList[i])
                    local mag = world.magnitude(hitpos, endPos)
                    return vec2.add(startPos, vec2.rotate({mag, 0}, vec2.angle(direction)))
                end
            end
        end
        local hitPos = validTarget(startPos, endPos) or world.lineCollision(startPos, endPos) or endPos
        world.debugLine(startPos, hitPos, "red")
        table.insert(debugHitScan, {startPos, hitPos})
        sb.setLogMap("[JPBAI] Item "..item.name()..":"..item.friendlyName().."-"..activeItem.hand() .. ":HitPos", "%s", hitPos)
        if hitPos and (bounces == 0) then break end
        prevHitPos = copy(hitPos)
    end
end

-- Scaling
function Weapon.damagePerShot(args)
    local mathResult = args.baseDamage or 1
    mathResult = mathResult * ((Weapon.damageLevelMultiplier or 1.0) / (args.count or 1.0)) * activeItem.ownerPowerMultiplier()
    
    return mathResult
end
function Weapon.basicDamage(args)
    local mathResult = args.baseDamage or 1
    mathResult = mathResult * (Weapon.damageLevelMultiplier or 1.0) * activeItem.ownerPowerMultiplier()

    return mathResult
end

function Weapon.energyPerAction(args)
    local mathResult = args.baseCost or 1
    if mathResult ~= 0 then 
        mathResult = mathResult * (1.0 / (args.count or 1.0))
    end
    return mathResult
end

-- Utility
function Weapon.canConsumeItem(ItemNameOrTable)
    if type(ItemNameOrTable) == "string" then
        if player.hasCountOfItem(ItemNameOrTable , true) == 0 then return false else return true end
    else
        if ItemNameOrTable.count then
            if player.hasCountOfItem(ItemNameOrTable , true) == 0 then return false else return true end
        else
            for index, item in ipairs(ItemNameOrTable) do
                if player.hasCountOfItem(item, true) == 0 then return false end
            end return true
        end
    end
end

function Weapon.consumeItem(ItemNameOrTable)
    if type(ItemNameOrTable) == "string" then
        return player.consumeItem(ItemNameOrTable , true, true)
    else
        if ItemNameOrTable.count then
            return player.consumeItem(ItemNameOrTable , true, true)
        else
            local result = true
            for index, item in ipairs(ItemNameOrTable) do 
                if not player.consumeItem(item , true, true) then result = false end
            end return result
        end
    end
end