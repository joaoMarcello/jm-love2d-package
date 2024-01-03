local string_format, mfloor, m_min, m_max, colorFromBytes, colorToBytes = string.format, math.floor, math.min, math.max,
    love.math.colorFromBytes, love.math.colorToBytes

local abs = math.abs

---@alias JM.Point {x: number, y:number}
--- Table representing a point with x end y coordinates.

---@alias JM.Color {[1]: number, [2]: number, [3]:number, [4]:number}
--- Represents a color in RGBA space

local ALPHA_MULT = 1

---@class JM.Utils
local Utils = {}

function Utils:set_alpha_range(value)
    value = Utils:clamp(value, 0, 255)
    ALPHA_MULT = value / 255
end

---@param width number|nil
---@param height number|nil
---@param ref_width number|nil
---@param ref_height number|nil
---@return JM.Point
function Utils:desired_size(width, height, ref_width, ref_height, keep_proportions)
    local dw, dh

    dw = width and width / ref_width or nil
    dh = height and height / ref_height or nil

    if keep_proportions then
        if not dw then
            dw = dh
        elseif not dh then
            dh = dw
        end
    end

    return { x = dw, y = dh }
end

function Utils:desired_size2(width, height, ref_width, ref_height, keep_proportions)
    local dw, dh

    dw = width and width / ref_width or nil
    dh = height and height / ref_height or nil

    if keep_proportions then
        if not dw then
            dw = dh
        elseif not dh then
            dh = dw
        end
    end

    return dw, dh
end

function Utils:desired_duration(duration, amount_steps)
    return duration / amount_steps
end

local results_parse = setmetatable({}, { __mode = 'kv' })

---@param line string
---@param sep string|nil
function Utils:parse_csv_line(line, sep)
    local result = results_parse[line]
    if result then return result end

    local res = {}
    local pos = 1
    sep = sep or ','
    while true do
        local c = string.sub(line, pos, pos)
        if (c == "") then break end
        if (c == '"') then
            -- quoted value (ignore separator within)
            local txt = ""
            repeat
                local startp, endp = string.find(line, '^%b""', pos)
                txt = txt .. string.sub(line, startp + 1, endp - 1)
                pos = endp + 1
                c = string.sub(line, pos, pos)
                if (c == '"') then txt = txt .. '"' end
                -- check first char AFTER quoted string, if it is another
                -- quoted string without separator, then append it
                -- this is the way to "escape" the quote char in a quote. example:
                --   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
            until (c ~= '"')
            table.insert(res, txt)
            assert(c == sep or c == "")
            pos = pos + 1
        else
            -- no quotes used, just look for the first separator
            local startp, endp = string.find(line, sep, pos)
            if (startp) then
                table.insert(res, string.sub(line, pos, startp - 1))
                pos = endp + 1
            else
                -- no separator found -> use rest of string and terminate
                table.insert(res, string.sub(line, pos))
                break
            end
        end
    end

    results_parse[line] = res
    return res
end

function Utils:get_lines_in_file(path)
    local lines = {}

    for line in love.filesystem.lines(path) do
        table.insert(lines, line)
    end

    return lines
end

--
function Utils:getText(path)
    local text = ""
    local lines = self:get_lines_in_file(path)

    for i, l in ipairs(lines) do
        text = text .. l .. (i == #lines and "" or "\n")
    end

    return text
end

Utils.shuffle = function(self, t, n)
    local N = n or #t
    for i = N, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

-- look up for 'k' in parent_list
local function search(k, parent_list)
    for i = 1, #parent_list do
        local v = parent_list[i][k]
        if v then return v end
    end
end

function Utils:create_class(...)
    local class_ = {}       -- the new class
    local parents = { ... } -- the parents for the new class

    -- class will search for absents fields in the parents list
    setmetatable(class_, {
        __index = function(t, k)
            local v = search(k, parents)
            t[k] = v -- saving for next access
            return v
        end
    })

    -- prepare the class to be the metatable of its instances
    class_.__index = class_

    -- defining a new constructor for this new class
    function class_:new()
        local obj = {}
        setmetatable(obj, class_)
        return obj
    end

    return class_
end

local colors = setmetatable({}, { __mode = 'v' })

---@return JM.Color
function Utils:get_rgba(r, g, b, a)
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0
    a = a or 1.0
    a = a

    local key = string_format("%d %d %d %d", colorToBytes(r, g, b, a))
    -- local key = string_format("%.15f %.15f %.15f %.15f", r, g, b, a)

    local color = colors[key]
    if color then return color end

    color = { r, g, b, a }
    colors[key] = color
    return color
end

function Utils:get_rgba2(r, g, b, a)
    r = r and r / 255 or 1.0
    g = g and g / 255 or 1.0
    b = b and b / 255 or 1.0
    a = a and a / 255 or 1.0
    return self:get_rgba(r, g, b, a)
end

---@param color JM.Color
function Utils:unpack_color(color)
    return color[1], color[2], color[3], color[4]
end

function Utils:round(x)
    local f = mfloor(x + 0.5)
    if (x == f) or (x % 2.0 == 0.5) then
        return f
    else
        return mfloor(x + 0.5)
    end
end

function Utils:clamp(value, min, max)
    return m_min(m_max(value, min), max)
end

---@param rgba string
function Utils:color_hex_2_rgba(rgba)
    local rb = tonumber(string.sub(rgba, 2, 3), 16)
    local gb = tonumber(string.sub(rgba, 4, 5), 16)
    local bb = tonumber(string.sub(rgba, 6, 7), 16)
    local ab = tonumber(string.sub(rgba, 8, 9), 16) or nil
    return colorFromBytes(rb, gb, bb, ab)
end

function Utils:hslToRgb(h, s, l)
    local C = (1 - abs(2 * l - 1)) * s
    local X = C * (1 - abs((h / 60 % 2) - 1))
    local m = l - C / 2

    local r1, g1, b1
    if h < 60 then
        r1, g1, b1 = C, X, 0
    elseif h < 120 then
        r1, g1, b1 = X, C, 0
    elseif h < 180 then
        r1, g1, b1 = 0, C, X
    elseif h < 240 then
        r1, g1, b1 = 0, X, C
    elseif h < 300 then
        r1, g1, b1 = X, 0, C
    elseif h <= 360 then
        r1, g1, b1 = C, 0, X
    end

    return r1 + m, g1 + m, b1 + m
end

function Utils:rgbToHsl(r, g, b)
    if type(r) == "string" then
        r, g, b = Utils:hex_to_rgba_float(r)
    end

    local cmax = m_max(r, g, b)
    local cmin = m_min(r, g, b)
    local dt = cmax - cmin

    local H, S, L

    if dt == 0 then
        H = 0
    else
        if cmax == r then
            H = ((g - b) / dt) % 6
        elseif cmax == g then
            H = ((b - r) / dt) + 2
        else
            H = ((r - g) / dt) + 4
        end
    end

    L = (cmax + cmin) / 2

    if dt == 0 then
        S = 0
    else
        S = dt / (1 - abs(2 * L - 1))
    end

    return H * 60, S, L
end

function Utils:rgbToHsv(r, g, b)
    if type(r) == "string" then
        r, g, b = Utils:hex_to_rgba_float(r)
    end

    local cmax = m_max(r, g, b)
    local cmin = m_min(r, g, b)
    local dt = cmax - cmin

    local H, S, V
    if dt == 0 then
        H = 0
    elseif cmax == r then
        H = ((g - b) / dt) % 6
    elseif cmax == g then
        H = ((b - r) / dt) + 2
    elseif cmax == b then
        H = ((r - g) / dt) + 4
    end

    S = cmax == 0 and 0 or (dt / cmax)

    V = cmax

    return H * 60, S, V
end

function Utils:hsvToRgb(h, s, v)
    local C = v * s
    local X = C * (1 - abs(((h / 60) % 2) - 1))
    local m = v - C

    local r1, g1, b1

    if h < 60 then
        r1, g1, b1 = C, X, 0
    elseif h < 120 then
        r1, g1, b1 = X, C, 0
    elseif h < 180 then
        r1, g1, b1 = 0, C, X
    elseif h < 240 then
        r1, g1, b1 = 0, X, C
    elseif h < 300 then
        r1, g1, b1 = X, 0, C
    elseif h <= 360 then
        r1, g1, b1 = C, 0, X
    end

    return (r1 + m), (g1 + m), (b1 + m)
end

--=====================================================================

---comment
---@param hex any
---@return number? r
---@return number? g
---@return number? b
---@return number|nil a
function Utils:hex_to_rgba(hex)
    if not hex then return 255, 255, 255, 255 end

    hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)),
        tonumber("0x" .. hex:sub(3, 4)),
        tonumber("0x" .. hex:sub(5, 6)),
        --if alpha exists in hex, return it
        #hex == 8 and tonumber("0x" .. hex:sub(7, 8)) or 255
end

function Utils:hex_to_rgba_float(hex)
    if not hex then return 1, 1, 1, 1 end

    local r, g, b, a = self:hex_to_rgba(hex)
    return r / 255, g / 255, b / 255, a / 255
end

--=========================================================================

local E = 2.718281828459

local function sigmoid(x)
    return 1.0 / (1.0 + (E ^ (-x)))
end

local function tanh(x)
    local E_2x = E ^ (2 * x)
    return (E_2x - 1) / (E_2x + 1)
end

--=========================================================================
---@enum JM.Utils.MoveTypes
local MoveTypes = {
    smooth = 1,
    linear = 2,
    fast_smooth = 3,
    balanced = 4,
    strong_dash = 5,
    smooth_dash = 6,
    gaussian = 7,
}

local Behavior = {
    [MoveTypes.smooth] = function(x)
        if x >= math.pi then
            return 1.0
        end
        return (1.0 - (1.0 + math.cos(x)) * 0.5)
    end,
    ---
    [MoveTypes.linear] = function(x)
        if x > 1.0 then return 1.0 end
        return x
    end,
    ---
    [MoveTypes.fast_smooth] = function(x)
        x = x - E
        local E_2x = E ^ (2.0 * x)
        local r = (1.0 + (E_2x - 1.0) / (E_2x + 1.0)) * 0.5
        if x < E then
            return r
        else
            return 1.0
        end
    end,
    ---
    [MoveTypes.balanced] = function(x)
        x = x - 5.0
        local r = 1.0 / (1.0 + (E ^ (-x)))

        if x < 5.0 then
            return r
        else
            return 1.0
        end
    end,
    ---
    [MoveTypes.strong_dash] = function(x)
        local E_2x = E ^ (2.0 * x)
        local r = ((E_2x - 1.0) / (E_2x + 1.0))
        if x < 3.0 then
            return r
        else
            return 1.0
        end
    end,
    ---
    [MoveTypes.smooth_dash] = function(x)
        if x >= math.pi * 0.5 then
            return 1.0
        end
        x = math.sin(x)
        return x
    end,
    ---
    [MoveTypes.gaussian] = function(x)
        local r = E ^ (-(x ^ 2.0))
        if x < 2.5 then
            return 1.0 - r
        else
            return 1.0
        end
    end
}

local Domain = {
    [MoveTypes.smooth] = math.pi,
    [MoveTypes.linear] = 1.0,
    [MoveTypes.fast_smooth] = E * 2.0,
    [MoveTypes.balanced] = 10.0,
    [MoveTypes.strong_dash] = 3.0,
    [MoveTypes.smooth_dash] = math.pi / 2.0,
    [MoveTypes.gaussian] = 2.5,
}

Utils.MoveTypes = MoveTypes
Utils.Behavior = Behavior
Utils.Domain = Domain

--=========================================================================

function Utils:smoothstep(edge0, edge1, x)
    local t = Utils:clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
end

Utils.E = E
Utils.tanh = tanh
Utils.sigmoid = sigmoid

return Utils
