exMath = {}

function exMath.vecLower(vecA, vecB, abs)
    if (not vecA) or (not vecB) then return false, "missing a vector" end
    if #vecA == #vecB then
        for i, v in pairs(vecB) do
            if abs then
                if math.abs(vecA[i]) >= vecB[i] then
                    return false
                end
            else
                if vecA[i] >= vecB[i] then
                    return false
                end
            end
        end
        return true
    elseif #vecA > #vecB then
        return false
    else
        return true
    end
end