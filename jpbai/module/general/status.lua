-- Function's to interact with player resources|status
statusEx = statusEx or {}
function statusEx.hasResources(resourceList) -- return if the resources in the table have the required amount available
    if not resourceList then return end
    for i, cfg in ipairs(resourceList) do
        if type(cfg) == "table" then
            if cfg.amount then
                --sb.logInfo("%s >= %s = %s", cfg.resource, status.resource(cfg.resource), (status.resource(cfg.resource) >= cfg.amount))
                if not (status.resource(cfg.resource) >= cfg.amount) then return false end
            else
                if not status.resourcePositive(cfg.resource) then return false end
            end
        elseif type(cfg) == "string" then
            if not status.resourcePositive(cfg) then return false end
        end
    end
    return true
end

function statusEx.resourcesLocked(resourceList)
    if not resourceList then return end
    for i, cfg in ipairs(resourceList) do
        if type(cfg) == "table" then
            if status.resourceLocked(cfg.resource) then return false end
        elseif type(cfg) == "string" then
            if status.resourceLocked(cfg) then return false end
        end
    end
    return true
end

function statusEx.setResourcesLocked(resourceList)
    if not resourceList then return end
    for i, cfg in ipairs(resourceList) do
        if type(cfg) == "table" then
            status.setResourceLocked(cfg.resource)
        elseif type(cfg) == "string" then
            status.setResourceLocked(cfg)
        end
    end
    return true
end

function statusEx.resourcesNegative(resourceList) -- return if the resources in the table are available
    if not resourceList then return end
    for i, cfg in ipairs(resourceList) do
        if type(cfg) == "table" then
            if cfg.amount then
                --sb.logInfo("%s : %s", cfg.resource, status.resource(cfg.resource))
                if (status.resource(cfg.resource) >= cfg.amount) then return false end
            else
                if status.resourcePositive(cfg.resource) then return false end
            end
        elseif type(cfg) == "string" then
            if status.resourcePositive(cfg) then return false end
        end
    end
    return true
end

function statusEx.hasStatus(status, hasAll) -- return bool
    if not status then return end
    local activeEffect = status.activeUniqueStatusEffectSummary()
    local hasAll = true
    local hasOne = false
    for effectName, effectDuration in pairs(status) do 
        if activeEffect[effectName] then
            hasOne = true
        else
            hasAll = false
        end
    end

    if hasAll then
        return hasAll
    else
        return hasOne
    end
end

function statusEx.statNegative(statName)
    return not status.statPositive(statName)
end

function statusEx.statusProperty(property, require)
    return status.statusProperty(property) == require
end