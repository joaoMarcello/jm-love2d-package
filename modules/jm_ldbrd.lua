local str_format = string.format
local str_find = string.find
local tab_insert = table.insert
local tonumber = tonumber
---@type JM.Loader
local Loader = require(_G.JM_Path .. "modules.jm_loader")
local Utils = _G.JM_Utils
local http
local dat
local MAX

local Module = { parse = Utils.parse_csv_line }

-- local dummy = {
--     [1] = "socket.http",
--     [2] = "add",
--     [3] = "delete",
--     [4] = "clear",
--     [5] = "xml",
--     [6] = "json",
--     [7] = "pipe",
--     [8] = "quote",
--     [9] = "request",
--     [10] = 'return require"socket.http"',
--     [11] = "-get",
--     [12] = "add-pipe",
--     [13] = "add-xml",
--     [14] = "add-quote"
-- }

function Module:init(args)
    local file = string.char(100, 97, 116, 97, 47, 100, 117, 109, 109, 121, 49, 46, 100, 97, 116)

    -- dat = Loader.load(JM_Path:gsub("%.", "/") .. "\100\97\116\97\47\100\117\109\109\121\49\46\100\97\116")

    dat = Loader.load(JM_Path:gsub("%.", "/") .. file)

    assert(args[1] and args[2])

    http = loadstring(dat[10])() -- module http

    -- public key (get scores)
    self.gtsc = args[1] .. "/%s" .. "/%s" .. "/%s/"
    -- private key (to send scores)
    self.sdsc = args[2] .. "/%s" .. "/%s" .. "/%s" .. "/%s" .. "/%s/"
    self.rtq = http[dat[9]]
    MAX = args[3] or 10
end

function Module:env(name, score, time, text)
    if not name then return false end
    score = score and tostring(score) or ""
    time = time and tostring(time) or ""
    text = text or ""
    return self.rtq(str_format(self.sdsc, dat[14], name, score, time, text))
end

function Module:get(data, init, final)
    data = data or dat[8]
    init = init or MAX
    final = final or ""
    return self.rtq(str_format(self.gtsc, data, init, final))
end

---@return table|any
function Module:get_tab(scores)
    ---@type string|any
    local scores = scores or self:get()
    if not scores then return nil end
    scores = scores:gsub('%"', '')

    local result = {}
    local cur_init = 1
    local N = #scores

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
function Module:get_proper(data)
    if not data then
        ---@diagnostic disable-next-line: missing-return-value, return-type-mismatch
        return nil
    end
    return data[1], tonumber(data[2]), tonumber(data[3]), data[4], data[5]
end

return Module
