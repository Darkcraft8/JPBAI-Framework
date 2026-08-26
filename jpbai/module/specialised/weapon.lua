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
            local travelPoint = {cfg.pos, (debugHitScan[i + 1] or {}).pos or cfg.pos}
            if cfg.type == "line" then 
                world.debugLine(travelPoint[1], travelPoint[2], cfg.color or {255 * (i / #debugHitScan), 0, 0})
            elseif cfg.type == "text" then
                world.debugText(cfg.string, cfg.pos, cfg.color or {255 * (i / #debugHitScan), 0, 0})
            elseif cfg.type == "point" then
                world.debugPoint(cfg.pos, cfg.color or {255 * (i / #debugHitScan), 0, 0})
            end
            
        end
    end
end
-- a very basic hitscan
function Weapon.hitscan(projectileType, projectileParameters, range, spawnPos, inaccuracy, baseDamage, damageScalingFunction, damageSourceKind, extra, maxSegmentRange, isCoroutine)
    --sb.logInfo("%s, %s, %s, %s, %s, %s, %s, %s, %s, %s", projectileType, projectileParameters, range, spawnPos, inaccuracy, baseDamage, damageScalingFunction, damageSourceKind, extra, maxSegmentRange)
    local dt = script.updateDt()
    local extra = extra or {}
    local projectileConfig = root.projectileConfig(projectileType)
    if damageScalingFunction or Weapon then -- Scale based on weapon stat or scaling function
        local callback = call({callback = damageScalingFunction or "Weapon.basicDamage", args = {baseDamage = baseDamage, count = 1}})
        projectileParameters.power = projectileParameters.power or callback
        projectileParameters.powerMultiplier = projectileParameters.powerMultiplier or activeItem.ownerPowerMultiplier()
    end

    local configParam = function(paramName, defaultValue)
        if projectileParameters[paramName] ~= nil then return projectileParameters[paramName] end
        if projectileConfig[paramName] ~= nil then return projectileConfig[paramName] end
        return defaultValue
    end
    local tragectory = hitscan.calculateTragectory(projectileType, projectileParameters, range, spawnPos, inaccuracy, maxSegmentRange, isCoroutine)
    debugHitScan = {}

    local _lastPos = false
    local collisionProj = copy(projectileParameters)
    collisionProj.actionOnReap = jarray({})
    collisionProj.timeToLive = 0
    collisionProj.speed = 1
    collisionProj.clientEntityMode = "ClientPresenceMaster"
	collisionProj.processing = "?multiply=fff0"
    local pierced = 0
    local piercesMax = configParam("pierces", 0)
    local hitEnt = {}
    local isCoroutine = copy(isCoroutine)
    for i, cfg in pairs(tragectory) do
        local travelPoint = {cfg.pos, (tragectory[i + 1] or {}).pos or cfg.pos}
        local _magnitude = math.max(world.magnitude(travelPoint[1], travelPoint[2]), 0)
        table.insert(debugHitScan, {type = "line", pos = {travelPoint[1], travelPoint[2]}, color = "yellow"})
        table.insert(debugHitScan, {type = "point", pos = vec2.add(travelPoint[1], vec2.withAngle(vec2.angle(cfg.aimVector), _magnitude * 0.5)), color = "yellow"})
        
        -- entity hit
        local entList = world.entityLineQuery(world.xwrap(travelPoint[1]), world.xwrap(travelPoint[2]), {
            withoutEntityId = activeItem.ownerEntityId(),
            order = "nearest"
        })
        local validEnt = false
        local canPierces = function()
            return configParam("piercing") or (pierced <= piercesMax) 
        end
        local stopAtEntityType = {
            player = true,
            monster = true,
            vehicle = true
        }
        --sb.logInfo("canPierces %s, piercing %s, pierces %s/%s", canPierces(), configParam("piercing"), pierced, configParam("pierces", 0))
        for i = 1, #entList do
            local targetEntity = entList[i]
            local validType = (world.entityType(targetEntity) == "monster") or (world.entityType(targetEntity) == "player") or (world.entityType(targetEntity) == "npc") or (world.entityType(targetEntity) == "vehicle") or (world.entityType(targetEntity) == "object")
            
            if world.entityCanDamage(activeItem.ownerEntityId(), targetEntity) and validType and (not hitEnt[tostring(targetEntity)]) then --need to find a way to reduce the lenght
                hitEnt[tostring(targetEntity)] = true
                local hitpos = world.entityPosition(targetEntity)
                local mag = world.magnitude(hitpos, travelPoint[1])
                local projPos = world.xwrap(vec2.add(travelPoint[1], vec2.withAngle(vec2.angle(cfg.aimVector), mag)))
                validEnt = true
                local shouldStop = (not canPierces()) and stopAtEntityType[string.lower(world.entityType(targetEntity))]
                --sb.logInfo("piercing %s, stopAtEntityType %s, shouldStop %s", (canPierces()), stopAtEntityType[string.lower(world.entityType(targetEntity))], shouldStop)
                if shouldStop then
                    --sb.logInfo("stopped at ent %s|%s", targetEntity, world.entityType(targetEntity))
                    validEnt = projPos
                    break
                else
                    if (stopAtEntityType[string.lower(world.entityType(targetEntity))]) then pierced = pierced + 1 end
                    validEnt = false
                    if not canPierces() then
                        validEnt = projPos
                        break
                    end
                    
                    if (piercesMax > 0) or configParam("piercing") then
                        world.spawnProjectile(projectileType, projPos, activeItem.ownerEntityId(), cfg.aimVector, false, jarray(collisionProj or {}))
                    end
                end
            end
        end
        -- last Point Check
        local lastPoint = (i == #tragectory)
        if validEnt and (not canPierces()) then lastPoint = true end
        --

        -- Visual
        if not extra.disableTrail then
            local max = #tragectory
            if lastPoint then
                max = i
                _magnitude = math.max(world.magnitude(travelPoint[1], validEnt or travelPoint[2]), 0)
            end
            local extra = copy(extra)
            local alpha = 1--((1 - (i / max)) * (extra.trailLengthMod or 1))
            local sizeOverride = extra.trailSizeOverride
            local destructionTime = extra.trailTimeToLive
            if #tragectory == 1 then 
                alpha = 1--math.min(1 * (extra.trailLengthMod or 1), 1)
                if not destructionTime then destructionTime = 0.1 end
                if not sizeOverride then sizeOverride = 1.25 * (extra.trailSizeMod or 1) end
            end
            if extra.trailColor then extra.trailColor[4] = extra.trailColor[4] * alpha end
            local visualParam = {}
            if extra.useStreak then
                visualParam = {
                    clientEntityMode = "ClientPresenceMaster",
                    speed = 0.001,
                    timeToLive = 0,
                    processing = "?multiply=fff0",
                    damageTeam = { type = "ghostly" },
                    movementSettings = {collisionEnabled = false, gravityEnable = false},
                    actionOnReap = {
                        {
                            rotate = true,
                            specification = {
                                fade = 1,
                                approach = {0, 0},
                                layer = "back",
                                destructionAction = extra.trailDestructionAction or "shrink",
                                type = "streak",
                                destructionTime = destructionTime or math.max(0.0625 + (i * 0.0625), 1),
                                size = sizeOverride or math.min((0.125 * (extra.trailSizeMod or 1)) + (math.max(max - i, 0) * 0.125), 1.25 * (extra.trailSizeMod or 1)),

                                initialVelocity = {0.125 * (destructionTime or math.max(0.0625 + (i * 0.0625), 1)), 0},
                                finalVelocity = {0, 0},
                                timeToLive = 0,
                                variance = {},
                                collidesForeground= false,
                                collidesLiquid= false,
                                flip = false,
                                fullbright = extra.trailFullbright or false,
                                color = extra.trailColor or {255, 255, 255, 255 * alpha},
                                light = extra.trailLight or {0, 0, 0},

                                length = (_magnitude * 8),
                                position = {_magnitude * 0.5, 0}
                            },
                            action = "particle"
                        }
                    }
                }
            else
                local baseDestTime = extra.trailBaseDestTime or 0
                local lengthDestTime = (extra.trailLengthDestTime or 0)
                local timeToLive = extra.trailTimeToLive or 0.005
                local trailDelay = extra.trailDelay or 0
                visualParam = {
                    clientEntityMode = "ClientMasterAllowed",
                    speed = 0.001,
                    timeToLive = 0 + (math.max((i - 1) * 0.125, 0) * (trailDelay + lengthDestTime)),
                    processing = "?multiply=fff0",
                    damageTeam = { type = "ghostly" },
                    movementSettings = {collisionEnabled = false, gravityEnable = false},
                    actionOnReap = {
                        {
                            rotate = true,
                            specification = {
                                fade = 1,
                                approach = {0, 0},
                                layer = "back",
                                destructionAction = extra.trailDestructionAction or "fade",
                                string = "/items/active/weapons/protectorate/aegisaltpistol/beam.png?crop;0;1;1;2?scalenearest=8?saturation=-100?border=8;0000?crop;0;8;16;16?flipx",
                                type = "Textured",
                                destructionTime = destructionTime or math.max(baseDestTime + ((i - 1) * (lengthDestTime + timeToLive)), 0),
                                size = sizeOverride or math.min((0.125 * (extra.trailSizeMod or 1)), 1.25),

                                initialVelocity = {0.0, 0},
                                finalVelocity = {0, 0},
                                timeToLive = 0,
                                variance = {},
                                collidesForeground= false,
                                collidesLiquid= false,
                                flip = false,
                                fullbright = extra.trailFullbright or false,
                                color = extra.trailColor or {255, 255, 255, 255 * alpha},
                                light = extra.trailLight or {0, 0, 0},

                                position = {_magnitude * 0.5, 0}
                            },
                            action = "particle"
                        }
                    }
                }
                local length, size = _magnitude * 1.1, math.max(visualParam.actionOnReap[1].specification.size, 0)
                if not extra.trailNoDelay then 
                    visualParam.timeToLive = (visualParam.timeToLive + visualParam.actionOnReap[1].specification.destructionTime) * 0.125
                    visualParam.actionOnReap[1].specification.destructionAction = extra.trailDestructionAction or "shrink"
                end
                visualParam.actionOnReap[1].specification.string = visualParam.actionOnReap[1].specification.string .. string.format("?scalenearest=%s;%s", length, (size * 0.125))
                visualParam.actionOnReap[1].specification.size = 1
            end
            if type(validEnt) == "table" then
                local mag = world.magnitude(validEnt, travelPoint[1])
                visualParam.actionOnReap[1].specification.position[1] = mag
                visualParam.actionOnReap[1].specification.length = (mag * 8) + 0.25
            end
            world.spawnProjectile("bullet-1", world.xwrap(travelPoint[1]), activeItem.ownerEntityId(), cfg.aimVector, false, jarray(visualParam or {}))
        end
        --

        -- last hit/collision
        if lastPoint then
            local param = copy(projectileParameters)
            param.timeToLive = 0
            param.speed = 1
            param.clientEntityMode = "ClientPresenceMaster"
			param.processing = "?multiply=fff0"
            param.movementSettings = param.movementSettings or {}
            param.movementSettings.stopOnFirstBounce = false
            param.movementSettings.stickyCollision = true
            param.movementSettings.stickyForce = 20
            --param.damageTeam = { type = "ghostly" }
            if type(validEnt) == "table" then
                world.spawnProjectile(projectileType, validEnt, activeItem.ownerEntityId(), cfg.aimVector, false, jarray(param or {}))
            else
                local n = world.magnitude(travelPoint[1], travelPoint[2])
                local endPos = world.xwrap(vec2.add(travelPoint[1], vec2.withAngle(vec2.angle(cfg.aimVector), n * 1)))
                
                world.spawnProjectile(projectileType, endPos, activeItem.ownerEntityId(), cfg.aimVector, false, jarray(param or {}))
            end
            break
        end
        _lastPos = vec2.add(_lastPos or {0, 0}, vec2.withAngle(vec2.angle(cfg.aimVector), _magnitude))
        if isCoroutine then
            if (i % 200) == 0 then
                coroutine.yield()
            end
        end
    end
    return tragectory
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