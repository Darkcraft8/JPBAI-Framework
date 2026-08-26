-- Custom Damage Impact
local damageCfgTemp = {
    damageNumberParticles = {
        hit = {},
        stronghit = {},
        weakhit = {},
        shieldhit = {},
        kill = {}
    },
    hitSoundKind = {
        organic = {
            weakhit = {},
            stronghit = {},
            kill = {}
        },
        robotic = {
            weakhit = {},
            stronghit = {},
            kill = {}
        }
    }
}
function damageImpact(damageCfg, notif)
    local damageCfg = damageCfg
    if not notif then return end
    if type(damageCfg) == "string" then damageCfg = root.assetJson(damageCfg) end
    if not damageCfg then 
        damageCfg = damageCfgTemp
    else
        damageCfg = util.mergeTable(damageCfgTemp, damageCfg)
        for i, s in pairs(damageCfg.hitSoundKind) do
            if not s.hit then
                damageCfg.hitSoundKind[i].hit = copy(s.weakhit)
            end
        end
    end
    local function round(num) -- thx stackoverflow for this stupidly easy method
        return math.floor(num+0.5)
    end
    local matKind = string.lower(notif.targetMaterialKind)
    local damageKind = notif.kind
    local hitType = string.lower(notif.hitType or "weakhit")
    local targetEntityId = notif.targetEntityId
    local position = notif.position
    local damageDealt = round(notif.damageDealt)
    local healthLost = round(notif.healthLost)

    local projectileParam = {
        clientEntityMode = "ClientPresenceMaster",
        speed = 0.001,
        timeToLive = delay or 0,
        processing = "?multiply=fff0",
        damageTeam = { type = "ghostly" },
        movementSettings = {collisionEnabled = false, gravityEnable = false},
        actionOnReap = {}
    }
    -- Sound Event
        --sb.logInfo("Preparing Damage Sound %s.%s", matKind, hitType)
        local sounds = damageCfg.hitSoundKind[matKind][hitType] or {}
        local pitch = 1
        local pool = sounds
        if sounds.pitch then
            pitch = sounds.pitch
            pool = sounds.pool
        end
        local soundEvent = {
            action = "sound",
            options = pool,
            pitch = pitch
        }
        table.insert(projectileParam.actionOnReap, soundEvent)
    -- Damage Particles Event
        --sb.logInfo("Preparing Damage Particles %s.%s", matKind, hitType)
        local damageNumberParticles = damageCfg.damageNumberParticles[hitType] or {}
        local event = {
            action = "particle",
            specification = {}
        }
        if not damageNumberParticles.text then
            for i, p in pairs(damageNumberParticles) do 
                local _event = copy(event)
                local _p = copy(p)
                _p.text = string.gsub(_p.text, "%$dmg%$", tostring(damageDealt))
                _event.specification = _p
                --table.insert(projectileParam.actionOnReap, _event)
            end
        else
            damageNumberParticles.text = string.gsub(damageNumberParticles.text, "%$dmg%$", tostring(damageDealt))
            event.specification = damageNumberParticles
            --table.insert(projectileParam.actionOnReap, event)
        end
    --
    world.spawnProjectile("bullet-1", position, activeItem.ownerEntityId(), {1, 0}, false, projectileParam)
end