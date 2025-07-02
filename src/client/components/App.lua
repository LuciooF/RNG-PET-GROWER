local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.react)

local Store = require(ReplicatedStorage:WaitForChild("store"))
local TopStats = require(script.Parent.TopStats)

local e = React.createElement

local function App()
    local playerData, setPlayerData = React.useState({
        money = 0,
        rebirths = 0,
        diamonds = 0
    })
    
    local screenSize, setScreenSize = React.useState(
        UserInputService.TouchEnabled and 
        Vector2.new(1024, 768) or 
        Vector2.new(1920, 1080)
    )
    
    React.useEffect(function()
        local connection = Store.changed:connect(function(newState)
            if newState.player then
                setPlayerData({
                    money = newState.player.resources.money,
                    rebirths = newState.player.resources.rebirths,
                    diamonds = newState.player.resources.diamonds
                })
            end
        end)
        
        return function()
            connection:disconnect()
        end
    end, {})
    
    React.useEffect(function()
        local function updateScreenSize()
            local camera = workspace.CurrentCamera
            if camera then
                setScreenSize(camera.ViewportSize)
            end
        end
        
        updateScreenSize()
        
        local connection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScreenSize)
        
        return function()
            connection:Disconnect()
        end
    end, {})
    
    return e("ScreenGui", {
        Name = "MainUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, {
        TopStats = e(TopStats, {
            playerData = playerData,
            screenSize = screenSize
        })
    })
end

return App