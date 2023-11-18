---@type JM.Tile
local Tile = require((...):gsub("tile_set", "tile"))

---@param self JM.TileSet
---@param img_data love.ImageData
---@param x number
---@param y number
local function check_empty(self, img_data, x, y)
    local acumulator = 0
    for i = x, x + self.tile_size - 1 do
        for j = y, y + self.tile_size - 1 do
            local r, g, b, a = img_data:getPixel(i, j)
            if a == 0 then
                acumulator = acumulator + 1
            else
                return false
            end
        end
    end

    return acumulator >= self.tile_size ^ 2
end

---@param self JM.TileSet
---@param img_data love.ImageData
local function load_tiles(self, img_data)
    local img_width, img_height = self.img:getDimensions()

    local qx = math.floor(img_width / self.tile_size)
    local qy = math.floor(img_height / self.tile_size)
    local current_id = 1

    for j = 1, qy do
        for i = 1, qx do
            local is_empty = check_empty(self, img_data,
                (i - 1) * self.tile_size,
                (j - 1) * self.tile_size
            )

            if not is_empty then
                local tile = Tile:new(
                    (current_id),
                    self.img,
                    self.tile_size * (i - 1),
                    self.tile_size * (j - 1),
                    self.tile_size
                )

                table.insert(self.tiles, tile)
                self.id_to_tile[tile.id] = tile

                local index = string.format("%d:%d", self.tile_size * qx, self.tile_size * qy)
                self.pos_to_tile[index] = tile

                current_id = current_id + 1
            end
        end
    end
    -- img_data:release()
end
--===================================================================
local pairs = pairs

---@class JM.TileSet
local TileSet = {}
TileSet.__index = TileSet

local tilesets = setmetatable({}, { __mode = 'v' })

---@param tile_size number|nil
---@return JM.TileSet
function TileSet:new(path, tile_size)
    --
    local result = tilesets[path]
    if result then return result end

    local obj = setmetatable({}, self)
    TileSet.__constructor__(obj, path, tile_size)

    tilesets[path] = obj
    return obj
end

---@param path string
---@param tile_size number|nil
function TileSet:__constructor__(path, tile_size)
    local img_data = love.image.newImageData(path)
    self.img = love.graphics.newImage(img_data)

    self.tile_size = tile_size or 32
    self.tiles = {}
    self.id_to_tile = {}
    self.pos_to_tile = {}

    load_tiles(self, img_data)
    img_data:release()
end

function TileSet:add_animated_tile(id, frames, speed)
    if self.id_to_tile[id] then return false end

    self.animated = self.animated or {}

    self.animated[id] = {
        frames = frames,
        speed = speed,
        time = 0,
        cur = 1,
        n = #frames
    }

    self.id_to_tile[id] = self:get_tile(frames[1])

    return true
end

---@return JM.Tile
function TileSet:get_tile_by_pos(x, y)
    x = x or 0
    y = y or 0
    x = math.floor(x / self.tile_size)
    y = math.floor(y / self.tile_size)
    return self.pos_to_tile[string.format("%d:%d", x, y)]
end

function TileSet:tile_is_animated(id)
    return self.animated and self.animated[id]
end

function TileSet:frame_changed()
    return self.__frame_changed
end

function TileSet:update(dt)
    if self.animated then
        self.__frame_changed = false

        for id, tile in pairs(self.animated) do
            tile.time = tile.time + dt

            if tile.time >= tile.speed then
                tile.time = tile.time - tile.speed
                tile.time = tile.time >= tile.speed and 0 or tile.time

                tile.cur = tile.cur + 1
                tile.cur = tile.cur > tile.n and 1 or tile.cur

                self.id_to_tile[id] = self:get_tile(tile.frames[tile.cur])

                self.__frame_changed = true
            end
        end -- END For tiles in list
    end     -- END IF has animated tiles
end

---@param id number
---@return JM.Tile
function TileSet:get_tile(id)
    return self.id_to_tile[id]
end

return TileSet
