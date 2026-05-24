require "/scripts/poly.lua"
require "/scripts/rect.lua"

function polyMine(minePoly, layer, sourcePos, damageType, damagevalue, harvestLevel, hitSoundName, blockSoundName) -- mine tile that are inside the poly
  --sb.logInfo("minePoly \n poly %s\n layer %s\n sourcePos %s\n damageType %s\n damagevalue %s\n harvestLevel %s\n hitSoundName %s\n blockSoundName %s", minePoly, layer, sourcePos, damageType, damagevalue, harvestLevel, hitSoundName, blockSoundName)
  local function tilePoly(minePoly)
    local tilePoly = {}
    for _, point in ipairs(minePoly) do -- move the point to tiles
      local _poly = util.tileCenter({util.round(point[1]), util.round(point[2])})
      table.insert(tilePoly, _poly)
    end
    return tilePoly
  end

  local function boxVector(rectangle)
    return {{rectangle[1], rectangle[2]}, {rectangle[3], rectangle[2]}, {rectangle[3], rectangle[4]}, {rectangle[1], rectangle[4]}}
  end
  local function hitArea(tilePoly, boundBox, layer)
    local x, y = copy(boundBox[1]), copy(boundBox[2])
    local result = {}
    while (x ~= boundBox[3]) or (y ~= boundBox[4]) do 
      --world.polyContains
      local tilePresent = false
      local rectangle = rect.fromVec2(vec2.sub({x, y}, 0.5), vec2.add({x, y}, 0.5))

      for _, point in ipairs(boxVector(rectangle)) do 
        if world.polyContains(tilePoly, point) and world.tileIsOccupied(world.xwrap(point), layer == "foreground", false) then
          tilePresent = true
          break
        end
      end
      if tilePresent then
        world.debugPoly(boxVector(rectangle), "green")
        table.insert(result, world.xwrap({x, y}))
      else
        world.debugPoly(boxVector(rectangle), "red")
      end

      if x ~= boundBox[3] then
        if x > boundBox[3] then
          x = x - 1
        elseif x < boundBox[3] then
          x = x + 1
        end
      elseif y ~= boundBox[4] then
        x = copy(boundBox[1])
        if y > boundBox[4] then
          y = y - 1
        elseif y < boundBox[4] then
          y = y + 1
        end
      end
    end
    return result
  end

  minePoly = tilePoly(minePoly)
  local boundBox = poly.boundBox(minePoly or {}) -- {x1, y1, x2, y2}
  local validTiles = hitArea(minePoly, boundBox, layer)

  local blockSound = getBlockSound(validTiles, layer)
  local damageTile = world.damageTiles(validTiles, layer, sourcePos, damageType, damagevalue, harvestLevel, activeItem.ownerEntityId())
  
  if damageTile then
    if hitSoundName then
      if animator.hasSound(hitSoundName) then
        animationEx.pitchShift(hitSoundName, 50)
        animator.playSound(hitSoundName)
      end
    end
    if blockSoundName then
      if animator.hasSound(blockSoundName) then
        animationEx.pitchShift(blockSoundName, 50)
        animator.setSoundPool(blockSoundName, blockSound)
        animator.playSound(blockSoundName)
      end
    end
  end
  return damageTile, blockSound
end

-- from pickslash.lua
function getBlockSound(brushArea, layer)
  local defaultFootstepSound = root.assetJson("/client.config:defaultFootstepSound")

  for _,pos in pairs(brushArea) do
    if world.isTileProtected(pos) then
      return root.assetJson("/client.config:defaultDingSound")
    end
  end

  for _,pos in pairs(brushArea) do
    local material = world.material(pos, layer)
    local mod = world.mod(pos, layer)
    local blockSound = type(material) == "string" and root.materialMiningSound(material, mod)
    if blockSound then return blockSound end
  end

  for _,pos in pairs(brushArea) do
    local material = world.material(pos, layer)
    local mod = world.mod(pos, layer)
    local blockSound = type(material) == "string" and root.materialFootstepSound(material, mod)
    if blockSound and blockSound ~= defaultFootstepSound then
      return blockSound
    end
  end

  return nil
end

function tileAreaBrush(radius, centerPosition)
  local result = jarray()
  local offset = {-radius/2, -radius/2}
  local intOffset = util.map(vec2.add(offset, centerPosition), util.round)

  for x = 0, radius-1 do
    for y = 0, radius-1 do
      local intPos = util.map({x, y}, util.round)
      table.insert(result, vec2.add(intPos, intOffset))
    end
  end
  return result
end