-- NumberFormatter - Utility for formatting numbers with K/M/B/T suffixes
local NumberFormatter = {}

-- Format numbers for display with better prettification
function NumberFormatter.format(num)
    if not num or num ~= num then -- Check for nil or NaN
        return "0"
    end
    
    num = math.floor(num) -- Ensure integer
    
    if num >= 1000000000000 then
        return string.format("%.1fT", num / 1000000000000)
    elseif num >= 1000000000 then
        return string.format("%.1fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

-- Compact format for smaller displays (shorter strings)
function NumberFormatter.formatCompact(num)
    if not num or num ~= num then -- Check for nil or NaN
        return "0"
    end
    
    num = math.floor(num) -- Ensure integer
    
    if num >= 1000000000000 then
        return string.format("%.0fT", num / 1000000000000)
    elseif num >= 1000000000 then
        return string.format("%.0fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.0fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.0fK", num / 1000)
    else
        return tostring(num)
    end
end

return NumberFormatter