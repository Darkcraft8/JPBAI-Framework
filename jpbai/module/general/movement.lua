movementControl = {}
function movementControl.controlModifiers(args) -- mostlikely useless to make bridge func for some if not most of these... problably should add a blacklist
    -- runningSuppressed
    --mcontroller.rotate()
    mcontroller.controlModifiers(args)
end

function movementControl.translateAboveGround(args)
    local userPos = world.entityPosition(activeItem.ownerEntityId())
    local groundPos = world.lineTileCollisionPoint(activeItem.ownerEntityId(), args.distance)
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