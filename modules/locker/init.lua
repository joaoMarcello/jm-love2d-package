local https = require "https"
local json = require((...):gsub("init", "json"))
local str_format = string.format
local tonumber = tonumber

---@class JM.Locker
---@field session JM.Locker.Session
local Locker = {
    parse = JM.Utils.parse_csv_line, Ldr = JM.Ldr
}

local __game_key

---@alias JM.Locker.Session {session_token:string, player_identifier:string, player_id:number, player_name:string, player_ulid:string, player_created_at:string, public_uid:string, seen_before:boolean, check_grant_notifications:boolean, check_deactivation_notifications:boolean, check_dlcs:table, success:boolean}

---@alias JM.Locker.PlayerData {member_id:string, rank:number, score:number, metadata:string}

---@alias JM.Locker.GetMemberResponse {pagination:{previous_cursor:any, total:number, next_cursor:number}, items:table<JM.Locker.PlayerData>}

---@overload fun(self:table, args:{[1]:string, [2]:string, [3]:number|nil})
---@param game_key any
---@param leaderboard_id any
---@param max any
function Locker:init(game_key, leaderboard_id, max)
    if type(game_key) == "table" then
        return self:init(unpack(game_key))
    end

    -- local code, body, headers = https.request(
    --     "https://api.lootlocker.io/game/v2/session/guest", {

    --         headers = {
    --             method = "POST",
    --             ["Content-Type"] = "application/json"
    --         },

    --         data =
    --             str_format("{\"game_key\":\"%s\", \"game_version\": \"0.10.0.0\"}", game_key),

    --     }
    -- )

    __game_key = game_key
    self:request_session(game_key)

    -- ---@type JM.Locker.Session
    -- self.session = json.decode(body)

    self:set_leaderboard_id(leaderboard_id)

    self.MAX = max or 10

    self.session_inited = false
end

local session_channel = love.thread.getChannel("jm_locker_session")
local thread_session = love.thread.newThread([[
do
    local jit = require "jit"
    jit.off(true, true)
end

local json = require("jm-love2d-package.modules.locker.json")
local https = require "https"
local game_key = ...
local code, body, headers = https.request(
    "https://api.lootlocker.io/game/v2/session/guest", {

        headers = {
            method = "POST",
            ["Content-Type"] = "application/json"
        },

        data =
            string.format("{\"game_key\":\"%s\", \"game_version\": \"0.10.0.0\"}", game_key),

    }
)
if code == 200 then
    local r = json.decode(body)
    love.thread.getChannel('jm_locker_session'):push(r)
end
]])

function Locker:request_session(game_key)
    game_key = game_key or __game_key
    if game_key and not self.session and not thread_session:isRunning() then
        print("going request...")
        thread_session:start(game_key)
        return true
    end
    return false
end

function Locker:verify_session()
    if not self.session then
        local session = session_channel:pop()
        if session then
            self.session = session
        end
    end
end

function Locker:update(dt)
    if not self.session then
        local session = session_channel:pop()
        if session then
            self.session = session
        end
    end
end

function Locker:set_max(value)
    self.MAX = value or self.MAX
end

function Locker:set_leaderboard_id(id)
    self.leaderboard_id = id
end

function Locker:env(member_id, score, time, text)
    assert(self.leaderboard_id, ">> No 'leaderboard_id' found. Use the set_leaderboard_id method.")
    if not self.session or not self.leaderboard_id then return "" end

    member_id = member_id or tostring(self.session.player_id)

    if time then
        time = tonumber(time)
        time = str_format("%d", time)
    end
    time = time or "0"
    text = text or ""

    local url, headers, data = self:str_env(member_id, score, time, text, true)

    ---@type number, JM.Locker.GetMemberResponse, table
    local code, body, _ = https.request(url, { method = "POST", headers = headers, data = data })

    do
        local code, body, _ = self:rec()
        if code ~= 200 then
            return ""
        end

        --- the data in comma separated values
        local quote = ""
        local decode = json.decode
        ---@type JM.Locker.GetMemberResponse
        local body = decode(body)
        local list = body.items
        local N = #list

        for i = 1, N do
            ---@type JM.Locker.PlayerData
            local data = list[i]

            local meta = data.metadata
            meta = meta == "" and "{}" or meta
            meta = meta:gsub("'", "\"")
            meta = decode(meta)

            local line = str_format(
                "\"%s\", \"%s\", \"%s\", \"%s\", \"%s\"",
                data.member_id, data.score, meta.seconds or "", meta.text or "", meta.date or ""
            )

            if i == 1 then
                quote = line
            else
                quote = str_format("%s\n%s", quote, line)
            end
        end

        return quote .. "\n"
    end
    ---
end

---@param member_id any
---@param score any
---@param time any
---@param text any
---@return string|nil url
---@return table|nil headers
---@return string|nil data
---@return string|nil url_rec
---@return table|nil headers_rec
function Locker:str_env(member_id, score, time, text, skip_str_rec)
    -- self:verify_session()

    if not self.session then
        return
    end

    local url = str_format("https://api.lootlocker.io/game/leaderboards/%s/submit", self.leaderboard_id)

    local headers = {
        ["Content-Type"] = "application/json",
        ["x-session-token"] = self.session.session_token,
    }

    local date = os.date("%m/%d/%Y %I:%M:%S %a %p", os.time())
    local metadata = str_format("{\'seconds\':\'%.2f\', \'date\':\'%s\', \'text\':\'%s\'}", time, date, text)

    local data = str_format("{\"member_id\":\"%s\", \"score\":%d, \"metadata\":\"%s\"}", member_id, score, metadata)

    if skip_str_rec then
        return url, headers, data
    end

    local url2, headers2 = self:str_rec()

    return url, headers, data, url2, headers2
end

function Locker:rec(count)
    assert(self.leaderboard_id, ">> No 'leaderboard_id' found. Use the set_leaderboard_id method.")
    if not self.session then return false end
    count = count or self.MAX

    local code, body, headers = https.request(
        str_format("https://api.lootlocker.io/game/leaderboards/%d/list?count=%d", self.leaderboard_id, count),
        {
            method = "GET",

            headers = {
                ["x-session-token"] = self.session.session_token,
            }
        }
    )

    return code, body, headers
end

function Locker:str_rec(data, init, final)
    -- self:verify_session()

    if not self.session then return end

    init = init or self.MAX
    local url = str_format("https://api.lootlocker.io/game/leaderboards/%d/list?count=%d", self.leaderboard_id, init)

    local headers = { ["x-session-token"] = self.session.session_token }

    return url, headers
end

---@return table|any
function Locker:get_tab(scores)
    ---@type string|any
    local scores = scores or self:rec()
    if not scores then return nil end
    scores = scores:gsub('%"', '')

    local str_find = string.find
    local tab_insert = table.insert

    local result = {}
    local cur_init = 1
    local N = #scores

    -- print(scores)
    while cur_init <= N do
        local startp, endp = str_find(scores, "\n", cur_init)

        local line = scores:sub(cur_init, endp)
        local r = self:parse(line, ",")
        tab_insert(result, r)
        cur_init = endp + 1
    end

    return result
end

---@return string name
---@return number? score
---@return number? seconds
---@return string text
---@return string date
function Locker:get_proper(data)
    if not data then
        ---@diagnostic disable-next-line: missing-return-value, return-type-mismatch
        return nil
    end
    return data[1], tonumber(data[2]), tonumber(data[3]), data[4], data[5]
end

return Locker
