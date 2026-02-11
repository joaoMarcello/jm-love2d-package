local playgames = false
do
    local success, r = pcall(function()
        return require "playgames"
    end)
    playgames = success and r or playgames
end

---@enum JM.CloudSaveManager.CallbackType
local CallbackType = {
    saveComplete = 1,
    saveFailed = 2,
    loadComplete = 3,
    loadFailed = 4,
    deleteComplete = 5,
    deleteFailed = 6,
}

---@alias JM.CloudSaveManager.Callbacks "saveComplete"|"saveFailed"|"loadComplete"|"loadFailed"|"deleteComplete"|"deleteFailed"

---@class JM.CloudSaveManager
local CloudSave = {}

local time = 0.0

---@type table<string, table>|nil
local pendingOperations -- {snapshotName = {type="save"|"load"|"delete", callback=func, args=any}}

---@type table|nil
local callbacks

---@type table|nil
local callbacks_args

---@param type JM.CloudSaveManager.CallbackType
local function dispatch_callback(type, ...)
    if not callbacks then return false end

    ---@type function?
    local func = callbacks[type]

    if func then
        local args = (...) or nil

        if args then
            local temp = callbacks_args and callbacks_args[type]

            if temp then
                func(temp, args)
                callbacks_args[type] = nil
            else
                func(args)
            end
        else
            local temp = callbacks_args and callbacks_args[type]
            func(temp)
            if temp then callbacks_args[type] = nil end
        end

        callbacks_args[type] = nil

        return true
    end

    return false
end

---@param type JM.CloudSaveManager.Callbacks
---@param func function
function CloudSave:setCallback(type, func, args)
    local temp = CallbackType[type]
    if not temp then return false end

    callbacks = callbacks or {}
    callbacks_args = callbacks_args or {}

    callbacks[temp] = func
    callbacks_args[temp] = args
end

function CloudSave:clearCallbacks()
    if callbacks then
        for k, v in next, callbacks do
            callbacks[k] = nil
        end
    end

    if callbacks_args then
        for k, v in next, callbacks_args do
            callbacks_args[k] = nil
        end
    end
end

if playgames then
    ---
    ---@return boolean
    function CloudSave:isEnabled()
        return playgames.isCloudSaveEnabled()
    end

    ---@param snapshotName string
    ---@param data string
    ---@param description string|nil
    ---@param playedTime number|nil
    ---@param progressValue number|nil Progress value 0-100, or -1 to ignore
    ---@param onSuccess function|nil
    ---@param onFail function|nil
    ---@param args any|nil
    function CloudSave:saveSnapshot(snapshotName, data, description, playedTime, progressValue, onSuccess, onFail, args)
        if not self:isEnabled() then
            if onFail then onFail("Cloud Save not enabled", args) end
            return false
        end

        if not playgames.isSignedIn() then
            if onFail then onFail("User not signed in", args) end
            return false
        end

        -- Registra operação pendente
        pendingOperations = pendingOperations or {}
        pendingOperations[snapshotName] = {
            type = "save",
            onSuccess = onSuccess,
            onFail = onFail,
            args = args
        }

        -- Inicia save assíncrono
        playgames.cloudSaveSnapshot(
            snapshotName,
            data,
            description or "",
            playedTime or 0,
            progressValue or -1 -- -1 = sem progresso
        )

        return true
    end

    ---@param snapshotName string
    ---@param onSuccess function|nil
    ---@param onFail function|nil
    ---@param args any|nil
    function CloudSave:loadSnapshot(snapshotName, onSuccess, onFail, args)
        if not self:isEnabled() then
            if onFail then onFail("Cloud Save not enabled", args) end
            return false
        end

        if not playgames.isSignedIn() then
            if onFail then onFail("User not signed in", args) end
            return false
        end

        -- Registra operação pendente
        pendingOperations = pendingOperations or {}
        pendingOperations[snapshotName] = {
            type = "load",
            onSuccess = onSuccess,
            onFail = onFail,
            args = args
        }

        -- Inicia load assíncrono
        playgames.cloudLoadSnapshot(snapshotName)

        return true
    end

    ---@param snapshotName string
    ---@param onSuccess function|nil
    ---@param onFail function|nil
    ---@param args any|nil
    function CloudSave:deleteSnapshot(snapshotName, onSuccess, onFail, args)
        if not self:isEnabled() then
            if onFail then onFail("Cloud Save not enabled", args) end
            return false
        end

        if not playgames.isSignedIn() then
            if onFail then onFail("User not signed in", args) end
            return false
        end

        -- Registra operação pendente
        pendingOperations = pendingOperations or {}
        pendingOperations[snapshotName] = {
            type = "delete",
            onSuccess = onSuccess,
            onFail = onFail,
            args = args
        }

        -- Inicia delete assíncrono
        playgames.cloudDeleteSnapshot(snapshotName)

        return true
    end

    ---@param title string|nil
    ---@param allowAdd boolean|nil
    ---@param allowDelete boolean|nil
    ---@param maxSnapshots number|nil
    function CloudSave:showSavedGamesUI(title, allowAdd, allowDelete, maxSnapshots)
        if not self:isEnabled() then return false end

        if not playgames.isSignedIn() then
            playgames.signIn()
            love.timer.sleep(0.5)
            if not playgames.isSignedIn() then
                return false
            end
        end

        playgames.cloudShowSavedGamesUI(
            title or "Saved Games",
            allowAdd ~= false,
            allowDelete ~= false,
            maxSnapshots or 3
        )
        return true
    end

    ---@return boolean
    function CloudSave:isSaveInProgress()
        if not self:isEnabled() then return false end
        return playgames.cloudIsSaveInProgress()
    end

    ---@return boolean
    function CloudSave:isLoadInProgress()
        if not self:isEnabled() then return false end
        return playgames.cloudIsLoadInProgress()
    end

    function CloudSave:clearResults()
        if not self:isEnabled() then return end
        playgames.cloudClearResults()
    end

    function CloudSave:checkForCloudSaveCallbacks()
        if not pendingOperations then return end

        for snapshotName, operation in next, pendingOperations do
            local hasError = playgames.cloudHasError(snapshotName)

            if hasError then
                local errorMsg = playgames.cloudGetError(snapshotName)

                if operation.type == "save" then
                    if operation.onFail then
                        operation.onFail(errorMsg, operation.args)
                    end
                    dispatch_callback(CallbackType.saveFailed, snapshotName, errorMsg)
                elseif operation.type == "load" then
                    if operation.onFail then
                        operation.onFail(errorMsg, operation.args)
                    end
                    dispatch_callback(CallbackType.loadFailed, snapshotName, errorMsg)
                elseif operation.type == "delete" then
                    if operation.onFail then
                        operation.onFail(errorMsg, operation.args)
                    end
                    dispatch_callback(CallbackType.deleteFailed, snapshotName, errorMsg)
                end

                pendingOperations[snapshotName] = nil
            else
                -- Verifica sucesso
                if operation.type == "save" then
                    if playgames.cloudHasSaveResult(snapshotName) then
                        local success = playgames.cloudGetSaveResult(snapshotName)

                        if success then
                            if operation.onSuccess then
                                operation.onSuccess(operation.args)
                            end
                            dispatch_callback(CallbackType.saveComplete, snapshotName)
                        else
                            if operation.onFail then
                                operation.onFail("Save failed", operation.args)
                            end
                            dispatch_callback(CallbackType.saveFailed, snapshotName, "Save failed")
                        end

                        pendingOperations[snapshotName] = nil
                    end
                elseif operation.type == "load" then
                    if playgames.cloudHasLoadedSnapshot(snapshotName) then
                        local data = playgames.cloudGetLoadedSnapshotData(snapshotName)

                        if data then
                            if operation.onSuccess then
                                operation.onSuccess(data, operation.args)
                            end
                            dispatch_callback(CallbackType.loadComplete, snapshotName, data)
                        else
                            if operation.onFail then
                                operation.onFail("Load failed - no data", operation.args)
                            end
                            dispatch_callback(CallbackType.loadFailed, snapshotName, "No data")
                        end

                        pendingOperations[snapshotName] = nil
                    end
                elseif operation.type == "delete" then
                    -- Delete não tem resultado específico, assume sucesso se não há erro
                    if not playgames.cloudIsSaveInProgress() and not playgames.cloudIsLoadInProgress() then
                        if operation.onSuccess then
                            operation.onSuccess(operation.args)
                        end
                        dispatch_callback(CallbackType.deleteComplete, snapshotName)

                        pendingOperations[snapshotName] = nil
                    end
                end
            end
        end
    end

    local lim = 1 / 30
    function CloudSave:update(dt)
        dt = dt > lim and lim or dt

        if time >= 0.1 then
            self:checkForCloudSaveCallbacks()
            time = 0.0
        end
        time = time + dt
    end

    ---
else
    ---
    -- Funções vazias quando Play Games não está disponível
    local func_false = function() return false end
    local func_empty = function() end

    CloudSave.isEnabled = func_false
    CloudSave.saveSnapshot = func_false
    CloudSave.loadSnapshot = func_false
    CloudSave.deleteSnapshot = func_false
    CloudSave.showSavedGamesUI = func_false
    CloudSave.isSaveInProgress = func_false
    CloudSave.isLoadInProgress = func_false
    CloudSave.clearResults = func_empty
    CloudSave.checkForCloudSaveCallbacks = func_empty
    CloudSave.update = func_empty
end

function CloudSave:loadedCloudSaveModule()
    return playgames ~= false
end

return CloudSave
