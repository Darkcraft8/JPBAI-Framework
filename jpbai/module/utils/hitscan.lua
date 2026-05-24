hitscan = {}
function hitscan.calculateTragectory(projectileType, projectileParameters, range, spawnPos, inaccuracy)
    local physicsConfig = root.assetJson("/projectiles/physics.config")
    local projectileConfig = root.projectileConfig(projectileType)
    local configParam = function(paramName, defaultValue)
        return projectileParameters[paramName] or projectileConfig[paramName] or defaultValue
    end

    local offset = offset or {0, 0}
    local bounces = configParam("bounces", 0)
    local movementSettings = util.mergeTable(configParam("movementSettings", {}), physicsConfig[configParam("physics", "default")])
    if movementSettings.collisionEnabled == nil then movementSettings.collisionEnabled = true end
    local movementCalulationStep = 0.25
    local calRange = function(speed, timeToLive)
        return (speed * timeToLive)
    end
    local speed = configParam("speed", 250)
    local initSpeed = copy(speed)
    local range = math.min((range or calRange(configParam("speed", 250), configParam("timeToLive", 5))), 2000)
    local totalRange = copy(range)
    local velDir = aimVector(0 or inaccuracy)

    local traveledSpace = vec2.withAngle(vec2.angle(velDir), range)
    local endPos = vec2.add(spawnPos, traveledSpace)
    local collidingWithNull = world.lineTileCollisionPoint(spawnPos, world.xwrap(endPos), {"Null"})
    --sb.logInfo("checking if the world is loaded : %s", collidingWithNull)
    if collidingWithNull then
        local mag = world.magnitude(spawnPos, collidingWithNull[1])
        range = mag
        --sb.logInfo("accidentaly shot noli at %s", collidingWithNull[1])
    end

    local traveledSpace = vec2.withAngle(vec2.angle(velDir), range)
    local lastNormal = false
    local collisionKind = {"Dynamic", "Block", "Slippery"}
    
    if not movementSettings.ignorePlatformCollision then table.insert(collisionKind, "Platform") end
    local tragectory = {}
    local divide = function(float, scalar)
        if (scalar == 0) or (float == 0) then return 0 end
        return float / scalar
    end
    local maxRangeStep = 8 * (movementSettings.maxMovementPerStep or 1)
    while (range > 0) do -- calculating Tragectory
        
        traveledSpace = vec2.withAngle(vec2.angle(velDir), math.min(range * (movementSettings.maxMovementPerStep or 1), maxRangeStep))
        local endPos = vec2.add(spawnPos, traveledSpace)
        
        local _magnitude = world.magnitude(spawnPos, endPos) * 0.5
        local gravity = ( (world.gravity(vec2.add(spawnPos, vec2.rotate({_magnitude, 0}, vec2.angle(velDir))))) * script.updateDt() ) * (movementSettings.gravityMultiplier or 0)
        --movementSettings.groundFriction -- i will ignore that until i need to make it
        --(range > (totalRange * 0.25)) -- disabled for now, grace range before gravity take effect
        if (gravity ~= 0) then
            gravity = gravity / (range + speed) -- divide the gravity by the range(figurative ray lifeSpend) and speed
            local nextAimVec = vec2.lerp(gravity, velDir, vec2.withAngle(math.rad(-90), 1)) -- lerp the velDir toward negative Y Axis based on the gravity
            --sb.logInfo("grav %s, aimVec %s, nAimVec %s, down velDir %s", gravity, velDir, nextAimVec, vec2.withAngle(math.rad(-90), 1))
            velDir = nextAimVec
        end

        traveledSpace = vec2.withAngle(vec2.angle(velDir), math.min(range * (movementSettings.maxMovementPerStep or 1), maxRangeStep))
        endPos = vec2.add(spawnPos, traveledSpace)

        local friction = 0
        if world.liquidAlongLine(spawnPos, endPos) then
            friction = movementSettings.liquidFriction
        else
            friction = movementSettings.airFriction
        end
        if friction ~= 0 then speed = speed * (1 / friction) end
        if ( speed < 0.01 ) then speed = 0 end
        local collisionPoint = world.lineTileCollisionPoint(spawnPos, endPos, collisionKind)
        if (bounces == 0) or (not collisionPoint) then
            if (not collisionPoint) or (not movementSettings.collisionEnabled) then
                world.debugLine(spawnPos, endPos, "red")
                if #tragectory > 0 then
                    local normalDif = world.magnitude(tragectory[#tragectory].pos[2], endPos)
                    if normalDif <= 0.25 then break end
                end
                table.insert(tragectory, {pos = {spawnPos, endPos}, aimVector = velDir})

                local _magnitude = world.magnitude(spawnPos, endPos)
                range = math.max(range - _magnitude, 0)
            else
                local _position, _normal = collisionPoint[1], collisionPoint[2]
                local _magnitude = world.magnitude(spawnPos, _position)
                range = math.max(range - _magnitude, 0)
                
                world.debugLine(spawnPos, _position, "red")
                if #tragectory > 0 then
                    local normalDif = world.magnitude(tragectory[#tragectory].pos[2], _position)
                    if normalDif <= 0.25 then break end
                end
                table.insert(tragectory, {pos = {spawnPos, _position}, aimVector = velDir})
                break
            end
            spawnPos = endPos
        elseif collisionPoint then
            local _position, _normal = collisionPoint[1], collisionPoint[2]
            local _magnitude = world.magnitude(spawnPos, _position)
            lastNormal = vec2.norm(_normal)

            world.debugLine(spawnPos, _position, "red")

            range = math.max(range - _magnitude, 0)
            if #tragectory > 0 then
                local normalDif = world.magnitude(tragectory[#tragectory].pos[2], _position)
                if normalDif <= 0.25 then break end
            end
            table.insert(tragectory, {pos = {spawnPos, _position}, aimVector = velDir})
            local reflect = vector2DReflect(velDir, _normal)

            velDir = reflect
            spawnPos = _position
            bounces = bounces - 1

            if bounces == 0 then break end
        end
        
        if (range <= 0) then break end
        if #tragectory >= 500 then break end
    end
    return tragectory
end

function hitscan.debugTragectory(projectileType, projectileParameters, range, spawnPos, inaccuracy)
    local tragectory = hitscan.calculateTragectory(projectileType, projectileParameters, range, spawnPos, inaccuracy)
    for i, p in pairs(tragectory or {}) do
        world.debugLine(p.pos[1], p.pos[2], "white")
    end
end

function vector2DReflect(velDir, collisionNorm)
    return vec2.sub(velDir, vec2.mul(vec2.mul(collisionNorm, 2), vec2.dot(velDir, collisionNorm)))
end

-- Extra :D
-- convert tragectory to a chain config for the vanilla chain animation script, might be a bit laggy
function hitscan.toChain(tragectory, startTexture, texture, endTexture, size, overdrawLength, drawPercent, fullbright, light, renderLayer)
    local newChain = {}
    for i, p in pairs(tragectory or {}) do
        local normal = world.magnitude(p.pos[1], p.pos[2])
        local cfg = {
            segmentImage = texture or "/items/active/weapons/protectorate/aegisaltpistol/beam.png?setcolor=fff",
            renderLayer = renderLayer,

            fullbright = fullbright or false,
            segmentSize = size or 0.48,
            drawPercentage = drawPercent or 1,
            overdrawLength = overdrawLength or 0.2,
            startPosition = p.pos[1],
            endPosition = p.pos[2],
            light = light
        }
        if i == #tragectory then
            cfg.segmentImage = endTexture or cfg.segmentImage
        elseif i == 1 then
            cfg.segmentImage = startTexture or cfg.segmentImage
        end
        table.insert(newChain, cfg)
    end
    return newChain
end