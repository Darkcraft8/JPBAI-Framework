function initBehavior()
    self.behaviors = config.getParameter("behaviors", {})
    self.behaviorPaths = config.getParameter("behaviorPaths", {})
    behaviorPathBuild()
    if type(self.behaviors) == "string" then self.behaviors = root.assetJson(self.behaviors) or {} end
    self.behavior = {}
    self.behaviorEvents = config.getParameter("behaviorEvents", {}) -- event can be placed in this table to be directly referred to instead of copying in each behavior
    self.behaviorCooldown = {}
    self.behaviorTime = {}
    self.behaviorCurrentTime = {}
    self.behaviorPeriodicEventTimer = {}
    self.behaviorPeriodicEventLock = {}
    self.initBehavior = config.getParameter("initBehavior", "idle")
    setBehavior(self.initBehavior)
    
    self.inflictedDamage_Listener = damageListener("inflictedDamage", inflictedDamage)
    self.inflictedHits_Listener = damageListener("inflictedHits", inflictedHits)
    self.damageTaken_Listener = damageListener("damageTaken", damageTaken)
    table.insert(updateFunc, "behaviorUpdate")
    table.insert(updateFunc, "behaviorEx.damageAreaUpdate")
    
end
behaviorName = ""
local behavCheck = false
local behavCheckTimer = 0
local lastPlayerInput = {
    fireMode = "none",
    isShiftHeld = false,
    currentMove = nil
}
function behaviorPathBuild()
    if config.getParameter("debug") then sb.logInfo("[JPBAI] Building Behaviors Path") end
    for behavName, behavParam in pairs(self.behaviors) do
        if config.getParameter("debug") then sb.logInfo("Building Behaviors Path for %s", behavName) end
        for i, p in ipairs(behavParam["possibleOutcome"]) do
            if type(p) == "string" then 
                if config.getParameter("debug") then sb.logInfo("Fetching Behaviors Path for %s, outcome n'%s named %s", behavName, i, p) end
                self.behaviors[behavName]["possibleOutcome"][i] = self.behaviorPaths[p]
                if config.getParameter("debug") then sb.logInfo("path now %s", self.behaviors[behavName]["possibleOutcome"][i]) end
            end
        end
    end
    if config.getParameter("debug") then sb.logInfo("[JPBAI] Behaviors Path Finished") end
end

function behaviorUpdate(dt, fireMode, isShiftHeld, currentMove) -- find a way to lower the amount of time we check for possible outcome
    self.inflictedDamage_Listener:update()
    self.inflictedHits_Listener:update()
    self.damageTaken_Listener:update()
    if self.behavior["periodicEvent"] then
        for i, e in ipairs(self.behavior["periodicEvent"]) do 
            local triggerEvent = true
            if self.behaviorPeriodicEventTimer[behavior] then
                triggerEvent = (self.behaviorTime[behavior] > e.time)
            else
                self.behaviorPeriodicEventTimer[behavior] = dt
                triggerEvent = false
            end
            if triggerEvent and not self.behaviorPeriodicEventLock[behavior] then
                behaviorEvent(e)
                if e['repeat'] then
                    self.behaviorPeriodicEventTimer[behavior] = dt
                else
                    self.behaviorPeriodicEventLock[behavior] = true
                end
            end
        end
    end
    if self.behavior["eventOnStance"] then -- if the current stanceName is the same as the group name then we call it events
        for s, e in pairs(self.behavior["eventOnStance"]) do 
            if s == self.stanceName and not self.eventDone.stance[s] then
                self.eventDone.stance[s] = true
                behaviorEvents(e)
            end
        end
    end
    behaviorTimer(self.behaviorCooldown, "decrease")
    behaviorTimer(self.behaviorCurrentTime, "increase", self.behaviorTime)
    behaviorTimer(self.behaviorPeriodicEventTimer, "increase")
    local checkPossibleOutcome = coroutine.create(function(dt, fireMode, isShiftHeld, currentMove)
        if self.behavior["possibleOutcome"] then 
            if not (#self.behavior["possibleOutcome"] > 0) then return end
            if not self.behavior["random"] then
                for i, p in ipairs(self.behavior["possibleOutcome"]) do
                    
                    local useBehav = true
                    local behavior = p.behavior
                    local checkResult = {}
                    if self.behaviors[behavior] then
                        if config.getParameter("debug") then sb.logInfo("--[ behavior %s", behavior) end
                        for k, v in pairs(p.require) do
                            if player then -- player specific check
                                if k == "inSwapSlot" and not player.swapSlotItem() then
                                    if useBehav then
                                        useBehav = false
                                    end  
                                end
                            end
                            if k == "fireMode" then
                                if config.getParameter("debug") then sb.logInfo("fireMode %s", useBehav) end
                                if useBehav then
                                    useBehav = (v == fireMode)
                                end 
                            end
                            if k == "time" then 
                                if self.behaviorCurrentTime[behavior] then
                                    if useBehav then useBehav = (self.behaviorCurrentTime[behavior] > v) end
                                else
                                    self.behaviorTime[behavior] = v
                                    self.behaviorCurrentTime[behavior] = dt

                                    useBehav = false
                                end
                                if config.getParameter("debug") then sb.logInfo("time %s, %s", useBehav, self.behaviorCurrentTime[behavior]) end
                            end
                            if k == "move" then
                                local individialCheckResult 
                                if useBehav then useBehav, individialCheckResult = check_Move(currentMove, v, behavior) end 
                                if config.getParameter("debug") then sb.logInfo("move %s", individialCheckResult or useBehav) end
                            end
                            if k == "shift" then 
                                if useBehav then useBehav = (v == isShiftHeld) end 
                                if config.getParameter("debug") then sb.logInfo("shift %s", useBehav) end 
                            end
                            if k == "stance" then
                                if useBehav then useBehav = (v == self.stanceName) end 
                                if config.getParameter("debug") then sb.logInfo("stance %s", useBehav) end 
                            end
                            -- For use with extra scripts ex: custom function that check if a specific parameters is at a specific value while some boolean are true
                            if k == "function" then 
                                if useBehav then useBehav = check_Function(v) if useBehav then useBehav = true end end 
                                if config.getParameter("debug") then sb.logInfo("function %s", useBehav) end 
                            end
                            
                            if k == "facing" then
                                if useBehav then
                                    if v == "left" then
                                        if mcontroller.facingDirection() > 0 then
                                            useBehav = false
                                        end
                                    elseif v == "right" then
                                        if mcontroller.facingDirection() < 0 then
                                            useBehav = false
                                        end
                                    else
                                        if mcontroller.facingDirection() < 0 then
                                            useBehav = false
                                        end
                                    end
                                end 
                                if config.getParameter("debug") then sb.logInfo("facing %s", useBehav) end 
                            end

                            if k == "exactParam" then 
                                if useBehav then
                                    useBehav = check_ExactParam(v) 
                                end 
                                if config.getParameter("debug") then sb.logInfo("exactParam %s", useBehav) end 
                            end
                            if k == "greaterParam" then
                                if useBehav then 
                                    useBehav = check_GreaterParam(v)
                                end 
                                if config.getParameter("debug") then sb.logInfo("greaterParam %s", useBehav) end 
                            end
                            if k == "lowerParam" then
                                if useBehav then 
                                    useBehav = check_LowerParam(v)
                                end 
                                if config.getParameter("debug") then sb.logInfo("lowerParam %s", useBehav) end
                            end
            
                            if k == "hasLineOfSight" then
                                if useBehav then
                                    useBehav = not check_raycastToSpawnPos(v)
                                end 
                                if config.getParameter("debug") then sb.logInfo("hasLineOfSight %s", useBehav) end
                            end
                        end
                        if p.cooldown then
                            if useBehav then 
                                useBehav = check_Cooldown(behavior) 
                            end 
                            if config.getParameter("debug") then sb.logInfo("cooldown %s", useBehav) end
                        end
                        if config.getParameter("debug") then sb.logInfo("--] require %s", p.require) end
                    else
                        useBehav = false
                        sb.logInfo("Behavior %s doesn't exist!!!")
                    end
                    
                    if useBehav == true then
                        if p.cooldown then self.behaviorCooldown[behavior] = p.cooldown end
                        setBehavior(behavior)
                    return "Switching to Behavior | " .. behavior end
                end
            else
                local randomizedIndex = math.random(#self.behavior["possibleOutcome"])
                local i, p = randomizedIndex, self.behavior["possibleOutcome"][randomizedIndex]
                local useBehav = true
                local behavior = p.behavior
                local checkResult = {}
                if self.behaviors[behavior] then
                    if config.getParameter("debug") then sb.logInfo("--[ behavior %s", behavior) end
                    for k, v in pairs(p.require) do
                        if player then -- player specific check
                            if k == "inSwapSlot" and not player.swapSlotItem() then
                                if useBehav then
                                    useBehav = false
                                end  
                            end
                        end
                        if k == "fireMode" then
                            if config.getParameter("debug") then sb.logInfo("fireMode %s", useBehav) end
                            if useBehav then
                                useBehav = (v == fireMode)
                            end 
                        end
                        if k == "time" then 
                            if self.behaviorCurrentTime[behavior] then
                                if useBehav then useBehav = (self.behaviorCurrentTime[behavior] > v) end
                            else
                                self.behaviorTime[behavior] = v
                                self.behaviorCurrentTime[behavior] = dt

                                useBehav = false
                            end
                            if config.getParameter("debug") then sb.logInfo("time %s", time) end
                        end
                        if k == "move" then
                            local individialCheckResult 
                            if useBehav then useBehav, individialCheckResult = check_Move(currentMove, v, behavior) end 
                            if config.getParameter("debug") then sb.logInfo("move %s", individialCheckResult) end
                        end
                        if k == "shift" then 
                            if useBehav then useBehav = (v == isShiftHeld) end 
                            if config.getParameter("debug") then sb.logInfo("shift %s", useBehav) end 
                        end
                        if k == "stance" then
                            if useBehav then useBehav = (v == self.stanceName) end 
                            if config.getParameter("debug") then sb.logInfo("stance %s", useBehav) end 
                        end
                        -- For use with extra scripts ex: custom function that check if a specific parameters is at a specific value while some boolean are true
                        if k == "function" then 
                            if useBehav then useBehav = check_Function(v) if useBehav then useBehav = true end end 
                            if config.getParameter("debug") then sb.logInfo("function %s", useBehav) end 
                        end
                        
                        if k == "facing" then
                            if useBehav then
                                if v == "left" then
                                    if mcontroller.facingDirection() > 0 then
                                        useBehav = false
                                    end
                                elseif v == "right" then
                                    if mcontroller.facingDirection() < 0 then
                                        useBehav = false
                                    end
                                else
                                    if mcontroller.facingDirection() < 0 then
                                        useBehav = false
                                    end
                                end
                            end 
                            if config.getParameter("debug") then sb.logInfo("facing %s", useBehav) end 
                        end

                        if k == "exactParam" then 
                            if useBehav then
                                useBehav = check_ExactParam(v) 
                            end 
                            if config.getParameter("debug") then sb.logInfo("exactParam %s", useBehav) end 
                        end
                        if k == "greaterParam" then
                            if useBehav then 
                                useBehav = check_GreaterParam(v)
                            end 
                            if config.getParameter("debug") then sb.logInfo("greaterParam %s", useBehav) end 
                        end
                        if k == "lowerParam" then
                            if useBehav then 
                                useBehav = check_LowerParam(v)
                            end 
                            if config.getParameter("debug") then sb.logInfo("lowerParam %s", useBehav) end
                        end
        
                        if k == "hasLineOfSight" then
                            if useBehav then
                                useBehav = not check_raycastToSpawnPos(v)
                            end 
                            if config.getParameter("debug") then sb.logInfo("hasLineOfSight %s", useBehav) end
                        end
                    end
                    if p.cooldown then
                        if useBehav then 
                            useBehav = check_Cooldown(behavior) 
                        end 
                        if config.getParameter("debug") then sb.logInfo("cooldown %s", useBehav) end
                    end
                    if config.getParameter("debug") then sb.logInfo("--] require %s", p.require) end
                else
                    useBehav = false
                    sb.logInfo("Behavior %s doesn't exist!!!")
                end
                    
                if useBehav == true then
                    if p.cooldown then self.behaviorCooldown[behavior] = p.cooldown end
                    setBehavior(behavior)
                return "Switching to Behavior | " .. behavior end
            end
        end    
    end)
    local status, responce = coroutine.resume(checkPossibleOutcome, dt, fireMode, isShiftHeld, currentMove)
    if not status then sb.logInfo("behaviorUpdate.checkPossibleOutcome | %s, %s", status, responce) end

    lastPlayerInput = {
        fireMode = fireMode,
        isShiftHeld = isShiftHeld,
        currentMove = currentMove
    }
end

function uninitBehavior()
    resetBehavior()
end

function setBehavior(newBehaviorName)
    if config.getParameter("debug") then sb.logInfo("--[ newBehaviorName %s", newBehaviorName) end
    if self.behavior["eventOnUninit"] then behaviorEvents(self.behavior["eventOnUninit"]) end
    resetBehavior()
    behaviorName = newBehaviorName
    self.behavior = self.behaviors[behaviorName]
    self.eventDone = {}
    if self.behavior["eventOnStance"] then self.eventDone.stance = {} end
    if self.behavior["eventOnInit"] then behaviorEvents(self.behavior["eventOnInit"]) end
    if self.behavior["stance"] then setStance(self.behavior["stance"]) end
end

function resetBehavior()
    self.behavior = {}
    self.behaviorCooldown = {}
    self.behaviorTime = {}
    self.behaviorCurrentTime = {}
    self.behaviorPeriodicEventTimer = {}
    self.behaviorPeriodicEventLock = {}
end

function behaviorEvents(events)
    local events = events or {}
    if config.getParameter("debug") then sb.logInfo("events %s", sb.printJson(events, 1)) end
    
    if events then
        if #events > 0 then
            for i, e in ipairs(events) do
                if type(e) == "string" then 
                    if config.getParameter("debug") then sb.logInfo("behaviorEvents %s", sb.printJson(self.behaviorEvents[e], 1)) end
                    if self.behaviorEvents[e] then behaviorEvents(self.behaviorEvents[e]) end
                else
                    behaviorEvent(e)
                end
            end
        else
            behaviorEvent(events)
        end
    end
end

function behaviorEvent(eventCfg) -- Handle the Different Event kind|Type
    if eventCfg.event then
        if string.lower(eventCfg.event) == "monster" then behavior_monster(eventCfg) return end
        if string.lower(eventCfg.event) == "projectile" then behavior_projectile(eventCfg) return end
        if string.lower(eventCfg.event) == "function" then call(eventCfg) return end
        if string.lower(eventCfg.event) == "setcursor" then activeItem.setCursor(eventCfg.cursor) return end
        if string.lower(eventCfg.event) == "damagearea" then behavior_hitbox(eventCfg) return end
        if string.lower(eventCfg.event) == "playsound" then animator.playSound(eventCfg.soundName, eventCfg.loopNumber or 0) return end
    end
end

function behaviorTimer(list, operation, treshold) -- increase or decrease value of time, merged into one func
    local dt = script.updateDt()
    if operation == 'decrease' then
        for n, t in pairs(list) do
            if t > 0 then
                list[n] = t - dt
            end
        end
    elseif operation == 'increase' then
        for n, t in pairs(list) do
            if (treshold or {})[n] then
                if t < treshold[n] then
                    list[n] = t + dt
                end
            else
                if t < 90000 then
                    list[n] = t + dt
                end
            end
        end
    end
end

-- Callback
function inflictedDamage(notifications)
    --sb.logInfo("damageDealt %s", notifications)
    if self.behavior["eventOnDamageDealt"] then
        for _,notification in pairs(notifications) do
            behaviorEvents(self.behavior["eventOnDamageDealt"], notification)
        end
    end
end

function inflictedHits(notifications) 
    --sb.logInfo("hitEvent %s", notifications)
    if self.behavior["eventOnHitDealt"] then 
        for _,notification in pairs(notifications) do
            behaviorEvents(self.behavior["eventOnHitDealt"], notification)
        end
    end
end

function damageTaken(notifications) 
    --sb.logInfo("damageTaken %s", notifications)
    -- -65536 seem to be world or self 
    if self.behavior["eventOnDamageTaken"] then
        for _,notification in pairs(notifications) do
            behaviorEvents(self.behavior["eventOnDamageTaken"], notification)
        end
    end
end

-- Requirement Checks
function check_Move(currentMove, value, behavior)
    local result = true
    local individialCheckResult = {}
    if type(value) == "table" then
        for m, b in pairs(value) do
            if config.getParameter("debug") then sb.logInfo("move : %s", m) end
            if m == "forward" or m == "backward" then
                local movingBackward, movingForward
                if mcontroller.facingDirection() < 0 then -- facing left
                    movingForward = currentMove["left"] == true
                    movingBackward = currentMove["right"] == true
                else -- facing right
                    movingForward = currentMove["right"] == true
                    movingBackward = currentMove["left"] == true
                end

                if config.getParameter("debug") then 
                    sb.logInfo("direction : %s", mcontroller.facingDirection())
                    sb.logInfo("left %s", currentMove["left"])
                    sb.logInfo("right %s", currentMove["right"])

                    sb.logInfo("is going forward %s", movingForward)
                    sb.logInfo("is going backward %s", movingBackward)
                end

                if m == "forward" then
                    if movingForward ~= b then
                        result = false
                        individialCheckResult[m] = false
                    else
                        individialCheckResult[m] = true
                    end
                else
                    if movingBackward ~= b then
                        result = false
                        individialCheckResult[m] = false
                    else
                        individialCheckResult[m] = true
                    end
                end
            else
                if not currentMove[m] then
                    if b then
                        result = false
                        individialCheckResult[m] = false
                    end
                elseif currentMove[m] ~= b then
                    result = false
                    individialCheckResult[m] = false
                else
                    individialCheckResult[m] = true
                end
            end
        end
    elseif type(value) == "string" then
        if value == "forward" or value == "backward" then
            local movingBackward, movingForward
            if mcontroller.facingDirection() < 0 then -- facing left
                movingForward = currentMove["left"] == true
                movingBackward = currentMove["right"] == true
            else -- facing right
                movingForward = currentMove["right"] == true
                movingBackward = currentMove["left"] == true
            end
            if m == "forward" then
                if movingForward == b then
                    individialCheckResult[value] = true return true, individialCheckResult
                end
            else
                if movingBackward == b then
                    individialCheckResult[value] = true return true, individialCheckResult
                end
            end
            if value == "forward" then
                if mcontroller.facingDirection() < 0 then
                    if currentMove["left"] then individialCheckResult[value] = true return true, individialCheckResult end
                else
                    if currentMove["right"] then individialCheckResult[value] = true return true, individialCheckResult end
                end
            else
                if mcontroller.facingDirection() < 0 then
                    if currentMove["right"] then individialCheckResult[value] = true return true, individialCheckResult end
                else
                    if currentMove["left"] then individialCheckResult[value] = true return true, individialCheckResult end
                end
            end
        else
            if currentMove[value] then individialCheckResult[value] = true return true, individialCheckResult end
        end
    else
        sb.logError("[JPBAI Framework] Invalid Move Requirement Config For Behavior | %s", behavior)
    end

    return result, individialCheckResult
end

function check_Function(callbacks)
    if config.getParameter("debug") then sb.logInfo("callbacks %s", callbacks) end
    local funcReturned = true
    for _, func in ipairs(callbacks or {}) do 
        local args = nil
        local callback = func
        if type(func) == "table" then
            callback = func.callback
            args = func.args
        end
        if funcReturned then funcReturned = call({callback = callback, args = args}) end
        if not funcReturned then return funcReturned end
    end
    return funcReturned
end

function check_Cooldown(behaviorName)
    if not self.behaviorCooldown[behaviorName] then return true end
    if self.behaviorCooldown[behaviorName] <= 0 then return true end
    return false
end

function check_ExactParam(param) -- Todo
    for p, v in pairs(param) do 
        --sb.logInfo("%s, %s", sb.print(v), sb.print(config.getParameter(p)))
        --sb.logInfo("%s", sb.print(v) ~= sb.print(config.getParameter(p)))
        if sb.print(v) ~= sb.print(config.getParameter(p)) then return false end
    end
    return true
end

function check_GreaterParam(param) -- Todo
    for p, v in pairs(param) do 
        local typeKind = type(config.getParameter(p))
        if typeKind == "number" then
            if (config.getParameter(p) <= v) then
                return false
            end
        end
        if typeKind == "boolean" then
            if v == false then if config.getParameter(p) ~= nil then return false end end
            if v == true then if config.getParameter(p) ~= true then return false end end
        end
        if  typeKind == "table" then
            sb.logInfo("table can't be compared for the moment")
            return false
        end
    end
    return true
end

function check_LowerParam(param) -- Todo
    for p, v in pairs(param) do 
        local typeKind = type(v)
        if typeKind == "number" then
            if (config.getParameter(p) >= v) then
                 return false
            end 
        end
        if typeKind == "boolean" then
            if config.getParameter(p) then
                return false
            end
        end
        if typeKind == "table" then
            sb.logInfo("table can't be compared for the moment")
            return false
        end
    end
    return true
end

function check_raycastToSpawnPos(args)
    return world.lineTileCollision(mcontroller.position(), spawnPosition(args))
end


function arrayEqual(tableA, TableB)
    if tableA == nil and tableB == nil then return true end
    if tableA == nil then return false elseif tableB == nil then return false end
    for name, value in pairs(tableA) do
        if TableB[name] then
            if value ~= TableB[name] then return false end
        else
            return false
        end
    end
    return true
end

function tableEqual(tableA, TableB)
    if tableA == nil and tableB == nil then return true end
    if tableA == nil then return false elseif tableB == nil then return false end
    for index, value in ipairs(tableA) do 
        if TableB[index] then
            if value ~= TableB[index] then return false end
        else
            return false
        end
    end
    return true
end