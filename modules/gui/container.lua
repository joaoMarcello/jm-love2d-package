local love_get_scissor = love.graphics.getScissor
local love_set_scissor = love.graphics.setScissor
local love_set_color = love.graphics.setColor
local love_rectangle = love.graphics.rectangle

---@type JM.GUI.Component
local Component = require((...):gsub("container", "component"))

local Affectable = JM.Affectable

---@enum JM.GUI.Container.InsertMode
local INSERT_MODE = {
    normal = 1,
    left = 2,
    right = 3,
    center = 4,
    top = 5,
    bottom = 6
}


---@class JM.GUI.Container: JM.GUI.Component
local Container = setmetatable({}, Component)
Container.__index = Container
Container.INSERT_MODE = INSERT_MODE

---@return JM.GUI.Container
function Container:new(args)
    ---@class JM.GUI.Container
    local obj = Component:new(args)
    self.__index = self
    setmetatable(obj, self)

    return obj:__constructor__(args)
end

-- ---@param args {scene: JM.Scene, type: string, mode: string, grid_x:number, grid_y: number}
function Container:__constructor__(args)
    args = args or {}
    -- self.scene = args.scene
    self.components = {}
    self.N = 0
    self.space_vertical = args.space_vertical     -- or 15
    self.space_horizontal = args.space_horizontal -- or 15
    self.border_x = args.border_x or 0            --15
    self.border_y = args.border_y or 0            --15
    self.type = self.TYPE.container
    ---@type JM.GUI.Component
    self.cur_gc = nil
    self.num = 0

    self.show_bounds = args.show_bounds
    self.skip_scissor = args.skip_scissor

    self.touch_mode = args.touch_mode or false

    self:set_type(args.type or "", args.mode or "center", args.grid_x, args.grid_y)
    return self
end

function Container:set_position(x, y)
    x = x or self.x
    y = y or self.y

    local diff_x, diff_y = x - self.x, y - self.y

    Component.set_position(self, x, y)

    if diff_x ~= 0 or diff_y ~= 0 then
        return self:shift_objects(diff_x, diff_y)
    end
end

function Container:shift_objects(dx, dy)
    dx = dx or 0
    dy = dy or 0

    for i = 1, self.N do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        gc:set_position(gc.x + dx, gc.y + dy)
    end
end

function Container:switch(index)
    ---@type JM.GUI.Component
    local last = self.cur_gc

    self.num = index or 1
    self.cur_gc = self.components[self.num]
    if last then
        last:set_focus(false)
    end
    if self.cur_gc and not self.touch_mode then
        self.cur_gc:set_focus(true)
    end
end

---@param obj JM.GUI.Component
function Container:switch_to_obj(obj)
    local list = self.components
    for i = 1, self.N do
        if list[i] == obj then
            return self:switch(i)
        end
    end
end

function Container:switch_up()
    self.num = self.num - 1
    if self.num <= 0 then
        self.num = self.N
    end
    return self:switch(self.num)
end

function Container:switch_down()
    self.num = self.num + 1
    if self.num > self.N then
        self.num = 1
    end
    return self:switch(self.num)
end

function Container:switch_left()
    return self:switch_up()
end

function Container:switch_right()
    return self:switch_down()
end

---@return JM.GUI.Component|any
function Container:get_obj_at(index)
    return self.components[index]
end

---@return JM.GUI.Component|any
function Container:get_cur_obj()
    return self.components[self.num]
end

---@param mx number
---@param my number
function Container:verify_mouse_collision(mx, my)
    for i = 1, self.N do
        local obj = self:get_obj_at(i)

        if not obj.on_focus
            and (obj.is_enable and obj.is_visible)
            and obj:check_collision(mx, my, 0, 0)
        then
            self:switch(i)
            ---
        elseif obj.on_focus and not obj:check_collision(mx, my, 0, 0) then
            obj:set_focus(false)
            ---
        end
    end
end

function Container:update(dt)
    self.__effect_manager:update(dt)

    local list = self.components
    local touch_mode = self.touch_mode

    for i = self.N, 1, -1 do
        ---@type JM.GUI.Component
        local gc = list[i]

        if gc.__remove then
            table.remove(list, i)
            self.N = self.N - 1
        else
            if gc.is_enable then
                gc:update(dt)

                if touch_mode then
                    if (not gc.__mouse_pressed) and (not gc.__touch_pressed)
                        and gc.on_focus
                    then
                        gc:set_focus(false)
                    end
                    ---
                end
            end
        end
        ---
    end
    ---
end

function Container:mousepressed(x, y, bt, istouch, presses)
    if self.touch_mode then self:put_on_focus_by_pos(x, y) end

    for i = 1, self.N do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_enable and not gc.__remove
            and gc:mousepressed(x, y, bt, istouch, presses)
    end
end

function Container:mousereleased(x, y, bt, istouch, presses)
    local list = self.components
    for i = 1, self.N do
        ---@type JM.GUI.Component
        local gc = list[i]

        local r = gc.is_enable and not gc.__remove
            and gc:mousereleased(x, y, bt, istouch, presses)
    end
end

function Container:mousemoved(x, y, dx, dy, istouch)
    if self.touch_mode then self:put_on_focus_by_pos(x, y) end

    local list = self.components
    for i = 1, self.N do
        ---@type JM.GUI.Component
        local gc = list[i]

        if gc.is_enable and not gc.__remove then
            gc:mousemoved(x, y, dx, dy, istouch)
        end
    end
end

function Container:touchpressed(id, x, y, dx, dy, pressure)
    if self.gamestate then
        x, y = self.gamestate:real_to_screen(x, y)
    end

    if self.touch_mode then
        self:put_on_focus_by_pos(x, y)
    end

    local list = self.components

    for i = 1, self.N do
        ---@type JM.GUI.Component
        local gc = list[i]

        if gc.is_enable and not gc.__remove then
            gc:touchpressed(id, x, y, dx, dy, pressure)
        end
    end
end

function Container:touchreleased(id, x, y, dx, dy, pressure)
    if self.gamestate then
        x, y = self.gamestate:real_to_screen(x, y)
    end

    if self.touch_mode then
        self:put_on_focus_by_pos(x, y)
    end

    local list = self.components

    for i = 1, self.N do
        ---@type JM.GUI.Component
        local gc = list[i]

        if gc.is_enable and not gc.__remove then
            gc:touchreleased(id, x, y, dx, dy, pressure)
        end
    end
end

function Container:touchmoved(id, x, y, dx, dy, pressure)
    if self.gamestate then
        x, y = self.gamestate:real_to_screen(x, y)
    end

    if self.touch_mode then
        self:put_on_focus_by_pos(x, y)
    end

    local list = self.components

    for i = 1, self.N do
        ---@type JM.GUI.Component
        local gc = list[i]

        if gc.is_enable and not gc.__remove then
            gc:touchmoved(id, x, y, dx, dy, pressure)
        end
    end
end

function Container:put_on_focus_by_pos(x, y)
    local list = self.components
    for i = 1, self.N do
        ---@type JM.GUI.Component
        local gc = list[i]
        if gc.is_enable and not gc.__remove then
            if gc:check_collision(x, y, 0, 0) and not gc.on_focus then
                gc:set_focus(true)
            end
        end
    end
end

function Container:remove_focus_by_pos(x, y)
    local list = self.components
    for i = 1, self.N do
        ---@type JM.GUI.Component
        local gc = list[i]
        if gc.is_enable and not gc.__remove then
            if not gc:check_collision(x, y, 0, 0) and gc.on_focus
                and not gc.time_press
            then
                gc:set_focus(false)
            end
        end
    end
end

function Container:keypressed(key, scancode, isrepeat)
    for i = 1, self.N do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_enable and not gc.__remove
            and gc:keypressed(key, scancode, isrepeat)
    end
end

function Container:keyreleased(key, scancode)
    for i = 1, self.N do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_enable and not gc.__remove
            and gc:keyreleased(key, scancode)
    end
end

function Container:set_dimensions(w, h)
    Component.set_dimensions(self, w, h)
    return self:__add_behavior__()
end

---@param camera JM.Camera.Camera|any
local function my_draw(self, camera)
    local sx, sy, sw, sh = love_get_scissor()

    if not self.skip_scissor and camera and camera.scene then
        local sx1, sy1, sw1, sh1 = camera:scissor_transform(self.x, self.y, self.w, self.h, camera.scene.subpixel)

        love_set_scissor(sx1, sy1, sw1, sh1)
    end

    local list = self.components
    local x, y = self.x, self.y
    local right, bottom = self.right, self.bottom

    for i = 1, self.N do
        ---@type JM.GUI.Component
        local gc = list[i]

        local out_of_limits = gc.right < x - 20
            or gc.x > right + 20
            or gc.bottom < y - 20
            or gc.y > bottom + 20

        local r = gc.is_visible and not gc.__remove and not out_of_limits
            and gc:draw()
    end

    love_set_scissor(sx, sy, sw, sh)

    if self.show_bounds then
        love_set_color(1, 0, 0, 1)
        love_rectangle("line", self:rect())

        love_set_color(0, 1, 1, 1)
        love_rectangle("line", x + self.border_x, y + self.border_y, self.w - self.border_x * 2,
            self.h - self.border_y * 2)
    end
end

function Container:draw(cam)
    return Affectable.draw(self, my_draw, cam)
end

---@param obj JM.GUI.Component
---@return JM.GUI.Component
function Container:add(obj)
    self.total_width = self.total_width or 0
    self.total_height = self.total_height or 0

    self.total_width = self.total_width + obj.w
    self.total_height = self.total_height + obj.h

    obj:set_holder(self)

    table.insert(self.components, obj)
    self.N = self.N + 1

    self:__add_behavior__()

    if not self.cur_gc then
        self:switch(1)
    end

    return obj
end

---@param type_ "horizontal_list"|"vertical_list"|"grid"|""|nil
function Container:set_type(type_, mode, grid_x, grid_y)
    mode = INSERT_MODE[mode]
    mode = mode or INSERT_MODE.center

    if type_ == "horizontal_list" then
        ---@diagnostic disable-next-line: duplicate-set-field
        self.__add_behavior__ = function(self)
            self:refresh_positions_x(mode)
        end
    elseif type_ == "vertical_list" then
        ---@diagnostic disable-next-line: duplicate-set-field
        self.__add_behavior__ = function(self)
            self:refresh_positions_y(mode)
        end
    elseif type_ == "grid" then
        ---@diagnostic disable-next-line: duplicate-set-field
        self.__add_behavior__ = function(self)
            self:refresh_pos_grid(grid_y, grid_x)
        end
    else -- free position
        ---@diagnostic disable-next-line: duplicate-set-field
        self.__add_behavior__ = function()
        end
    end
end

---@param mode JM.GUI.Container.InsertMode
function Container:refresh_positions_y(mode)
    local N = self.N
    if N <= 0 then return end

    local x = self.x + self.border_x
    local y = self.y + self.border_y
    local w = self.w - self.border_x * 2
    local h = self.h - self.border_y * 2
    local space = self.space_vertical
        or ((h - self.total_height) / (N - 1))

    for i = 1, N do
        ---@type JM.GUI.Component|nil
        local prev = self.components[i - 1]

        ---@type JM.GUI.Component
        local gc = self.components[i]

        local px = gc.x
        if mode == INSERT_MODE.left then
            px = x
        elseif mode == INSERT_MODE.right then
            px = x + w - gc.w
        elseif mode == INSERT_MODE.center then
            px = self.x + self.border_x
                + (self.w - self.border_x * 2) / 2
                - gc.w / 2
        end

        gc:set_position(
            px,
            prev and prev.bottom + space or y
        )
    end
end

---@param mode JM.GUI.Container.InsertMode
function Container:refresh_positions_x(mode)
    local N = self.N
    if N <= 0 then return end

    local x = self.x + self.border_x
    local y = self.y + self.border_y
    local w = self.w - self.border_x * 2
    local h = self.h - self.border_y * 2

    local space
    if N == 1 then
        space = w * 0.5
    else
        space = (w - self.total_width) / (N - 1)
    end

    for i = 1, N do
        ---@type JM.GUI.Component|nil
        local prev = self.components[i - 1]

        ---@type JM.GUI.Component
        local gc = self.components[i]

        local py = gc.y
        if mode == INSERT_MODE.center then
            py = y + h / 2 - gc.h / 2
        elseif mode == INSERT_MODE.top then
            py = y
        elseif mode == INSERT_MODE.bottom then
            py = y + h - gc.h
        end

        gc:set_position(
            (prev and (prev.right + space))
            or (N == 1 and (x + space - gc.w * 0.5))
            or x,
            py
        )
    end
end

function Container:refresh_pos_grid(row, column)
    local N = self.N
    if N <= 0 then return end

    row, column = row or 3, column or 2

    assert(N <= row * column, "\n>>Error: Many components added to container.")

    local x = self.x + self.border_x
    local y = self.y + self.border_y
    local w = self.w - self.border_x * 2
    local h = self.h - self.border_y * 2

    local cell_w = w / column
    local cell_h = h / row

    for i = 1, row do
        for j = 1, column do
            ---@type JM.GUI.Component
            local gc = self.components[column * (i - 1) + j]

            if gc then
                local py = y + (i - 1) * cell_h
                local px = x + (j - 1) * cell_w

                gc:set_position(
                    px + cell_w / 2 - gc.w / 2,
                    py + cell_h / 2 - gc.h / 2
                )
            else
                return
            end
        end
    end
end

return Container
