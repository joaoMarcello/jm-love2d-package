local https
do
    local success, result = pcall(function()
        return require "https"
    end)
    https = success and result or https

    -- https = require "https"
end

if not https then
    local success, result = pcall(function()
        return require "lua-https"
    end)
    https = success and result or https
end

-- assert(https, "not found https")

local json = require((...):gsub("init", "json"))

---@type JM.Foreign.JS
local JS = require(JM_Path .. "modules.js")
assert(type(JS.newPromiseRequest) == "function", "Error: module JS not found.")

local str_format = string.format
local tonumber = tonumber

---@class JM.Locker
---@field session JM.Locker.Session
local Locker = {
    parse = JM.Utils.parse_csv_line, Ldr = JM.Ldr
}

local __game_key

local _WEB

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

---@type love.Channel?
local session_channel

---@type love.Thread?
local thread_session

---@param value boolean?
function Locker:set_web_mode(value)
    _WEB = value and true

    if _WEB then
        if session_channel then
            session_channel:clear()
            session_channel:release()
        end
        if thread_session then
            thread_session:release()
        end
        session_channel = nil
        thread_session = nil
        ---
    else
        session_channel = love.thread.getChannel("jm_locker_session")
        thread_session = love.thread.newThread([[
do
    local jit = require "jit"
    jit.off(true, true)
end

local https = require "https"
local json = require("jm-love2d-package.modules.locker.json")
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
    end
end

function Locker:on_succeed_session(action, args)
    self.__on_succeed_session = action
    self.__on_succeed_session_args = args
end

local function set_session(data)
    Locker.session = json.decode(tostring(data))
    -- print("got session")
    -- print("My token: " .. tostring(Locker.session.session_token))
    Locker.__requesting_session = false
    if Locker.__on_succeed_session then
        Locker.__on_succeed_session(Locker.__on_succeed_session_args)
    end
end

local function on_session_error(id, data)
    print("session time out")
    Locker.__requesting_session = false
end

---@param self JM.Locker
local function do_the_request(self, game_key)
    if _WEB then
        -- print("requesting using javascript")

        local data = string.format("{\"game_key\":\"%s\", \"game_version\": \"0.10.0.0\"}", game_key)

        local str = ([[
            var xhr = new XMLHttpRequest();

            xhr.onreadystatechange = function () {
                if (this.readyState == XMLHttpRequest.DONE
                    && this.status == 200)
                {
                    _$_(this.responseText);
                }
            };

            xhr.open("POST", "https://api.lootlocker.io/game/v2/session/guest");

            xhr.setRequestHeader("Content-Type", "application/json");

            var data = `%s`;

            xhr.send(data);
    ]]):format(data)

        -- var data = JSON.stringify(%s);
        -- var data = `%s`;

        JS.newPromiseRequest(JS.stringFunc(str), set_session, on_session_error, 10, 112)

        self.__requesting_session = true
        ---
    elseif thread_session then
        -- print("going request...")
        thread_session:start(game_key)
    end
end

function Locker:request_session(game_key, force)
    game_key = game_key or __game_key

    if game_key and ((not self.session) or force)
        and not self:is_requesting_session()
    then
        self.session = nil
        return do_the_request(self, game_key)
    end

    -- if _WEB then
    --     if game_key and (not self.session or force) and
    --         not self:is_requesting_session()
    --     then
    --         return true
    --     end
    --     return false
    -- else
    --     if game_key and (not self.session or force)
    --         and not self:is_requesting_session()
    --     then
    --         print("going request...")
    --         thread_session:start(game_key)
    --         return true
    --     end
    --     return false
    -- end
end

function Locker:is_requesting_session()
    if _WEB then
        return self.__requesting_session
    end
    return thread_session and thread_session:isRunning()
end

function Locker:get_session_data(dt)
    if _WEB then
        -- JS.retrieveData(dt)
        return self.session
    else
        return session_channel and session_channel:pop()
    end
end

function Locker:update(dt)
    if not self.session then
        local session = self:get_session_data(dt)
        if session then
            self.session = session
            self.__requesting_session = false
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
    self:request_session(__game_key)
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
    self:request_session(__game_key)
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

Locker:set_web_mode(false)

return Locker
