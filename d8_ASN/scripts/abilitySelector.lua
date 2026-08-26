-- ability selector builder

function buildAbilitySelector()
    local cfg = root.assetJson("/d8_ASN/interfaces/scripted/abilitySelector/main.json")
    local bgImg = "/assetmissing.png?crop;0;0;1;1?setcolor=fff0?replace;fff0=0000?scalenearest;67=67?scalenearest=%s;1"
    cfg.abilities = getAbilityDeck()
    cfg.idleState = config.getParameter("abilitySelect_idleState", "idle")
    cfg.exitState = config.getParameter("abilitySelect_exitState", "idle")


    local abilityCount = math.min(util.tableSize(cfg.abilities or {}), 7)
    cfg.gui.background.fileBody = string.format(bgImg, abilityCount)
    cfg.gui.screenCanvas.size[1] = 67 * abilityCount
    --sb.logInfo("cfg : %s", sb.printJson(cfg, 1))
    return cfg
end

function getAbilityDeck()
    local abilities = {}
    if activeItem then
        for _, abilityName in ipairs(config.getParameter("innateAbility", {})) do
            table.insert(abilities, abilityName)
        end
    end
    for _, abilityName in ipairs(status.statusProperty("d8_ASN_AbilityDeck", {})) do
        table.insert(abilities, abilityName)
    end
    return abilities
end

function openAbilitySelector()
    local gui = buildAbilitySelector()
    player.interact("scriptPane", gui)
end

function jpbai_loadAbilities()
    local abilityList = root.assetJson("/d8_ASN/items/active/abilities/abilityList.config")
    local abilities = getAbilityDeck()
    for i, name in pairs(abilities or {}) do
        local cfg = abilityList[name]
        if cfg then
            if type(cfg) == "string" then cfg = root.assetJson(cfg) end

            if cfg.stances then table.insert(preInit_baseStances, cfg.stances or {}) end
            if cfg.behavs then table.insert(preInit_behaviors, cfg.behavs or {}) end
            if cfg.paths then table.insert(preInit_behaviorPaths, cfg.paths or {}) end
            if cfg.events then table.insert(preInit_behaviorEvents, cfg.events or {}) end
        end
    end
end