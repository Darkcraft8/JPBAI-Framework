movementControl = {}
local movementModifiers = {}
local movementParameters = {}

function movementControl.init()
    movementControl.resetParameters()
    movementControl.resetModifiers()
    mcontroller.setRotation(0)
end

function movementControl.uninit()
    movementControl.resetParameters()
    movementControl.resetModifiers()
    mcontroller.setRotation(0)
end

function movementControl.update(dt)
    if movementModifiers then
        mcontroller.controlModifiers(movementModifiers or {})
    end
    if movementParameters then
        mcontroller.controlParameters(movementParameters or {})
    end
end

function movementControl.translateAboveGround(distance)
    if not distance then return end
    local userPos = world.entityPosition(activeItem.ownerEntityId())
    local groundPos = world.lineTileCollisionPoint(userPos, {userPos[1], distance})
    if groundPos.position then
        local effectiveYPos = userPos[2] + (groundPos.position[2] - distance)
        mcontroller.setYPosition(effectiveYPos)
    end
end

function movementControl.aimedVelocity(vel, verticalOffset)
    if not vel then return end
    local aimAngle = activeItem.aimAngle(verticalOffset or 0, activeItem.ownerAimPosition())
    local newVec = vec2.rotate(vel, aimAngle)
    mcontroller.setVelocity(newVec)
end

function movementControl.addAimedVelocity(vel, verticalOffset)
    if not vel then return end
    local aimAngle = activeItem.aimAngle(verticalOffset or 0, activeItem.ownerAimPosition())
    local newVec = vec2.add(mcontroller.velocity(), vec2.rotate(vel, aimAngle))
    mcontroller.setVelocity(newVec)
end

function movementControl.aimTranslation(vec, verticalOffset, checkForObstacle, offset, maxCorrection)
    if not vec then return end
    local aimAngle = activeItem.aimAngle(verticalOffset or 0, activeItem.ownerAimPosition())
    local new = vec2.add(mcontroller.position(), vec2.rotate(vec, aimAngle))
    if checkForObstacle then
        local collisionPoint = world.lineCollision(mcontroller.position(), new, {"Block", "Dynamic", "Null", "Slippery"})
        if collisionPoint then
            new = collisionPoint
        end
    end
    --mcontroller.setPosition(new)
    local resolvedCollision = world.resolvePolyCollision(mcontroller.collisionPoly(), vec2.add(new, offset or {0, 2.5}), maxCorrection or 3, {"Block", "Dynamic", "Null", "Slippery"})
    if resolvedCollision then
        mcontroller.setPosition(resolvedCollision)
    end
end

function movementControl.translatePos(pos, maxCorrection)
    if not pos then return end
    local new = vec2.add(mcontroller.position(), pos)
    local resolvedCollision = world.resolvePolyCollision(mcontroller.collisionPoly(), new, maxCorrection or 3, {"Block", "Dynamic", "Null", "Slippery"})
    if resolvedCollision then
        mcontroller.setPosition(resolvedCollision)
    end
end

function movementControl.setParameters(ActorMovementParameters)
    if not movementParameters then movementParameters = {} end
    movementParameters = sb.jsonMerge(movementParameters, ActorMovementParameters)
end

function movementControl.resetParameters()
    movementParameters = nil
end
function movementControl.setModifiers(ActorMovementParameters)
    if not movementModifiers then movementModifiers = {} end
    movementModifiers = sb.jsonMerge(movementModifiers, ActorMovementParameters)
end

function movementControl.resetModifiers()
    movementModifiers = nil
end

function movementControl.multVelocity(x, y)
    local velocity = mcontroller.velocity()
    if x then mcontroller.setXVelocity(velocity[1] * x) end
    if y then mcontroller.setYVelocity(velocity[2] * y) end
end

--[[ [controlModifiers Possible Args]
    movementSuppressed
    facingSuppressed
    runningSuppressed
    jumpingSuppressed
    ... ok there mostlikely more
]]