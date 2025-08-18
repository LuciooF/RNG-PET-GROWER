-- TimeFormatter - Utility for formatting time durations
local TimeFormatter = {}

-- Format seconds into a human-readable string like "1d 2h 30m 20s"
function TimeFormatter.formatDuration(totalSeconds)
    if not totalSeconds or totalSeconds < 0 then
        return "0s"
    end
    
    -- Round to nearest second
    totalSeconds = math.floor(totalSeconds)
    
    local days = math.floor(totalSeconds / 86400)
    local hours = math.floor((totalSeconds % 86400) / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60
    
    local parts = {}
    
    if days > 0 then
        table.insert(parts, days .. "d")
    end
    if hours > 0 then
        table.insert(parts, hours .. "h")
    end
    if minutes > 0 then
        table.insert(parts, minutes .. "m")
    end
    if seconds > 0 or #parts == 0 then -- Always show seconds if it's the only unit
        table.insert(parts, seconds .. "s")
    end
    
    return table.concat(parts, " ")
end

-- Format seconds for leaderboard display (shorter format for long durations)
function TimeFormatter.formatForLeaderboard(totalSeconds)
    if not totalSeconds or totalSeconds < 0 then
        return "0s"
    end
    
    -- Round to nearest second
    totalSeconds = math.floor(totalSeconds)
    
    local days = math.floor(totalSeconds / 86400)
    local hours = math.floor((totalSeconds % 86400) / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    
    -- For very long durations, show fewer units
    if days > 0 then
        if hours > 0 then
            return string.format("%dd %dh", days, hours)
        else
            return string.format("%dd", days)
        end
    elseif hours > 0 then
        if minutes > 0 then
            return string.format("%dh %dm", hours, minutes)
        else
            return string.format("%dh", hours)
        end
    elseif minutes > 0 then
        return string.format("%dm", minutes)
    else
        return string.format("%ds", totalSeconds % 60)
    end
end

return TimeFormatter