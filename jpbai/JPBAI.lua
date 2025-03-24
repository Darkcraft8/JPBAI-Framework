require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/status.lua"
-- Json Powered Behavioral Active Item >:D
-- or JPBAI for short
-- a bunch of list for frequent func type
initFunc = {
    "activeItemCfg",
    "initStances",
    "initBehavior",
    "configInit"
}
updateFunc = {}  -- just so that incase a script has a update function it can be added
uninitFunc = {
    "uninitBehavior",
    "uninitStance"
}

require "/jpbai/module/general/stance.lua"
require "/jpbai/module/general/animation.lua"
require "/jpbai/module/general/inventory.lua"
require "/jpbai/module/general/status.lua"
require "/jpbai/module/general/behavior.lua"
require "/jpbai/module/general/behaviorEX.lua"

local playerInteractTimer = 0
function init()
    JPBAIConfig = root.assetJson("/jpbai/JPBAI.config")
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
            callback()
        end
    end
end

function update(dt, fireMode, isShiftHeld, currentMove)
    for _, func in ipairs(updateFunc) do 
        if type(func) == "function" then
            func(dt, fireMode, isShiftHeld, currentMove)
        else
            local callback = findCallback(func)
            callback(dt, fireMode, isShiftHeld, currentMove)
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
            callback()
        end
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

function segmentPath(path)
    local pathSegment = {}
    if string.find(path, "[.]") then
    while string.find(path, "[.]") do
        local dotNumber = string.find(path, "[.]")
        if dotNumber then
        table.insert(pathSegment, string.sub(path, 1, dotNumber - 1))
        path = string.sub(path, dotNumber + 1, string.len(path))
        end
    end
    end
    table.insert(pathSegment, path)
    return pathSegment
end

function call(eventCfg) -- because whe can't directly do _ENV[funcGroup.Func]()
    if type(eventCfg) == "string" then
        callback = findCallback(tostring(eventCfg))
    if callback then return callback() else sb.logError("[JPBAI Framework] Function %s Couldn't be found", eventCfg) end
    else
        callback = findCallback(tostring(eventCfg.callback))
        if callback then return callback(eventCfg.args) else sb.logError("[JPBAI Framework] Function %s Couldn't be found", eventCfg.callback) end
    end
end

function findCallback(functionPath, bypassBlacklist, bypassBridge)
    if JPBAIConfig.bridgeFunc[functionPath] and not bypassBridge then
        functionPath = JPBAIConfig.bridgeFunc[functionPath]
    end -- swap function with their bridge variant 
    
    local findCallback = function(path)
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
        local currentResult = nil
        for _, string in ipairs(pathSegment) do
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

function playerInteractBridge(args)
    local _type, pane = args.type, args.pane
    if not _type or not pane then return end

    if type(pane) == "string" then pane = root.assetJson(pane) end
    if pane.dismissable ~= false and playerInteractTimer <= 0 then player.interact(_type, pane) playerInteractTimer = 0.5 end -- to prevent bad actor from giving pane that can't be dismissed
end