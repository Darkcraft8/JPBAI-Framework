-- Swoosh Paticle
function swooshToParticle(imagePath, posOffset, delay, swooshDir, centered, localPos, inaccuracy, layer, destructionAction, size, fullbright, color, light, dir, posOverride)
    -- turn into a coroutine if a delay is given
    if delay and (delay ~= 0) then
        local co = coroutine.create(function(imagePath, posOffset, delay, swooshDir, centered, localPos, inaccuracy, layer, destructionAction, size, fullbright, color, light, dir)
            local imagePath, posOffset, delay, swooshDir, centered, localPos, inaccuracy, layer, destructionAction, size, fullbright, color, light, dir = imagePath, posOffset, delay, swooshDir, centered, localPos, inaccuracy, layer, destructionAction, size, fullbright, color, light, dir
            dir = dir or aimVector(inaccuracy or 0)
            util.wait((delay or 0) - (dt or script.updateDt()))
            local handPos = activeItem.handPosition(posOffset or {0, 0})
            local posOverride = vec2.add(world.entityPosition(activeItem.ownerEntityId()), handPos)
            swooshToParticle(imagePath, posOffset, 0, swooshDir, centered, localPos, inaccuracy, layer, destructionAction, size, fullbright, color, light, dir, posOverride)
        end)
        coroutine.resume(co, imagePath, posOffset, delay, swooshDir, centered, localPos, inaccuracy, layer, destructionAction, size, fullbright, color, light, dir)
        if coroutineList then table.insert(coroutineList, co) end
        return co
    end
    local dt = dt or script.updateDt()
    local localPos = localPos
    if not (localPos ~= nil) then localPos = true end
    local swooshDir = swooshDir or {1, 1}
    local projectileParam = {
        clientEntityMode = "ClientPresenceMaster",
        speed = 0.001,
        timeToLive = delay or 0,
        processing = "?multiply=fff0",
        damageTeam = { type = "ghostly" },
        movementSettings = {collisionEnabled = false, gravityEnable = false},
        actionOnReap ={}
    }
    local projectileDir = dir or aimVector(inaccuracy or 0)
    if projectileDir[1] < 0 then
        imagePath = imagePath .. "?flipy"
    end
    local imageSize = root.imageSize(imagePath)
    local offset = {0, 0}
    if centered then
        offset = vec2.mul(vec2.mul(imageSize, 0.125), 0.5)
    end
    if projectileDir[1] < 0 then
        offset = vec2.add(offset, {0, 0.125})
    end
    for ia = 1, imageSize[1] do
        for ib = 1, imageSize[2] do 
            local crop = string.format("?crop;%s=%s;%s=%s", ia - 1, ib - 1, ia, ib)
            local imagePixel = imagePath .. crop
            local particlePos = vec2.mul({ia, ib}, 0.125)
            local timeA, timeB = (ia * dt), (ib * (dt * 2))
            if swooshDir[1] < 0 then
                timeA = ((imageSize[1] - ia) * dt)
            elseif swooshDir[1] == 0 then
                timeA = 0
            end
            
            if swooshDir[2] < 0 then
                timeB = ((imageSize[2] - ib) * dt)
            elseif swooshDir[2] == 0 then
                timeB = 0
            end
            local time = ( (timeA + timeB) * 0.5 )
            local visualParam = {
                rotate = true,
                specification = {
                    fade = 1,
                    approach = {0, 0},
                    layer = layer or "middle",
                    destructionAction = destructionAction or "fade",
                    string = imagePixel,
                    type = "Textured",
                    destructionTime = (destructionTime or 0) + time,
                    size = size or 1,

                    initialVelocity = {0.25, 0},
                    finalVelocity = {0, 0},
                    timeToLive = 0,
                    variance = {},
                    collidesForeground= false,
                    collidesLiquid= false,
                    flip = false,
                    fullbright = fullbright or false,
                    color = color or {255, 255, 255, 255},
                    light = light or {0, 0, 0},

                    position = vec2.sub(particlePos, offset)
                },
                action = "particle"
            }
            table.insert(projectileParam.actionOnReap, visualParam)
        end
    end
    world.spawnProjectile("bullet-1", posOverride or vec2.add(world.entityPosition(activeItem.ownerEntityId()), activeItem.handPosition(posOffset or {0, 0})), activeItem.ownerEntityId(), projectileDir, localPos, projectileParam)
end