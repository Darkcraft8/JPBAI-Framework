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

local test = {}
function Weapon.update(dt) 
    if debugHitScan then
        for i, cfg in pairs(debugHitScan or {}) do 
            if cfg.type == "line" then 
                world.debugLine(cfg.pos[1], cfg.pos[2], cfg.color or {255 * (i / #debugHitScan), 0, 0})
            elseif cfg.type == "text" then
                world.debugText(cfg.string, cfg.pos, cfg.color or {255 * (i / #debugHitScan), 0, 0})
            elseif cfg.type == "point" then
                world.debugPoint(cfg.pos, cfg.color or {255 * (i / #debugHitScan), 0, 0})
            end
            
        end
    end
end
-- a very basic hitscan
function Weapon.hitscan(projectileType, projectileParameters, range, spawnPos, inaccuracy, baseDamage, damageScalingFunction, damageSourceKind, hitboxName, extra)
    --test = table.pack(projectileType, projectileParameters, range, spawnPos, inaccuracy, baseDamage, damageScalingFunction, damageSourceKind, hitboxName, extra)
    local extra = extra or {}
    local projectileConfig = root.projectileConfig(projectileType)
    if damageScalingFunction or Weapon then -- Scale based on weapon stat or scaling function
        local callback = call({callback = damageScalingFunction or "Weapon.basicDamage", args = {baseDamage = baseDamage, count = 1}})
        projectileParameters.power = projectileParameters.power or callback
        projectileParameters.powerMultiplier = projectileParameters.powerMultiplier or activeItem.ownerPowerMultiplier()
    end

    local configParam = function(paramName, defaultValue)
        return projectileParameters[paramName] or projectileConfig[paramName] or defaultValue
    end
    local tragectory = hitscan.calculateTragectory(projectileType, projectileParameters, range, spawnPos, inaccuracy)
    debugHitScan = {}

    local _lastPos = false
    local collisionProj = copy(projectileParameters)
    collisionProj.actionOnReap = jarray({})
    collisionProj.timeToLive = 0
    collisionProj.speed = 1
    collisionProj.clientEntityMode = "ClientPresenceMaster"
	collisionProj.processing = "?multiply=fff0"
    for i, cfg in pairs(tragectory) do
        local _magnitude = math.max(world.magnitude(cfg.pos[1], cfg.pos[2]), 0)
        table.insert(debugHitScan, {type = "line", pos = {cfg.pos[1], cfg.pos[2]}, color = "yellow"})
        table.insert(debugHitScan, {type = "point", pos = vec2.add(cfg.pos[1], vec2.withAngle(vec2.angle(cfg.aimVector), _magnitude * 0.5)), color = "yellow"})
        
        -- entity hit
        local entList = world.entityLineQuery(world.xwrap(cfg.pos[1]), world.xwrap(cfg.pos[2]), {
            withoutEntityId = activeItem.ownerEntityId(),
            order = "nearest"
        })
        local validEnt = false
        for i = 1, #entList do
            local targetEntity = entList[i]
            local validType = (world.entityType(targetEntity) == "monster") or (world.entityType(targetEntity) == "player") or (world.entityType(targetEntity) == "npc") or (world.entityType(targetEntity) == "vehicle") or (world.entityType(targetEntity) == "object")
            if world.entityCanDamage(activeItem.ownerEntityId(), targetEntity) and validType then --need to find a way to reduce the lenght
                local hitpos = world.entityPosition(targetEntity)
                local mag = world.magnitude(hitpos, cfg.pos[1])
                local projPos = world.xwrap(vec2.add(cfg.pos[1], vec2.withAngle(vec2.angle(cfg.aimVector), mag)))
                validEnt = true
                local shouldStop = (not configParam("piercing")) and (not (world.entityType(targetEntity) == "object"))
                --sb.logInfo("piercing %s, isObject %s, shouldStop %s", (configParam("piercing")), ((world.entityType(targetEntity) == "object")), shouldStop)
                if shouldStop then
                    --sb.logInfo("stopped at ent %s|%s", targetEntity, world.entityType(targetEntity))
                    validEnt = projPos
                    break
                else
                    validEnt = false
                    world.spawnProjectile(projectileType, projPos, activeItem.ownerEntityId(), cfg.aimVector, false, jarray(collisionProj or {})) 
                end
            end
        end

        -- Visual
        local extra = copy(extra)
        local alpha = ((1 - (i / #tragectory)) * 0.25)
        extra.trailColor[4] = extra.trailColor[4] * alpha
        local visualParam = {
            clientEntityMode = "ClientPresenceMaster",
            speed = 0,
            timeToLive = 0,
            processing = "?multiply=fff0",
            damageTeam = { type = "ghostly" },
            actionOnReap = {
                {
                    rotate = true,
                    specification = {
                        fade = 1,
                        approach = {0, 0},
                        layer = "front",
                        destructionAction = "shrink",
                        type = "streak",
                        destructionTime = math.max(0.0625 + (i * 0.0625), 1),
                        size = math.min(0.125 + (math.max(#tragectory - i, 0) * 0.125), 1.25),

                        initialVelocity = {0.1, 0},
                        finalVelocity = {0, 0},
                        timeToLive = 0,
                        length = (_magnitude * 8),
                        variance = {
                            size = 0.0625
                        },
						collidesForeground= false,
						collidesLiquid= false,
                        flip = false,
                        fullbright = extra.trailFullbright or true,
                        color = extra.trailColor or {255, 255, 255, 255 * alpha},
                        light = extra.trailLight or {0, 0, 0},
                        position = {_magnitude, 0}
                    },
                    action = "particle"
                }
            }
        }
        if type(validEnt) == "table" then
            local mag = world.magnitude(validEnt, cfg.pos[1])
            visualParam.actionOnReap[1].specification.position[1] = mag
            visualParam.actionOnReap[1].specification.length = mag * 8
        end
        world.spawnProjectile("invisibleprojectile", world.xwrap(cfg.pos[1]), activeItem.ownerEntityId(), cfg.aimVector, false, jarray(visualParam or {}))
        --

        -- last hit/collision
        local lastPoint = (i == #tragectory)
        if validEnt and (not configParam("piercing")) then lastPoint = true end
        if lastPoint then
            local param = copy(projectileParameters)
            param.timeToLive = 0
            param.speed = 20
            param.clientEntityMode = "ClientPresenceMaster"
			param.processing = "?multiply=fff0"
            if type(validEnt) == "table" then
                world.spawnProjectile(projectileType, validEnt, activeItem.ownerEntityId(), cfg.aimVector, false, jarray(param or {}))
            else
                local n = world.magnitude(cfg.pos[1], cfg.pos[2])
                local endPos = world.xwrap(vec2.add(cfg.pos[1], vec2.withAngle(vec2.angle(cfg.aimVector), n * 0.975)))
                
                world.spawnProjectile(projectileType, endPos, activeItem.ownerEntityId(), cfg.aimVector, false, jarray(param or {}))
            end
            break
        end
        _lastPos = vec2.add(_lastPos or {0, 0}, vec2.withAngle(vec2.angle(cfg.aimVector), _magnitude))
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