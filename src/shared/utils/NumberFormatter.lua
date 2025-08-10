-- NumberFormatter - Utility for formatting numbers with K/M/B/T suffixes
local NumberFormatter = {}

-- Format numbers for display with better prettification
function NumberFormatter.format(num)
    if not num or num ~= num then -- Check for nil or NaN
        return "0"
    end
    
    num = math.floor(num) -- Ensure integer
    
    if num >= 1000000000000 then
        local formatted = num / 1000000000000
        return formatted == math.floor(formatted) and string.format("%.0fT", formatted) or string.format("%.1fT", formatted)
    elseif num >= 1000000000 then
        local formatted = num / 1000000000
        return formatted == math.floor(formatted) and string.format("%.0fB", formatted) or string.format("%.1fB", formatted)
    elseif num >= 1000000 then
        local formatted = num / 1000000
        return formatted == math.floor(formatted) and string.format("%.0fM", formatted) or string.format("%.1fM", formatted)
    elseif num >= 1000 then
        local formatted = num / 1000
        return formatted == math.floor(formatted) and string.format("%.0fK", formatted) or string.format("%.1fK", formatted)
    else
        return tostring(num)
    end
end

-- Format boost multipliers (handles decimal values)
function NumberFormatter.formatBoost(num)
    if not num or num ~= num then -- Check for nil or NaN
        return "1"
    end
    
    -- For boost values >= 1000, use K/M/B format
    if num >= 1000000000 then
        return string.format("%.1fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    elseif num >= 100 then
        -- For values 100-999, show as integer
        return string.format("%.0f", num)
    elseif num >= 10 then
        -- For values 10-99, show one decimal if needed
        if num == math.floor(num) then
            return string.format("%.0f", num)
        else
            return string.format("%.1f", num)
        end
    else
        -- For values < 10, show up to 2 decimals if needed
        if num == math.floor(num) then
            return string.format("%.0f", num)
        else
            return string.format("%.2f", num)
        end
    end
end

return NumberFormatter