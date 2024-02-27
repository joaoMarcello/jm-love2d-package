local type, str_format, pairs, loadstring = type, string.format, pairs, loadstring

local serialize
--- serialize tables without cycles
serialize = function(o)
    local tp = type(o)

    if tp == "number" then
        local c = o % 1 == 0
        local r = str_format(c and "%d" or (_G.WEB and "%f" or "%a"), o)
        return r
        --
    elseif tp == "string" then
        return str_format("%q", o)
        --
    elseif tp == "boolean" then
        local v = o and "true" or "false"
        return v
        --
    elseif tp == "nil" then
        return "nil"
        --
    elseif tp == "table" then
        local r = "{"

        for k, v in next, o do
            r = str_format("%s[%s]=%s,", r, serialize(k), serialize(v))
        end
        r = str_format("%s}", r)
        return r
    else
        error("Cannot serialize a " .. type(o))
    end
end

---@class JM.Serial
local Serial = {
    pack = serialize,
    --
    unpack = function(data)
        assert(type(data) == "string")
        local r = loadstring(str_format("return %s", data))()
        -- r = setfenv(r, env)
        return r
    end
}

return Serial
