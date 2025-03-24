local _config, _parameters
function configBehavior(behaviorName)
    local list = root.assetJson("/jpbai/item/buildscript/JPBAI/behaviorList.config")
    local behaviorConfigPath = list[behaviorName]
    if behaviorConfigPath then return root.assetJson(behaviorConfigPath) end
end

function setupBehavior(config, parameters, behaviorName, fireType)
    _config, _parameters = config, parameters
    local configParameter = function(keyName, defaultValue)
        if _parameters[keyName] ~= nil then
            return _parameters[keyName]
        elseif _config[keyName] ~= nil then
            return _config[keyName]
        else
            return defaultValue
        end
    end
    local cfg = configBehavior(behaviorName)
    
    if not cfg then return end
    if _config.buildConfig.override then
        for var, val in pairs(_config.buildConfig.override or {}) do
            replaceInData(cfg, nil, "<"..var..">", val)
        end
        if cfg.defaultOverride then
            for var, val in pairs(cfg.defaultOverride or {}) do
                local val = _config.buildConfig.override[var] or val
                replaceInData(cfg, nil, "<"..var..">", val)
            end
        end
    end
    local merge = json.sbMerge(cfg, config)
    for stanceName, stanceCfg in pairs(config.stances or {}) do 
        merge.stances[stanceName] = stanceCfg
    end
    merge.behaviorName = nil -- remove the behaviorName, doesn't serve a purpose outside of the oSb Script
    --sb.logInfo("[json.sbMerge] %s : %s", config.shortdescription, sb.printJson(merge, 1))
    --sb.logInfo("[util.mergeTable] %s", sb.printJson(util.mergeTable(cfg, config), 1))
    local newConfig = merge--util.mergeTable(cfg, config)
    return newConfig
end