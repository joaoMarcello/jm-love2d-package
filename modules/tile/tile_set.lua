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

    local qx = math.floor(self.img_width / self.tile_size)
    local qy = math.floor(self.img_height / self.tile_size)
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

                current_id = current_id + 1
            end
        end
    end
    -- img_data:release()
end

---@class JM.TileSet
local TileSet = {}
TileSet.__index = TileSet

---@param tile_size number|nil
---@return JM.TileSet
function TileSet:new(path, tile_size)
    local obj = setmetatable({}, self)
    TileSet.__constructor__(obj, path, tile_size)
    return obj
end

---@param path string
---@param tile_size number|nil
function TileSet:__constructor__(path, tile_size)
    local img_data = love.image.newImageData(path)
    self.img = love.graphics.newImage(img_data)

    self.tile_size = tile_size or 32
    self.img_width, self.img_height = self.img:getDimensions()
    self.tiles = {}
    self.id_to_tile = {}

    load_tiles(self, img_data)
    img_data:release()
end

---@param id number
---@return JM.Tile
function TileSet:get_tile(id)
    return self.id_to_tile[id]
end

return TileSet
