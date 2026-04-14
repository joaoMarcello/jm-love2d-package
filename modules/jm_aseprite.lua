--[[ Lua module for loading and parsing Aseprite files in LÖVE 2D.

    Loads .aseprite files directly without exporting to PNG.
    Converts sprite data to LÖVE2D Image and Quads for animation.
]]

---@enum JM.Aseprite.ColorDepths
local ColorDepths = {
    indexed = 8,
    grayscale = 16,
    rgba = 32,
}

---@enum JM.Aseprite.ChunkTypes
local ChunkTypes = {
    layer = 0x2004,
    cel = 0x2005,
    cel_info = 0x2006,
    color_profile = 0x2007,
    frame_tags = 0x2018,
    palette = 0x2019,
}

---@enum JM.Aseprite.CelTypes
local CelTypes = {
    raw = 0,
    linked = 1,
    compressed = 2,
    tilemap = 3,
}

---@class JM.Aseprite.Layer
---@field layerType number
---@field childLevel number
---@field blendMode number
---@field opacity number
---@field cels table
---@field name string
---@field indent number
---@field layerIndex number
---@field visible boolean
---@field editable boolean
---@field lock boolean
---@field background boolean
---@field preferLinked boolean
---@field collapsed boolean
---@field ref boolean

---@class JM.Aseprite.Frame
---@field tags table
---@field duration number

---@class JM.Aseprite.Sprite
---@field frameCount number
---@field frames table<number, JM.Aseprite.Frame>
---@field layers table<number, JM.Aseprite.Layer>
---@field width number
---@field height number
---@field colorDepth number
---@field image love.Image
---@field data love.ImageData
---@field quads table
---@field quadw number
---@field quadh number
---@field rowSize number
---@field path string
---@field aseprite boolean
local Sprite = {}
Sprite.__index = Sprite

---Constructor for new Sprite instance
---@param args {frameCount: number, width: number, height: number, colorDepth: number, path: string}
---@return JM.Aseprite.Sprite
function Sprite:new(args)
    local obj = setmetatable({}, Sprite)
    Sprite.__constructor__(obj, args)
    return obj
end

---Initialize sprite fields
---@param args {frameCount: number, width: number, height: number, colorDepth: number, path: string}
function Sprite:__constructor__(args)
    self.frameCount = args.frameCount
    self.frames = {}
    self.layers = {}
    self.width = args.width
    self.height = args.height
    self.colorDepth = args.colorDepth
    self.aseprite = true
    self.path = args.path
end

---Get total animation duration (sum of all frame durations in milliseconds)
---@return number Duration in milliseconds
function Sprite:getTotalDuration()
    if not self or not self.frames then
        return 500 -- Default 500ms
    end

    local total = 0
    for _, frame in ipairs(self.frames) do
        if frame.duration and frame.duration > 0 then
            total = total + frame.duration
        else
            total = total + 100 -- Default 100ms per frame if not set
        end
    end

    return total > 0 and total or 500 -- Return total or default 500ms
end

---Get total animation duration in seconds (for JM.Anima)
---@return number Duration in seconds (for use with JM.Anima)
function Sprite:getTotalDurationSeconds()
    return self:getTotalDuration() / 1000
end

---@class JM.Aseprite
---@field cache table<string, JM.Aseprite.Sprite>
---@field timeStamps table<string, number>
local Aseprite = {}
Aseprite.__index = Aseprite

---@return JM.Aseprite
function Aseprite:new()
    local obj = {
        cache = {},
        timeStamps = {},
    }
    setmetatable(obj, Aseprite)
    return obj
end

local function unsign(n)
    if n > 2 ^ 15 then
        n = n - 2 ^ 16
    end
    return n
end

---@private
---Blend new pixel over existing pixel using alpha blending
local function blendPixel(spriteData, x, y, r_new, g_new, b_new, a_new)
    local r_old, g_old, b_old, a_old = spriteData:getPixel(x, y)

    -- Alpha blend: out = new + old * (1 - alpha_new)
    local a_out = a_new + a_old * (1 - a_new)

    if a_out == 0 then
        spriteData:setPixel(x, y, 0, 0, 0, 0)
    else
        local r_out = (r_new * a_new + r_old * a_old * (1 - a_new)) / a_out
        local g_out = (g_new * a_new + g_old * a_old * (1 - a_new)) / a_out
        local b_out = (b_new * a_new + b_old * a_old * (1 - a_new)) / a_out
        spriteData:setPixel(x, y, r_out, g_out, b_out, a_out)
    end
end

---@private
local function readByte(openFile)
    local byte_val = openFile:read(1)
    return byte_val and string.byte(byte_val) or 0
end

---@private
local function read(openFile, range)
    local n = 0
    for i = 0, range - 1 do
        local byte_val = openFile:read(1)
        if not byte_val then break end
        n = n + string.byte(byte_val) * math.max(1, i * 256)
    end
    return n
end

---@private
local function readStr(openFile, range)
    local str = ""
    for i = 1, range do
        local byte_val = openFile:read(1)
        if not byte_val then break end
        str = str .. byte_val
    end
    return str
end

---@private
local function processCel(sprite, openFile, cel, frameIndex, chunkLength, read_fn, readStr_fn)
    local layer = sprite.layers[cel.layerIndex]

    if cel.celType == CelTypes.linked then
        cel.linkTo = read_fn(openFile, 2) + 1
        cel = layer[cel.linkTo]
    else
        cel.width = read_fn(openFile, 2)
        cel.height = read_fn(openFile, 2)
        layer[frameIndex] = cel
    end

    if cel.celType == CelTypes.raw then
        -- raw pixels
    elseif cel.celType == CelTypes.compressed then
        -- compressed with ZLIB
        -- chunkLength includes header (26 bytes), so subtract to get compressed data size
        local compressedSize = chunkLength - 26
        local str = cel.data or love.data.decompress("string", "zlib", openFile:read(compressedSize))
        cel.data = str

        if (layer.visible or sprite.seperate) and layer.layerType == 0 then
            local spriteData = layer.spriteData or sprite.data
            local w = spriteData:getWidth()
            local h = spriteData:getHeight()

            if sprite.colorDepth == ColorDepths.indexed then
                for i = 1, #str do
                    local n = string.byte(str:sub(i, i))
                    local x = (i - 1) % cel.width + (frameIndex - 1) * sprite.width + cel.x
                    local y = math.floor((i - 1) / cel.width) + cel.y

                    if n and x >= 0 and x < w and y >= 0 and y < h then
                        spriteData:setPixel(x, y, n / 255, n / 255, n / 255, 1)
                    end
                end
            elseif sprite.colorDepth == ColorDepths.grayscale then
                for i = 1, #str / 2 do
                    local i2 = i * 2
                    local n = string.byte(str:sub(i2 - 1, i2 - 1)) / 255
                    local a = string.byte(str:sub(i2, i2))

                    -- Apply cel and layer opacity to pixel alpha
                    local celOpacity = cel.opacity / 255
                    local layerOpacity = layer.opacity / 255
                    local finalAlpha = (a / 255) * celOpacity * layerOpacity

                    local x = (i - 1) % cel.width + (frameIndex - 1) * sprite.width + cel.x
                    local y = math.floor((i - 1) / cel.width) + cel.y

                    if finalAlpha > 0 and x >= 0 and x < w and y >= 0 and y < h then
                        blendPixel(spriteData, x, y, n, n, n, finalAlpha)
                    end
                end
            elseif sprite.colorDepth == ColorDepths.rgba then
                for i = 1, #str / 4 do
                    local i2 = i * 4
                    local r = string.byte(str:sub(i2 - 3, i2 - 3))
                    local g = string.byte(str:sub(i2 - 2, i2 - 2))
                    local b = string.byte(str:sub(i2 - 1, i2 - 1))
                    local a = string.byte(str:sub(i2, i2))

                    -- Apply cel and layer opacity to pixel alpha
                    local celOpacity = cel.opacity / 255
                    local layerOpacity = layer.opacity / 255
                    local finalAlpha = (a / 255) * celOpacity * layerOpacity

                    local x = (i - 1) % cel.width + (frameIndex - 1) * sprite.width + cel.x
                    local y = math.floor((i - 1) / cel.width) + cel.y

                    if finalAlpha > 0 and x >= 0 and x < w and y >= 0 and y < h then
                        blendPixel(spriteData, x, y, r / 255, g / 255, b / 255, finalAlpha)
                    end
                end
            end
        end
    elseif cel.celType == CelTypes.tilemap then
        cel.tileWidth = read_fn(openFile, 2)
        cel.tileHeight = read_fn(openFile, 2)
        cel.bitsPerTile = read_fn(openFile, 2)
        cel.bitMask = read_fn(openFile, 4)
        cel.bitMaskFlpx = read_fn(openFile, 4)
        cel.bitMaskFlpy = read_fn(openFile, 4)
        cel.bitMaskFlpd = read_fn(openFile, 4)
        openFile:read(10)
    end

    return cel
end

---@private
local function getFrame(sprite, openFile, frameIndex, read_fn, readStr_fn)
    local frame = {
        tags = {},
        duration = 0 -- Duration in milliseconds
    }

    local length = read_fn(openFile, 4)
    local magicNumber = read_fn(openFile, 2)
    local chunksOld = read_fn(openFile, 2)
    frame.duration = read_fn(openFile, 2)
    read_fn(openFile, 2)
    local chunks = math.max(chunksOld, read_fn(openFile, 4))

    local lastCel
    local lastData
    local lastSpriteData

    for i = 1, chunks do
        local chunkLength = read_fn(openFile, 4)
        local chunkType = read_fn(openFile, 2)

        if chunkType == ChunkTypes.layer then
            local tags = read_fn(openFile, 2)

            local layer = {
                layerType = read_fn(openFile, 2),
                childLevel = read_fn(openFile, 2),
                read_fn(openFile, 4),
                blendMode = read_fn(openFile, 2),
                opacity = readByte(openFile),
                cels = {}
            }
            openFile:read(3)

            if tags >= 64 then layer.ref, tags = true, tags - 64 end
            if tags >= 32 then layer.collapsed, tags = true, tags - 32 end
            if tags >= 16 then layer.preferLinked, tags = true, tags - 16 end
            if tags >= 8 then layer.background, tags = true, tags - 8 end
            if tags >= 4 then layer.lock, tags = true, tags - 4 end
            if tags >= 2 then layer.editable, tags = true, tags - 2 end
            if tags >= 1 then layer.visible, tags = true, tags - 1 end

            lastData = layer
            layer.name = readStr_fn(openFile, read_fn(openFile, 2))
            layer.name, layer.indent = string.gsub(layer.name, "%-", "")

            if layer.layerType == 0 then
                if layer.childLevel == 0 then
                    lastSpriteData = nil
                else
                    layer.spriteData = lastSpriteData
                end
            elseif layer.layerType == 1 then
                -- group layer
            elseif layer.layerType == 2 then
                layer.tilesetIndex = read_fn(openFile, 4)
            end

            layer.layerIndex = #sprite.layers
            table.insert(sprite.layers, layer)
        elseif chunkType == ChunkTypes.cel then
            if not sprite.data then
                if sprite.seperate then
                    sprite.data = love.image.newImageData(sprite.width * sprite.frameCount,
                        sprite.height * #sprite.layers)
                else
                    sprite.data = love.image.newImageData(sprite.width * sprite.frameCount, sprite.height)
                end
            end

            local cel = {
                layerIndex = read_fn(openFile, 2) + 1,
                x = unsign(read_fn(openFile, 2)),
                y = unsign(read_fn(openFile, 2)),
                opacity = readByte(openFile),
                celType = read_fn(openFile, 2),
                z = unsign(read_fn(openFile, 2)),
            }
            openFile:read(5)

            lastCel = processCel(sprite, openFile, cel, frameIndex, chunkLength, read_fn, readStr_fn)
            lastData = lastCel
        elseif chunkType == ChunkTypes.cel_info then
            lastCel.flags = read_fn(openFile, 4)
            lastCel.preciseX = tonumber(read_fn(openFile, 2) .. "." .. read_fn(openFile, 2))
            lastCel.preciseY = tonumber(read_fn(openFile, 2) .. "." .. read_fn(openFile, 2))
            lastCel.width2 = tonumber(read_fn(openFile, 2) .. "." .. read_fn(openFile, 2))
            lastCel.height2 = tonumber(read_fn(openFile, 2) .. "." .. read_fn(openFile, 2))
            openFile:read(16)
        elseif chunkType == ChunkTypes.color_profile then
            sprite.colorProfileType = read_fn(openFile, 2)
            sprite.colorProfileFlags = read_fn(openFile, 2)
            sprite.fixedGamma = tonumber(read_fn(openFile, 2) .. "." .. read_fn(openFile, 2))
            openFile:read(8)

            if sprite.colorProfileType == 2 then
                sprite.ICClength = read_fn(openFile, 4)
                openFile:read(chunkLength - 22)
            end
        elseif chunkType == ChunkTypes.frame_tags then
            local tagNumber = read_fn(openFile, 2)
            openFile:read(8)

            for i = 1, tagNumber do
                local tag = {
                    startPos = read_fn(openFile, 2),
                    endPos = read_fn(openFile, 2),
                    direction = openFile:read(1),
                    loops = read_fn(openFile, 2),
                }
                openFile:read(10)
                tag.name = readStr_fn(openFile, read_fn(openFile, 2))
                table.insert(frame.tags, tag)
            end
        elseif chunkType == ChunkTypes.palette then
            local entries = read_fn(openFile, 4)
            local first = read_fn(openFile, 4)
            local last = read_fn(openFile, 4)
            openFile:read(8)

            sprite.palette = {}

            for i = first, last do
                sprite.palette[i] = {
                    flags = read_fn(openFile, 2),
                    r = openFile:read(1),
                    g = openFile:read(1),
                    b = openFile:read(1),
                    a = openFile:read(1),
                }

                if sprite.palette[i].flags == 1 then
                    sprite.palette[i].name = readStr_fn(openFile, read_fn(openFile, 2))
                end
            end

            lastData = sprite.palette
        else
            openFile:read(chunkLength - 6)
        end
    end

    table.insert(sprite.frames, frame)
end

---@param filename string
---@param name string
---@return JM.Aseprite.Sprite?
function Aseprite:load(filename, name)
    local info = love.filesystem.getInfo(filename)

    if not info then
        print("Error: Aseprite file not found: " .. filename)
        return nil
    end

    -- Check cache: if sprite exists and file hasn't been modified, return cached version
    if self.cache[name] and self.timeStamps[name] == info.modtime then
        return self.cache[name]
    end

    local openFile = love.filesystem.newFile(filename)

    openFile:open("r")
    openFile:seek(0)

    -- Read header
    local size = read(openFile, 4)
    local magicNumber = read(openFile, 2)
    local frames = read(openFile, 2)
    local width = read(openFile, 2)
    local height = read(openFile, 2)
    local colorDepth = read(openFile, 2)
    local flags = read(openFile, 4)
    local speed = read(openFile, 2)
    read(openFile, 4)
    read(openFile, 4)

    local transparent = readByte(openFile)
    read(openFile, 3)
    local colorCount = read(openFile, 2)

    local pixelRatio = readByte(openFile)
    local pixelHeight = readByte(openFile)

    local gridX = unsign(read(openFile, 2))
    local gridY = unsign(read(openFile, 2))
    local gridWidth = read(openFile, 2)
    local gridHeight = read(openFile, 2)

    read(openFile, 84)

    -- Create sprite object
    local sprite = Sprite:new {
        frameCount = frames,
        width = width,
        height = height,
        colorDepth = colorDepth,
        path = filename,
    }

    -- Process all frames
    for i = 1, frames do
        getFrame(sprite, openFile, i, read, readStr)
    end

    -- Cache sprite
    self.cache[name] = sprite
    self.timeStamps[name] = info.modtime

    -- Create image from data
    sprite.image = love.graphics.newImage(sprite.data)
    sprite.image:setWrap("repeat", "repeat")

    openFile:close()

    return sprite
end

---@param sprite JM.Aseprite.Sprite
---@return love.Image, table, number, number, number
function Aseprite:getQuads(sprite)
    local image = sprite.image
    local quads = {}
    local quadw = sprite.width
    local quadh = sprite.height
    local rowSize = image:getWidth() / quadw

    for frameIdx = 0, sprite.frameCount - 1 do
        local x = (frameIdx % rowSize) * quadw
        local y = math.floor(frameIdx / rowSize) * quadh
        quads[frameIdx + 1] = love.graphics.newQuad(x, y, quadw, quadh, image:getDimensions())
    end

    sprite.quads = quads
    sprite.quadw = quadw
    sprite.quadh = quadh
    sprite.rowSize = rowSize

    return image, quads, quadw, quadh, rowSize
end

---@param name string
---@return JM.Aseprite.Sprite?
function Aseprite:get(name)
    return self.cache[name]
end

---@param name string
---@return boolean
function Aseprite:has(name)
    return self.cache[name] ~= nil
end

---@param name string
function Aseprite:unload(name)
    local sprite = self.cache[name]
    if sprite then
        if sprite.image then
            sprite.image:release()
        end
        if sprite.data then
            sprite.data = nil
        end
        self.cache[name] = nil
        self.timeStamps[name] = nil
    end
end

function Aseprite:clear()
    for name, _ in pairs(self.cache) do
        self:unload(name)
    end
end

return Aseprite
