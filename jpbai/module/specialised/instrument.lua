--[[
    Yes a functions specificaly for instrument-like sound manipulation
--[[]]
instrument = {}
local soundPlayed = {}
function instrument.pressNote(soundName, loops) -- reset the volume and play the sound
    if animator.hasSound(soundName or "") then
        animator.setSoundVolume(soundName, self.animationCfg["sounds"][soundName]["volume"] or 1.0)
        --[[if not soundPlayed[soundName] then 
            if (loops or 0) == -1 then 
                soundPlayed[soundName] = true 
            end
            animator.playSound(soundName, loops or 0) 
        end]]
        if (loops or 0) == -1 then 
            animator.stopAllSounds(soundName)
        end
        animator.playSound(soundName, loops or 0) 
    end
end

function instrument.releaseNote(soundName, rampTime) -- set the volume to 0 with the given rampTime (1 by default)
    if animator.hasSound(soundName or "") then
        animator.setSoundVolume(soundName, 0, rampTime or 1)
    end
end