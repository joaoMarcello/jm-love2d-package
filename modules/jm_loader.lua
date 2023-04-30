-- ---@type Tserial
-- local tserial = require(JM_Path .. "others.TSerial")
---@type JM.Serial
local myserial = require((...):gsub("jm_loader", "jm_serial"))
local filesys = love.filesystem
local write = filesys.write
local char = string.char
--- love.data
-- local lovedata = _G[char(0x6C, 0x6F, 0x76, 0x65)][char(0x64, 0x61, 0x74, 0x61)]
local lovedata = love.data
local encode = lovedata.encode
local decode = lovedata.decode
local compress = lovedata.compress
local decompress = lovedata.decompress
-- local newImageData = love.image.newImageData
-- local newImage = love.graphics.newImage

local str, bytedata, format_comp, format_enc, format_enc2

---@class JM.Loader
local Loader = {
    ser = myserial,
    --
    save = function(data, path)
        ---@type any
        local dat = type(data) == "string" and data or myserial.pack(data)
        dat = encode(str, format_enc, dat)
        dat = compress(str, format_comp, dat)
        local r = path and write(path, dat)
        return dat
    end,
    --
    load = function(path, return_type, skip_unpack)
        return_type = return_type or str
        ---@type any
        local dat = filesys.read(path)
        dat = decompress(return_type, format_comp, dat)
        dat = decode(return_type, format_enc, dat)
        dat = not skip_unpack and myserial.unpack(dat) or dat
        return dat
    end,
    --
    ---@param self JM.Loader
    savexp = function(self, data, path, skip_encode, enc, comp)
        ---@type string|any
        local dat = data

        dat = not skip_encode and encode(str, enc or format_enc2, dat) or dat
        dat = compress(str, comp or format_comp, dat, 0x9)

        write(path, dat)
        return dat
    end,
    --
    ---@param return_type "string"|"data"|nil
    loadxp = function(path, skip_decode, return_type)
        return_type = return_type or str
        ---@type any
        local dat = filesys.read(path)
        dat = decompress(return_type, format_comp, dat)
        dat = not skip_decode and decode(return_type, format_enc2, dat) or dat
        return dat
    end,
    --
    init = function()
        str = char(0x73, 0x74, 0x72, 0x69, 0x6E, 0x67)        -- string
        bytedata = char(0x64, 0x61, 0x74, 0x61)               -- data
        format_comp = char(0x7A, 0x6C, 0x69, 0x62)            -- zlib
        format_enc = char(0x62, 0x61, 0x73, 0x65, 0x36, 0x34) -- base64
        format_enc2 = char(0x68, 0x65, 0x78)
    end,
    -- --
    -- ---@param self JM.Loader
    -- img = function(self, path, w, h)
    --     ---@type any
    --     local dat = filesys.read(path)
    --     dat = decompress(str, format_comp, dat)
    --     -- dat = decode(bytedata, format_enc2, dat)
    --     ---@diagnostic disable-next-line: param-type-mismatch
    --     return newImage(newImageData(w, h, nil, dat))
    -- end,
}

Loader.init()

return Loader
