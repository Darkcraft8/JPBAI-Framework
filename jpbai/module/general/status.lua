-- Function's to interact with player resources|status
statusEx = statusEx or {}
function statusEx.hasResources(resourceList) -- return if the resources in the table are available
    if not args then return end
    for i, cfg in ipairs(args) do
        if cfg.amount then
            if not status.resource(cfg.resource) >= cfg.amount then return false end
        else
            if not status.resourcePositive(cfg.resource) then return false end
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