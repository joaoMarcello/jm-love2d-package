local playgames = false
do
    local success, r = pcall(function()
        return require "playgames"
    end)
    playgames = success and r or playgames
end

---@class JM.PlayGamesManager
local PlayGames = {}

---@type string|nil
local leaderboard_normal_id
---@type string|nil
local leaderboard_hard_id

local auto_signin = true

-- Callback system for score retrieval
---@type table<string, function>|nil
local scoreCallbacks

---@type table<string, any>|nil
local scoreCallbackArgs

local time = 0.0

---@param args {normalLeaderboardId:string, hardLeaderboardId:string, autoSignIn:boolean, onSignInSuccess:function|nil}|nil
function PlayGames:init(args)
    args = args or {}

    if args.normalLeaderboardId then
        leaderboard_normal_id = args.normalLeaderboardId
    end

    if args.hardLeaderboardId then
        leaderboard_hard_id = args.hardLeaderboardId
    end

    if args.autoSignIn ~= nil then
        auto_signin = args.autoSignIn
    end

    -- Auto sign-in se configurado
    if auto_signin and playgames and playgames.isEnabled() then
        if not playgames.isSignedIn() then
            playgames.signIn()
        end
    end
end

---@param leaderboardId string
---@param onSuccess function
---@param args any|nil
function PlayGames:setScoreCallback(leaderboardId, onSuccess, args)
    if not leaderboardId or not onSuccess then return false end

    scoreCallbacks = scoreCallbacks or {}
    scoreCallbackArgs = scoreCallbackArgs or {}

    scoreCallbacks[leaderboardId] = onSuccess
    scoreCallbackArgs[leaderboardId] = args

    return true
end

function PlayGames:clearScoreCallbacks()
    if scoreCallbacks then
        for k, v in next, scoreCallbacks do
            scoreCallbacks[k] = nil
        end
    end

    if scoreCallbackArgs then
        for k, v in next, scoreCallbackArgs do
            scoreCallbackArgs[k] = nil
        end
    end
end

if playgames then
    ---
    ---@return boolean
    function PlayGames:isEnabled()
        return playgames.isEnabled()
    end

    function PlayGames:signIn()
        if not playgames.isEnabled() then return false end
        playgames.signIn()
        return true
    end

    function PlayGames:signOut()
        if not playgames.isEnabled() then return false end
        playgames.signOut()
        return true
    end

    ---@return boolean
    function PlayGames:isSignedIn()
        if not playgames.isEnabled() then return false end
        return playgames.isSignedIn()
    end

    ---@param leaderboardId string
    ---@param score number
    function PlayGames:submitScore(leaderboardId, score)
        if not playgames.isEnabled() then return false end
        if not playgames.isSignedIn() then return false end

        playgames.submitScore(leaderboardId, score)
        return true
    end

    ---@param difficulty "normal"|"hard"|nil
    ---@param score number
    function PlayGames:submitScoreByDifficulty(difficulty, score)
        if not playgames.isEnabled() then return false end
        if not playgames.isSignedIn() then return false end

        local id
        if difficulty == "hard" then
            id = leaderboard_hard_id
        else
            id = leaderboard_normal_id
        end

        if not id or id == "" then return false end

        playgames.submitScore(id, score)
        return true
    end

    ---@param leaderboardId string|nil
    function PlayGames:showLeaderboard(leaderboardId)
        if not playgames.isEnabled() then return false end

        -- Se não está logado, tenta fazer login primeiro
        if not playgames.isSignedIn() then
            playgames.signIn()
            -- Aguarda um pouco para o login processar
            love.timer.sleep(0.5)
            if not playgames.isSignedIn() then
                return false
            end
        end

        if leaderboardId then
            playgames.showLeaderboard(leaderboardId)
        else
            playgames.showAllLeaderboards()
        end
        return true
    end

    ---@param difficulty "normal"|"hard"|nil
    function PlayGames:showLeaderboardByDifficulty(difficulty)
        if not playgames.isEnabled() then return false end

        local id
        if difficulty == "hard" then
            id = leaderboard_hard_id
        else
            id = leaderboard_normal_id
        end

        if not id or id == "" then
            return self:showAllLeaderboards()
        end

        return self:showLeaderboard(id)
    end

    function PlayGames:showAllLeaderboards()
        if not playgames.isEnabled() then return false end

        -- Se não está logado, tenta fazer login primeiro
        if not playgames.isSignedIn() then
            playgames.signIn()
            love.timer.sleep(0.5)
            if not playgames.isSignedIn() then
                return false
            end
        end

        playgames.showAllLeaderboards()
        return true
    end

    ---@return string
    function PlayGames:getPlayerName()
        if not playgames.isEnabled() then return "" end
        if not playgames.isSignedIn() then return "" end
        return playgames.getPlayerName()
    end

    ---@return string
    function PlayGames:getPlayerId()
        if not playgames.isEnabled() then return "" end
        if not playgames.isSignedIn() then return "" end
        return playgames.getPlayerId()
    end

    ---@return string
    function PlayGames:getLeaderboardNormalId()
        return leaderboard_normal_id or ""
    end

    ---@return string
    function PlayGames:getLeaderboardHardId()
        return leaderboard_hard_id or ""
    end

    ---@param leaderboardId string
    ---@param onSuccess function
    ---@param args any|nil
    function PlayGames:requestPlayerScore(leaderboardId, onSuccess, args)
        if not playgames.isEnabled() then return false end
        if not playgames.isSignedIn() then return false end
        if not leaderboardId or not onSuccess then return false end
        -- Proteção contra requisições duplicadas
        if scoreCallbacks and scoreCallbacks[leaderboardId] then
            print("[PlayGames] Requisição duplicada ignorada para " .. leaderboardId)
            return false
        end
        -- Registra o callback
        self:setScoreCallback(leaderboardId, onSuccess, args)

        -- Inicia a requisição assíncrona
        playgames.getPlayerScore(leaderboardId)

        return true
    end

    function PlayGames:checkForScoreCallbacks()
        if not scoreCallbacks then return end

        for leaderboardId, callback in next, scoreCallbacks do
            if playgames.hasScoreForLeaderboard(leaderboardId) then
                local score = playgames.getScore(leaderboardId)
                local args = scoreCallbackArgs and scoreCallbackArgs[leaderboardId]

                -- Dispara o callback
                if args then
                    callback(score, args)
                else
                    callback(score)
                end

                -- Remove o callback após disparar
                scoreCallbacks[leaderboardId] = nil
                if scoreCallbackArgs then
                    scoreCallbackArgs[leaderboardId] = nil
                end
            end
        end
    end

    local lim = 1 / 30
    function PlayGames:update(dt)
        dt = dt > lim and lim or dt

        if time >= 0.1 then
            self:checkForScoreCallbacks()
            time = 0.0
        end
        time = time + dt
    end

    ---
else
    ---
    -- Funções vazias quando Play Games não está disponível
    local func_false = function() end
    local func_empty = function() return "" end

    PlayGames.isEnabled = func_false
    PlayGames.signIn = func_false
    PlayGames.signOut = func_false
    PlayGames.isSignedIn = func_false
    PlayGames.submitScore = func_false
    PlayGames.submitScoreByDifficulty = func_false
    PlayGames.showLeaderboard = func_false
    PlayGames.showLeaderboardByDifficulty = func_false
    PlayGames.showAllLeaderboards = func_false
    PlayGames.getPlayerName = func_empty
    PlayGames.getPlayerId = func_empty
    PlayGames.getLeaderboardNormalId = func_empty
    PlayGames.getLeaderboardHardId = func_empty
    PlayGames.requestPlayerScore = func_false
    PlayGames.checkForScoreCallbacks = func_false
    PlayGames.update = func_false
end

function PlayGames:loadedPlayGamesModule()
    return playgames ~= false
end

return PlayGames
