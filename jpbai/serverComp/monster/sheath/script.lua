require "/scripts/poly.lua"
local offset = {0, 0}
local parentEntity = nil
local direction = 1
local renderCfg = {
    texture = "/assetmissing.png",
    centered = true,

    rotation = 0,
    translate = {0, 0},
    scale = {1, 1}
}
local renderList = {}
local humanoid = "/humanoid.config"
function init()
    humanoid = root.assetJson(humanoid)
    parentEntity = config.getParameter("parentEntity")
    script.setUpdateDelta(1)
    if not parentEntity then self.die = true return end
end

function update(dt)
    if not parentEntity then return shouldDie(true) end
    if not world.entityExists(parentEntity) then return shouldDie(true) end

    local pos = world.entityMouthPosition(parentEntity)
    local vel = world.entityVelocity(parentEntity)

    mcontroller.setPosition(vec2.add(vec2.add(pos, offset), vec2.mul(vel, dt)))
    facingDirection(world.sendEntityMessage(parentEntity, "facingDirection", entity.id()):result())
    crouching(world.sendEntityMessage(parentEntity, "crouching", entity.id()):result())
    local bobingPos = findBobState(dt)
    local preparedRenders = {}

    for i, p in pairs(renderList or {}) do
        if not p.hide then
            local render = prepareRender(dt, p, bobingPos)
            if render then
                table.insert(preparedRenders, render) 
            end
        end
    end
    localRender(preparedRenders)
end

function uninit()
    shouldDie(true)
end

function crouching(crouching)
    if crouching then
        offset = {0, -0.5}
    else
        offset = {0, 0}
    end
end

function facingDirection(facingDirection)
    if facingDirection then
        direction = facingDirection
        if facingDirection > 0 then
            animator.setFlipped(true)
        else
            animator.setFlipped(false)
        end
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

function addRender(id, texture, centered, translate, rotation, scale, renderLayer)
    renderList[id] = copy(renderCfg)

    if texture ~= nil then renderList[id].texture = texture end
    if centered ~= nil then renderList[id].centered = centered end

    if rotation ~= nil then renderList[id].rotation = rotation end
    if translate ~= nil then renderList[id].translate = translate end
    if scale ~= nil then renderList[id].scale = scale end

    if renderLayer ~= nil then renderList[id].renderLayer = renderLayer end
end

function removeRender(id)
    renderList[id] = nil
end

function showRender(id)
    renderList[id].hide = nil
end
function hideRender(id)
    renderList[id].hide = true
end

function setTexture(fullImagePath)
    renderList[id].texture = fullImagePath
end

function setRotate(id, val)
    renderList[id].rotation = (renderList[id].rotation + val) % 360
end

function setTranslate(id, val)
    renderList[id].translate = vec2.add(renderList[id].translate, val)
end

function setScale(id, val)
    renderList[id].scale = vec2.mul(renderList[id].scale, val)
end

function setCentered(id, val)
    renderList[id].centered = val
end

function setRenderLayer(id, val)
    renderList[id].renderLayer = val
end

function reset(id)
    renderList[id] = copy(renderCfg)
end

function prepareRender(dt, renderCfg, bobingPos)
    local cfg = {}
    local rotation = vec2.withAngle(math.rad(renderCfg.rotation))
    local texture = copy(renderCfg.texture)
    local pos = vec2.add(entity.position(), vec2.mul(renderCfg.translate, {direction, 1}))
    if renderCfg.scale then
        if type(renderCfg.scale) == "table" then
            if (renderCfg.scale[1] == 0) and (renderCfg.scale[2] == 0) then
                return {}
            else
                texture = texture .. "?scalenearest;" .. renderCfg.scale[1] .. "=" .. renderCfg.scale[2]
            end
        else
            if renderCfg.scale == 0 then
                return {}
            else
                texture = texture .. "?scalenearest=" .. renderCfg.scale
            end
        end
    end
    local imageSize = root.imageSize(texture)

    rotation = vec2.add(rotation, {0.02, 0})
    if (direction > 0) then
        if not ((rotation[1] <= 0) and ((math.abs(rotation[1]) ~= 0))) then
            texture = texture .. "?flipy"
        end
    elseif (direction < 0) then
        if ((rotation[1] >= 0) and ((math.abs(rotation[1]) ~= 0))) then
            texture = texture .. "?flipy"
        end
    end
    if not renderCfg.centered then -- move the position to act in a way that it isn't centered if needed for some reason
        --pos = vec2.sub(pos, vec2.mul(vec2.mul(imageSize, 0.125), 0.5)) 
    end
    local texturePos = vec2.sub(pos, vec2.mul(vec2.mul(rotation, {direction, 1}), 0.5))
    local rotationVec2 = vec2.add(pos, vec2.mul(vec2.mul(rotation, {direction, 1}), 0.5))

    --[[
        world.debugLine(pos, rotationVec2, "red")
        world.debugPoint(pos, "green")
        world.debugPoint(texturePos, "yellow")
        world.debugPoint(vec2.add(entity.position(), animator.partPoint("body", "offset")), "green")
    --]]
    cfg = {
        segmentImage = texture,
        maxLength = 1,

        fullbright = false,
        segmentSize = 1,
        startPosition = vec2.add(texturePos, {0, bobingPos}),
        endPosition = vec2.add(rotationVec2, {0, bobingPos})
    }
    if direction > 0 then
        cfg.renderLayer = renderCfg.renderLayer or "player-1"
    else
        cfg.renderLayer = renderCfg.renderLayer or "player"
    end
    
    return cfg
end
function localRender(cfg)
    monster.setAnimationParameter("chains", cfg)
end

local lastBobState = "idle"
local frameIndex = 1
local frameCycle = 0
function findBobState(dt)
    local result
    local bobState = world.sendEntityMessage(parentEntity, "bobState", entity.id()):result()
    if not bobState then return 0 end
    local bobState, backward = bobState[1], bobState[2]
    local humanoidTiming = humanoid.humanoidTiming
    local stateCycleIndex = {
        idle = 1,
        walk = 2,
        run = 3,
        swim = 4
    }
    local stateCycle = humanoidTiming.stateCycle[stateCycleIndex[bobState]] or 1
    local stateFrames = humanoidTiming.stateFrames[stateCycleIndex[bobState]]

    local bobFrameCount = 1
    if bobState ~= lastBobState then frameIndex = 1 frameCycle = dt end
    local frame = 1 + math.floor(frameIndex)
    local bobOffset = function(bobState, frame, stateFrames, backward)
        if backward then
            return humanoid[bobState][stateFrames - (frame - 1)]
        else
            return humanoid[bobState][frame]
        end
    end
    if bobState == "walk" then
        result = bobOffset("walkBob", frame, stateFrames, backward)
    elseif bobState == "run" then
        result = bobOffset("runBob", frame, stateFrames, backward)
    elseif bobState == "swimming" then
        result = bobOffset("swimBob", frame, stateFrames, backward)
    end
    -- this section is basicaly copy pasted from the starHumanoid file
    frameCycle = (frameCycle + (dt * 1)) % stateCycle
    frameIndex = util.clamp(frameCycle * stateFrames / stateCycle, 0, stateFrames - 1) 
    --
    lastBobState = bobState
    if result then
        return (result + 1) * 0.125
    else
        return 0
    end
end