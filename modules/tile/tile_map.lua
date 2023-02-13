local love_set_color = love.graphics.setColor
local love_draw = love.graphics.draw
local math_floor, math_min, math_max = math.floor, math.min, math.max

local Font = _G.JM_Font

---@alias JM.TileMap.Cell {x:number, y:number, id:number}

---@type JM.TileSet
local TileSet = require((...):gsub("tile_map", "tile_set"))

local function clamp(value, A, B)
    return math_min(math_max(value, A), B)
end

--==========================================================================

---@class JM.TileMap
local TileMap = {}
TileMap.__index = TileMap

---@param path_map string
---@param path_tileset string
---@param tile_size number
---@param filter function|nil
---@return JM.TileMap
function TileMap:new(path_map, path_tileset, tile_size, filter, regions)
    local obj = setmetatable({}, self)
    TileMap.__constructor__(obj, path_map, path_tileset, tile_size, filter, regions)
    return obj
end

---@param path_map string
---@param path_tileset string
---@param tile_size number
---@param filter function|nil
function TileMap:__constructor__(path_map, path_tileset, tile_size, filter, regions)
    self.path = path_map
    self.tile_size = tile_size or 32
    self.tile_set = TileSet:new(path_tileset, self.tile_size)
    self.sprite_batch = love.graphics.newSpriteBatch(self.tile_set.img)

    self:load_map(filter, regions)

    self.__bound_left = -math.huge
    self.__bound_top = -math.huge
    self.__bound_right = math.huge
    self.__bound_bottom = math.huge
end

---@param filter function|nil
function TileMap:load_map(filter, regions, keep)

    JM_Map_Cells = keep and self.cells_by_pos or nil
    JM_Map_Filter = filter
    JM_World_Region = regions --or { "desert" }
    local data = dofile(self.path)

    -- will store the cells indexed by cell position
    self.cells_by_pos = data.cells

    self.min_x = data.min_x
    self.min_y = data.min_y
    self.max_x = data.max_x
    self.max_y = data.max_y
    self.n_cells = data.n_cells
end

---@param self JM.TileMap
local function draw_with_bounds(self, left, top, right, bottom)

    self.__bound_left = left
    self.__bound_top = top
    self.__bound_right = right
    self.__bound_bottom = bottom

    self.sprite_batch:clear()

    top = math_floor(top / self.tile_size) * self.tile_size
    top = clamp(top, self.min_y, top)

    left = math_floor(left / self.tile_size) * self.tile_size
    left = clamp(left, self.min_x, left)

    for j = top, bottom, self.tile_size do

        if left > self.max_x or top > self.max_y then goto end_function end

        for i = left, right, self.tile_size do

            ---@type JM.TileMap.Cell
            local cell = self.cells_by_pos[j] and self.cells_by_pos[j][i]

            if cell then

                local tile = self.tile_set:get_tile(cell.id)

                if tile then
                    self.sprite_batch:add(tile.quad, cell.x, cell.y)
                end
            end

        end

    end


    love_set_color(1, 1, 1, 1)
    love_draw(self.sprite_batch)

    ::end_function::
    -- Font:print("" .. (self.n_cells), 32 * 15, 32 * 8)
end

-- ---@param self JM.TileMap
-- local function draw_without_bounds(self)
--     self.sprite_batch:clear()

--     for i = 1, #(self.map) do

--         ---@type JM.TileMap.Cell
--         local cell = self.map[i]

--         local tile = self.tile_set:get_tile(cell.id)

--         if tile then
--             self.sprite_batch:add(tile.quad, cell.x, cell.y)
--         end
--     end

--     love_set_color(1, 1, 1, 1)
--     love_draw(self.sprite_batch)
-- end

---@param self JM.TileMap
local function bounds_changed(self, left, top, right, bottom)
    return left ~= self.__bound_left
        or top ~= self.__bound_top
        or right ~= self.__bound_right
        or bottom ~= self.__bound_bottom
end

---@param camera JM.Camera.Camera|nil
function TileMap:draw(camera)

    if camera then

        local x, y, w, h = camera:get_viewport_in_world_coord()
        local right, bottom = x + w, y + h

        x, y = x + 32, y + 32
        right, bottom = right - 32, bottom - 32

        if bounds_changed(self, x, y, right, bottom) then
            draw_with_bounds(self, x, y, right, bottom)
        else
            love_set_color(1, 1, 1, 1)
            love_draw(self.sprite_batch)
        end
    else
        --draw_without_bounds(self)
    end
end

function TileMap:draw_with_bounds(left, top, right, bottom)
    return draw_with_bounds(self, left, top, right, bottom)
end

return TileMap
