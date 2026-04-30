hitscan = {}
function hitscan.calculate(range, spawnPos, spawnOffset)
    local startPos = spawnPosition({
        spawnPos = spawnPos.anchor or "ownerPosFaceDirection",
        spawnOffset = spawnOffset or {0, 0}
    })
end

function hitscan.hitPos(entPos, damageLine, damagePoly, notif)
    
end

function quatradicBezierCurve(time, vec3F)
   --(1-time)^2*vec3F[1]+2*(1-time)*time*vec3F[2]+time^2*vec3F[3], 0<time<1
   --util.lerp
end