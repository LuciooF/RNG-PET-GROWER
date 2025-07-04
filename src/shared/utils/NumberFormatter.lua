local NumberFormatter = {}

-- Format numbers with K, M, B, T suffixes
function NumberFormatter.format(number)
    if not number or type(number) ~= "number" then
        return "0"
    end
    
    if number < 1000 then
        return tostring(math.floor(number))
    elseif number < 1000000 then
        return string.format("%.1fK", number / 1000)
    elseif number < 1000000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number < 1000000000000 then
        return string.format("%.1fB", number / 1000000000)
    else
        return string.format("%.1fT", number / 1000000000000)
    end
end

-- Format currency with $ prefix
function NumberFormatter.formatCurrency(number)
    if not number or type(number) ~= "number" then
        return "$0"
    end
    
    return "$" .. NumberFormatter.format(number)
end

-- Format percentage with % suffix
function NumberFormatter.formatPercentage(number, decimals)
    if not number or type(number) ~= "number" then
        return "0%"
    end
    
    decimals = decimals or 1
    local formatStr = "%." .. decimals .. "f%%"
    return string.format(formatStr, number)
end

-- Format multiplier (e.g., "x2.5")
function NumberFormatter.formatMultiplier(number, decimals)
    if not number or type(number) ~= "number" then
        return "x1"
    end
    
    decimals = decimals or 1
    local formatStr = "x%." .. decimals .. "f"
    return string.format(formatStr, number)
end

-- Format boost percentage (e.g., "+50%")
function NumberFormatter.formatBoost(multiplier, decimals)
    if not multiplier or type(multiplier) ~= "number" then
        return "+0%"
    end
    
    local percentValue = (multiplier - 1) * 100
    decimals = decimals or 0
    local formatStr = "+%." .. decimals .. "f%%"
    return string.format(formatStr, percentValue)
end

-- Format time duration (seconds to readable format)
function NumberFormatter.formatTime(seconds)
    if not seconds or type(seconds) ~= "number" or seconds < 0 then
        return "0s"
    end
    
    if seconds < 60 then
        return math.floor(seconds) .. "s"
    elseif seconds < 3600 then
        return math.floor(seconds / 60) .. "m"
    elseif seconds < 86400 then
        return math.floor(seconds / 3600) .. "h"
    else
        return math.floor(seconds / 86400) .. "d"
    end
end

-- Format large numbers with commas (for precise display)
function NumberFormatter.formatWithCommas(number)
    if not number or type(number) ~= "number" then
        return "0"
    end
    
    local formatted = tostring(math.floor(number))
    local k = 0
    while k < string.len(formatted) do
        k = k + 4
        if k <= string.len(formatted) then
            formatted = string.sub(formatted, 1, string.len(formatted) - k + 1) .. "," .. string.sub(formatted, string.len(formatted) - k + 2)
        end
    end
    return formatted
end

return NumberFormatter