local love_set_color = love.graphics.setColor
local love_draw = love.graphics.draw
local love_file_load = love.filesystem.load
local math_floor, math_min, math_max = math.floor, math.min, math.max

local MAX_COLUMN = 9999

--- -- @alias JM.TileMap.Cell {x:number, y:number, id:number}
-- ---@alias JM.TileMap.Cell number

---@type JM.TileSet
local TileSet = require((...):gsub("tile_map", "tile_set"))

local function clamp(value, A, B)
    return math_min(math_max(value, A), B)
end

local function round(x)
    local f = math_floor(x + 0.5)
    if (x == f) or (x % 2.0 == 0.5) then
        return f
    else
        return math_floor(x + 0.5)
    end
end

local filter_default = function(x, y, id, ...)
    return true
end

---@param self JM.TileMap
local function get_index(self, x, y)
    local r = (y / self.tile_size) * MAX_COLUMN + (x / self.tile_size)
    return r
    -- return string_format("%d:%d", x, y)
end

---@param self JM.TileMap
local function index_to_x_y(self, index)
    local x = index % MAX_COLUMN
    local y = math_floor(index / MAX_COLUMN)
    return x * self.tile_size, y * self.tile_size
end

--==========================================================================
-- Entry x - y - id

---@class JM.TileMap
local TileMap = {}
TileMap.__index = TileMap

---@param path_map string|any
---@param path_tileset string
---@param tile_size number
---@param filter function|nil
---@return JM.TileMap
function TileMap:new(path_map, path_tileset, tile_size, filter, regions, batchmode)
    local obj = setmetatable({}, self)
    TileMap.__constructor__(obj, path_map, path_tileset, tile_size, filter, regions, batchmode)
    return obj
end

---@param path_map string|function
---@param path_tileset string
---@param tile_size number
---@param filter function|nil
function TileMap:__constructor__(path_map, path_tileset, tile_size, filter, regions, batchmode)
    batchmode = batchmode or "dynamic"
    -- self.path = path_map
    self.tile_size = tile_size or 32
    self.tile_set = TileSet:new(path_tileset, self.tile_size)
    self.sprite_batch = love.graphics.newSpriteBatch(self.tile_set.img, nil, batchmode)

    self.__bound_left = -math.huge
    self.__bound_top = -math.huge
    self.__bound_right = math.huge
    self.__bound_bottom = math.huge

    self.last_index_top = nil
    self.last_index_left = nil
    self.last_index_bottom = nil
    self.last_index_right = nil

    self.color = { 1, 1, 1, 1 }

    self.changed = nil

    self:load_map(path_map, filter, regions)
end

---@param filter function|nil
function TileMap:load_map(data, filter, regions, clean_up)
    -- regions = { "desert" }

    self.cells_by_pos = (not clean_up and self.cells_by_pos) or {}
    self.min_x = (not clean_up and self.min_x) or math.huge
    self.min_y = (not clean_up and self.min_y) or math.huge
    self.max_x = (not clean_up and self.max_x) or -math.huge
    self.max_y = (not clean_up and self.max_y) or -math.huge
    -- self.n_cells = 0

    local Entry = function(x, y, id, ...)
        local filter_ = filter or filter_default

        if ((...) and filter_(x, y, id, unpack { ... }))
            or filter_(x, y, id)
        then
            --
            -- self.n_cells = self.n_cells + 1

            -- self.cells_by_pos[y] = self.cells_by_pos[y] or {}
            -- self.cells_by_pos[y][x] = id

            self.cells_by_pos[get_index(self, x, y)] = id

            self.min_x = x < self.min_x and x or self.min_x
            self.min_y = y < self.min_y and y or self.min_y

            self.max_x = x > self.max_x and x or self.max_x
            self.max_y = y > self.max_y and y or self.max_y
        end
    end

    local Region = function(id)
        if type(regions) == "table" then
            for i = 1, #regions do
                if regions[i] == id then return true end
            end
        else
            return not regions or regions == id
        end
    end

    local data = type(data) == "string" and love_file_load(data)
        or data

    local func = setfenv(data, {
        Entry = Entry,
        Region = Region,
        tile_size = self.tile_size,
        tile = self.tile_size,
        _G = _G
    })

    func()
    -- data()
end

function TileMap:get_index(x, y)
    return get_index(self, x, y)
end

---@param index number
---@return number x
---@return number y
function TileMap:index_to_x_y(index)
    return index_to_x_y(self, index)
end

function TileMap:fix_position(x, y)
    local tile = self.tile_size
    x = math_floor(x / tile) * tile
    y = math_floor(y / tile) * tile
    return x, y
end

function TileMap:get_id_by_img_position(x, y)
    local tile = self.tile_set:get_tile_by_pos(x, y)
    return tile and tile.id
end

function TileMap:insert_tile(x, y, id)
    x, y = self:fix_position(x, y)

    self.cells_by_pos[get_index(self, x, y)] = id

    self:refresh_min_max(x, y)

    self.last_index_top = nil
    self.__bound_left = nil
end

function TileMap:remove_tile(x, y)
    x, y = self:fix_position(x, y)

    if not self.cells_by_pos[get_index(self, x, y)] then return end

    self.cells_by_pos[get_index(self, x, y)] = nil

    if x == self.min_x then
        local min_x = math.huge

        for j = self.min_y, self.max_y, self.tile_size do
            for i = self.min_x, self.max_x, self.tile_size do
                local id = self.cells_by_pos[get_index(self, i, j)]

                if id and i < min_x then
                    min_x = i
                    break
                end

                if i > min_x then
                    break
                end
            end
        end

        self.min_x = min_x
    end

    if x == self.max_x then
        local max_x = -math.huge

        for j = self.min_y, self.max_y, self.tile_size do
            for i = self.max_x, self.min_x, -self.tile_size do
                local id = self.cells_by_pos[get_index(self, i, j)]

                if id and i > max_x then
                    max_x = i
                    break
                end

                if i < max_x then
                    break
                end
            end
        end

        self.max_x = max_x
    end

    if y == self.min_y then
        local min_y = math.huge

        for i = self.min_x, self.max_x, self.tile_size do
            for j = self.min_y, self.max_y, self.tile_size do
                local id = self.cells_by_pos[get_index(self, i, j)]

                if id and j < min_y then
                    min_y = j
                    break
                end

                if j > min_y then
                    break
                end
            end
        end

        self.min_y = min_y
    end

    if y == self.max_y then
        local max_y = -math.huge

        for i = self.min_x, self.max_x, self.tile_size do
            for j = self.max_y, self.min_y, -self.tile_size do
                local id = self.cells_by_pos[get_index(self, i, j)]

                if id and j > max_y then
                    max_y = j
                    break
                end

                if j < max_y then
                    break
                end
            end
        end

        self.max_y = max_y
    end

    self.last_index_top = nil
    self.__bound_left = nil
end

function TileMap:refresh_min_max(x, y)
    self.min_x = x < self.min_x and x or self.min_x
    self.min_y = y < self.min_y and y or self.min_y

    self.max_x = x > self.max_x and x or self.max_x
    self.max_y = y > self.max_y and y or self.max_y
end

function TileMap:clear()
    -- self.cells_by_pos = {}
    for i, v in pairs(self.cells_by_pos) do
        self.cells_by_pos[i] = nil
    end

    self.min_x = math.huge
    self.min_y = self.min_x
    self.max_x = -self.min_x
    self.max_y = -self.min_x
end

function TileMap:get_id(x, y)
    return self.cells_by_pos[get_index(self, x, y)]
end

function TileMap:reset_spritebatch()
    self.__bound_left = nil
    self.last_index_top = nil
end

function TileMap:update(dt)
    self.tile_set:update(dt)
end

---@param self JM.TileMap
---@param batch love.SpriteBatch
local function draw_spritebatch(self, batch)
    if batch:getCount() == 0 then
        return
    end
    self.changed = false
    love_set_color(self.color)
    return love_draw(batch)
end

---@param self JM.TileMap
local function draw_with_bounds(self, left, top, right, bottom)
    self.__bound_left = left
    self.__bound_top = top
    self.__bound_right = right
    self.__bound_bottom = bottom

    local tile_size = self.tile_size

    top = math_floor(top / tile_size) * tile_size
    top = clamp(top, self.min_y, top)

    left = math_floor(left / tile_size) * tile_size
    left = clamp(left, self.min_x, left)

    right = math_floor(right / tile_size) * tile_size
    right = clamp(right, self.min_x, right)

    bottom = math_floor(bottom / tile_size) * tile_size
    bottom = clamp(bottom, self.min_y, bottom)

    -- if left > self.max_x or right < self.min_x
    --     or top > self.max_y or bottom < self.min_y
    -- then
    --     if self.sprite_batch:getCount() > 0 then
    --         self.sprite_batch:clear()
    --     end
    --     self.changed = false
    --     return
    -- end

    if top == self.last_index_top and left == self.last_index_left
        and right == self.last_index_right
        and bottom == self.last_index_bottom
        and not self.tile_set:frame_changed()
    then
        -- love_set_color(self.color)
        -- love_draw(self.sprite_batch)
        -- self.changed = false
        -- return
        return draw_spritebatch(self, self.sprite_batch)
    end

    self.changed = true

    self.last_index_left = left
    self.last_index_top = top
    self.last_index_bottom = bottom
    self.last_index_right = right

    local batch = self.sprite_batch
    batch:clear()

    if left > self.max_x or top > self.max_y
        or bottom < self.min_y or right < self.min_x
    then
        return
    end

    local tile_set = self.tile_set
    local cells_by_pos = self.cells_by_pos
    local get_tile = tile_set.get_tile

    for j = top, bottom, tile_size do
        --
        local y = j / tile_size

        for i = left, right, tile_size do
            --
            local x = i / tile_size

            local index = y * MAX_COLUMN + x

            local cell = cells_by_pos[index]

            if cell then
                -- local tile = tile_set:get_tile(cell)
                local tile = get_tile(tile_set, cell)

                if tile then
                    batch:add(tile.quad, i, j)
                end
            end
        end
        --
    end
    batch:flush()

    -- love_set_color(self.color)
    -- return love_draw(batch)
    return draw_spritebatch(self, batch)
end

---@param tileset JM.TileSet
function TileMap:change_tileset(tileset)
    if not tileset or tileset.img == self.sprite_batch:getTexture()
    then
        return false
    end

    self.sprite_batch:setTexture(tileset.img)
    self:reset_spritebatch()
    return true
end

---@param img love.Image
function TileMap:change_img(img)
    if not img or img == self.sprite_batch:getTexture() then return false end
    self.sprite_batch:setTexture(img)
    self:reset_spritebatch()
    return true
end

---@param self JM.TileMap
local function bounds_changed(self, left, top, right, bottom)
    return left ~= self.__bound_left
        or top ~= self.__bound_top
        or right ~= self.__bound_right
        or bottom ~= self.__bound_bottom
end

---@param camera JM.Camera.Camera|nil
function TileMap:draw(camera, factor_x, factor_y)
    if camera then
        -- local x, y, w, h = camera:get_viewport_in_world_coord()
        -- x = x + (factor_x and round(x * factor_x) or 0)
        -- y = y + (factor_y and round(y * factor_y) or 0)
        -- local right, bottom = x + w, y + h
        -- -- x, y = x + 16, y + 16
        -- -- right, bottom = right - 16, bottom - 16

        local x, y, w, h = camera:get_drawing_viewport()
        x = x + (factor_x and round(x * factor_x) or 0)
        y = y + (factor_y and round(y * factor_y) or 0)
        local right = x + w
        local bottom = y + h
        -- x, y = x + 16, y + 16
        -- right, bottom = right - 16, bottom - 16

        if bounds_changed(self, x, y, right, bottom)
            or self.tile_set:frame_changed()
        then
            draw_with_bounds(self, x, y, right, bottom)
            --
        else
            -- love_set_color(self.color)
            -- love_draw(self.sprite_batch)
            -- self.changed = false
            return draw_spritebatch(self, self.sprite_batch)
        end
    end
end

function TileMap:draw_with_bounds(left, top, right, bottom)
    if bounds_changed(self, left, top, right, bottom)
        or self.tile_set:frame_changed()
    then
        return draw_with_bounds(self, left, top, right, bottom)
    else
        -- love_set_color(self.color)
        -- love_draw(self.sprite_batch)
        -- self.changed = false
        return draw_spritebatch(self, self.sprite_batch)
    end
end

return TileMap
