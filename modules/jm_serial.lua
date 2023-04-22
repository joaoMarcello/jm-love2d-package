local type, str_format, pairs = type, string.format, pairs
local filesys = love.filesystem
-- local fmt = { integer = "%d", float = "%a" }
local save_dir = "srl.txt"

--- serialize tables without cycles
local function serialize(o)
    local tp = type(o)

    if tp == "number" then
        filesys.append(save_dir, str_format(math.type(o) == "integer" and "%d" or "%a", o))
        --
    elseif tp == "string" then
        filesys.append(save_dir, str_format("%q", o))
        --
    elseif tp == "boolean" then
        local v = o and "true" or "false"
        filesys.append(save_dir, v)
        --
    elseif tp == "nil" then
        filesys.append(save_dir, "nil")
        --
    elseif tp == "table" then
        filesys.append(save_dir, "{\n")

        for k, v in pairs(o) do
            local str = str_format("   [%s] = ", serialize(k))
            filesys.append(save_dir, str)
            serialize(v)
            filesys.append(save_dir, "\n")
        end
        filesys.append(save_dir, "\n")
    else
        error("Cannot serialize a " .. type(o))
    end
end

---@class JM.Serial
local Serial = {
    serialize = serialize,
}

return Serial
