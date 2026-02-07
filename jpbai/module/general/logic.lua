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

calculus = {}

function calculus.add(numA, numB)
    return numA + numB
end

function calculus.sub(numA, numB)
    return numA - numB
end

function calculus.mul(num, mul)
    return num * mul
end

function calculus.div(num, div)
    if div == 0 then return 0 end
    return num / div
end

function calculus.lowerThan(numA, numB)
    if (not numA) or (not numB) then return end
    return numA < numB
end

function calculus.lowerOrEqualTo(numA, numB)
    if (not numA) or (not numB) then return end
    return numA <= numB
end

function calculus.greaterThan(numA, numB)
    if (not numA) or (not numB) then return end
    return numA > numB
end

function calculus.greaterOrEqualTo(numA, numB)
    if (not numA) or (not numB) then return end
    return numA >= numB
end

function calculus.modulus(numA, modulus)
    if (not numA) or (not modulus) then return end
    return (numA % modulus)
end

logic = {}

function logic.equalTo(a, b)
    if (not a) or (not b) then return end
    return a == b
end

function logic.equalAny(a, b)
    if (not a) or (not b) then return end
    if type(b) ~= "table" then
        return logic.equalTo(a, b)
    else
        for _, _b in pairs(b) do 
            if a == _b then return true end
        end
    end
end

function logic.tableContent(table, path, defaultValue)
    if not table then sb.logError("logic.tableContent, %s | %s ins't a table", itemId, table) return defaultValue end
    if not path then return table end
    local pathSegment = segmentPath(path)
    local currentResult = nil
    
    for _, string in ipairs(pathSegment) do
        if not currentResult then 
            if table[string] then
                currentResult = table[string]
            else
                if not defaultValue then 
                    sb.logError("logic.tableContent, %s | failed to find value with path on start : %s", itemId, path) 
                else
                    --sb.logError("logic.tableContent, %s | failed to find value with path on start : %s, using %s", itemId, path, defaultValue)
                end
                return defaultValue
            end
        else
            if currentResult[string] then
                currentResult = currentResult[string]
            else
                if not defaultValue then 
                    sb.logError("logic.tableContent, %s | failed to find value with path in loop : %s", itemId, path) 
                else
                    --sb.logError("logic.tableContent, %s | failed to find value with path in loop : %s, using %s", itemId, path, defaultValue)
                end
                return defaultValue
            end
        end
    end
    if currentResult ~= nil then
        return currentResult or defaultValue
    else
        if not defaultValue then
            sb.logError("logic.tableContent, %s | failed to find value with path : %s", itemId, path) 
        else
            --sb.logError("logic.tableContent, %s | failed to find value with path : %s, using %s", itemId, path, defaultValue)
        end
        return defaultValue
    end
end
