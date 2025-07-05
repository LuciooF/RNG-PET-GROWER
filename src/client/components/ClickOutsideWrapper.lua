-- Click Outside Wrapper Component
-- Wraps UI panels and provides click-outside-to-close functionality

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local e = React.createElement

local function ClickOutsideWrapper(props)
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local children = props.children
    
    if not visible then
        return nil
    end
    
    return e("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 1,
        Active = true,
    }, {
        -- Semi-transparent background that captures clicks
        Background = e("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 1,
            [React.Event.Activated] = function()
                onClose()
            end
        }),
        
        -- Content container that stops click propagation
        ContentContainer = e("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = 2,
            Active = true,
        }, {
            -- This TextButton blocks clicks from reaching the background
            ClickBlocker = e("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 2,
                Active = true,
                [React.Event.Activated] = function()
                    -- Do nothing - this just blocks the click
                end
            }, children)
        })
    })
end

return ClickOutsideWrapper