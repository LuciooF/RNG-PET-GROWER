-- PetCollectionService - Handles client-side pet ball collection
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local PetCollectionService = {}
PetCollectionService.__index = PetCollectionService

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Remote events - wait for server to create it
local collectPetRemote = ReplicatedStorage:WaitForChild("CollectPet")

-- Track collected balls to prevent double collection
local collectedBalls = {}

function PetCollectionService:Initialize()
    -- Set up collection detection
    self:SetupCollectionDetection()
    
    -- Handle character respawn
    player.CharacterAdded:Connect(function(newCharacter)
        character = newCharacter
        humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
    end)
end

function PetCollectionService:SetupCollectionDetection()
    -- Monitor workspace for pet balls
    workspace.DescendantAdded:Connect(function(descendant)
        if descendant.Name == "PetBall" and descendant:IsA("BasePart") then
            self:SetupBallCollection(descendant)
        end
    end)
    
    -- Handle existing pet balls
    for _, descendant in pairs(workspace:GetDescendants()) do
        if descendant.Name == "PetBall" and descendant:IsA("BasePart") then
            self:SetupBallCollection(descendant)
        end
    end
end

function PetCollectionService:SetupBallCollection(petBall)
    local connection
    connection = petBall.Touched:Connect(function(hit)
        -- Check if player touched it
        if hit.Parent == character then
            self:CollectPetBall(petBall, connection)
        end
    end)
    
    -- Clean up connection when ball is destroyed
    petBall.AncestryChanged:Connect(function()
        if not petBall.Parent then
            if connection then
                connection:Disconnect()
            end
            collectedBalls[petBall] = nil
        end
    end)
end

function PetCollectionService:CollectPetBall(petBall, connection)
    -- Prevent double collection
    if collectedBalls[petBall] then
        return
    end
    collectedBalls[petBall] = true
    
    -- Disconnect the touch event immediately
    if connection then
        connection:Disconnect()
    end
    
    -- Get pet data
    local petDataValue = petBall:FindFirstChild("PetData")
    if not petDataValue then
        warn("PetCollectionService: Pet ball has no pet data!")
        collectedBalls[petBall] = nil
        return
    end
    
    -- Decode pet data
    local success, petData = pcall(function()
        return HttpService:JSONDecode(petDataValue.Value)
    end)
    
    if not success or not petData then
        warn("PetCollectionService: Failed to decode pet data")
        collectedBalls[petBall] = nil
        return
    end
    
    -- Get ball path before destroying it
    local ballPath = petBall:GetFullName()
    
    -- Instantly destroy the ball for immediate feedback
    petBall:Destroy()
    
    -- Send to server with ball information for counter update
    collectPetRemote:FireServer(petData, ballPath)
end

function PetCollectionService:PlayCollectionEffect(petBall)
    -- Create shrink and fade effect
    local shrinkTween = TweenService:Create(petBall,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Size = Vector3.new(0, 0, 0), Transparency = 1}
    )
    
    -- Play the tween
    shrinkTween:Play()
    
    -- Destroy after animation
    shrinkTween.Completed:Connect(function()
        petBall:Destroy()
    end)
end

return PetCollectionService