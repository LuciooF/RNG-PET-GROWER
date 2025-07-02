local NumberFormatter = {}

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

return NumberFormatter