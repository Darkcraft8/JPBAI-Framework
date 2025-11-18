-- function for gappling hook type capability

function reelTowardEntity(entityId, speed, maxControlForce)
    local targetPos
    if (type(entityId) == "table") then
        targetPos = vec2.add(entity.position(), entityId)
    elseif world.entityExists(entityId) then
        targetPos = world.entityPosition(entityId)
    end
    if not targetPos then return end
    local dist = world.distance(targetPos, entity.position()) 
    local vel = vec2.rotate({speed, 0}, vec2.angle(dist))
    mcontroller.setVelocity(vel, maxControlForce or 250)
end

function spawnHookProjectile(projectileType, spawnPositionCfg, direction, trackSource, projectileParameters, inaccuracy, hookToEntity, hookToEnemy)
    local position = spawnPosition({
        spawnPos = spawnPositionCfg.anchor or "ownerPosFaceDirection",
        spawnOffset = {0, 0}
    })
    local position2 = spawnPosition({
        spawnPos = spawnPositionCfg.anchor or "ownerPosFaceDirection",
        spawnOffset = spawnPositionCfg.offset or {0, 0}
    })
    -- collision physic
    local collisionPoint = world.lineCollision(position, position2, {"Block", "Dynamic", "Null", "Slippery"})
    if collisionPoint then collisionPoint = spawnPosition({
        spawnPos = spawnPositionCfg.anchor or "ownerPosFaceDirection",
        spawnOffset = {world.magnitude(position, collisionPoint) - 1.25, 0}
    }) end
    -- hurtBox collision
    local entityList = {}
    if (hookToEntity or hookToEnemy) then entityList = world.entityLineQuery(position, position2, {withoutEntityId = activeItem.ownerEntityId(), order = "nearest"}) end
    local entityPoint = nil
    for _, id in pairs(entityList or {}) do
        local add = true
        if hookToEnemy then add = world.entityCanDamage(activeItem.ownerEntityId(), id) end
        if add then --need to find a way to reduce the lenght
            local targPos = vec2.add(world.entityPosition(id), {0, 1.29993})
            local dist = world.distance(world.entityPosition(activeItem.ownerEntityId()), targPos)
            local mag = world.magnitude(world.entityPosition(activeItem.ownerEntityId()), targPos)
            entityPoint = spawnPosition({
                spawnPos = spawnPositionCfg.anchor or "ownerPosFaceDirection",
                spawnOffset = {mag - 1.25, 0}
            })
            break
        end
    end
    if collisionPoint and entityPoint then
        local distA, distB = world.magnitude(position, collisionPoint), world.magnitude(position, entityPoint)
        if distA < distB then
            position2 = collisionPoint
        else
            position2 = entityPoint
        end
    elseif entityPoint then
        position2 = entityPoint
    elseif collisionPoint then
        position2 = collisionPoint
    end
    local direction = direction or aimVector((inaccuracy or 0))
    
    --sb.logInfo("type %s,\nposition %s,\ndirection %s,\ntrackSource %s,\nparameters %s", projectileType, position2, direction, trackSource, projectileParameters)
    return world.spawnProjectile(projectileType, position2, activeItem.ownerEntityId(), direction, trackSource, projectileParameters)
end

function magBetweenEntity(entity1, entity2, percent)
    if not entity1 then return end
    local a, b = entity1, entity2 or activeItem.ownerEntityId()
    if world.entityExists(a) and world.entityExists(b) then
        if percent then
            local mag = world.magnitude(world.entityPosition(a), world.entityPosition(b))
            return mag > percent
        else
            return world.magnitude(world.entityPosition(a), world.entityPosition(b))
        end
    end
end
