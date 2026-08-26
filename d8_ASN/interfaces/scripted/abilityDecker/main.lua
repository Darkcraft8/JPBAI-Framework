require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"
require "/scripts/rect.lua"
local ability = {"crush"}
local racialAbilities = {}
local curDeck = {}
local learnedAbilities = {}

local listPath = "abilities.list"
function init()
    curDeck = status.statusProperty("d8_ASN_AbilityDeck", {})
    learnedAbilities = status.statusProperty("d8_ASN_LearnedAbilities", {})

    abilityList = root.assetJson("/d8_ASN/items/active/abilities/abilityList.config")
    ability = config.getParameter("abilities", ability) -- default unlock

    racialAbilities = config.getParameter("racialAbilities", racialAbilities)
    racialAbilities = racialAbilities[player.species()] or {}

    widget.clearListItems(listPath)
    populateList(listPath, ability)
    populateList(listPath, learnedAbilities)
end

function populateList(path, abilities)
    for i, n in pairs(abilities) do
        local name = i
        if type(i) == "number" then name = n end
        sb.logInfo("i %s : %s", i, abilityList[i])
        sb.logInfo("n %s : %s", n, abilityList[n])
        if (abilityList[i] or abilityList[n]) then
            local id = widget.addListItem(path)
            local path = path.."."..id
            addAbilityRender(path, (abilityList[i] or abilityList[n]))
        end
    end
end

function addAbilityRender(path, nameOrCfg)
    local cfg = copy(nameOrCfg)
    if type(cfg) == "string" then
        if not string.find(cfg, "/") then cfg = learnedAbilities[cfg] end
        if type(cfg) == "string" then cfg = root.assetJson(cfg) end
    end
    local front = (cfg.card.front or {})
    local bg = "/d8_ASN/interfaces/scripted/abilitySelector/texture/%s/front.png"
    if string.find(front.backgroundType, "/") then
        bg = front.backgroundType
    else
        bg = string.format(bg, front.backgroundType)
    end
    local bgSize = root.imageSize(bg) or {64, 64}
    local draw = front.draw
    local offset = {1, 1}
    widget.addChild(path, {
        type = "image",
        file = "/assetmissing.png",
        position = {0, 0},
        mouseTransparent = true,
        centered = false,
        zlevel = -1
    }, "background")
    widget.addChild(path, {
        type = "image",
        file = bg,
        position = offset,
        mouseTransparent = true,
        centered = false,
        zlevel = 0
    }, "bg")
    for i, c in pairs(draw) do
        local c = copy(c)
        if c.type == "drawable" then            
            c.type = "image"
            c.file = copy(c.image)
            c.image = nil
            c.centered = true
        elseif c.type == "label" then
            c.position = vec2.add(c.position, {1, 0})
            c.value = copy(c.string)
            c.string = nil
            c.centered = true
            c.vAnchor = c.vAnchor or "top"
        end

        c.position = vec2.add(c.position, offset)
        widget.addChild(path, c, i)
    end
end