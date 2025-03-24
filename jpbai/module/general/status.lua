-- Function's to interact with player resources|status
statusEx = statusEx or {}
function statusEx.hasResources(args) -- return if the resources in the table are available
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
 -- modifie the resource depending on the given operation and amount
function statusEx.modResources(args) -- return nil, take table [ resource : 'string' resouceName, amount : 'interger or number' resouceAmount, op : 'string' operation]
    if not args then return end
    for i, cfg in ipairs(args) do 
        if args.op == "give" then
            status.giveResource(args.resource, args.amount)
        elseif args.op == "consume" then
            status.consumeResource(args.resource, args.amount)
        elseif args.op == "overConsume" then
            status.overConsumeResource(args.resource, args.amount)
        elseif args.op == "set" then
            status.setResource(args.resource, args.amount)
        end
    end
end

function statusEx.hasStatus(args) -- return bool
    if not args then return end
    local activeEffect = status.activeUniqueStatusEffectSummary()
    local hasAll = true
    local hasOne = false
    for effectName, effectDuration in pairs(args.status) do 
        if activeEffect[effectName] then
            hasOne = true
        else
            hasAll = false
        end
    end

    if args.hasAll then
        return hasAll
    else
        return hasOne
    end
end