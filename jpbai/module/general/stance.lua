require "/scripts/activeitem/stances.lua"
require "/scripts/interp.lua"
-- Maybe i should make so that it use/change part of stance.lua
-- i will put here any stance specific function that i need to create
local oldSetStance = setStance
local oldUpdateStance = updateStance
local oldInitStances = initStances
function initStances()
    oldInitStances()
    table.insert(updateFunc, "updateStance")
end
local function inherit(stanceName, json)
    if self.stances[stanceName]["inherit"] then
        local parent = inherit(self.stances[stanceName]["inherit"], self.stances[stanceName])
        local result = sb.jsonMerge(copy(self.stances[self.stances[stanceName]["inherit"]]), copy(json) )
        return result
    else
        if self.stances[stanceName] then
            return sb.jsonMerge(copy(self.stances[stanceName]), copy(json))  
        else
            return json
        end
    end
end
function setStance(stanceName) -- replace and expend on the old version in stances.lua
    self.stanceName = stanceName
    status.setPrimaryDirectives("")
    if self.stances[stanceName] then
        if self.stances[stanceName]["inherit"] then
            self.stance = inherit(self.stances[stanceName]["inherit"], self.stances[stanceName]) -- sb.jsonMerge(copy(self.stances[self.stances[stanceName]["inherit"]]), self.stances[stanceName])  
        else
            self.stance = copy(self.stances[stanceName])
        end
    else
        sb.logError("[JPBAI Framework] [setStance] stance %s couldn't be found", stanceName)
    end
    self.stanceTimer = self.stance.duration

    for a, s in pairs(self.stance.animationStates or {}) do
        if hasAnimationState(a, s) then -- why doesn't starbound already have such a function ?
            animator.setAnimationState(a, s)
        else
            sb.logError("[JPBAI Framework] %s in %s couldn't be found", a, s)
        end
    end
    if self.stance.playSounds then
        for _, s in ipairs(self.stance.playSounds) do
            if animator.hasSound(s) then animator.playSound(s) end
        end
    end
    if self.stance.burstParticleEmitters then
        for _, e in ipairs(self.stance.burstParticleEmitters) do
            animator.burstParticleEmitter(e)
        end
    end
    if not self.lightFlash then
        self.lightFlash = {}
        self.lightFlashprogress = {}
        self.lightFlashDuration = {}
    end
    for lightName, value in pairs(self.stance.lightFlash or {}) do
        animator.setLightActive(lightName, true)

        self.lightFlash[lightName] = getLightColor(lightName)
        self.lightFlashprogress[lightName] = 0
        self.lightFlashDuration[lightName] = 10
        if type(value) == "number" then self.lightFlashDuration[lightName] = value end
    end
    
    if self.player then
        if self.player.rotate then self.stancePlayerRotation = copy(self.player.rotate) mcontroller.setRotation(util.toRadians(self.stancePlayerRotation) * mcontroller.facingDirection()) end
        if self.player.primaryDirective then status.setPrimaryDirectives(self.player.primaryDirective) end
    else
        if self.stancePlayerRotation then self.stancePlayerRotation = 0 mcontroller.setRotation(0) end -- reset player rotation because it can mess with collision
    end
    -- Convert Weapon.lua weapon rotation and offset to proper Transformation for weapon group, merge if a transformation for weapon group already exist

    if self.stance.weaponRotation or self.stance.weaponOffset then
        if config.getParameter("debug") then
            sb.logInfo("[JPBAI Framework] Found Weapon.lua specific weapon transform in stance %s", self.stanceName)
            if self.stance.weaponRotation and not self.stance.weaponOffset then
                sb.logInfo("[JPBAI Framework] Found weaponRotation : %s", self.stance.weaponRotation)
            elseif not self.stance.weaponRotation and self.stance.weaponOffset then
                sb.logInfo("[JPBAI Framework] Found weaponOffset : %s", self.stance.weaponOffset)
            else
                sb.logInfo("[JPBAI Framework] Found weaponRotation : %s and weaponOffset : %s", self.stance.weaponRotation, self.stance.weaponOffset)
            end
        end
        if not self.stance.transformations then self.stance.transformations = jarray() end
        if not self.stance.transformations.weapon then self.stance.transformations.weapon = jarray() end

        if self.stance.weaponRotation then
            if self.stance.transformations.weapon.rotate ~= nil then
                self.stance.transformations.weapon.rotate = self.stance.transformations.weapon.rotate + self.stance.weaponRotation
            else
                self.stance.transformations.weapon.rotate = self.stance.weaponRotation
            end
        end
        if self.stance.weaponOffset then
            if self.stance.transformations.weapon.translate ~= nil then 
                self.stance.transformations.weapon.translate = vec2.add(self.stance.transformations.weapon.translate, self.stance.weaponOffset) 
            else 
                self.stance.transformations.weapon.translate = self.stance.weaponOffset
            end 
        end
    end

    if self.stance.weaponAngularVelocity then
        if config.getParameter("debug") then
            sb.logInfo("[JPBAI Framework] Found Weapon.lua specific velocity for weapon transform in stance %s", self.stanceName)
            sb.logInfo("[JPBAI Framework] Found weaponAngularVelocity : %s", self.stance.weaponAngularVelocity)
        end
        if not self.stance.transformations then self.stance.transformations = jarray() end
        if not self.stance.transformations.weapon then self.stance.transformations.weapon = jarray() end
        if not self.stance.transformations.weapon.velocity then self.stance.transformations.weapon.velocity = jarray() end

        if self.stance.weaponAngularVelocity and self.stance.weaponAngularVelocity ~= 0 then 
            if self.stance.transformations.weapon.velocity.rotate then 
                self.stance.transformations.weapon.velocity.rotate = self.stance.transformations.weapon.velocity.rotate + self.stance.weaponAngularVelocity 
            else 
                self.stance.transformations.weapon.velocity.rotate = self.stance.weaponAngularVelocity 
            end 
        end
    end
    for group, transform in pairs(self.stance.transformations or {}) do
        animator.resetTransformationGroup(group)
        local rotationCenter = transform.rotationCenter or {0, 0}
        local translate, rotate, scale, rotationCenter = copy(transform.translate), copy(transform.rotate), copy(transform.scale), copy(transform.rotationCenter) or {0, 0}

        if transform.inherit then
            local inheritedValue = self.stance.transformations[transform.inherit]
            if inheritedValue then
                if inheritedValue.translate then translate = vec2.add(inheritedValue.translate or {0, 0}, translate or {0, 0}) end
                if inheritedValue.rotate then rotate = (inheritedValue.rotate or 0) + (rotate or 0) end
                if inheritedValue.scale then scale = (inheritedValue.scale or 0) + (scale or 1) end
                if inheritedValue.rotationCenter then rotationCenter = vec2.add(inheritedValue.rotationCenter or {0, 0}, rotationCenter or {0, 0}) end
            end
        end
        
        if translate then animator.translateTransformationGroup(group, translate) end
        if rotate then animator.rotateTransformationGroup(group, util.toRadians(rotate), rotationCenter) end
        if scale then animator.scaleTransformationGroup(group, scale) end
    end

    if type(self.stance.armRotation) == "table" then
        self.armRotation = self.stance.armRotation[1]
    else
        self.armRotation = self.stance.armRotation or 0
    end
    
    if self.stance.lerpTo then
        if not coroutine.resume(self.coroutine.lerp) then
            self.coroutine.lerp = coroutine.create(function(dt) lerpStance(dt) end)
            coroutine.resume(self.coroutine.lerp, script.updateDt())
        end
    end
    
    if self.stance.resetAim then
        self.aimAngle = 0
    elseif self.stance.aimAngle then
        self.aimAngle = self.stance.aimAngle
    end

    if self.stance.frontArmFrame ~= nil then activeItem.setFrontArmFrame(self.stance.frontArmFrame) end
    if self.stance.backArmFrame ~= nil then activeItem.setBackArmFrame(self.stance.backArmFrame) end
    if self.stance.holdingItem ~= nil then activeItem.setHoldingItem(self.stance.holdingItem) end
    if self.stance.twoHanded ~= nil then activeItem.setTwoHandedGrip(self.stance.twoHanded) end

    updateAim(self.stance.allowRotate, self.stance.allowFlip)
    if self.stance.invertDirection then
        activeItem.setFacingDirection(-1 * (self.aimDirection or 0))
    end

    if self.stance.user then
        if self.stance.user.rotate then mcontroller.rotate(util.toRadians(self.stance.user.rotate)) end
        if self.stance.user.angle then mcontroller.setRotation(self.stance.user.angle) end
        if self.stance.user.resetAngle then mcontroller.setRotation(0) end
        if self.stance.user.invertFacingDirection then mcontroller.controlFace(-1 * mcontroller.facingDirection()) end
    end
end

function updateStance(dt) -- added updateAim in so that rotation and flip get updated
    if self.stance then
        updateAim(self.stance.allowRotate, self.stance.allowFlip)
        
        if self.coroutine.lerp then
            local status, error = coroutine.resume(self.coroutine.lerp, dt)
            if not status then
                if not error == "cannot resume dead coroutine" then sb.logError("[JPBAI Framework] %s", error) end
                self.coroutine.lerp = nil
            end
        else
            if self.stance.armAngularVelocity ~= nil then self.armRotation = self.armRotation + self.stance.armAngularVelocity end
            if sb.printJson(self.stance.transformations or {}) ~= "{}" then end
            for group, transform in pairs(self.stance.transformations or {}) do
                local velocity = copy(transform.velocity)
                local translate, rotate, scale, rotationCenter
                if velocity then
                    translate, rotate, scale, rotationCenter = copy(velocity.translate), copy(velocity.rotate), copy(velocity.scale), copy(transform.rotationCenter) or {0, 0}
                end

                if transform.inherit then
                    local inheritedValue = self.stance.transformations[transform.inherit]
                    if inheritedValue.velocity then
                        if not velocity then velocity = jarray() end
                        --sb.logInfo("inheritedValue.velocity %s", inheritedValue.velocity)
                        if inheritedValue.velocity.translate then translate = vec2.add(inheritedValue.velocity.translate or {0, 0}, translate or {0, 0}) end
                        if inheritedValue.velocity.rotate then rotate = (inheritedValue.velocity.rotate or 0) + (rotate or 0) end
                        if inheritedValue.velocity.scale then scale = (inheritedValue.velocity.scale or 0) + (scale or 0) end
                    end
                end
                if translate or rotate or scale then
                    --sb.logInfo("%s, %s, %s, %s", translate, rotate, scale, rotationCenter)
                    if translate then animator.translateTransformationGroup(group, vec2.mul(translate, dt)) end
                    if velocity.rotate then animator.rotateTransformationGroup(group, util.toRadians((velocity.rotate * dt)), rotationCenter) end
                    if scale then animator.scaleTransformationGroup(group, scale * dt) end
                end
            end
            if self.player then
                if self.player.velocity then 
                    if self.player.velocity.rotate then
                        self.stancePlayerRotation = self.stancePlayerRotation + (self.player.velocity.rotate * dt)
                        mcontroller.setRotation(util.toRadians(self.stancePlayerRotation) * mcontroller.facingDirection())
                    end
                end
            end
            if self.stance.invertDirection then activeItem.setFacingDirection(-1 * (self.aimDirection or 0)) else activeItem.setFacingDirection((self.aimDirection or 0)) end
        end

        for lightName, _ in pairs(self.lightFlash or {}) do
            if self.lightFlashprogress[lightName] < 1 then
                self.lightFlash[lightName] = interpColor(self.lightFlashprogress[lightName], self.lightFlash[lightName], {0, 0, 0})
                self.lightFlashprogress[lightName] = math.min(1.0, self.lightFlashprogress[lightName] + (dt / self.lightFlashDuration[lightName]))
                animator.setLightColor(lightName, self.lightFlash[lightName])
                if self.lightFlashprogress[lightName] >= 1 then
                    animator.setLightActive(lightName, false)
                    animator.setLightColor(lightName, getLightColor(lightName))
                end
            end
        end

        if self.stanceTimer then
            self.stanceTimer = math.max(self.stanceTimer - dt, 0)
        
            if type(self.stance.armRotation) == "table" and not self.coroutine.lerp then
            local stanceRatio = 1 - (self.stanceTimer / self.stance.duration)
            self.armRotation = util.lerp(stanceRatio, self.stance.armRotation)
            end
        
            if self.stanceTimer <= 0 and not self.coroutine.lerp then
            if self.stance.transition then
                setStance(self.stance.transition)
            end
            if self.stance.transitionFunction then
                _ENV[self.stance.transitionFunction]()
            end
            end
        end
    end
end

function lerpStance(dt)
    local progress = 0
    local from = self.stance
    local to = self.stances[from['transition']]
    local fromAimAngle = self.aimAngle or 0
    local armProgress, aimProgress, armAngle

    util.wait(from.duration or 0.25, function(dt)
        for group, transform in pairs(from.transformations or {}) do
            if to.transformations[group] then
                animator.resetTransformationGroup(group)
                local toTranform = to.transformations[group]

                local translate, rotate, scale, rotationCenter = copy(transform.translate), copy(transform.rotate), copy(transform.scale), copy(transform.rotationCenter)
                if transform.inherit then
                    local inheritedValue = from.transformations[transform.inherit]
                    translate = vec2.add(inheritedValue.translate or {0, 0}, translate or {0, 0})
                    rotate = (inheritedValue.rotate or 0) + (rotate or 0)
                    scale = (inheritedValue.scale or 0) + (scale or 1)
                    rotationCenter = vec2.add(inheritedValue.rotationCenter or {0, 0}, rotationCenter or {0, 0})
                end

                local translate = vec2.lerp(progress, translate or {0, 0}, toTranform.translate or {0, 0})
                local rotate = interp.linear(progress, rotate or 0, toTranform.rotate or 0)
                local rotationCenter = vec2.lerp(progress, rotationCenter or {0, 0}, toTranform.rotationCenter or {0, 0})
                local scale = interp.linear(progress, scale or 1 , toTranform.scale or 1)

                if translate then animator.translateTransformationGroup(group, translate) end
                if rotate then animator.rotateTransformationGroup(group, util.toRadians(rotate), rotationCenter) end
                if scale then animator.scaleTransformationGroup(group, scale) end

            else 
                animator.resetTransformationGroup(group)
                local translate, rotate, scale, rotationCenter = copy(transform.translate), copy(transform.rotate), copy(transform.scale), copy(transform.rotationCenter)
                if transform.inherit then
                    local inheritedValue = from.transformations[transform.inherit]
                    translate = vec2.add(inheritedValue.translate or {0, 0}, translate or {0, 0})
                    rotate = (inheritedValue.rotate or 0) + (rotate or 0)
                    scale = (inheritedValue.scale or 0) + (scale or 1)
                    rotationCenter = vec2.add(inheritedValue.rotationCenter or {0, 0}, rotationCenter or {0, 0})
                end

                local translate = vec2.lerp(progress, translate or {0, 0}, {0, 0})
                local rotate = interp.linear(progress, rotate or 0, 0)
                local rotationCenter = vec2.lerp(progress, rotationCenter or {0, 0}, {0, 0})
                local scale = interp.linear(progress, scale or 1, 1)

                if translate then animator.translateTransformationGroup(group, translate) end
                if rotate then animator.rotateTransformationGroup(group, util.toRadians(rotate), rotationCenter) end
                if scale then animator.scaleTransformationGroup(group, scale) end
            end
        end
        
        local aimAngle = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
        armAngle = 0
        armProgress = util.toRadians(interp.linear(progress, from.armRotation or 0, to.armRotation or 0) )
        aimProgress = interp.linear(progress, fromAimAngle, aimAngle or 0)
        
        if (from.allowRotate and to.allowRotate) or to.allowRotate then
            armAngle = aimProgress + armProgress
        elseif from.allowRotate then
            armAngle = interp.linear(progress, fromAimAngle + util.toRadians(from.armRotation), 0 + util.toRadians(to.armRotation) )
        else
            armAngle = armProgress
        end
        activeItem.setArmAngle(armAngle)
        if progress > 0.5 then 
            if to.frontArmFrame ~= nil then activeItem.setFrontArmFrame(to.frontArmFrame) end
            if to.backArmFrame ~= nil then activeItem.setBackArmFrame(to.backArmFrame) end
            if to.invertDirection then
                activeItem.setFacingDirection(-1 * (self.aimDirection or 0))
            end
        end

        if to.user then
            if to.user.angle then 
                mcontroller.rotate(interp.linear(progress, util.toRadians(from.user.angle or 0), util.toRadians(to.user.angle or 0)))
            end
            if progress > 0.5 then
                if to.user.invertFacingDirection then 
                    mcontroller.controlFace(-1 * mcontroller.facingDirection()) 
                end
            end
        end

        progress = math.min(1.0, progress + (dt / from.duration))
    end)
    self.armRotation = to.armRotation or 0
    if tostring.resetAim then
        self.aimAngle = 0
    elseif to.aimAngle then
        self.aimAngle = to.aimAngle
    end
    updateAim(to.allowRotate, to.allowFlip)
end

function uninitStance()
    for lightName, _ in pairs(self.lightFlash or {}) do-- reset light state and color
        animator.setLightActive(lightName, getLightState(lightName))
        animator.setLightColor(lightName, getLightColor(lightName))
    end
end

-- Stance Variable/Parameters
-- "duration"
-- "animationState"
-- "transformations"
-- "armRotation"
-- "resetAim"
-- "twoHanded"
-- "allowRotate"
-- "allowFlip"
-- "transitionFunction"
-- "transition" can be added to a stance to change stances... don't remember seeing it used in vanilla