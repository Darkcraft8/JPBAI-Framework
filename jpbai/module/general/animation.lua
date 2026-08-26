animationEx = {}
-- a bunch of bridge function for animator
function animationEx.init() -- keep in memory the 'effective' animation config of the item
    local animationFile = config.getParameter("animation") 
    if type(animationFile) == "string" then animationFile = root.assetJson(config.getParameter("animation")) end
    
    local itemCfg = root.itemConfig(item.descriptor())
    itemCfg = itemCfg["parameters"]["animationCustom"] or itemCfg["config"]["animationCustom"] or {}
    self.animationCfg = util.mergeTable(animationFile, itemCfg)
end

function animationEx.setGlobalTags(tags)
    if not tags then return end
    for tagName, tagValues in pairs(tags) do
        animator.setGlobalTag(tagName, tagValues)
    end
end

function animationEx.randGlobalTag(tagName, varNum)
    if not tagName then return end
    animator.setGlobalTag(tagName, math.random(1, varNum or 1))
end

function animationEx.randPartTag(partType, tagName, varNum)
    if not partType or not tagName then return end
    animator.setPartTag(partType, tagName, math.random(1, varNum or 1))
end

function animationEx.setGlobalTag(tagName, varNum)
    if not tagName or not varNum then return end
    animator.setGlobalTag(tagName, varNum)
end

function animationEx.setPartTag(partType, tagName, varNum)
    if not partType or not tagName or not varNum then return end
    animator.setPartTag(partType, tagName, varNum)
end

function animationEx.pitchShift(soundName, range, pitch) -- pitch the shift a bit to make sound not seem too repetitif
    local range = range or 50
    local pitch = pitch 
    if type(pitch) ~= "number" then
        if animator.hasSound(soundName) then
            pitch = getSoundPitch(soundName)
        else
            pitch = 1
        end
    end
    --sb.logInfo("ogPitch %s", pitch)
    local modif = ( (math.random(0, range) - (range/2)) / (100 + range) )
    pitch = pitch + modif
    --sb.logInfo("modifier %s", modif)
    --sb.logInfo("newPitch %s", pitch)
    if animator.hasSound(soundName) then animator.setSoundPitch(soundName, pitch) end
    return pitch
end
-- 

function animationEx.setAnimationState(stateType, newState, startNew, requiredState)
    --sb.logInfo("%s, %s, %s, %s", stateType, newState, startNew, requiredState)
    if (requiredState ~= nil and requiredState ~= "null") then
        local hasRequiredStateResult, hasAnimationStateResult = hasAnimationState(stateType, requiredState), hasAnimationState(stateType, newState)
        if hasRequiredStateResult and hasAnimationStateResult then
            if animator.animationState(stateType) == requiredState then
                animator.setAnimationState(stateType, newState, startNew)
            end
        end
    else
        local hasAnimationStateResult = hasAnimationState(stateType, newState)
        if hasAnimationStateResult then
            animator.setAnimationState(stateType, newState, startNew)
        end
    end
end

function animationEx.playSounds(soundNames)
    if type(soundNames) == "string" then
        if animator.hasSound(soundNames) then animator.playSound(soundNames) end
    elseif type(soundNames) == "table" then
        for i, name in pairs(soundNames) do 
            if animator.hasSound(name) then animator.playSound(name) end
        end
    end
end
function animationEx.setSoundPool(soundName, soundPool)
    if not (soundName and soundPool) then return end
    if animator.hasSound(soundName) then animator.setSoundPool(soundName, soundPool) end
end
function animationEx.setSoundPitch(soundName, soundPitch, pitchShift)
    if not (soundName and soundPitch) then return end
    if pitchShift then
        animationEx.pitchShift(soundName, pitchShift, soundPitch)
    else
        if animator.hasSound(soundName) then animator.setSoundPitch(soundName, soundPitch) end
    end
end
function animationEx.setSoundPosition(soundName, position)
    if not (soundName and position) then return end
    if animator.hasSound(soundName) then animator.setSoundPosition(soundName, position) end
end
function animationEx.setSoundVolume(soundName, volume, rampTime)
    if not (soundName and volume) then return end
    if animator.hasSound(soundName) then animator.setSoundVolume(soundName, volume, rampTime) end
end


function animationEx.playSoundsAt(position, soundPools)
    if (type(position) ~= "table") and type(soundPools) ~= "table" then return end
    local projectiles = {}
    if type(soundPools[1]) == "table" then -- multiple sound pools
        for i, soundPool in pairs(soundPools or {}) do 
            local temp = {
                action = "sound",
                pitch = soundPool.pitch or 1,
                options = soundPool.pool or soundPool
            }
            if soundPool.pitchShift then
                local range = soundPool.pitchShift
                if type(range) ~= "number" then range = 25 end
                temp.pitch = animationEx.pitchShift("null", range, temp.pitch)
            end
            table.insert(projectiles, temp)
        end
    else -- single particle type
        local temp = {
            action = "sound",
            pitch = soundPools.pitch or 1,
            options = soundPools.pool or soundPools
        }
        if soundPools.pitchShift then
            local range = soundPools.pitchShift
            if type(range) ~= "number" then range = 25 end
            temp.pitch = animationEx.pitchShift("null", range, temp.pitch)
        end
        table.insert(projectiles, temp)
    end
    local param = {
        clientEntityMode = "ClientPresenceMaster",
        speed = 0.0001,
        timeToLive = 0,
        processing = "?multiply=fff0",
        damageTeam = { type = "ghostly" },
        movementSettings = {collisionEnabled = false, gravityEnable = false},
        actionOnReap = projectiles
    }
    --sb.logInfo("actionOnReap : %s", sb.printJson(projectiles, 1))
    world.spawnProjectile("bullet-1", position or mcontroller.position(), activeItem.ownerEntityId(), {1, 0}, false, jarray(param or {}))
end
function animationEx.spawnParticles(particles) -- particles = {"specification" : {}, "rotation" : 0}
    if type(particles) ~= "table" then return end
    local projectiles = {}
    if not particles.specification then -- multiple particle type
        for i, cfg in pairs(particles or {}) do 
            local temp = {
                action = "loop",
                count =  cfg.count or 1,
                body = {
                    {
			            action = "particle",
                        rotate = true,
                        specification = cfg.specification or {}
                    }
                }
            }
            local rotation = cfg.rotation or 0
            if not projectiles[tostring(rotation)] then projectiles[tostring(rotation)] = {} end
            table.insert(projectiles[tostring(rotation)], temp)
        end
    else -- single particle type
        local temp = {
            action = "loop",
            count =  particles.count or 1,
            body = {
                {
		            action = "particle",
                    rotate = true,
                    specification = particles.specification or {}
                }
            }
        }
        local rotation = particles.rotation or 0
        if not projectiles[tostring(rotation)] then projectiles[tostring(rotation)] = {} end
        table.insert(projectiles[tostring(rotation)], temp)
    end
    for rotationStr, onReap in pairs(projectiles or {}) do
        local param = {
            clientEntityMode = "ClientPresenceMaster",
            speed = 0.0001,
            timeToLive = 0,
            processing = "?multiply=fff0",
            damageTeam = { type = "ghostly" },
            movementSettings = {collisionEnabled = false, gravityEnable = false},
            actionOnReap = onReap
        }
        local dir = vec2.rotate({1, 0}, util.toRadians(tonumber(rotationStr)))
        world.spawnProjectile("bullet-1", mcontroller.position(), activeItem.ownerEntityId(), dir, false, jarray(param or {}))
    end
end

-- some animator utils --
function interpColor(ratio, a, b)
    local color = {0,0,0}
    color[1] = interp.linear(ratio, a[1], b[1])
    color[2] = interp.linear(ratio, a[2], b[2])
    color[3] = interp.linear(ratio, a[3], b[3])
    return color
end

function getLightState(lightName) --- return default light state
    local state = false
    if self.animationCfg["lights"] then
        if self.animationCfg["lights"] then
            if self.animationCfg["lights"][lightName] then
                if self.animationCfg["lights"][lightName]["active"] ~= nil then 
                    state = self.animationCfg["lights"][lightName]["active"]
                else
                    state = false
                end
            end
        end
    end
    return state
end

function getLightColor(lightName) --- return default light color
    local color = {255, 255, 255}
    if self.animationCfg["lights"] then
        if self.animationCfg["lights"] then
            if self.animationCfg["lights"][lightName] then
                if self.animationCfg["lights"][lightName]["color"] then 
                    color = self.animationCfg["lights"][lightName]["color"]
                end
            end
        end
    end
    return color
end

function getSoundPitch(soundName) --- return default sound pitch
    if self.animationCfg["sounds"] then
        if self.animationCfg["sounds"][soundName] then
            return self.animationCfg["sounds"][soundName]["pitchMultiplier"] or 1.0
        end
    end
    return 1.0
end

function hasAnimationType(stateType) --- return if the stateType exist
    if not stateType then return false end
    if self.animationCfg["animatedParts"] then
        if self.animationCfg["animatedParts"]["stateTypes"] then
            if self.animationCfg["animatedParts"]["stateTypes"][stateType] then
                return true
            end
        end
    end
    return false
end

function hasAnimationState(stateType, state) --- return if the state for the stateType exist
    if not stateType or not state then return false end
    if hasAnimationType(stateType) then
        if self.animationCfg["animatedParts"]["stateTypes"][stateType]["states"][state] then
            return true
        end
    end
    return false
end
---