hitscan = {}
useOldHitscanTragectoryMath = false
local function oldTragectoryMath(projectileType, projectileParameters, range, spawnPos, inaccuracy, maxSegmentRange, isCoroutine)
    local isCoroutine = copy(isCoroutine or false)
    local physicsConfig = root.assetJson("/projectiles/physics.config")
    local projectileConfig = root.projectileConfig(projectileType)
    local configParam = function(paramName, defaultValue)
        if projectileParameters[paramName] then return projectileParameters[paramName] end
        if projectileConfig[paramName] then return projectileConfig[paramName] end
        return defaultValue
    end

    local bounces = configParam("bounces", 0)
    local movementSettings = util.mergeTable(physicsConfig[configParam("physics", "default")], configParam("movementSettings", {}))
    if movementSettings.collisionEnabled == nil then movementSettings.collisionEnabled = true end
    local movementCalulationStep = 0.25
    local calRange = function(speed, timeToLive)
        return (speed * timeToLive)
    end
    local speed = configParam("speed", 250)
    local range = math.min((range or calRange(configParam("speed", 250), configParam("timeToLive", 5))), 100000)
    local traveledRange = 0
    local totalRange = copy(range)
    local velDir = aimVector(inaccuracy or 0)

    local lastNormal = false
    local collisionKind = {"Dynamic", "Block", "Slippery", "Null"}
    
    if not movementSettings.ignorePlatformCollision then table.insert(collisionKind, "Platform") end
    local tragectory = {}
    local divide = function(float, scalar)
        if (scalar == 0) or (float == 0) then return 0 end
        return float / scalar
    end
    local maxRangeStep = maxSegmentRange or (8 * (movementSettings.maxMovementPerStep or 1))
    local dt = script.updateDt()
    local calculationDuringTick = 0
    --(range > 0)
    table.insert(tragectory, {pos = spawnPos, aimVector = velDir})
    while true do -- calculating Tragectory
        sb.logInfo("expected tragectory percent %s", traveledRange / totalRange)
        local traveledSpace = function(velDir, speed)
            return vec2.withAngle(vec2.angle(velDir), math.max(math.min(speed * (movementSettings.maxMovementPerStep or 1), maxRangeStep), 0.125))
        end
        local endPos = vec2.add(spawnPos, traveledSpace(velDir, speed))
        
        local _magnitude = world.magnitude(spawnPos, endPos) * 0.5
        local gravity = ( (world.gravity(vec2.add(spawnPos, vec2.rotate({_magnitude, 0}, vec2.angle(velDir))))) )
        --movementSettings.groundFriction -- i will ignore that until i need to make it
        --(range > (totalRange * 0.25)) -- disabled for now, grace range before gravity take effect
        if (gravity ~= 0) then
            local gravity = (gravity * dt) * (1.5 / 180)
            local nextAimVec = vec2.sub(velDir, {0, gravity})

            -- lerp the velDir toward negative Y Axis based on the gravity
            --local nextAimVec = vec2.lerp(math.max(gravity * dt, 0), velDir, vec2.withAngle(math.rad(-90), 1))
            velDir = nextAimVec
            if velDir[2] < 0 then
                local t = vec2.withAngle(vec2.angle(velDir), 1)
                sb.logInfo("velDir[2] %s", t[2])
                sb.logInfo("gravity %s", gravity)
                sb.logInfo("gravity * dt %s", gravity * dt)
                sb.logInfo("((gravity * math.max(-1 * velDir[2], 1)) * dt) %s", ((gravity * math.max(-1 * t[2], 1)) * dt))
                speed = speed + ((gravity * math.max(-1 * t[2], 1)))
            end
        end

        endPos = vec2.add(spawnPos, traveledSpace(velDir, speed))

        local friction = 0
        if world.liquidAlongLine(spawnPos, endPos) then
            friction = movementSettings.liquidFriction
        else
            friction = movementSettings.airFriction
        end
        
        speed = interp.linear(friction, speed, 0)
        if ( speed < 0.01 ) then speed = 0 end
        sb.logInfo("speed %s", speed)

        local collisionPoint = world.lineTileCollisionPoint(spawnPos, endPos, collisionKind)
        if (bounces == 0) or (not collisionPoint) then
            if (not collisionPoint) or (not movementSettings.collisionEnabled) then
                world.debugLine(spawnPos, endPos, "red")
                if #tragectory > 0 then
                    local normalDif = world.magnitude(tragectory[#tragectory].pos[2], endPos)
                    --if normalDif <= 0.25 then break end
                end
                table.insert(tragectory, {pos = endPos, aimVector = velDir})

                local _magnitude = world.magnitude(spawnPos, endPos)
                traveledRange = traveledRange + _magnitude
                range = math.max(range - _magnitude, 0)
            else
                local _position, _normal = collisionPoint[1], collisionPoint[2]
                local _magnitude = world.magnitude(spawnPos, _position)
                traveledRange = traveledRange + _magnitude
                range = math.max(range - _magnitude, 0)
                
                world.debugLine(spawnPos, _position, "red")
                if #tragectory > 0 then
                    local normalDif = world.magnitude(tragectory[#tragectory].pos[2], _position)
                    --if normalDif <= 0.25 then break end
                end
                table.insert(tragectory, {pos = _position, aimVector = velDir})
                break
            end
            spawnPos = endPos
        elseif collisionPoint then
            local _position, _normal = collisionPoint[1], collisionPoint[2]
            local _magnitude = world.magnitude(spawnPos, _position)
            lastNormal = vec2.norm(_normal)

            world.debugLine(spawnPos, _position, "red")

            traveledRange = traveledRange + _magnitude
            range = math.max(range - _magnitude, 0)
            if #tragectory > 0 then
                local normalDif = world.magnitude(tragectory[#tragectory].pos[2], _position)
                --if normalDif <= 0.25 then break end
            end
            table.insert(tragectory, {pos = _position, aimVector = velDir})
            local reflect = vector2DReflect(velDir, _normal)

            velDir = reflect
            spawnPos = _position
            bounces = bounces - 1

            if bounces == 0 then break end
        end
        
        if (range <= 0) and (not isCoroutine) then break end
        --if (speed == 0) then break end
        if isCoroutine then
            if calculationDuringTick >= 500 then
                coroutine.yield()
                calculationDuringTick = 0
            end
        elseif calculationDuringTick >= 500 then
            break
        end
        calculationDuringTick = calculationDuringTick + 1
    end
    return tragectory
end

function hitscan.calculateTragectory(projectileType, projectileParameters, range, spawnPos, inaccuracy, maxSegmentRange, isCoroutine)
    if useOldHitscanTragectoryMath then
        local result = oldTragectoryMath(projectileType, projectileParameters, range, spawnPos, inaccuracy, maxSegmentRange, isCoroutine)
        return result
    else
        local isCoroutine = copy(isCoroutine or false)
        --
            local dt = script.updateDt()
            local calculationDuringTick = 0 -- let lower lagSpike if whe can
            local worldSize = world.size()
        --
        -- Projectile Config
        local physicsConfig = root.assetJson("/projectiles/physics.config")
        local projectileConfig = root.projectileConfig(projectileType)
        local configParam = function(paramName, defaultValue)
            if projectileParameters[paramName] then return projectileParameters[paramName] end
            if projectileConfig[paramName] then return projectileConfig[paramName] end
            return defaultValue
        end

        local movementSettings = util.mergeTable(physicsConfig[configParam("physics", "default")], configParam("movementSettings", {}))
        if movementSettings.collisionEnabled == nil then movementSettings.collisionEnabled = true end

        local bounces = configParam("bounces", 0)
        local speed = configParam("speed", 50)
        local timeToLive = configParam("timeToLive", 5)

        local velocity = aimVector(inaccuracy or 0)
        velocity = vec2.withAngle(vec2.angle(velocity), speed)
        --

        -- math function
            local distMod = 1
            local traveledSpace = function(velocity)
                local r = vec2.mul(velocity, (movementSettings.maxMovementPerStep or 1))
                r = vec2.mul(r, dt * distMod)
                return r 
            end
            local median = function(a, b)
                return (a + b) / 2
            end
            local friction = function(posA, posB)
                local friction = 0
                if world.liquidAlongLine(posA, posB) then
                    friction = movementSettings.liquidFriction
                else
                    friction = movementSettings.airFriction
                end
                return friction
            end
        --
        local collisionKind = {"Dynamic", "Block", "Slippery", "Null"}
        if not movementSettings.ignorePlatformCollision then table.insert(collisionKind, "Platform") end
        local maxRangeStep = maxSegmentRange or (8 * (movementSettings.maxMovementPerStep or 1))
        local tragectory = {}
        table.insert(tragectory, {pos = spawnPos, aimVector = vec2.withAngle(vec2.angle(world.distance(vec2.add(spawnPos, traveledSpace(velocity)), spawnPos)), 1)})
        while (timeToLive > 0) or (timeToLive == -1) do
            if (timeToLive > 0) then timeToLive = timeToLive - dt end
            local endPos = vec2.add(spawnPos, traveledSpace(velocity))
            -- gravity
                local gravStrStart = world.gravity(spawnPos) * (0.4 * distMod)
                local gravStrEnd = world.gravity(endPos) * (0.4 * distMod)
                local gravStrMed = median(gravStrStart, gravStrEnd)
                local appliedGrav = ((gravStrMed * (movementSettings.gravityMultiplier or 0)) * dt)
                --sb.logInfo("grav : start(%s), end(%s), median(%s) : applied(%s)", gravStrStart, gravStrEnd, gravStrMed, appliedGrav)
                if appliedGrav ~= 0 then
                    velocity[2] = velocity[2] - appliedGrav
                end
                endPos = vec2.add(spawnPos, traveledSpace(velocity))
            --
            -- friction
                local friction = friction(spawnPos, endPos)
                velocity = vec2.mul(velocity, 1 - (friction * dt))
                endPos = vec2.add(spawnPos, traveledSpace(velocity))
            --
            local collisionPoint = world.lineTileCollisionPoint(spawnPos, endPos, collisionKind)
            local collisionPointNull = world.lineTileCollisionPoint(spawnPos, endPos, {"null"})
            local posMag = world.magnitude(spawnPos, endPos)
            local velDir = vec2.withAngle(vec2.angle(world.distance(endPos, spawnPos)), 1)
            if (bounces == 0) or (not collisionPoint) then
                if (not collisionPoint) or (not movementSettings.collisionEnabled) then
                    table.insert(tragectory, {pos = endPos, aimVector = velDir})
                else 
                    local _position, _normal = collisionPoint[1], collisionPoint[2]
                    if ((not collisionPointNull)) or (endPos[2] <= 0) then
                        table.insert(tragectory, {pos = _position, aimVector = velDir})
                        break
                    end
                end
                spawnPos = endPos
            elseif collisionPoint then
                local _position, _normal = collisionPoint[1], collisionPoint[2]
                local reflect = vector2DReflect(velocity, _normal)

                table.insert(tragectory, {pos = _position, aimVector = velDir})

                velocity = reflect
                spawnPos = _position
                bounces = bounces - 1

                if bounces == 0 then break end
            end

            if isCoroutine then
                if calculationDuringTick >= 500 then
                    coroutine.yield()
                    calculationDuringTick = 0
                end
            elseif calculationDuringTick >= 500 then
                break
            elseif #tragectory >= 230 then
                --break
            end
            calculationDuringTick = calculationDuringTick + 1
        end
        return tragectory
    end
end

function hitscan.debugTragectory(projectileType, projectileParameters, range, spawnPos, inaccuracy)
    local tragectory = hitscan.calculateTragectory(projectileType, projectileParameters, range, spawnPos, inaccuracy)
    for i, p in pairs(tragectory or {}) do
        local travelPoint = {p.pos, (tragectory[i + 1] or {}).pos or p.pos}
        world.debugLine(travelPoint[1], travelPoint[2], "white")
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
        local travelPoint = {p.pos, (tragectory[i + 1] or {}).pos or p.pos}
        local normal = world.magnitude(travelPoint[1], travelPoint[2])
        local cfg = {
            segmentImage = texture or "/items/active/weapons/protectorate/aegisaltpistol/beam.png?setcolor=fff",
            renderLayer = renderLayer,

            fullbright = fullbright or false,
            segmentSize = size or 0.48,
            drawPercentage = drawPercent or 1,
            overdrawLength = overdrawLength or 0.2,
            startPosition = travelPoint[1],
            endPosition = travelPoint[2],
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