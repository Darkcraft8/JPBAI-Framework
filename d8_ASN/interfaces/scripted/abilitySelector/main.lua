

require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"
require "/scripts/rect.lua"
require "/shared/darkcraft8/canvas/base.lua"

local selectedBehavior
local curItemBehavior
local nilResultCount = 0
local abilityList = {}
local ability = {"crush"}
local idleState = "idle"
local exitState = "idle"

function init()
    canvas:setCanvas("screenCanvas")
    abilityList = root.assetJson("/d8_ASN/items/active/abilities/abilityList.config")
    ability = config.getParameter("abilities", ability)
    idleState = config.getParameter("idleState", "idle")
    exitState = config.getParameter("exitState", "idle")
    for i, name in pairs(ability or {}) do
        local cfg = abilityList[name]
        if cfg then
            if type(cfg) == "string" then cfg = root.assetJson(cfg) end
            local card = cfg.card.front 
            abilityRender:new(card.group or cfg.startBehav or card.behaviorName, card.priority, card.draw, string.format("/d8_ASN/interfaces/scripted/abilitySelector/texture/%s/front.png", card.backgroundType))
        end
    end
end

function update(dt)
    local result = world.sendEntityMessage(player.id(), "getItemBehavior", player.id()):result()
    if result then nilResultCount = 0 curItemBehavior = result else
        nilResultCount = nilResultCount + 1
        if nilResultCount > 1 then pane.dismiss() return end --indicate that no item compatible is held
    end
    sb.setLogMap("-0, pane abSelect", "curItemBehavior %s, selectedBehavior %s", curItemBehavior, selectedBehavior)
    if ((curItemBehavior ~= idleState) and result) then pane.dismiss() return end
    abilityRender:upd(dt)
end

function dismissed()
    if (not selectedBehavior) or (selectedBehavior == "") then
        if curItemBehavior ~= exitState then world.sendEntityMessage(player.id(), "setItemBehavior", player.id(), exitState) end
    else
        world.sendEntityMessage(player.id(), "setItemBehavior", player.id(), selectedBehavior)
    end
end

function canvasClickEvent(position, mouseButton, isButtonDown)
    local _selectedBehavior
    if (mouseButton == 0) and isButtonDown then
        for i, name in pairs(ability or {}) do
            local cfg = abilityList[name]
            if cfg then
                if type(cfg) == "string" then cfg = root.assetJson(cfg) end
                local card = cfg.card.front
                local group = card.group or cfg.startBehav or card.behaviorName
                if group == abilityRender.overredGroup then
                    _selectedBehavior = cfg.startBehav or card.behaviorName
                    break
                end
            end
        end
    end
    if isButtonDown then 
        if selectedBehavior ~= _selectedBehavior then
            selectedBehavior = _selectedBehavior
            pane.dismiss()
        elseif (mouseButton == 0) then
            pane.dismiss()
        end
    end
    if (mouseButton == 2) then pane.dismiss() end
end

-- render tablet/card/page
abilityRender = {
    template = {
        {
            type = "drawable",
            image = "/d8_ASN/interfaces/scripted/abilitySelector/texture/tablet/front.png",
            position = {0, 0},
            scale = 1, 
            color = {255, 255, 255, 255}, 
            rotation = 0
        }
    },
    overYOffset = {},
    renders = {},
    overredGroup = nil,

    new = function(self, groupName, priority, elements, backgroundImage, tooltip)
        local temp = copy(self.template)
        if backgroundImage then temp[1].image = backgroundImage end
        local imageSize = root.imageSize(temp[1].image)
        temp[1].position = vec2.mul(imageSize, {0.5, 0.5})
        temp[1].size = imageSize

        for i, p in pairs(elements or {}) do 
            if p.type == "drawable" then
                table.insert(temp, {
                    type = p.type,
                    image = p.image or "/assetmissing.png",
                    position = p.position or {0, 0},
                    scale = p.scale or 1, 
                    color = p.color or {255, 255, 255, 255}, 
                    rotation = p.rotation or 0
                })
            elseif p.type == "label" then
                table.insert(temp, {
                    type = p.type,
                    text = p.string or "404", 
                    textPositioning = p.positioning or {
                        position = p.position or {0, 7},
                        horizontalAnchor = p.hAnchor or "left", -- left, mid, right
                        verticalAnchor = p.vAnchor or "top", -- top, mid, bottom
                        wrapWidth = p.wrapWidth or imageSize[1] -- wrap width in pixels or nil
                    },
                    fontSize = p.fontSize or 7, 
                    color = p.color or {255, 255, 255, 255}
                })
            end
        end
        self.renders[groupName] = {temp, tooltip, priority or 0}
    end,
    upd = function(self, dt)
        canvas:clear()

        local count = util.tableSize(self.renders)
        local canvasSize = canvas:size()
        local renders = {}
        for group, part in pairs(self.renders or {}) do
            local part = copy(part)
            part.group = group
            table.insert(renders, part)
        end
        table.sort(renders, function(a, b)
            return a[3] < b[3]
        end)
        local cursorPos = canvas:mousePosition()
        local overredGroup
        for index, part in pairs(renders or {}) do
            if not self.overYOffset[part.group] then self.overYOffset[part.group] = 0 end
            local position = vec2.mul(canvasSize, 0.5) position[2] = 0
            local elements = part[1] or {}
            local size = elements[1].size or root.imageSize(elements[1].image)
            local rectangle = rect.fromVec2({0, 0}, size)
            -- centering by index
                size[2] = 0
                position = vec2.add(position, vec2.mul(size, index - 1))
                position = vec2.sub(position, vec2.mul(size, count * 0.5))
            -- adding Y position offset when overred
                rectangle = rect.translate(rectangle, position)
                
                local isOverred = rect.contains(rectangle, cursorPos)
                if (not overredGroup) and isOverred then
                    overredGroup = part.group
                else
                    isOverred = false
                end
                if isOverred and (self.overYOffset[part.group] < 1) then
                    self.overYOffset[part.group] = math.min(self.overYOffset[part.group] + (dt * 6), 1)
                elseif (not isOverred) and (self.overYOffset[part.group] > 0) then
                    self.overYOffset[part.group] = math.max(self.overYOffset[part.group] - (dt * 4), 0)
                end
                local yOffset = self.overYOffset[part.group]
                position = vec2.sub(position, {0, 46 * (1 - yOffset)})
            --
            for index, cfg in pairs(elements) do
                if not isOverred then
                    cfg.color[1] = cfg.color[1] * 0.5
                    cfg.color[2] = cfg.color[2] * 0.5
                    cfg.color[3] = cfg.color[3] * 0.5
                    cfg.color[4] = cfg.color[4] * 0.85
                end
                if cfg.type == "label" then
                    local textPositioning = copy(cfg.textPositioning)
                    textPositioning.position = vec2.add(textPositioning.position, position)
                    canvas:drawText(cfg.text, textPositioning, cfg.fontSize, cfg.color)
                elseif cfg.type == "drawable" then
                    canvas:drawImageDrawable(cfg.image, vec2.add(cfg.position, position), cfg.scale, cfg.color, cfg.rotation)
                end
            end
            -- Debug
                if debugMode then
                    if isOverred then
                        canvas:drawPoly({
                            rect.ll(rectangle),
                            rect.lr(rectangle),
                            rect.ur(rectangle),
                            rect.ul(rectangle)
                        }, "green", 1)
                    else
                        canvas:drawPoly({
                            rect.ll(rectangle),
                            rect.lr(rectangle),
                            rect.ur(rectangle),
                            rect.ul(rectangle)
                        }, "red", 1)
                    end
                end
            --
        end
        self.overredGroup = overredGroup
    end
}