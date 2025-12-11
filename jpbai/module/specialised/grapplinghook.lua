-- function for gappling hook type capability

function reelTowardEntity(entityId, speed, maxControlForce)
    local targetPos
    if (type(entityId) == "table") then
        targetPos = vec2.add(entity.position(), entityId)
    elseif world.entityExists(entityId) then
        targetPos = world.entityPosition(entityId)
    end
    if not targetPos then return end
    local dist = world.distance(targetPos, entity.position()) 
    local vel = vec2.rotate({speed, 0}, vec2.angle(dist))
    mcontroller.setVelocity(vel, maxControlForce or 250)
end
-- maybe i should move this
function spawnFalseHitscanProjectile(projectileType, spawnPositionCfg, direction, trackSource, projectileParameters, inaccuracy, hookToEntity, hookToEnemy, collisionSet)
	local position, position2 = 1, 1
    position = spawnPosition({
        spawnPos = spawnPositionCfg.anchor or "ownerPosFaceDirection",
        spawnOffset = {0, 0}
    })
    position2 = spawnPosition({
        spawnPos = spawnPositionCfg.anchor or "ownerPosFaceDirection",
        spawnOffset = spawnPositionCfg.offset or {0, 0}
    })
	if direction then
		position2 = spawnPosition({
			spawnPos = spawnPositionCfg.anchor or "ownerPosFaceDirection",
			spawnOffset = vec2.rotate(spawnPositionCfg.offset or {0, 0}, vec2.angle(direction))
		})
	end
    -- collision physic
    local collisionPoint = world.lineCollision(position, position2, collisionSet or {"Block", "Dynamic", "Null", "Slippery"})
    if collisionPoint then 
        local mag = world.magnitude(position, collisionPoint)
        if direction then 
			collisionPoint = spawnPosition({
				spawnPos = spawnPositionCfg.anchor or "ownerPosFaceDirection",
				spawnOffset = vec2.rotate({mag - 1.25, 0}, vec2.angle(direction))
		    })
		else
	    	local direction = copy(spawnPositionCfg.offset or {0, 0})
			if direction[1] ~= 0 then direction[1] = ((direction[1] / direction[1]) * mag) - 1.25 end
		    if direction[2] ~= 0 then direction[2] = ((direction[2] / direction[2]) * mag) - 1.25 end
			if (direction[1] ~= 0) and (direction[2] ~= 0) then
				direction = vec2.rotate({mag - 1.25, 0}, vec2.angle(spawnPositionCfg.offset or {0, 0}))
		    end
					
			collisionPoint = spawnPosition({
				spawnPos = spawnPositionCfg.anchor or "ownerPosFaceDirection",
				spawnOffset = direction
			})			
		end
    end
    -- hurtBox collision
    local entityPoint
    if (hookToEntity or hookToEnemy) then -- note that the projectile sticking to the entity has to be done in the projectile.
		for _, id in pairs(world.entityLineQuery(position, position2, {withoutEntityId = activeItem.ownerEntityId(), order = "nearest"}) or {}) do
			local add = true
            local entType = world.entityType(id)
            if hookToEnemy then add = world.entityCanDamage(activeItem.ownerEntityId(), id) end
            if type(hookToEntity) == "table" then
                add = false
                for _, _entType in pairs(hookToEntity or {}) do 
                    if string.lower(_entType) == string.lower(entType) then
                        if hookToEnemy then
                            add = world.entityCanDamage(activeItem.ownerEntityId(), id)
                        else
                            add = true
                        end
                        break
                    end
                end
            end
			if add then --need to find a way to reduce the lenght
				local targPos = vec2.add(world.entityPosition(id), {0, 1.29993})
				local dist = world.distance(world.entityPosition(activeItem.ownerEntityId()), targPos)
				local mag = world.magnitude(world.entityPosition(activeItem.ownerEntityId()), targPos)
				if direction then 
					entityPoint = spawnPosition({
						spawnPos = spawnPositionCfg.anchor or "ownerPosFaceDirection",
						spawnOffset = vec2.rotate({mag - 1.25, 0}, vec2.angle(direction))
					})
				else
					local direction = copy(spawnPositionCfg.offset or {0, 0})
					if direction[1] ~= 0 then direction[1] = ((direction[1] / direction[1]) * mag) - 1.25 end
					if direction[2] ~= 0 then direction[2] = ((direction[2] / direction[2]) * mag) - 1.25 end
					if (direction[1] ~= 0) and (direction[2] ~= 0) then
						direction = vec2.rotate({mag - 1.25, 0}, vec2.angle(spawnPositionCfg.offset or {0, 0}))
					end
					
					entityPoint = spawnPosition({
						spawnPos = spawnPositionCfg.anchor or "ownerPosFaceDirection",
						spawnOffset = direction
					})
					
				end
				break
			end
		end 
	end
    if collisionPoint and entityPoint then
        local distA, distB = world.magnitude(position, collisionPoint), world.magnitude(position, entityPoint)
        if distA < distB then
            position2 = collisionPoint
        else
            position2 = entityPoint
        end
    elseif entityPoint then
        position2 = entityPoint
    elseif collisionPoint then
        position2 = collisionPoint
    end
    local direction = direction or aimVector((inaccuracy or 0))
    
    --sb.logInfo("type %s,\nposition %s,\ndirection %s,\ntrackSource %s,\nparameters %s", projectileType, position2, direction, trackSource, projectileParameters)
    sb.setLogMap("0| spawnFalseHitScanProj", "offset %s, effOffset %s", sb.printJson(spawnPositionCfg.offset or {0, 0}) , sb.printJson(position2))
    
    return world.spawnProjectile(projectileType, position2, activeItem.ownerEntityId(), direction, trackSource, projectileParameters)
end

function magBetweenEntity(entity1, entity2, percent)
    if not entity1 then return end
    local a, b = entity1, entity2 or activeItem.ownerEntityId()
    if world.entityExists(a) and world.entityExists(b) then
        if percent then
            local mag = world.magnitude(world.entityPosition(a), world.entityPosition(b))
            return mag > percent
        else
            return world.magnitude(world.entityPosition(a), world.entityPosition(b))
        end
    end
end
