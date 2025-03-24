animationEx = {}
-- a bunch of bridge function for animator
function animationEx.init() -- keep in memory the 'effective' animation config of the item
    local animationFile = config.getParameter("animation") 
    if type(animationFile) == "string" then animationFile = root.assetJson(config.getParameter("animation")) end
    
    local itemCfg = root.itemConfig(item.descriptor())
    itemCfg = itemCfg["parameters"]["animationCustom"] or itemCfg["config"]["animationCustom"] or {}
    self.animationCfg = util.mergeTable(animationFile, itemCfg)
end

function animationEx.randGlobalTag(args)
    local tagName, varNum = args.tagName, args.varNum
    animator.setGlobalTag(tagName, math.random(1, varNum or 1))
end

function animationEx.randPartTag(args)
    local partType, tagName, varNum = args.partType, args.tagName, args.varNum
    animator.setPartTag(partType, tagName, math.random(1, varNum or 1))
end

function animationEx.setGlobalTag(args)
    local tagName, varNum = args.tagName, args.varNum
    animator.setGlobalTag(tagName, varNum)
end

function animationEx.setPartTag(args)
    local partType, tagName, varNum = args.partType, args.tagName, args.varNum
    animator.setPartTag(partType, tagName, varNum)
end

function animationEx.pitchShift(args) -- pitch the shift a bit to make sound not repetitif
    local range = args.range or 50
    local pitch = getSoundPitch(args.soundName)
    --sb.logInfo("ogPitch %s", pitch)
    local modif = ( (math.random(0, range) - (range/2)) / (100 + range) )
    pitch = pitch + modif
    --sb.logInfo("modifier %s", modif)
    --sb.logInfo("newPitch %s", pitch)
    animator.setSoundPitch(args.soundName, pitch)
end
-- 

function animationEx.setAnimationState(args)
    local requiredState, newState, stateType, startNew = args.requiredState, args.newState, args.stateType, args.startNew
    if requiredState then
        if hasAnimationState(stateType, requiredState) and hasAnimationState(stateType, newState) then
            if animator.animationState(stateType) == requiredState then
                animator.setAnimationState(stateType, newState, startNew)
            end
        end
    else
        if hasAnimationState(stateType, newState) then
            animator.setAnimationState(stateType, newState, startNew)
        end
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