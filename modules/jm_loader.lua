---@type Tserial
local tserial = require(JM_Path .. "others.TSerial")
local filesys = love.filesystem
local write = filesys.write
local lovedata = love.data
local encode = lovedata.encode
local decode = lovedata.decode
local compress = lovedata.compress
local decompress = lovedata.decompress
local newImageData = love.image.newImageData
local newImage = love.graphics.newImage

local str = "\115\116\114\105\110\103"
local bytedata = "\100\97\116\97"
local format_comp = "\122\108\105\98"
local format_enc = "\98\97\115\101\54\52"
local format_enc2 = "\104\101\120"

---@class JM.Loader
local Loader = {
    save = function(data, path)
        ---@type any
        local dat = type(data) == "string" and data or tserial.pack(data)
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
        dat = not skip_unpack and tserial.unpack(dat) or dat
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


return Loader
