require "/scripts/vec2.lua"

function init()
    self.damageFlashTime = 0

    message.setHandler("applyStatusEffect", function(_, _, effectConfig, duration, sourceEntityId)
      --status.addEphemeralEffect(effectConfig, duration, sourceEntityId)
    end)
end

function applyDamageRequest(damageRequest)
    return {}
end

function update(dt)
    if mcontroller.atWorldLimit(true) then
        status.setResourcePercentage("health", 0)
    end
end
