projCal = {}
function projCal.wouldTouchEntity(startPos, endPos, boundBox, options)
    local query = world.entityQuery(vec2.sub(startPos, {boundBox[1], [2]}), vec2.sub(endPos, {boundBox[3], [4]}), {withoutEntityId = activeItem.ownerEntityId(), order = "nearest"} or {})
    --world.polyContains
    
end

function projCal.maxHigh(upwardVelocity, angle)
    local gravity = world.gravity()
end