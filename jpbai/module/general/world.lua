worldEx = {}
function worldEx.entityInPoly(points, whiteList, options)
    if not points then return nil end
    local options = options or {
        withoutEntityId = activeItem.ownerEntityId(),
        order = "nearest"
    }
    local points = poly.scale(points, 1.05)
    points = poly.translate(poly.scale(points, {mcontroller.facingDirection(), 1}), mcontroller.position())
    local boundBox = poly.boundBox(points)
    local list = world.entityQuery({boundBox[1], boundBox[2]}, {boundBox[3], boundBox[4]}, options)
    world.debugPoly(points, "yellow")
    world.debugLine({boundBox[1], boundBox[2]}, {boundBox[3], boundBox[2]}, "green")
    world.debugLine({boundBox[3], boundBox[2]}, {boundBox[3], boundBox[4]}, "green")
    world.debugLine({boundBox[3], boundBox[4]}, {boundBox[1], boundBox[4]}, "green")
    world.debugLine({boundBox[1], boundBox[4]}, {boundBox[1], boundBox[2]}, "green")
    for i, e in pairs(list or {}) do
        local posA = world.entityPosition(e)
        local posB = world.entityMouthPosition(e) or posA
        world.debugLine(posA, posB, "red")
        if world.polyContains(points, posA) or world.polyContains(points, posB) then
            if whiteList then
                local entityType = world.entityType(e)
                if type(whiteList) == "table" then
                    for _, t in pairs(whiteList) do 
                        if t == entityType then return e end
                    end
                else
                    if whiteList[entityType] then return e end
                end
            else
                return e
            end
        end
    end
end

function worldEx.entitiesInPoly(points, whiteList, options)
    if not points then return nil end
    local options = options or {
        withoutEntityId = activeItem.ownerEntityId(),
        order = "nearest"
    }

    local points = poly.scale(points, 1.05)
    points = poly.translate(poly.scale(points, {mcontroller.facingDirection(), 1}), mcontroller.position())
    local boundBox = poly.boundBox(points)
    local list = world.entityQuery({boundBox[1], boundBox[2]}, {boundBox[3], boundBox[4]}, options)
    world.debugPoly(points, "yellow")
    world.debugLine({boundBox[1], boundBox[2]}, {boundBox[3], boundBox[2]}, "green")
    world.debugLine({boundBox[3], boundBox[2]}, {boundBox[3], boundBox[4]}, "green")
    world.debugLine({boundBox[3], boundBox[4]}, {boundBox[1], boundBox[4]}, "green")
    world.debugLine({boundBox[1], boundBox[4]}, {boundBox[1], boundBox[2]}, "green")
    
    local result = {}
    for i, e in pairs(list or {}) do
        local posA = world.entityPosition(e)
        local posB = world.entityMouthPosition(e) or posA
        world.debugLine(posA, posB, "red")
        if world.polyContains(points, posA) or world.polyContains(points, posB) then
            if whiteList then
                local entityType = world.entityType(e)
                if type(whiteList) == "table" then
                    for _, t in pairs(whiteList) do 
                        if t == entityType then table.insert(result, e) end
                    end
                else
                    if whiteList[entityType] then table.insert(result, e) end
                end
            else
                table.insert(result, e)
            end
        end
    end
    return result
end