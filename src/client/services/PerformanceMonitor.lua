-- Performance Monitor Service
-- Tracks and reports performance metrics for optimization

local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local PerformanceMonitor = {}
PerformanceMonitor.__index = PerformanceMonitor

-- Configuration
local SAMPLE_RATE = 1 -- Check performance every 1 second
local WARNING_FPS = 30 -- Warn if FPS drops below this
local CRITICAL_FPS = 20 -- Critical warning if FPS drops below this

-- Internal state
local lastSampleTime = 0
local frameCount = 0
local connection = nil
local performanceData = {
    averageFPS = 60,
    minFPS = 60,
    maxFPS = 60,
    avgHeartbeatTime = 0,
    totalHeartbeatCalls = 0
}

-- Track individual service performance
local serviceMetrics = {}

function PerformanceMonitor:Initialize()
    -- Reset metrics
    performanceData = {
        averageFPS = 60,
        minFPS = 60,
        maxFPS = 60,
        avgHeartbeatTime = 0,
        totalHeartbeatCalls = 0
    }
    
    -- Start monitoring
    if connection then
        connection:Disconnect()
    end
    
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        self:UpdateMetrics(deltaTime)
    end)
    
    -- Log performance data periodically
    task.spawn(function()
        while connection do
            task.wait(10) -- Log every 10 seconds
            self:LogPerformanceReport()
        end
    end)
end

function PerformanceMonitor:UpdateMetrics(deltaTime)
    frameCount = frameCount + 1
    performanceData.totalHeartbeatCalls = performanceData.totalHeartbeatCalls + 1
    
    local currentTime = tick()
    local timeSinceLastSample = currentTime - lastSampleTime
    
    if timeSinceLastSample >= SAMPLE_RATE then
        -- Calculate FPS
        local currentFPS = frameCount / timeSinceLastSample
        performanceData.averageFPS = (performanceData.averageFPS + currentFPS) / 2
        performanceData.minFPS = math.min(performanceData.minFPS, currentFPS)
        performanceData.maxFPS = math.max(performanceData.maxFPS, currentFPS)
        
        -- Check for performance issues
        if currentFPS < CRITICAL_FPS then
            warn(string.format("[CRITICAL] FPS dropped to %.1f - Performance severely impacted!", currentFPS))
        elseif currentFPS < WARNING_FPS then
            warn(string.format("[WARNING] FPS dropped to %.1f - Performance degraded", currentFPS))
        end
        
        -- Reset counters
        frameCount = 0
        lastSampleTime = currentTime
    end
    
    -- Track heartbeat time
    performanceData.avgHeartbeatTime = (performanceData.avgHeartbeatTime + deltaTime) / 2
end

function PerformanceMonitor:TrackService(serviceName, executionTime)
    if not serviceMetrics[serviceName] then
        serviceMetrics[serviceName] = {
            totalTime = 0,
            callCount = 0,
            avgTime = 0,
            maxTime = 0
        }
    end
    
    local metrics = serviceMetrics[serviceName]
    metrics.totalTime = metrics.totalTime + executionTime
    metrics.callCount = metrics.callCount + 1
    metrics.avgTime = metrics.totalTime / metrics.callCount
    metrics.maxTime = math.max(metrics.maxTime, executionTime)
end

function PerformanceMonitor:LogPerformanceReport()
    print("\n=== Performance Report ===")
    print(string.format("Average FPS: %.1f (Min: %.1f, Max: %.1f)", 
        performanceData.averageFPS, 
        performanceData.minFPS, 
        performanceData.maxFPS
    ))
    print(string.format("Average Frame Time: %.3fms", performanceData.avgHeartbeatTime * 1000))
    print(string.format("Total Heartbeat Calls: %d", performanceData.totalHeartbeatCalls))
    
    -- Log service-specific metrics
    if next(serviceMetrics) then
        print("\n--- Service Performance ---")
        for serviceName, metrics in pairs(serviceMetrics) do
            print(string.format("%s: Avg %.3fms, Max %.3fms (%d calls)", 
                serviceName,
                metrics.avgTime * 1000,
                metrics.maxTime * 1000,
                metrics.callCount
            ))
        end
    end
    
    -- Memory usage
    local memoryUsage = collectgarbage("count") / 1024 -- Convert to MB
    print(string.format("\nMemory Usage: %.2f MB", memoryUsage))
    print("========================\n")
end

function PerformanceMonitor:Cleanup()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    -- Final report
    self:LogPerformanceReport()
end

-- Utility function to measure execution time
function PerformanceMonitor:MeasureFunction(funcName, func, ...)
    local startTime = tick()
    local results = {func(...)}
    local executionTime = tick() - startTime
    
    self:TrackService(funcName, executionTime)
    
    return unpack(results)
end

return PerformanceMonitor