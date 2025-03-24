-- general function for weapon's --
Weapon = {}
function Weapon.init()
    -- Usual Culprit
    Weapon.damageLevelMultiplier = config.getParameter("damageLevelMultiplier", root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1)))
    Weapon.level = config.getParameter("level", 1)
    Weapon.inaccuracy = 0
    animator.setGlobalTag("elementalType", Weapon.elementalType or "")
end

function Weapon_uninit() end

-- Scaling
function Weapon.damagePerShot(args)
    local mathResult = args.baseDamage or 1
    mathResult = mathResult * (Weapon.damageLevelMultiplier or 1.0)
    mathResult = mathResult * ((Weapon.damageLevelMultiplier or 1.0) / (args.count or 1.0)) * activeItem.ownerPowerMultiplier()

    return mathResult
end
function Weapon.basicDamage(args)
    local mathResult = args.baseDamage or 1
    mathResult = mathResult * (Weapon.damageLevelMultiplier or 1.0) * activeItem.ownerPowerMultiplier()

    return mathResult
end

function Weapon.energyPerAction(args)
    local mathResult = args.baseCost or 1
    if mathResult ~= 0 then 
        mathResult = mathResult * (1.0 / (args.count or 1.0))
    end
    return mathResult
end

-- Utility
function Weapon.canConsumeItem(ItemNameOrTable)
    if type(ItemNameOrTable) == "string" then
        if player.hasCountOfItem(ItemNameOrTable , true) == 0 then return false else return true end
    else
        if ItemNameOrTable.count then
            if player.hasCountOfItem(ItemNameOrTable , true) == 0 then return false else return true end
        else
            for index, item in ipairs(ItemNameOrTable) do
                if player.hasCountOfItem(item, true) == 0 then return false end
            end return true
        end
    end
end

function Weapon.consumeItem(ItemNameOrTable)
    if type(ItemNameOrTable) == "string" then
        return player.consumeItem(ItemNameOrTable , true, true)
    else
        if ItemNameOrTable.count then
            return player.consumeItem(ItemNameOrTable , true, true)
        else
            local result = true
            for index, item in ipairs(ItemNameOrTable) do 
                if not player.consumeItem(item , true, true) then result = false end
            end return result
        end
    end
end