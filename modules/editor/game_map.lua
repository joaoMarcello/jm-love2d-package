local dir = ...
local GC = _G.JM.GameObject

---@type JM.MapLayer
local Layer = require(string.gsub(dir, "game_map", "map_layer"))

---@type JM.MapPiece
local Piece = require(string.gsub(dir, "game_map", "map_piece"))

local tile_size = 16

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
                self.cur_layer.tilemap:remove_tile(self.cur_piece.x, self.cur_piece.y)
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
local Object = setmetatable({}, GC)
Object.__index = Object

---@return JM.GameMap
function Object:new(x, y, w, h, draw_order, update_order, reuse_tab)
    local obj = GC:new(x, y, w, h, draw_order, update_order, reuse_tab)
    setmetatable(obj, self)
    Object.__constructor__(obj)
    return obj
end

function Object:__constructor__()
    self.camera = JM.Camera:new {
        x = 64 * 4,
        y = 64 * 4,
        w = 64 * 8,
        h = 64 * 4,
        tile_size = 16,
        bounds = { left = -math.huge, right = math.huge, top = -math.huge, bottom = math.huge },
        border_color = { 1, 0, 0, 1 },
    }
    self.camera:toggle_grid()
    self.camera:toggle_world_bounds()
    self.camera.max_zoom = 4

    self.layers = {}
    table.insert(self.layers, Layer:new())

    self.pieces = {}
    self.pieces_order = {}
    do
        self.pieces["block-1x1"] = Piece:new {
            tiles = { { 1 } },
        }
        table.insert(self.pieces_order, self.pieces["block-1x1"])

        self.pieces["slope-1x1"] = Piece:new {
            tiles = { { 2 } },
        }
        table.insert(self.pieces_order, self.pieces["slope-1x1"])

        self.pieces["slope-1x1-inv"] = Piece:new {
            tiles = { { 5 } },
        }
        table.insert(self.pieces_order, self.pieces["slope-1x1-inv"])

        self.pieces["slope-2x1"] = Piece:new {
            tiles = { { 3, 4 } },
        }
        table.insert(self.pieces_order, self.pieces["slope-2x1"])

        self.pieces["slope-2x1-inv"] = Piece:new {
            tiles = { { 6, 7 } },
        }
        table.insert(self.pieces_order, self.pieces["slope-2x1-inv"])

        self.pieces["slope-3x1"] = Piece:new {
            tiles = { { 9, 10, 11 } },
        }
        table.insert(self.pieces_order, self.pieces["slope-3x1"])

        self.pieces["slope-3x1-inv"] = Piece:new {
            tiles = { { 12, 13, 14 } },
        }
        table.insert(self.pieces_order, self.pieces["slope-3x1-inv"])

        self.pieces["slope-4x1"] = Piece:new {
            tiles = { { 15, 16, 17, 18 } },
        }
        table.insert(self.pieces_order, self.pieces["slope-4x1"])

        self.pieces["slope-4x1-inv"] = Piece:new {
            tiles = { { 19, 20, 21, 22 } },
        }
        table.insert(self.pieces_order, self.pieces["slope-4x1-inv"])

        self.pieces["ceil-1x1-inv"] = Piece:new {
            tiles = { { 23 } },
        }
        table.insert(self.pieces_order, self.pieces["ceil-1x1-inv"])

        self.pieces["ceil-1x1"] = Piece:new {
            tiles = { { 26 } },
        }
        table.insert(self.pieces_order, self.pieces["ceil-1x1"])

        self.pieces["ceil-2x1-inv"] = Piece:new {
            tiles = { { 24, 25 } },
        }
        table.insert(self.pieces_order, self.pieces["ceil-2x1-inv"])

        self.pieces["ceil-2x1"] = Piece:new {
            tiles = { { 27, 28 } },
        }
        table.insert(self.pieces_order, self.pieces["ceil-2x1"])

        self.pieces["ceil-3x1-inv"] = Piece:new {
            tiles = { { 29, 30, 31 } },
        }
        table.insert(self.pieces_order, self.pieces["ceil-3x1-inv"])

        self.pieces["ceil-3x1"] = Piece:new {
            tiles = { { 32, 33, 34 } },
        }
        table.insert(self.pieces_order, self.pieces["ceil-3x1"])

        self.pieces["ceil-4x1-inv"] = Piece:new {
            tiles = { { 35, 36, 37, 38 } },
        }
        table.insert(self.pieces_order, self.pieces["ceil-4x1-inv"])

        self.pieces["ceil-4x1"] = Piece:new {
            tiles = { { 39, 40, 41, 42 } },
        }
        table.insert(self.pieces_order, self.pieces["ceil-4x1"])
    end

    self.cur_piece_index = 1
    ---@type JM.MapPiece
    self.cur_piece = self.pieces_order[1]

    self.cur_layer_index = 1
    ---@type JM.MapLayer
    self.cur_layer = self.layers[1]

    Piece:init_module(self.cur_layer.tilemap)

    self.state = nil --Tools.move_map
    -- self.cur_action = tool_actions[self.state]
    self:set_state(Tools.move_map)

    --
    self.update = Object.update
    self.draw = Object.draw
end

function Object:load()
    Layer:load()
end

function Object:init()

end

---@param new_state JM.GameMap.Tools
function Object:set_state(new_state)
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

function Object:keypressed(key)
    if key == 'a' then
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
            self:fix_piece_position()
        elseif key == 's' then
            self.cur_piece_index = self.cur_piece_index + 1
            if self.cur_piece_index > #self.pieces_order then
                self.cur_piece_index = 1
            end
            self.cur_piece = self.pieces_order[self.cur_piece_index]
            self:fix_piece_position()
        end
    end
end

function Object:keyreleased(key)

end

function Object:mousepressed(x, y, button, istouch, presses)
    if button == 3 then
        self.camera:toggle_grid()
        self.camera:toggle_world_bounds()
    end
end

function Object:mousereleased(x, y, button, istouch, presses)

end

function Object:fix_piece_position()
    local mx, my     = self.gamestate:get_mouse_position(self.camera)
    self.cell_x      = math.floor(mx / tile_size)
    self.cell_y      = math.floor(my / tile_size)
    self.cur_piece.x = self.cell_x * tile_size
    self.cur_piece.y = self.cell_y * tile_size
end

function Object:mousemoved(x, y, dx, dy, istouch)
    local mx, my = self.gamestate:get_mouse_position(self.camera)
    self.camera:set_focus(self.camera:world_to_screen(mx, my))

    if ((dx and math.abs(dx) > 1) or (dy and math.abs(dy) > 1))
        and love.mouse.isDown(1)
        and self:mouse_is_on_view()
        and self.state == Tools.move_map
    then
        local qx = self.gamestate:monitor_length_to_world(dx, self.camera)
        local qy = self.gamestate:monitor_length_to_world(dy, self.camera)

        self.camera:move(-qx, -qy)
    end

    self:fix_piece_position()
end

function Object:wheelmoved(x, y, force)
    if not self:mouse_is_on_view() and not force then return false end
    if not self.is_enable then return false end

    local zoom
    local speed = 0.1
    if y > 0 then
        zoom = self.camera.scale + speed
    else
        zoom = self.camera.scale - speed
    end

    return self.camera:set_zoom(zoom)
end

function Object:mouse_is_on_view()
    local mx, my = self.gamestate:get_mouse_position(self.camera)
    return self.camera:point_is_on_view(mx, my)
end

function Object:update(dt)
    local speed = 96 / self.camera.scale
    if love.keyboard.isDown("up") then
        self.camera:move(0, -speed * dt)
    elseif love.keyboard.isDown("down") then
        self.camera:move(0, speed * dt)
    end

    if love.keyboard.isDown("left") then
        self.camera:move(-speed * dt, 0)
    elseif love.keyboard.isDown("right") then
        self.camera:move(speed * dt, 0)
    end
    self:fix_piece_position()

    self:cur_action(dt)
end

function Object:my_draw()
    love.graphics.setColor(0, 0, 1, 0.2)
    love.graphics.rectangle("fill", 0, 0, 64 * 3, 64 * 3)

    self.cur_layer.tilemap:draw(self.camera)

    local mx, my = self.gamestate:get_mouse_position(self.camera)
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.rectangle("fill", mx, my, 16, 16)

    self.cur_piece:draw()
end

function Object:draw()
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("fill", self.camera:get_viewport())

    self.camera:attach(nil, self.gamestate.subpixel)
    GC.draw(self, self.my_draw)
    self.camera:draw_info()
    self.camera:detach()

    local font = JM:get_font()
    local r = self:mouse_is_on_view()
    font:print(r and "on view" or "out", self.camera.viewport_x, self.camera.viewport_y - 20)
end

return Object
