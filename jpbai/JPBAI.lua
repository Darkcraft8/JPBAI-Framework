require "/scripts/poly.lua"
require "/scripts/status.lua"
-- Json Powered Behavioral Active Item >:D
-- or JPBAI for short
-- Can also be called behavioral items
-- a bunch of list for frequently called func
initFunc = {
    "activeItemCfg",
    "initStances",
    "initBehavior",
    "movementControl.init",
    "configInit"
}
updateFunc = { -- just so that incase a script has a update function it can be added
    "movementControl.update"
}
uninitFunc = {
    "uninitBehavior",
    "uninitStance",
    "movementControl.uninit"
}

require "/jpbai/module/general/logic.lua"
require "/jpbai/module/general/stance.lua"
require "/jpbai/module/general/animation.lua"
require "/jpbai/module/general/inventory.lua"
require "/jpbai/module/general/status.lua"
require "/jpbai/module/general/behavior.lua"
require "/jpbai/module/general/behaviorEX.lua"
require "/jpbai/module/general/movement.lua"

debugMode = false
local playerInteractTimer = 0
function init()
    debugMode = config.getParameter("debug", false)
    JPBAIConfig = root.assetJson("/jpbai/JPBAI.config")
    storage = config.getParameter("scriptStorage", {})
    for _, func in ipairs(initFunc) do
        if type(func) == "function" then
            func()
        else
            local callback = findCallback(func, true)
            callback()
        end
    end
    for _, func in ipairs(config.getParameter("initFunction", {})) do 
        if type(func) == "function" then
            func()
        else
            local callback = findCallback(func, true)
            if callback then
                callback()
            end
        end
    end
    
    for _, scriptPath in ipairs(config.getParameter("pRequire", {})) do 
        pRequire(scriptPath)
    end
    overrideTech(true)
end

function update(dt, fireMode, isShiftHeld, currentMove)
    for _, func in ipairs(updateFunc) do 
        if type(func) == "function" then
            func(dt, fireMode, isShiftHeld, currentMove)
        else
            local callback = findCallback(func)
            if callback then
                callback(dt, fireMode, isShiftHeld, currentMove)
            end
        end
    end
    if playerInteractTimer > 0 then playerInteractTimer = playerInteractTimer - dt end
end

function uninit()
    for _, func in ipairs(uninitFunc, {}) do 
        if type(func) == "function" then
            func()
        else
            local callback = findCallback(func, true)
            callback()
        end
    end
    for _, func in ipairs(config.getParameter("uninitFunction", {})) do
        if type(func) == "function" then
            func()
        else
            local callback = findCallback(func, true)
            if callback then
                callback()
            end
        end
    end
    behaviorEvents(config.getParameter("uninitEvent", {}))
    overrideTech(false)
    if type(storage) ~= "nil" then
        --sb.logInfo("storage == [ %s ]", storage)
        activeItem.setInstanceValue("scriptStorage", storage)
    end
end

function activeItemCfg()
    self.coroutine = {} -- here just so that i don't have to make a new func just for it
    if animationEx.init then animationEx.init() end -- keep in memory the 'effective' animation config of the item
end

-- getParameters Replacement, modified a bit from Encyclopedia
function configInit()
    customConfig = {}
    customConfig.rootParameter = config.getParameter
    customConfig.getParameter = function(path, defaultValue)
        if path == "" then return util.mergeTable(config.param, config.rootParameter('')) end -- lua asked for all the parameters data
        local pathSegment = segmentPath(path)
        local currentResult = nil
        for _, string in ipairs(pathSegment) do
            if not currentResult then 
                if config.rootParameter(string) then
                    currentResult = config.rootParameter(string)
                else
                    return defaultValue
                end
            else
                if currentResult[string] then
                    currentResult = currentResult[string]
                else
                    return defaultValue
                end
            end
        end
        if currentResult ~= nil then
            return currentResult
        else
            return defaultValue
        end
    end
    config = customConfig
    --sb.logInfo("Config Override Initialisation Done\nconfig.rootParameter | Vanilla getParameter\nconfig.getParameter  | getParameter from a list that can get updated using setParameter")
end

function call(eventCfg) -- because whe can't directly do _ENV[funcGroup.Func]()
    --sb.logInfo("eventCfg %s", eventCfg)
    if type(eventCfg) == "string" then
        callback = findCallback(tostring(eventCfg))
        if callback then
            return callback()
        else
            sb.logError("[JPBAI Framework] Function %s Couldn't be found", eventCfg)
        end
    else
        callback = findCallback(tostring(eventCfg.callback))
        if callback then
            local args = {}
            for i, arg in pairs(eventCfg.args or {}) do
                args[i] = checkStorage(arg)
            end
            if type(eventCfg.args) == "table" then
                local result
                if eventCfg.args[1] then
                    --sb.logInfo("executing %s with args %s", tostring(eventCfg.callback), sb.printJson(args))
                    result = table.pack(callback(table.unpack(args)))
                else
                    --sb.logInfo("executing %s with args %s", tostring(eventCfg.callback), eventCfg.args)
                    result = table.pack(callback(args))
                end
                if eventCfg.storage then
                    if type(eventCfg.storage) == "table" then
                        for i, a in pairs(eventCfg.storage or {}) do
                            setStorage(a or i, result[i])
                        end
                    else
                        if result[1] ~= nil then
                            setStorage(eventCfg.storage, table.unpack(result))
                        end
                    end
                end
                return table.unpack(result)
            else
                --sb.logInfo("executing %s with args %s", tostring(eventCfg.callback), eventCfg.args)
                return callback(args)
            end
        else
            sb.logError("[JPBAI Framework] Function %s Couldn't be found", eventCfg.callback)
        end
    end
end

-- callback functions

function findCallback(functionPath, bypassBlacklist, bypassBridge)
    -- Stop the function returning nil and logging the attempt in the logs
    if JPBAIConfig.funcAllowedlist[functionPath] == false and not bypassBlacklist then sb.logWarn('[JPBAI] Item %s:%s, behavior "%s", tried to call blacklisted function %s!', item.name(), item.friendlyName(), behaviorName, functionPath) return end
	if type(functionPath) ~= "string" then sb.logWarn('[JPBAI] Item %s:%s, behavior "%s", function %s ins\'t string!', item.name(), item.friendlyName(), behaviorName, functionPath) return  end
	
    if JPBAIConfig.override[functionPath] and not bypassBridge then
        functionPath = JPBAIConfig.override[functionPath]
    end -- swap function with the given variant... primarily for safety consern or compatibility

    local findCallback = function(path)
        local currentResult = nil
        for _, string in ipairs(segmentPath(path)) do
          if not currentResult then 
            currentResult = _ENV[string]
          else
            currentResult = currentResult[string]
          end
        end
        if currentResult ~= nil then
          return currentResult
        else
          return defaultValue
        end
    end
    local callback = findCallback(functionPath)
    
    return callback
end

function playerInteractBridge(interactionType, paneCfg, sourceEntityId)
    if not interactionType or not paneCfg then return end

    --if type(paneCfg) == "string" then paneCfg = root.assetJson(paneCfg) end -- was used to make sure that pane where dismissable...
    if playerInteractTimer <= 0 then player.interact(interactionType, paneCfg) playerInteractTimer = 0.5 end -- just so that it doesn't open a insane amount of pane
end

function segmentPath(path)
    local pathSegment = {}
    if string.find(path, "[.:]") then
      while string.find(path, "[.:]") do
        local dotNumber = string.find(path, "[.:]")
        if dotNumber then
          table.insert(pathSegment, string.sub(path, 1, dotNumber - 1))
          path = string.sub(path, dotNumber + 1, string.len(path))
        end
      end
    end
    table.insert(pathSegment, path)
    return pathSegment
end

function checkStorage(path)
    if type(path) == "string" then
        if string.find(path, "storage:") == 1 then
            path = string.gsub(path, "storage:", "")
            --sb.logInfo("storage[%s] %s", path, storage[path])
            if storage[path] then return storage[path] else return nil end
        end
    elseif type(path) == "table" then
        if isEmpty(path) then return path end
        local _path = {}
        local isArray = true
        
        for a, b in ipairs(path or {}) do
            isArray = false
            table.insert(_path, checkStorage(b))
        end
        for a, b in pairs(path or {}) do
            if (not isArray) then break end
            _path[a] = checkStorage(b)
        end
        return _path
    end

    return path
end

function setStorage(name, value)
    storage[name] = value
    --sb.logInfo("storage[%s] = %s", name, value)
end

function insertInStorageTable(name, value)
    if type(storage[name]) ~= "table" then storage[name] = {} end
    table.insert(storage[name], value)
end
-- tech interaction
local playerTech = {}
function overrideTech(bool)
    if config.getParameter("overrideTech") then
        if not item.twoHanded() or not player then return end
        if bool then
            playerTech = {
                head = player.equippedTech("head"),
                body = player.equippedTech("body"),
                legs = player.equippedTech("legs")
            }
            for slot, techName in pairs(playerTech) do 
                player.unequipTech(techName)
            end
            for slot, techName in pairs(config.getParameter("overrideTech") or {}) do 
                player.equipTech(techName)
            end
        else
            for slot, techName in pairs(config.getParameter("overrideTech") or {}) do 
                player.unequipTech(techName)
            end
            for slot, techName in pairs(playerTech) do 
                player.equipTech(techName)
            end
        end
    end
end

function pRequire(scriptPath)
    if not scriptPath then return end
    if pcall(require, scriptPath) then
        require(scriptPath)
    else
        sb.logError("Couldn't Load Script %s, file doesn't exist", scriptPath)
    end
end

function worldentityExists(entityId)
    if not entityId then return false end
    return world.entityExists(entityId)
end

function worldCallScriptedEntity(entityId, ...)
    if not entityId then return false end
    if world.entityExists(entityId) then
        return world.callScriptedEntity(entityId, ...)
    end
end