movementControl = {}
function movementControl.translateAboveGround(distance)
    if not distance then return end
    local userPos = world.entityPosition(activeItem.ownerEntityId())
    local groundPos = world.lineTileCollisionPoint(activeItem.ownerEntityId(), distance)
    if groundPos.position then
        local effectiveYPos = userPos[2] + (groundPos.position[2] - args.distance[2])
        mcontroller.setYPosition(effectiveYPos)
    end
end

-- [controlModifiers Possible Args]
-- movementSuppressed
-- facingSuppressed
-- runningSuppressed
-- jumpingSuppressed