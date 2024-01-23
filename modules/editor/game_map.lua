local dir = ...
local GC = _G.JM.GameObject
local Phys = _G.JM.Physics

---@type JM.MapLayer
local Layer = require(string.gsub(dir, "game_map", "map_layer"))

---@type JM.MapPiece
local Piece = require(string.gsub(dir, "game_map", "map_piece"))

--===========================================================================

local pieces = {}
local pieces_order = {}
do
    pieces["block-1x1"] = Piece:new {
        tiles = { { 1 } },
    }
    table.insert(pieces_order, pieces["block-1x1"])

    pieces["slope-1x1"] = Piece:new {
        tiles = { { 2 } },
    }
    table.insert(pieces_order, pieces["slope-1x1"])

    pieces["slope-1x1-inv"] = Piece:new {
        tiles = { { 5 } },
    }
    table.insert(pieces_order, pieces["slope-1x1-inv"])

    pieces["slope-2x1"] = Piece:new {
        tiles = { { 3, 4 } },
    }
    table.insert(pieces_order, pieces["slope-2x1"])

    pieces["slope-2x1-inv"] = Piece:new {
        tiles = { { 6, 7 } },
    }
    table.insert(pieces_order, pieces["slope-2x1-inv"])

    pieces["slope-3x1"] = Piece:new {
        tiles = { { 9, 10, 11 } },
    }
    table.insert(pieces_order, pieces["slope-3x1"])

    pieces["slope-3x1-inv"] = Piece:new {
        tiles = { { 12, 13, 14 } },
    }
    table.insert(pieces_order, pieces["slope-3x1-inv"])

    pieces["slope-4x1"] = Piece:new {
        tiles = { { 15, 16, 17, 18 } },
    }
    table.insert(pieces_order, pieces["slope-4x1"])

    pieces["slope-4x1-inv"] = Piece:new {
        tiles = { { 19, 20, 21, 22 } },
    }
    table.insert(pieces_order, pieces["slope-4x1-inv"])

    pieces["ceil-1x1-inv"] = Piece:new {
        tiles = { { 23 } },
    }
    table.insert(pieces_order, pieces["ceil-1x1-inv"])

    pieces["ceil-1x1"] = Piece:new {
        tiles = { { 26 } },
    }
    table.insert(pieces_order, pieces["ceil-1x1"])

    pieces["ceil-2x1-inv"] = Piece:new {
        tiles = { { 24, 25 } },
    }
    table.insert(pieces_order, pieces["ceil-2x1-inv"])

    pieces["ceil-2x1"] = Piece:new {
        tiles = { { 27, 28 } },
    }
    table.insert(pieces_order, pieces["ceil-2x1"])

    pieces["ceil-3x1-inv"] = Piece:new {
        tiles = { { 29, 30, 31 } },
    }
    table.insert(pieces_order, pieces["ceil-3x1-inv"])

    pieces["ceil-3x1"] = Piece:new {
        tiles = { { 32, 33, 34 } },
    }
    table.insert(pieces_order, pieces["ceil-3x1"])

    pieces["ceil-4x1-inv"] = Piece:new {
        tiles = { { 35, 36, 37, 38 } },
    }
    table.insert(pieces_order, pieces["ceil-4x1-inv"])

    pieces["ceil-4x1"] = Piece:new {
        tiles = { { 39, 40, 41, 42 } },
    }
    table.insert(pieces_order, pieces["ceil-4x1"])
end
--========================================================================

local tile_size = 16

local map_count = 1

---@enum JM.GameMap.Tools
local Tools = {
    add_tile = 1,
    erase_tile = 2,
    move_map = 3,
}

local tool_actions = {
    ---@param self JM.GameMap
    [Tools.add_tile] = function(self, dt)
        ----
        self.cur_piece:update(dt)
        local mouse_is_on_view = self:mouse_is_on_view()

        if mouse_is_on_view then
            if love.mouse.isDown(1) then
                self.cur_piece:insert()
                ---
            elseif love.mouse.isDown(2) then
                self.cur_piece:remove()
            end
        end
    end,
    --
    --
    ---@param self JM.GameMap
    [Tools.move_map] = function(self, dt)

    end
}

---@class JM.GameMap : GameObject
local Map = setmetatable({
    MapCount = map_count,
    MapLayer = Layer,
    Piece = Piece,
    Tools = Tools,
    pieces = pieces,
    pieces_order = pieces_order,
    tile_size = tile_size,
}, GC)
Map.__index = Map

function Map:init_module(tilesize, mapCount)
    tile_size = tilesize or tile_size
    map_count = mapCount or map_count
    Layer:init_module(nil, tile_size)
end

---@overload fun(self:any, scene:JM.Scene)
---@param args table
---@return JM.GameMap
function Map:new(args)
    local obj = GC:new(0, 0, love.graphics:getDimensions())
    setmetatable(obj, self)

    if args and args.__is_scene then
        args = { scene = args }
    end

    Map.__constructor__(obj, args or {})
    return obj
end

function Map:__constructor__(args)
    self:set_gamestate(args.scene)

    self.cur_piece_index = 1
    ---@type JM.MapPiece
    self.cur_piece = self.pieces_order[1]

    self:init(args)

    self.state = nil
    self:set_state(Tools.move_map)

    --
    self.update_debug = Map.update_debug
    self.debbug_draw = Map.debbug_draw
end

function Map:load()
    Layer:load()
end

---@param camera JM.Camera.Camera
function Map:set_camera(camera)
    self.camera = camera
end

function Map:init(data, world_config)
    self.name = data.name or string.format("level_%03d", map_count)
    map_count = map_count + 1

    self.layers = {}
    Layer:init_module(self)

    if data.layers then
        for i = 1, #data.layers do
            table.insert(self.layers, Layer:new(data.layers[i]))
        end
    else
        table.insert(self.layers, Layer:new())
    end

    self.cur_layer_index = 0
    self:change_layer(1)

    self.show_world = false

    self.list_world = {}

    for i = 1, (data.n_worlds or 1) do
        local config = world_config and world_config[i] or { tile = tile_size }
        self.list_world[i] = Phys:newWorld(config)
    end

    ---@type JM.Physics.World
    self.world = self.list_world[1]
end

---@param state JM.Scene
function Map:set_gamestate(state)
    self.gamestate = state
end

function Map:get_save_data()
    local data = {
        layers = {},
        name = self.name,
        n_worlds = #self.list_world,
    }

    for i = 1, #self.layers do
        ---@type JM.MapLayer
        local layer = self.layers[i]
        table.insert(data.layers, layer:get_save_data())
    end

    return data
end

---@param layer JM.MapLayer
function Map:apply_autotile_rules(id, i, j, layer)
    local block = self.pieces["block-1x1"].tiles[1][1]
    local slope_1x1 = self.pieces["slope-1x1"].tiles[1][1]
    local slope_1x1_inv = self.pieces["slope-1x1-inv"].tiles[1][1]
    local slope_2x1 = self.pieces["slope-2x1"].tiles[1][1]
    local slope_2x1_inv = self.pieces["slope-2x1-inv"].tiles[1][1]
    local slope_3x1 = self.pieces["slope-3x1"].tiles[1][1]
    local slope_3x1_inv = self.pieces["slope-3x1-inv"].tiles[1][1]
    local slope_4x1 = self.pieces["slope-4x1"].tiles[1][1]
    local slope_4x1_inv = self.pieces["slope-4x1-inv"].tiles[1][1]
    local ceil_1x1 = self.pieces["ceil-1x1"].tiles[1][1]
    local ceil_1x1_inv = self.pieces["ceil-1x1-inv"].tiles[1][1]
    local ceil_2x1 = self.pieces["ceil-2x1"].tiles[1][1]
    local ceil_2x1_inv = self.pieces["ceil-2x1-inv"].tiles[1][1]
    local ceil_3x1 = self.pieces["ceil-3x1"].tiles[1][1]
    local ceil_3x1_inv = self.pieces["ceil-3x1-inv"].tiles[1][1]
    local ceil_4x1 = self.pieces["ceil-4x1"].tiles[1][1]
    local ceil_4x1_inv = self.pieces["ceil-4x1-inv"].tiles[1][1]

    local left = layer:tile_left(i, j)
    local right = layer:tile_right(i, j)
    local bottom = layer:tile_bottom(i, j)
    local top = layer:tile_top(i, j)
    local top_left = layer:tile_top_left(i, j)
    local top_right = layer:tile_top_right(i, j)
    local bottom_left = layer:tile_bottom_left(i, j)
    local bottom_right = layer:tile_bottom_right(i, j)

    local output = layer.out_tilemap

    local tile = layer.out_tilemap.tile_size

    local id_by_position = function(x, y)
        return output:get_id_by_img_position(x, y)
    end

    if id == block and not bottom
        and not left
        and not right
        and not top
    then
        output:insert_tile(i, j, id_by_position(16, 16))
    end

    if id == block
        and right
        and not top
        and not left
        and bottom == block
    then
        output:insert_tile(i, j, id_by_position(57, 23))
    end

    if id == block and not right
        and left
        and not top
        and bottom == block
    then
        output:insert_tile(i, j, id_by_position(105, 24))
    end

    if id == block and not top
        and bottom == block
        and left
        and right
    then
        local prev = output:get_id(i - tile, j)
        local id = id_by_position(72, 24)

        if not prev or prev ~= id then
            output:insert_tile(i, j, id) --3
        else
            output:insert_tile(i, j, id_by_position(89, 23))
        end
    end

    if id == block and
        not left
        and right == block
        and bottom == block
        and top == block
        and (not top_left or top_left == block)
    then
        local prev = output:get_id(i, j - tile)

        if not prev or prev ~= 6 then
            output:insert_tile(i, j, 6)
        else
            output:insert_tile(i, j, 10)
        end
    end

    if id == block
        and not right
        and left == block
        and bottom == block
        and top == block
        and (not top_right or top_right == block)
    then
        local prev = output:get_id(i, j - tile)

        if not prev or prev ~= 9 then
            output:insert_tile(i, j, 9)
        else
            output:insert_tile(i, j, 13)
        end
    end

    if id == block
        and top == block
        and bottom == block
        and left
        and right
    -- and top_left
    -- and top_right
    -- and bottom_left
    -- and bottom_right
    then
        -- 7 - 8  - 11 - 12

        local prev_up = output:get_id(i, j - tile)
        local prev_left = output:get_id(i - tile, j)

        if prev_up ~= 7 and prev_up ~= 8
        -- and prev_up ~= 11 and prev_up ~= 12
        then
            if prev_left ~= 7 then
                output:insert_tile(i, j, 7)
            else
                output:insert_tile(i, j, 8)
            end
            --
        else
            --
            if prev_left ~= 11 then
                output:insert_tile(i, j, 11)
            else
                output:insert_tile(i, j, 12)
            end
        end
    end

    if id == block
        and not left
        and bottom ~= block
        and right == block
        and top == block
    then
        output:insert_tile(i, j, 14)
    end

    if id == block
        and not right
        and bottom ~= block
        and left == block
        and top == block
    then
        output:insert_tile(i, j, 17)
    end

    if id == block
        and not bottom
        and left
        and right
        and top == block
    then
        local prev = output:get_id(i - tile, j)
        if prev ~= 15 then
            output:insert_tile(i, j, 15)
        else
            output:insert_tile(i, j, 16)
        end
    end

    if id == block
        and left
        and right
        and top == block
        and bottom
        and top_left
        and bottom_left
        and not top_right
    then
        output:insert_tile(i, j, 19)
    end

    if id == block
        and left
        and right
        and bottom
        and top == block
        and top_right
        and bottom_right
        and not top_left
    then
        output:insert_tile(i, j, 18)
    end

    if id == slope_1x1
        and bottom == block
        and (left or bottom_left)
    then
        output:insert_tile(i, j, 20)
        output:insert_tile(i, j + tile, 22)
    end

    if id == slope_1x1_inv
        and bottom == block
        and (right or bottom_right)
    then
        output:insert_tile(i, j, 21)
        output:insert_tile(i, j + tile, 23)
    end

    if id == slope_2x1
        and bottom == block
        and (left or bottom_left)
    then
        output:insert_tile(i, j, 24)
        output:insert_tile(i + tile, j, 25)
        output:insert_tile(i, j + tile, 33)
        output:insert_tile(i + tile, j + tile, 34)
    end

    if id == slope_2x1_inv
        and (layer:tile_bottom(i + tile, j))
        and (layer:tile_bottom_right(i + tile, j)
            or layer:tile_right(i + tile, j))
    then
        output:insert_tile(i, j, 42)
        output:insert_tile(i + tile, j, 43)
        output:insert_tile(i, j + tile, 51)
        output:insert_tile(i + tile, j + tile, 52)
    end

    if id == slope_3x1
        and bottom == block
        and bottom_left
    then
        output:insert_tile(i, j, 26)
        output:insert_tile(i + tile, j, 27)
        output:insert_tile(i + tile + tile, j, 28)
        output:insert_tile(i, j + tile, 35)
        output:insert_tile(i + tile, j + tile, 36)
        output:insert_tile(i + tile + tile, j + tile, 37)
    end

    if id == slope_3x1_inv
        and layer:tile_bottom(i + tile * 2, j)
        and (layer:tile_bottom_right(i + tile * 2, j)
            or layer:tile_right(i + tile * 2, j))
    then
        output:insert_tile(i, j, 44)
        output:insert_tile(i + tile, j, 45)
        output:insert_tile(i + tile + tile, j, 46)
        output:insert_tile(i, j + tile, 53)
        output:insert_tile(i + tile, j + tile, 54)
        output:insert_tile(i + tile + tile, j + tile, 55)
    end

    if id == slope_4x1
        and bottom == block
        and (left or bottom_left)
    then
        output:insert_tile(i, j, 29)
        output:insert_tile(i + tile, j, 30)
        output:insert_tile(i + tile * 2, j, 31)
        output:insert_tile(i + tile * 3, j, 32)
        output:insert_tile(i, j + tile, 38)
        output:insert_tile(i + tile, j + tile, 39)
        output:insert_tile(i + tile * 2, j + tile, 40)
        output:insert_tile(i + tile * 3, j + tile, 41)
    end

    if id == slope_4x1_inv
        and layer:tile_bottom(i + tile * 3, j)
        and (layer:tile_right(i + tile * 3, j)
            or layer:tile_bottom_right(i + tile * 3, j))
    then
        output:insert_tile(i, j, 47)
        output:insert_tile(i + tile, j, 48)
        output:insert_tile(i + tile * 2, j, 49)
        output:insert_tile(i + tile * 3, j, 50)
        output:insert_tile(i, j + tile, 56)
        output:insert_tile(i + tile, j + tile, 57)
        output:insert_tile(i + tile * 2, j + tile, 58)
        output:insert_tile(i + tile * 3, j + tile, 59)
    end

    --borders
    if id == block
        and left == block
        and bottom == block
        and right == block
        and top == block
        and not bottom_right
    then
        output:insert_tile(i, j, 60)
    end

    if id == block
        and left == block
        and bottom == block
        and right == block
        and top == block
        and not bottom_left
    then
        output:insert_tile(i, j, 62)
    end

    -- bottom
    if id == ceil_1x1
        and top_right
    then
        output:insert_tile(i, j, 63)
        output:insert_tile(i, j - tile, 7)

        if bottom_left == block then
            output:insert_tile(i - tile, j + tile, 67)
        end
    end

    if id == ceil_1x1_inv
        and top_left
    then
        output:insert_tile(i, j, 64)
        output:insert_tile(i, j - tile, 7)

        if bottom_right == block then
            output:insert_tile(i + tile, j + tile, 68)
        end
    end

    if id == ceil_2x1
        and layer:tile_top_right(i + tile, j)
    then
        output:insert_tile(i, j, 72)
        output:insert_tile(i, j - tile, 11)
        output:insert_tile(i + tile, j, 73)
        output:insert_tile(i + tile, j - tile, 12)

        if bottom_left == block then
            output:insert_tile(i - tile, j + tile, 67)
        end
    end

    if id == ceil_2x1_inv
        and top_left
    then
        output:insert_tile(i, j, 74)
        output:insert_tile(i, j - tile, 11)
        output:insert_tile(i + tile, j, 75)
        output:insert_tile(i + tile, j - tile, 12)

        if layer:tile_bottom_right(i + tile, j) == block then
            output:insert_tile(i + tile + tile, j + tile, 68)
        end
    end

    if id == ceil_3x1
        and layer:tile_top_right(i + tile * 2, j)
    then
        output:insert_tile(i, j, 76)
        output:insert_tile(i + tile, j, 77)
        output:insert_tile(i + tile * 2, j, 78)
        output:insert_tile(i, j - tile, 7)
        output:insert_tile(i + tile, j - tile, 8)
        output:insert_tile(i + tile * 2, j - tile, 7)

        if bottom_left == block then
            output:insert_tile(i - tile, j + tile, 67)
        end
    end

    if id == ceil_3x1_inv
        and top_left
    then
        output:insert_tile(i, j, 79)
        output:insert_tile(i + tile, j, 80)
        output:insert_tile(i + tile * 2, j, 81)
        output:insert_tile(i, j - tile, 7)
        output:insert_tile(i + tile, j - tile, 8)
        output:insert_tile(i + tile * 2, j - tile, 7)

        if layer:tile_bottom_right(i + tile * 2, j) == block then
            output:insert_tile(i + tile * 3, j + tile, 68)
        end
    end

    if id == ceil_4x1
        and layer:tile_top_right(i + tile * 3, j)
    then
        output:insert_tile(i, j, 82)
        output:insert_tile(i + tile, j, 83)
        output:insert_tile(i + tile * 2, j, 84)
        output:insert_tile(i + tile * 3, j, 85)
        output:insert_tile(i, j - tile, 7)
        output:insert_tile(i + tile, j - tile, 8)
        output:insert_tile(i + tile * 2, j - tile, 7)
        output:insert_tile(i + tile * 3, j - tile, 8)

        if bottom_left == block then
            output:insert_tile(i - tile, j + tile, 67)
        end
    end

    if id == ceil_4x1_inv
        and top_left
    then
        output:insert_tile(i, j, 86)
        output:insert_tile(i + tile, j, 87)
        output:insert_tile(i + tile * 2, j, 88)
        output:insert_tile(i + tile * 3, j, 89)
        output:insert_tile(i, j - tile, 7)
        output:insert_tile(i + tile, j - tile, 8)
        output:insert_tile(i + tile * 2, j - tile, 7)
        output:insert_tile(i + tile * 3, j - tile, 8)

        if layer:tile_bottom_right(i + tile * 3, j) == block then
            output:insert_tile(i + tile * 4, j + tile, 68)
        end
    end

    if id == ceil_1x1_inv
        and not top_left
        and layer:tile_top(i, j - tile)
    then
        output:insert_tile(i, j, 97)
        output:insert_tile(i, j - tile, 91)

        if bottom_right == block then
            output:insert_tile(i + tile, j + tile, 68)
        end
    end

    if id == ceil_1x1
        and not top_right
        and layer:tile_top(i, j - tile)
    then
        output:insert_tile(i, j, 96)
        output:insert_tile(i, j - tile, 90)

        if bottom_left == block then
            output:insert_tile(i - tile, j + tile, 67)
        end
    end

    if id == ceil_2x1
        and not layer:tile_right(i + tile, j - tile)
        and layer:tile_top(i + tile, j - tile)
    then
        output:insert_tile(i, j, 98)
        output:insert_tile(i + tile, j, 99)
        output:insert_tile(i, j - tile, 92)
        output:insert_tile(i + tile, j - tile, 93)
        if bottom_left == block then
            output:insert_tile(i - tile, j + tile, 67)
        end
    end

    if id == ceil_2x1_inv
        and not top_left
        and layer:tile_top(i, j - tile)
    then
        output:insert_tile(i, j, 100)
        output:insert_tile(i + tile, j, 101)
        output:insert_tile(i, j - tile, 94)
        output:insert_tile(i + tile, j - tile, 95)
        if layer:tile_bottom_right(i + tile, j) then
            output:insert_tile(i + tile * 2, j + tile, 68)
        end
    end

    if id == ceil_3x1
        and not layer:tile_right(i + tile * 2, j - tile)
        and layer:tile_top(i + tile * 2, j - tile)
    then
        output:insert_tile(i, j, 112)
        output:insert_tile(i + tile, j, 113)
        output:insert_tile(i + tile * 2, j, 114)
        output:insert_tile(i, j - tile, 102)
        output:insert_tile(i + tile, j - tile, 103)
        output:insert_tile(i + tile * 2, j - tile, 104)
        if bottom_left == block then
            output:insert_tile(i - tile, j + tile, 67)
        end
    end

    if id == ceil_3x1_inv
        and not top_left
        and layer:tile_top(i, j - tile)
    then
        output:insert_tile(i, j, 115)
        output:insert_tile(i + tile, j, 116)
        output:insert_tile(i + tile * 2, j, 117)
        output:insert_tile(i, j - tile, 105)
        output:insert_tile(i + tile, j - tile, 106)
        output:insert_tile(i + tile * 2, j - tile, 107)
        if layer:tile_bottom_right(i + tile * 2, j) == block then
            output:insert_tile(i + tile * 3, j + tile, 68)
        end
    end

    if id == ceil_4x1
        and not layer:tile_right(i + tile * 3, j - tile)
        and layer:tile_top(i + tile * 3, j - tile)
    then
        output:insert_tile(i, j, 118)
        output:insert_tile(i + tile, j, 119)
        output:insert_tile(i + tile * 2, j, 120)
        output:insert_tile(i + tile * 3, j, 121)
        output:insert_tile(i, j - tile, 108)
        output:insert_tile(i + tile, j - tile, 109)
        output:insert_tile(i + tile * 2, j - tile, 110)
        output:insert_tile(i + tile * 3, j - tile, 111)
        if bottom_left == block then
            output:insert_tile(i - tile, j + tile, 67)
        end
    end

    if id == ceil_4x1_inv
        and not top_left
        and layer:tile_top(i, j - tile)
    then
        output:insert_tile(i, j, 126)
        output:insert_tile(i + tile, j, 127)
        output:insert_tile(i + tile * 2, j, 128)
        output:insert_tile(i + tile * 3, j, 129)
        output:insert_tile(i, j - tile, 122)
        output:insert_tile(i + tile, j - tile, 123)
        output:insert_tile(i + tile * 2, j - tile, 124)
        output:insert_tile(i + tile * 3, j - tile, 125)
        if layer:tile_bottom_right(i + tile * 3, j) == block then
            output:insert_tile(i + tile * 4, j + tile, 68)
        end
    end

    if id == ceil_1x1
        and not top_right
        and top == block
        and not layer:tile_top(i, j - tile)
    then
        output:insert_tile(i, j, 139)
        output:insert_tile(i, j - tile, 130)
        if bottom_left == block then
            output:insert_tile(i - tile, j + tile, 67)
        end
    end

    if id == ceil_1x1_inv
        and not top_left
        and top == block
        and not layer:tile_top(i, j - tile)
    then
        output:insert_tile(i, j, 140)
        output:insert_tile(i, j - tile, 131)
        if bottom_right == block then
            output:insert_tile(i + tile, j + tile, 68)
        end
    end

    if id == ceil_2x1
        and not layer:tile_top_right(i + tile, j)
        and layer:tile_top(i + tile, j) == block
        and not layer:tile_top(i + tile, j - tile)
    then
        output:insert_tile(i, j, 141)
        output:insert_tile(i + tile, j, 142)
        output:insert_tile(i, j - tile, 132)
        output:insert_tile(i + tile, j - tile, 133)
        if bottom_left == block then
            output:insert_tile(i - tile, j + tile, 67)
        end
    end

    if id == ceil_2x1_inv
        and not top_left
        and top == block
        and not layer:tile_top(i, j - tile)
    then
        output:insert_tile(i, j, 143)
        output:insert_tile(i + tile, j, 144)
        output:insert_tile(i, j - tile, 134)
        output:insert_tile(i + tile, j - tile, 135)
        if layer:tile_bottom_right(i + tile, j) == block then
            output:insert_tile(i + tile * 2, j + tile, 68)
        end
    end

    if id == ceil_3x1
        and not layer:tile_top_right(i + tile * 2, j)
        and layer:tile_top(i + tile * 2, j) == block
        and not layer:tile_top(i + tile * 2, j - tile)
    then
        output:insert_tile(i, j, 145)
        output:insert_tile(i + tile, j, 146)
        output:insert_tile(i + tile * 2, j, 147)
        output:insert_tile(i, j - tile, 136)
        output:insert_tile(i + tile, j - tile, 137)
        output:insert_tile(i + tile * 2, j - tile, 138)
        if bottom_left == block then
            output:insert_tile(i - tile, j + tile, 67)
        end
    end

    if id == ceil_3x1_inv
        and not top_left
        and top == block
        and not layer:tile_top(i, j - tile)
    then
        output:insert_tile(i, j, 159)
        output:insert_tile(i + tile, j, 160)
        output:insert_tile(i + tile * 2, j, 161)
        output:insert_tile(i, j - tile, 148)
        output:insert_tile(i + tile, j - tile, 149)
        output:insert_tile(i + tile * 2, j - tile, 150)
        if layer:tile_bottom_right(i + tile * 2, j) == block then
            output:insert_tile(i + tile * 3, j + tile, 68)
        end
    end

    if id == ceil_4x1
        and not layer:tile_top_right(i + tile * 3, j)
        and layer:tile_top(i + tile * 3, j) == block
        and not layer:tile_top(i + tile * 3, j - tile)
    then
        output:insert_tile(i, j, 162)
        output:insert_tile(i + tile, j, 163)
        output:insert_tile(i + tile * 2, j, 164)
        output:insert_tile(i + tile * 3, j, 165)
        output:insert_tile(i, j - tile, 151)
        output:insert_tile(i + tile, j - tile, 152)
        output:insert_tile(i + tile * 2, j - tile, 153)
        output:insert_tile(i + tile * 3, j - tile, 154)
        if bottom_left == block then
            output:insert_tile(i - tile, j + tile, 67)
        end
    end

    if id == ceil_4x1_inv
        and not top_left
        and top == block
        and not layer:tile_top(i, j - tile)
    then
        output:insert_tile(i, j, 166)
        output:insert_tile(i + tile, j, 167)
        output:insert_tile(i + tile * 2, j, 168)
        output:insert_tile(i + tile * 3, j, 169)
        output:insert_tile(i, j - tile, 155)
        output:insert_tile(i + tile, j - tile, 156)
        output:insert_tile(i + tile * 2, j - tile, 157)
        output:insert_tile(i + tile * 3, j - tile, 158)
        if layer:tile_bottom_right(i + tile * 3, j) == block then
            output:insert_tile(i + tile * 4, j + tile, 68)
        end
    end

    --one tile
    if id == block
        and not left
        and not bottom
        and not top
        and right == block
    then
        output:insert_tile(i, j, 171)
    end

    if id == block
        and not right
        and not top
        and not bottom
        and left == block
    then
        output:insert_tile(i, j, 174)
    end

    if id == block
        and not top and not bottom
        and left == block and right == block
    then
        if output:get_id(i - tile, j) ~= 172 then
            output:insert_tile(i, j, 172)
        else
            output:insert_tile(i, j, 173)
        end
    end

    if id == block
        and not left and not right
    then
        if not top and bottom == block then
            output:insert_tile(i, j, 170)
            --
        elseif top == block and not bottom then
            output:insert_tile(i, j, 183)
            --
        elseif bottom == block and top == block then
            if output:get_id(i, j - tile) ~= 175 then
                output:insert_tile(i, j, 175)
            else
                output:insert_tile(i, j, 176)
            end
        end
    end

    if id == block
        and left == block and right == block
        and bottom == block
        and (output:get_id(i, j - tile) == 175
            or output:get_id(i, j - tile) == 176)
    then
        output:insert_tile(i, j, 190)
    end

    --border slope
    if id == slope_1x1
        and not bottom_left
        and bottom == block
        and layer:tile_bottom(i, j + tile) == block
    then
        output:insert_tile(i, j, 177)
        output:insert_tile(i, j + tile, 184)
    end

    if id == slope_1x1_inv
        and not bottom_right
        and bottom == block
        and layer:tile_bottom(i, j + tile) == block
    then
        output:insert_tile(i, j, 178)
        output:insert_tile(i, j + tile, 185)
    end

    if id == slope_2x1
        and not bottom_left
        and bottom == block
        and layer:tile_bottom(i, j + tile) == block
    then
        output:insert_tile(i, j, 179)
        output:insert_tile(i + tile, j, 180)
        output:insert_tile(i, j + tile, 186)
        output:insert_tile(i + tile, j + tile, 187)
    end

    if id == slope_2x1_inv
        and not layer:tile_bottom_right(i + tile, j)
        and layer:tile_bottom(i + tile, j)
        and layer:tile_bottom(i + tile, j + tile)
    then
        output:insert_tile(i, j, 181)
        output:insert_tile(i + tile, j, 182)
        output:insert_tile(i, j + tile, 188)
        output:insert_tile(i + tile, j + tile, 189)
    end

    if id == slope_3x1
        and not bottom_left
        and bottom == block
        and layer:tile_bottom(i, j + tile) == block
    then
        output:insert_tile(i, j, 191)
        output:insert_tile(i + tile, j, 192)
        output:insert_tile(i + tile * 2, j, 193)
        output:insert_tile(i, j + tile, 197)
        output:insert_tile(i + tile, j + tile, 198)
        output:insert_tile(i + tile * 2, j + tile, 199)
    end

    if id == slope_3x1_inv
        and not layer:tile_bottom_right(i + tile * 2, j)
        and layer:tile_bottom(i + tile * 2, j)
        and layer:tile_bottom(i + tile * 2, j + tile)
    then
        output:insert_tile(i, j, 194)
        output:insert_tile(i + tile, j, 195)
        output:insert_tile(i + tile * 2, j, 196)
        output:insert_tile(i, j + tile, 200)
        output:insert_tile(i + tile, j + tile, 201)
        output:insert_tile(i + tile * 2, j + tile, 202)
    end

    if id == slope_4x1
        and not bottom_left
        and bottom == block
        and layer:tile_bottom(i, j + tile) == block
    then
        output:insert_tile(i, j, 203)
        output:insert_tile(i + tile, j, 204)
        output:insert_tile(i + tile * 2, j, 205)
        output:insert_tile(i + tile * 3, j, 206)
        output:insert_tile(i, j + tile, 211)
        output:insert_tile(i + tile, j + tile, 212)
        output:insert_tile(i + tile * 2, j + tile, 213)
        output:insert_tile(i + tile * 3, j + tile, 214)
    end

    if id == slope_4x1_inv
        and not layer:tile_bottom_right(i + tile * 3, j)
        and layer:tile_bottom(i + tile * 3, j)
        and layer:tile_bottom(i + tile * 3, j + tile)
    then
        output:insert_tile(i, j, 207)
        output:insert_tile(i + tile, j, 208)
        output:insert_tile(i + tile * 2, j, 209)
        output:insert_tile(i + tile * 3, j, 210)
        output:insert_tile(i, j + tile, 215)
        output:insert_tile(i + tile, j + tile, 216)
        output:insert_tile(i + tile * 2, j + tile, 217)
        output:insert_tile(i + tile * 3, j + tile, 218)
    end

    -- one tile border
    if id == block
        and left ~= block
        and top ~= block
        and not bottom_left
        and not bottom_right
        and right == block
        and bottom == block
    then
        output:insert_tile(i, j, 219)
    end

    if id == block
        and right ~= block
        and top ~= block
        and not bottom_left
        and not bottom_right
        and left == block
        and bottom == block
    then
        output:insert_tile(i, j, 222)
    end

    if id == block
        and left ~= block
        and not top_left
        and not top_right
        and right == block
        and top == block
    then
        if bottom ~= block
        then
            output:insert_tile(i, j, 231)
        else
            output:insert_tile(i, j, 224)
        end
    end

    if id == block
        and right ~= block
        and left == block
        and top == block
        and not top_left
        and not top_right
    then
        if bottom ~= block then
            output:insert_tile(i, j, 234)
        else
            output:insert_tile(i, j, 223)
        end
    end
end

function Map:auto_tile()
    for k = 1, #self.layers do
        ---@type JM.MapLayer
        local layer = self.layers[k]

        local tilemap = layer.tilemap
        local out_map = layer.out_tilemap
        local tile = out_map.tile_size

        out_map:clear()

        for j = tilemap.min_y, tilemap.max_y, tile do
            for i = tilemap.min_x, tilemap.max_x, tile do
                --
                local id = tilemap.cells_by_pos[tilemap:get_index(i, j)]

                if id then
                    self:apply_autotile_rules(id, i, j, layer)
                end
                --
            end
        end

        layer.show_auto_tilemap = true
        out_map:reset_spritebatch()
    end
end

function Map:remove_negative()
    local min_x, min_y = math.huge, math.huge
    local N = #self.layers

    for k = 1, N do
        ---@type JM.MapLayer
        local layer = self.layers[k]

        local minx, _ = layer:get_min_max_x()
        local miny, _ = layer:get_min_max_y()

        min_x = minx < min_x and minx or min_x
        min_y = miny < min_y and miny or min_y
    end

    local dx = -min_x
    local dy = -min_y

    if dx ~= 0 or dy ~= 0 then
        for k = 1, N do
            ---@type JM.MapLayer
            local layer = self.layers[k]
            layer:move(dx, dy)
            layer.show_auto_tilemap = false
        end
    end
end

function Map:build_world()
    local tile = self.cur_layer.out_tilemap.tile_size
    local n_worlds = #self.list_world
    -- local world = self.world
    -- world:clear()
    for i = 1, n_worlds do
        ---@type JM.Physics.World
        local world = self.list_world[i]

        world:clear()
    end

    for k = 1, #self.layers do
        local mapped = {}
        ---@type JM.MapLayer
        local layer = self.layers[k]

        local map = layer.tilemap

        local world = self.list_world[layer.world_number or 1]

        if (layer.type == Layer.Types.static
                or layer.type == Layer.Types.only_fall)
            and world
        then
            for j = map.min_y, map.max_y, tile do
                for i = map.min_x, map.max_x, tile do
                    --
                    local index = map:get_index(i, j)
                    local id = map.cells_by_pos[index]

                    local bd_type = layer.type == Layer.Types.only_fall and "only_fall" or "static"

                    if id == self.pieces["block-1x1"].tiles[1][1]
                        and not mapped[index]
                    then
                        --
                        local w = tile
                        local h = tile

                        for _i_ = i + tile, map.max_x, tile do
                            local _ind_ = map:get_index(_i_, j)
                            local _id_ = map.cells_by_pos[_ind_]

                            if not mapped[_ind_] and _id_ == id then
                                w = w + tile
                            else
                                break
                            end
                        end

                        local min_h = math.huge

                        for _i_ = i, i + w - 1, tile do
                            --
                            local column_h = tile

                            for _j_ = j + tile, map.max_y, tile do
                                --
                                local _ind_ = map:get_index(_i_, _j_)
                                local _id_ = map.cells_by_pos[_ind_]

                                if not mapped[_ind_] and _id_ == id then
                                    column_h = column_h + tile
                                else
                                    break
                                end
                            end

                            if column_h < min_h and column_h ~= 0 then
                                min_h = column_h
                            end
                        end

                        h = min_h

                        for _j_ = j, j + h - 1, tile do
                            for _i_ = i, i + w - 1, tile do
                                local _ind_ = map:get_index(_i_, _j_)
                                mapped[_ind_] = true
                            end
                        end

                        -- if map.cells_by_pos[map:get_index(i + tile, j)] == id then
                        --     w = w + tile
                        --     mapped[map:get_index(i + tile, j)] = true
                        -- end
                        -- mapped[index] = true

                        local tp = layer.type == Layer.Types.static and "static" or "only_fall"

                        Phys:newBody(world, i, j, w, h, tp)
                        --
                        --
                    elseif id == self.pieces["slope-1x1"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile, tile, "floor", "normal", bd_type)
                        --
                    elseif id == self.pieces["slope-1x1-inv"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile, tile, "floor", "inv", bd_type)
                        --
                    elseif id == self.pieces["slope-2x1"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile * 2, tile, "floor", "normal", bd_type)
                        --
                    elseif id == self.pieces["slope-2x1-inv"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile * 2, tile, "floor", "inv", bd_type)
                        --
                    elseif id == self.pieces["slope-3x1"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile * 3, tile, "floor", "normal", bd_type)
                        --
                    elseif id == self.pieces["slope-3x1-inv"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile * 3, tile, "floor", "inv", bd_type)
                        --
                    elseif id == self.pieces["slope-4x1"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile * 4, tile, "floor", "normal", bd_type)
                        --
                    elseif id == self.pieces["slope-4x1-inv"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile * 4, tile, "floor", "inv", bd_type)
                        --
                    elseif id == self.pieces["ceil-1x1"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile, tile, "ceil", "normal", bd_type)
                        --
                    elseif id == self.pieces["ceil-1x1-inv"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile, tile, "ceil", "inv", bd_type)
                        --
                    elseif id == self.pieces["ceil-2x1"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile * 2, tile, "ceil", "normal", bd_type)
                        --
                    elseif id == self.pieces["ceil-2x1-inv"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile * 2, tile, "ceil", "inv", bd_type)
                        --
                    elseif id == self.pieces["ceil-3x1"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile * 3, tile, "ceil", "normal", bd_type)
                        --
                    elseif id == self.pieces["ceil-3x1-inv"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile * 3, tile, "ceil", "inv", bd_type)
                        --
                    elseif id == self.pieces["ceil-4x1"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile * 4, tile, "ceil", "normal", bd_type)
                        --
                    elseif id == self.pieces["ceil-4x1-inv"].tiles[1][1] then
                        Phys:newSlope(world, i, j, tile * 4, tile, "ceil", "inv", bd_type)
                        --
                    end
                end
            end
        end
    end

    for i = 1, n_worlds do
        ---@type JM.Physics.World
        local world = self.list_world[i]
        world:optimize()
        world:optimize()
        world:fix_slope()
        world:fix_adj_bodies()
        -- world:fix_ground_to_slope()
    end

    return self.list_world[1]
end

---@param new_state JM.GameMap.Tools
function Map:set_state(new_state)
    if new_state == self.state then return false end
    self.state = new_state
    self.cur_action = tool_actions[self.state]
    self.cur_piece.is_visible = false

    if new_state == Tools.add_tile then
        self.cur_piece.is_visible = true
        ---
    elseif new_state == Tools.move_map then

    end
    return true
end

function Map:keypressed(key)
    if key == 'a' then
        for i = 1, #self.layers do
            ---@type JM.MapLayer
            local l = self.layers[i]
            l.show_auto_tilemap = false
        end
        self.show_world = false
        return self:set_state(Tools.add_tile)
    elseif key == 'v' then
        return self:set_state(Tools.move_map)
    end

    if self.state == Tools.add_tile then
        if key == 'w' then
            self.cur_piece_index = self.cur_piece_index - 1
            if self.cur_piece_index <= 0 then
                self.cur_piece_index = #self.pieces_order
            end
            self.cur_piece = self.pieces_order[self.cur_piece_index]
            self:fix_piece_position(self.camera)
        elseif key == 's' then
            self.cur_piece_index = self.cur_piece_index + 1
            if self.cur_piece_index > #self.pieces_order then
                self.cur_piece_index = 1
            end
            self.cur_piece = self.pieces_order[self.cur_piece_index]
            self:fix_piece_position(self.camera)
        end
    end

    -- if key == 'f' then
    --     for i = 1, #self.layers do
    --         ---@type JM.MapLayer
    --         local layer = self.layers[i]
    --         layer:fix_map()
    --     end
    --     return
    -- end

    if key == 'g' then
        self.show_world = not self.show_world
        if self.show_world then
            for i = 1, #self.layers do
                ---@type JM.MapLayer
                local l = self.layers[i]
                l.show_auto_tilemap = false
            end
            self:keypressed('v')
            self.show_world = true
            self.world = self:build_world()
            collectgarbage()
        end
        return
    end
end

function Map:new_layer(name, type)
    local layer = Layer:new { name = name, type = type, tile_size = tile_size }
    table.insert(self.layers, layer)
    self:change_layer(#self.layers)
    return layer
end

function Map:change_layer(index)
    local Utils = JM.Utils
    index = Utils:clamp(index, 1, #self.layers)
    -- if index == self.cur_layer_index then return false end

    self.cur_layer_index = index
    self.cur_layer = self.layers[self.cur_layer_index]
    Piece:init_module(self.cur_layer.tilemap)
    return true
end

function Map:prev_layer()
    self.cur_layer_index = self.cur_layer_index - 1
    if self.cur_layer_index <= 0 then
        self.cur_layer_index = #self.layers
    end
    self:change_layer(self.cur_layer_index)
end

function Map:next_layer()
    self.cur_layer_index = self.cur_layer_index + 1
    if self.cur_layer_index > #self.layers then
        self.cur_layer_index = 1
    end
    self:change_layer(self.cur_layer_index)
end

function Map:keyreleased(key)

end

-- function Map:mousepressed(x, y, button, istouch, presses)
--     -- if button == 3 then
--     --     self.camera:toggle_grid()
--     --     self.camera:toggle_world_bounds()
--     -- end
-- end

-- function Map:mousereleased(x, y, button, istouch, presses)

-- end

function Map:fix_piece_position(cam)
    local cam    = self.camera
    local mx, my = self.gamestate:get_mouse_position(cam)

    ---@type JM.MapLayer
    local layer  = self.layers[self.cur_layer_index]
    if layer then
        local cx, cy = cam.x, cam.y
        cam:set_position(cam.x * layer.factor_x, cam.y * layer.factor_y)
        local mx2, my2 = self.gamestate:get_mouse_position(cam)
        cam:set_position(cx, cy)

        mx = mx + (mx2 - mx)
        my = my + (my2 - my)
    end

    self.cell_x      = math.floor(mx / tile_size)
    self.cell_y      = math.floor(my / tile_size)
    self.cur_piece.x = self.cell_x * tile_size
    self.cur_piece.y = self.cell_y * tile_size
end

-- function Map:mousemoved(x, y, dx, dy, istouch)
--     -- local mx, my = self.gamestate:get_mouse_position(self.camera)
--     -- self.camera:set_focus(self.camera:world_to_screen(mx, my))

--     -- if ((dx and math.abs(dx) > 1) or (dy and math.abs(dy) > 1))
--     --     and love.mouse.isDown(1)
--     --     and self:mouse_is_on_view()
--     --     and self.state == Tools.move_map
--     -- then
--     --     local qx = self.gamestate:monitor_length_to_world(dx, self.camera)
--     --     local qy = self.gamestate:monitor_length_to_world(dy, self.camera)

--     --     self.camera:move(-qx, -qy)
--     -- end

--     -- self:fix_piece_position()
-- end

-- function Map:wheelmoved(x, y, force)
--     -- if not self:mouse_is_on_view() and not force then return false end
--     -- if not self.is_enable then return false end

--     -- local zoom
--     -- local speed = 0.1
--     -- if y > 0 then
--     --     zoom = self.camera.scale + speed
--     -- else
--     --     zoom = self.camera.scale - speed
--     -- end

--     -- return self.camera:set_zoom(zoom)
-- end

function Map:mouse_is_on_view()
    local mx, my = self.gamestate:get_mouse_position(self.camera)
    return self.camera:point_is_on_view(mx, my)
end

function Map:update_debug(dt)
    local cam = self.camera

    local speed = 128 / cam.scale
    if love.keyboard.isDown("up") then
        cam:move(0, -speed * dt)
    elseif love.keyboard.isDown("down") then
        cam:move(0, speed * dt)
    end

    if love.keyboard.isDown("left") then
        cam:move(-speed * dt, 0)
    elseif love.keyboard.isDown("right") then
        cam:move(speed * dt, 0)
    end
    self:fix_piece_position(cam)

    self:cur_action(dt)
end

function Map:my_debug_draw()
    local cam = self.camera

    if not self.show_world then
        local N_layers = #self.layers

        for i = 1, N_layers do
            local cx, cy = cam.x, cam.y
            local sc = cam.scale

            ---@type JM.MapLayer
            local layer = self.layers[i]

            if i == self.cur_layer_index then
                layer:set_opacity(1)
            else
                layer:set_opacity(0.5)
            end

            if layer.type == Layer.Types.only_fall then
                cam:set_position(cam.x * layer.factor_x,
                    cam.y * layer.factor_y)

                cam:attach(nil, self.gamestate.subpixel)

                layer:draw_no_factor(self.camera)

                if i == self.cur_layer_index then
                    self.cur_piece:draw()
                    cam:draw_info()
                end

                cam:detach()
            end

            cam.x = cx
            cam.y = cy
            cam.scale = sc
        end

        for i = 1, N_layers do
            local cx, cy = cam.x, cam.y
            local sc = cam.scale

            ---@type JM.MapLayer
            local layer = self.layers[i]

            if i == self.cur_layer_index then
                layer:set_opacity(1)
            else
                layer:set_opacity(0.5)
            end

            if layer.type ~= Layer.Types.only_fall then
                cam:set_position(cam.x * layer.factor_x,
                    cam.y * layer.factor_y)

                cam:attach(nil, self.gamestate.subpixel)
                layer:draw_no_factor(self.camera)

                if i == self.cur_layer_index then
                    self.cur_piece:draw()
                    cam:draw_info()
                end
                cam:detach()
            end

            cam.x = cx
            cam.y = cy
            cam.scale = sc
        end
    end

    if self.world and self.show_world then
        cam:attach(nil, self.gamestate.subpixel)

        local N = #self.world.bodies_static

        for i = 1, N do
            ---@type JM.Physics.Collide
            local bd = self.world.bodies_static[i]

            if not bd.is_slope and bd.type == bd.Types.only_fall then
                if self.camera:rect_is_on_view(bd:rect()) then
                    bd:draw()
                end
            end
        end

        for i = 1, N do
            ---@type JM.Physics.Collide
            local bd = self.world.bodies_static[i]

            if bd.is_slope then
                if self.camera:rect_is_on_view(bd:rect()) then
                    bd:draw()
                end
            end
        end



        for i = 1, N do
            ---@type JM.Physics.Collide
            local bd = self.world.bodies_static[i]

            if not bd.is_slope and bd.type == bd.Types.static then
                if self.camera:rect_is_on_view(bd:rect()) then
                    bd:draw()
                end
            end
        end

        cam:draw_info()
        cam:detach()
    end
    --=======================================================================
    cam:attach(nil, self.gamestate.subpixel)

    local mx, my = self.gamestate:get_mouse_position(cam)
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.rectangle("fill", mx, my, 16, 16)
    -- self.cur_piece:draw()

    -- cam:draw_info()
    cam:detach()
end

---@param cam JM.Camera.Camera|nil
function Map:debbug_draw(cam)
    local camera = cam or self.camera

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("fill", camera:get_viewport())

    self:my_debug_draw()

    local font = JM:get_font()
    local r = self:mouse_is_on_view()
    font:print(r and "on view" or "out", camera.viewport_x, camera.viewport_y - 20)

    font:print(self.name, camera.viewport_x + 100, camera.viewport_y - 20)

    font:print(self.cur_layer.name, camera.viewport_x + 200, camera.viewport_y - 20)

    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle("line", camera:get_viewport())
end

-- function Map:layer_draw(camera)
--     local cam = camera --or self.camera

--     for i = 1, #self.layers do
--         ---@type JM.MapLayer
--         local layer = self.layers[i]
--         layer:set_opacity(1)
--         layer:draw(cam)
--     end

--     -- love.graphics.setColor(1, 1, 0)
--     -- love.graphics.rectangle("line", cam:get_viewport())
-- end

function Map.load_map(dir, world_config)
    local map = Map:new(GC.gamestate)
    local d = JM.Ldr.load(dir)
    map:init(d, world_config)
    map:build_world()
    map:auto_tile()

    for i = 1, #map.layers do
        ---@type JM.MapLayer
        local layer = map.layers[i]
        -- layer.out_tilemap = layer.tilemap
        layer.tilemap = nil
    end
    collectgarbage("collect")
    return map
end

function Map:update(dt)
    for i = 1, #self.list_world do
        ---@type JM.Physics.World
        local world = self.list_world[i]
        world:update(dt)
    end
end

---@param cam JM.Camera.Camera
function Map:draw(cam)
    for i = 1, #self.layers do
        ---@type JM.MapLayer
        local layer = self.layers[i]
        layer:set_opacity(1)
        layer:draw(cam)
    end
end

return Map
