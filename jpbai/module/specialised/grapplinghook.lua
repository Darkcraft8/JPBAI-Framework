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