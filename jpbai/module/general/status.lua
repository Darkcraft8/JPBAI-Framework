-- Function's to interact with player resources|status
statusEx = statusEx or {}
function statusEx.hasResources(resourceList) -- return if the resources in the table are available
    if not resourceList then return end
    for i, cfg in ipairs(resourceList) do
        if type(cfg) == "table" then
            if cfg.amount then
                --sb.logInfo("%s : %s", cfg.resource, status.resource(cfg.resource))
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