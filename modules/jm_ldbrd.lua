local str_format = string.format
local str_find = string.find
local tab_insert = table.insert
---@type JM.Loader
local Loader = require(_G.JM_Path .. "modules.jm_loader")
local Utils = _G.JM_Utils
local http
local dat
local MAX

local Module = {}

-- local dummy = {
--     [1] = "socket.http",
--     [2] = "add",
--     [3] = "delete",
--     [4] = "clear",
--     [5] = "xml",
--     [6] = "json",
--     [7] = "pipe",
--     [8] = "quote"
-- }

function Module:init(args)
    dat = Loader.load(JM_Path:gsub("%.", "/") .. "data/dummy1.dat")

    http = require(dat[1]) -- module http
    self.pub = args[1] .. "/%s" .. "/%s" .. "/%s"
    self.priv = args[2] .. "/%s" .. "/%s" .. "/%s" .. "/%s" .. "/%s"
    self.req = http.request
    MAX = args[3] or 5
end

function Module:add(name, score, time, text)
    if not name then return false end
    score = score or ""
    time = time or ""
    text = text or ""
    return self.req(str_format(self.priv, dat[2], name, score, time, text))
end

function Module:get(data, init, final)
    data = data or dat[8]
    init = init or MAX
    final = final or ""
    return self.req(str_format(self.pub, data, init, final))
end

---@return table|any
function Module:tab()
    ---@type string|any
    local scores = self:get()
    if not scores then return nil end
    scores = scores:gsub('%"', '')

    local result = {}
    local cur_init = 1
    local N = #scores

    while cur_init <= N do
        local startp, endp = str_find(scores, "\n", cur_init)

        local line = scores:sub(cur_init, endp)
        local r = Utils:parse_csv_line(line, ",")
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
function Module:get_proper(data)
    if not data then
        ---@diagnostic disable-next-line: missing-return-value, return-type-mismatch
        return nil
    end
    return data[1], tonumber(data[2]), tonumber(data[3]), data[4], data[5]
end

return Module
