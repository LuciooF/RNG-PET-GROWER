-- PetMagnetService - Cinematic curved-path pet magnet with area-bounded tracking
-- Drop-in replacement for your previous PetMagnetService

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local DataSyncService = require(script.Parent.DataSyncService)
local GamepassConfig = require(ReplicatedStorage.config.GamepassConfig)
local PotionService = require(script.Parent.PotionService)
local PotionConfig = require(ReplicatedStorage.config.PotionConfig)

local PetMagnetService = {}
PetMagnetService.__index = PetMagnetService

local player = Players.LocalPlayer

-- =========================
-- Config (cinematic feel)
-- =========================
local magnetBenefits = GamepassConfig.getBenefits("PetMagnet") or {}
local function coalesce(v, d) return (v == nil) and d or v end

-- Your constraints: speed/range do not change at runtime
local MAGNET_RANGE       = coalesce(magnetBenefits.magnetRange, 100)
local MAGNET_SPEED       = coalesce(magnetBenefits.magnetSpeed, 25) -- used indirectly via time per stud
local THROUGH_WALLS      = coalesce(magnetBenefits.throughWalls, true)

-- Update cadence: not every frame (perf + stability)
local UPDATE_INTERVAL    = 0.12

-- Pickup radius guard
local MIN_PICKUP_DISTANCE = 3
local Y_OFFSET            = Vector3.new(0, -2, 0)

-- Cinematic timing & easing
local BASE_TIME          = 0.25          -- ensures even short hops are visible
local TIME_PER_STUD      = 0.060         -- main "speed" (bigger = slower)
local DURATION_MIN       = 0.28
local DURATION_MAX       = 1.60
local STAGGER_RANGE      = 0.25          -- random delay per ball, makes wave-like pulls
local EASING_STYLE       = Enum.EasingStyle.Quad
local EASING_DIR         = Enum.EasingDirection.InOut

-- Arc shape (control point height factor)
local ARC_HEIGHT_PER_STUD = 0.35         -- arc height scales with distance
local ARC_HEIGHT_MIN      = 2.0          -- minimum bump so short hops still arc

-- Tag / group recognition (works with your spawner)
local PETBALL_TAG = "PetBall"
local PETBALL_COLLISION_GROUP = "PetBalls"

-- =========================
-- Internal state
-- =========================
local heartbeatConn: RBXScriptConnection? = nil
local areaChildAddedConn: RBXScriptConnection? = nil
local areaChildRemovingConn: RBXScriptConnection? = nil
local dataSubscription: (() -> ())? = nil
local potionCallbacks = {}

-- trackedBalls: set<BasePart>
local trackedBalls: {[BasePart]: true} = {}

-- activeTweens: map<BasePart] = { tween: Tween, tVal: NumberValue, con: RBXScriptConnection, completed: RBXScriptConnection }
local activeTweens: {[BasePart]: {tween: Tween, tVal: NumberValue, changedCon: RBXScriptConnection?, completedCon: RBXScriptConnection?}} = {}

local lastUpdate = 0
local currentArea: Instance? = nil

-- =========================
-- Helpers
-- =========================
local function getHRP(): BasePart?
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart") :: BasePart
end

local function hasPetBallTag(part: Instance)
    return CollectionService:HasTag(part, PETBALL_TAG)
end

local function isPetBall(inst: Instance): boolean
    if not inst or not inst:IsA("BasePart") then return false end
    if hasPetBallTag(inst) then return true end
    if inst.Name == "PetBall" then return true end
    local ok, group = pcall(function() return inst.CollisionGroup end)
    if ok and group == PETBALL_COLLISION_GROUP then return true end
    return false
end

local function lineOfSightClear(fromPos: Vector3, toPos: Vector3, ignore: {Instance}?): boolean
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = ignore or {}
    local dir = toPos - fromPos
    local result = Workspace:Raycast(fromPos, dir, rayParams)
    return result == nil
end

-- Quadratic Bezier interpolation
local function quadBezier(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
    local u = 1 - t
    return u*u*p0 + 2*u*t*p1 + t*t*p2
end

-- Build a nice upward-curving control point between start->end
local function computeControlPoint(startPos: Vector3, endPos: Vector3): Vector3
    local mid = (startPos + endPos) * 0.5
    local dist = (endPos - startPos).Magnitude
    local up = Vector3.new(0, math.max(ARC_HEIGHT_MIN, dist * ARC_HEIGHT_PER_STUD), 0)
    return mid + up
end

-- =========================
-- Area discovery & tracking (cached)
-- =========================
function PetMagnetService:FindPlayerArea(): Instance?
    local playerAreas = Workspace:FindFirstChild("PlayerAreas")
    if not playerAreas then return nil end

    -- Your current naming/nameplate convention; done once, not per frame
    for _, area in ipairs(playerAreas:GetChildren()) do
        if area.Name:match("PlayerArea") then
            local nameplate = area:FindFirstChild("AreaNameplate")
            local billboard = nameplate and nameplate:FindFirstChild("NameplateBillboard")
            local textLabel = billboard and billboard:FindFirstChild("TextLabel")
            if textLabel and textLabel:IsA("TextLabel") then
                if textLabel.Text == (player.Name .. "'s Area") then
                    return area
                end
            end
        end
    end
    return nil
end

local function cancelAndClearTween(ball: BasePart)
    local rec = activeTweens[ball]
    if rec then
        if rec.completedCon then rec.completedCon:Disconnect() end
        if rec.changedCon then rec.changedCon:Disconnect() end
        if rec.tween then rec.tween:Cancel() end
        if rec.tVal then rec.tVal:Destroy() end
        activeTweens[ball] = nil
    end
end

local function clearTracking()
    for ball, rec in pairs(activeTweens) do
        if rec then
            if rec.completedCon then rec.completedCon:Disconnect() end
            if rec.changedCon then rec.changedCon:Disconnect() end
            if rec.tween then rec.tween:Cancel() end
            if rec.tVal then rec.tVal:Destroy() end
        end
        if THROUGH_WALLS and ball and ball.Parent then
            ball.CanCollide = true
        end
    end
    table.clear(activeTweens)
    table.clear(trackedBalls)
end

function PetMagnetService:AttachArea(area: Instance)
    if currentArea == area then return end

    if areaChildAddedConn then areaChildAddedConn:Disconnect() areaChildAddedConn = nil end
    if areaChildRemovingConn then areaChildRemovingConn:Disconnect() areaChildRemovingConn = nil end
    clearTracking()

    currentArea = area

    -- Seed tracking with existing balls in this area
    for _, d in ipairs(area:GetDescendants()) do
        if isPetBall(d) then
            trackedBalls[d] = true
        end
    end

    -- Track changes without rescanning
    areaChildAddedConn = area.DescendantAdded:Connect(function(inst)
        if isPetBall(inst) then
            trackedBalls[inst] = true
        end
    end)
    areaChildRemovingConn = area.DescendantRemoving:Connect(function(inst)
        if trackedBalls[inst] then
            trackedBalls[inst] = nil
            cancelAndClearTween(inst :: BasePart)
        end
    end)
end

-- =========================
-- Core magnet (curved path)
-- =========================
function PetMagnetService:AttractPetBall(petBall: BasePart, targetPos: Vector3)
    if activeTweens[petBall] then return end

    local startPos = petBall.Position
    local endPos   = targetPos + Y_OFFSET
    local diff     = endPos - startPos
    local dist     = diff.Magnitude
    if dist <= MIN_PICKUP_DISTANCE then return end

    if not THROUGH_WALLS then
        if not lineOfSightClear(startPos, endPos, {player.Character, petBall}) then
            return
        end
    end

    -- Snapshot state we’ll restore
    local originalCanCollide = petBall.CanCollide
    local originalAnchored   = petBall.Anchored
    local originalCFrame     = petBall.CFrame

    -- Anchor during animation to prevent gravity/physics fights
    petBall.Anchored = true
    if THROUGH_WALLS then
        petBall.CanCollide = false
    end

    -- Build arc
    local ctrl = computeControlPoint(startPos, endPos)
    local duration = math.clamp(BASE_TIME + dist * TIME_PER_STUD, DURATION_MIN, DURATION_MAX)
    local delayAmt = (dist > 10) and math.random() * STAGGER_RANGE or 0

    -- Reserve slot so we don't double-book while delayed
    activeTweens[petBall] = {tween = nil, tVal = nil, changedCon = nil, completedCon = nil}

    task.delay(delayAmt, function()
        if not petBall or not petBall.Parent then
            activeTweens[petBall] = nil
            return
        end

        -- Freeze any residual velocities just in case
        petBall.AssemblyLinearVelocity = Vector3.zero
        petBall.AssemblyAngularVelocity = Vector3.zero

        -- Tween parameter t 0→1; drive ball via CFrame along bezier
        local tVal = Instance.new("NumberValue")
        tVal.Value = 0

        local tween = TweenService:Create(
            tVal,
            TweenInfo.new(duration, EASING_STYLE, EASING_DIR),
            { Value = 1 }
        )

        local changedCon = tVal:GetPropertyChangedSignal("Value"):Connect(function()
            local t = tVal.Value

            -- Soft-follow the player while we fly
            local hrp = getHRP()
            local liveEnd = (hrp and hrp.Position or targetPos) + Y_OFFSET
            local liveCtrl = computeControlPoint(startPos, liveEnd)
            local blendedCtrl = liveCtrl:Lerp(ctrl, 0.4)

            local pos = quadBezier(startPos, blendedCtrl, liveEnd, t)

            -- Keep original orientation
            local cf = CFrame.new(pos) * CFrame.fromMatrix(Vector3.new(), originalCFrame.XVector, originalCFrame.YVector, originalCFrame.ZVector)

            -- Or: make the ball look at the player slightly (uncomment to try)
            -- local lookDir = (liveEnd - pos).Magnitude > 0.001 and (liveEnd - pos).Unit or originalCFrame.LookVector
            -- local cf = CFrame.lookAt(pos, pos + lookDir)

            if petBall and petBall.Parent then
                petBall.CFrame = cf
            end
        end)

        local function finish()
            -- Restore properties safely
            if petBall and petBall.Parent then
                petBall.Anchored = originalAnchored
                petBall.CanCollide = originalCanCollide
                -- ensure velocities are calm after we unanchor
                petBall.AssemblyLinearVelocity = Vector3.zero
                petBall.AssemblyAngularVelocity = Vector3.zero
            end
            if changedCon then changedCon:Disconnect() end
            if activeTweens[petBall] and activeTweens[petBall].completedCon then
                activeTweens[petBall].completedCon:Disconnect()
            end
            if tVal then tVal:Destroy() end
            activeTweens[petBall] = nil
        end

        local completedCon = tween.Completed:Connect(finish)

        -- Store refs for cleanup
        activeTweens[petBall] = {
            tween = tween,
            tVal = tVal,
            changedCon = changedCon,
            completedCon = completedCon,
        }

        -- If ball gets deleted mid-flight
        petBall.AncestryChanged:Once(function(_, parent)
            if parent == nil then
                if tween then tween:Cancel() end
                finish()
                trackedBalls[petBall] = nil
            end
        end)

        tween:Play()
    end)
end


function PetMagnetService:Step(dt: number)
    lastUpdate += dt
    if lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = 0

    local hrp = getHRP()
    if not hrp then return end
    local targetPos = hrp.Position
    local rangeSq = MAGNET_RANGE * MAGNET_RANGE
    local minSq   = MIN_PICKUP_DISTANCE * MIN_PICKUP_DISTANCE

    -- Iterate current area’s tracked balls
    for ball in pairs(trackedBalls) do
        if not ball or not ball.Parent then
            trackedBalls[ball] = nil
            cancelAndClearTween(ball)
        elseif not activeTweens[ball] then
            local offset = ball.Position - targetPos
            local distSq = offset.X*offset.X + offset.Y*offset.Y + offset.Z*offset.Z
            if distSq <= rangeSq and distSq > minSq then
                self:AttractPetBall(ball, targetPos)
            end
        end
    end
end

-- =========================
-- Lifecycle & wiring
-- =========================
function PetMagnetService:StartLoop()
    if heartbeatConn then return end
    heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        self:Step(dt)
    end)
end

function PetMagnetService:StopLoop()
    if heartbeatConn then heartbeatConn:Disconnect() heartbeatConn = nil end
    clearTracking()
end

function PetMagnetService:PlayerOwnsPetMagnet(playerData)
    if not playerData or not playerData.OwnedGamepasses then return false end
    for _, gp in pairs(playerData.OwnedGamepasses) do
        if gp == "PetMagnet" then return true end
    end
    return false
end

function PetMagnetService:PlayerHasPetMagnetPotion()
    return PotionService:HasActiveBoost(PotionConfig.BoostTypes.PET_MAGNET)
end

function PetMagnetService:UpdateMagnetStatus(playerData)
    local owns = self:PlayerOwnsPetMagnet(playerData)
    local enabled = playerData.GamepassSettings and playerData.GamepassSettings.PetMagnetEnabled
    local potion = self:PlayerHasPetMagnetPotion()
    local shouldRun = (owns and enabled) or potion

    if shouldRun then
        if not currentArea or not currentArea.Parent then
            local area = self:FindPlayerArea()
            if area then
                self:AttachArea(area)
            else
                return
            end
        end
        self:StartLoop()
    else
        self:StopLoop()
    end
end

function PetMagnetService:SetupDataSubscription()
    dataSubscription = DataSyncService:Subscribe(function(newState)
        if newState.player then
            self:UpdateMagnetStatus(newState.player)
        end
    end)

    local initial = DataSyncService:GetPlayerData()
    if initial then
        self:UpdateMagnetStatus(initial)
    end
end

function PetMagnetService:SetupPotionSubscription()
    local function onPotionEvent()
        local playerData = DataSyncService:GetPlayerData()
        if playerData then
            self:UpdateMagnetStatus(playerData)
        end
    end
    PotionService:RegisterCallback("PotionActivated", onPotionEvent)
    PotionService:RegisterCallback("PotionExpired", onPotionEvent)
    PotionService:RegisterCallback("PotionsSynced", onPotionEvent)
    potionCallbacks = { onPotionEvent, onPotionEvent, onPotionEvent }
end

function PetMagnetService:Initialize()
    local area = self:FindPlayerArea()
    if area then
        self:AttachArea(area)
    end
    self:SetupDataSubscription()
    self:SetupPotionSubscription()
end

function PetMagnetService:Cleanup()
    self:StopLoop()

    if dataSubscription then
        dataSubscription()
        dataSubscription = nil
    end

    if areaChildAddedConn then areaChildAddedConn:Disconnect() areaChildAddedConn = nil end
    if areaChildRemovingConn then areaChildRemovingConn:Disconnect() areaChildRemovingConn = nil end

    if #potionCallbacks > 0 then
        PotionService:UnregisterCallback("PotionActivated", potionCallbacks[1])
        PotionService:UnregisterCallback("PotionExpired", potionCallbacks[2])
        PotionService:UnregisterCallback("PotionsSynced", potionCallbacks[3])
        potionCallbacks = {}
    end
end

-- Re-evaluate after respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    local playerData = DataSyncService:GetPlayerData()
    if playerData then
        PetMagnetService:UpdateMagnetStatus(playerData)
    end
end)

return PetMagnetService
