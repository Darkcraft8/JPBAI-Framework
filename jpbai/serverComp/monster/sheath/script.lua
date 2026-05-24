require "/scripts/poly.lua"

local parentEntity = nil
local offset = {0, 0}
function init()
    parentEntity = config.getParameter("parentEntity")
    script.setUpdateDelta(1)
    if not parentEntity then self.die = true return end
end

function update(dt)
    if not parentEntity then return end
    local pos = world.entityMouthPosition(parentEntity)
    
    mcontroller.setPosition(vec2.add(pos, offset))
    world.sendEntityMessage(parentEntity, "facingDirection", entity.id())
    world.sendEntityMessage(parentEntity, "crouching", entity.id())
end
function crouching(crouching)
    if crouching then
        offset = {0, -0.25}
    else
        offset = {0, 0}
    end
end
function facingDirection(facingDirection)
    if facingDirection > 0 then
        animator.setFlipped(true)
    else
        animator.setFlipped(false)
    end
end

function shouldDie(bool)
    if bool then self.die = bool end
    return bool or self.die or false
end

function setTag(tagName, tagValue)
    if (not tagName) or (not tagValue) then return end
    animator.setGlobalTag(tagName, tagValue)
end

function rotate(group, val)
    animator.rotateTransformationGroup("base", math.rad(val or 0))
end

function translate(group, val)
    animator.translateTransformationGroup("base", val)
end

function scale(group, val)
    animator.scaleTransformationGroup("base", val)
end

function reset(group)
    animator.resetTransformationGroup("base")
end
