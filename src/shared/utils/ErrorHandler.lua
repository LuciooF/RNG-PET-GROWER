-- Error Handler Utility
-- Standardized error handling patterns to eliminate code duplication
-- Provides consistent error logging and fallback mechanisms

local ErrorHandler = {}

-- Configuration
local LOG_ERRORS = true -- Set to false in production to reduce log spam
local ERROR_PREFIX = "[ErrorHandler]"

-- Basic safe call wrapper
function ErrorHandler.safeCall(operation, context, fallback)
    if type(operation) ~= "function" then
        warn(ERROR_PREFIX, context or "Unknown", "- operation is not a function")
        return fallback
    end
    
    local success, result = pcall(operation)
    if not success then
        if LOG_ERRORS then
            warn(ERROR_PREFIX, context or "Operation", "failed:", result)
        end
        return fallback
    end
    
    return result
end

-- Safe call with custom error handler
function ErrorHandler.safeCallWithHandler(operation, context, errorHandler, fallback)
    if type(operation) ~= "function" then
        if errorHandler then
            errorHandler("Operation is not a function")
        end
        return fallback
    end
    
    local success, result = pcall(operation)
    if not success then
        if errorHandler then
            errorHandler(result)
        elseif LOG_ERRORS then
            warn(ERROR_PREFIX, context or "Operation", "failed:", result)
        end
        return fallback
    end
    
    return result
end

-- Safe call that returns success status and result
function ErrorHandler.trySafeCall(operation, context)
    if type(operation) ~= "function" then
        if LOG_ERRORS then
            warn(ERROR_PREFIX, context or "Unknown", "- operation is not a function")
        end
        return false, "Operation is not a function"
    end
    
    local success, result = pcall(operation)
    if not success and LOG_ERRORS then
        warn(ERROR_PREFIX, context or "Operation", "failed:", result)
    end
    
    return success, result
end

-- Service initialization wrapper
function ErrorHandler.initializeService(serviceName, initFunction)
    return ErrorHandler.safeCall(
        initFunction,
        serviceName .. " initialization",
        false
    )
end

-- Remote event wrapper
function ErrorHandler.safeRemoteCall(remote, context, ...)
    if not remote then
        warn(ERROR_PREFIX, context or "Remote call", "- remote is nil")
        return false
    end
    
    return ErrorHandler.safeCall(
        function()
            remote:FireServer(...)
            return true
        end,
        context or "Remote call",
        false
    )
end

-- Instance creation wrapper
function ErrorHandler.safeCreate(className, properties, parent, context)
    return ErrorHandler.safeCall(
        function()
            local instance = Instance.new(className)
            
            if properties then
                for property, value in pairs(properties) do
                    instance[property] = value
                end
            end
            
            if parent then
                instance.Parent = parent
            end
            
            return instance
        end,
        context or ("Creating " .. className),
        nil
    )
end

-- Data validation wrapper
function ErrorHandler.validateData(data, validator, context)
    if not data then
        if LOG_ERRORS then
            warn(ERROR_PREFIX, context or "Data validation", "- data is nil")
        end
        return false, "Data is nil"
    end
    
    return ErrorHandler.trySafeCall(
        function()
            return validator(data)
        end,
        context or "Data validation"
    )
end

-- Asset loading wrapper
function ErrorHandler.safeLoadAsset(assetPath, context)
    return ErrorHandler.safeCall(
        function()
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local assets = require(ReplicatedStorage.assets)
            return assets[assetPath]
        end,
        context or ("Loading asset: " .. tostring(assetPath)),
        nil
    )
end

-- Store dispatch wrapper
function ErrorHandler.safeDispatch(store, action, context)
    if not store then
        warn(ERROR_PREFIX, context or "Store dispatch", "- store is nil")
        return false
    end
    
    if not action then
        warn(ERROR_PREFIX, context or "Store dispatch", "- action is nil")
        return false
    end
    
    return ErrorHandler.safeCall(
        function()
            store:dispatch(action)
            return true
        end,
        context or "Store dispatch",
        false
    )
end

-- Service method wrapper
function ErrorHandler.wrapServiceMethod(service, methodName, fallback)
    local originalMethod = service[methodName]
    if type(originalMethod) ~= "function" then
        warn(ERROR_PREFIX, "Cannot wrap non-function method:", methodName)
        return
    end
    
    service[methodName] = function(self, ...)
        return ErrorHandler.safeCall(
            function()
                return originalMethod(self, ...)
            end,
            string.format("%s:%s", tostring(service), methodName),
            fallback
        )
    end
end

-- Batch operation wrapper
function ErrorHandler.safeBatch(operations, context, continueOnError)
    continueOnError = continueOnError or false
    local results = {}
    local errors = {}
    
    for i, operation in ipairs(operations) do
        local success, result = ErrorHandler.trySafeCall(
            operation,
            string.format("%s [%d]", context or "Batch operation", i)
        )
        
        if success then
            table.insert(results, result)
        else
            table.insert(errors, {index = i, error = result})
            if not continueOnError then
                break
            end
        end
    end
    
    return results, errors
end

-- Cleanup wrapper for services
function ErrorHandler.safeCleanup(cleanupFunction, context)
    ErrorHandler.safeCall(
        cleanupFunction,
        context or "Cleanup operation",
        nil
    )
end

-- Retry mechanism with exponential backoff
function ErrorHandler.retryOperation(operation, maxRetries, context, baseDelay)
    maxRetries = maxRetries or 3
    baseDelay = baseDelay or 1
    
    for attempt = 1, maxRetries do
        local success, result = ErrorHandler.trySafeCall(
            operation,
            string.format("%s (attempt %d/%d)", context or "Retry operation", attempt, maxRetries)
        )
        
        if success then
            return result
        end
        
        if attempt < maxRetries then
            wait(baseDelay * (2 ^ (attempt - 1))) -- Exponential backoff
        end
    end
    
    warn(ERROR_PREFIX, context or "Retry operation", "failed after", maxRetries, "attempts")
    return nil
end

-- Performance monitoring wrapper
function ErrorHandler.withPerformanceMonitoring(operation, context, warningThreshold)
    warningThreshold = warningThreshold or 1 -- 1 second default threshold
    
    local startTime = tick()
    local result = ErrorHandler.safeCall(operation, context, nil)
    local duration = tick() - startTime
    
    if duration > warningThreshold then
        warn(ERROR_PREFIX, context or "Performance", "took", string.format("%.2fs", duration), "(threshold:", warningThreshold .. "s)")
    end
    
    return result
end

-- Configuration
function ErrorHandler.setLogging(enabled)
    LOG_ERRORS = enabled
end

function ErrorHandler.isLoggingEnabled()
    return LOG_ERRORS
end

return ErrorHandler