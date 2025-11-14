-- Function to communicate between primary and secondary item
--  both of these functions are meant for one-handed items
    function setBlockBehavior(bool) -- set a flag that indicate to the system to skip a behavior when paired with 'isBehaviorBlocked'... toggle if no boolean are given
        if bool ~= nil then
            self.behaviorBlocked = bool
        else
            self.behaviorBlocked = (not self.behaviorBlocked)
        end
    end

    function isBehaviorBlocked() -- return false if the behavior block flag is true...
        return (not self.behaviorBlocked)
    end
--


--activeItem.callOtherHandScript(call, eventCfg)