---@type JM.GUI.Component
local Component = require(string.gsub(..., "stick", "component"))

---@type JM.GUI.TouchButton
local TouchButton = require(string.gsub(..., "stick", "touch_button"))

local Utils = _G.JM_Utils

local math_abs, math_sin, math_cos = math.abs, math.sin, math.cos
local math_atan2, math_sqrt = math.atan2, math.sqrt
local lgx = love.graphics
local lmouse = love.mouse
-- local ltouch = love.touch

---@class JM.GUI.VirtualStick : JM.GUI.Component
local Stick = setmetatable({}, Component)
Stick.__index = Stick

---@return JM.GUI.VirtualStick
function Stick:new(args)
    args = args or {}
    args.x = args.x or 250
    args.y = args.y or 250
    args.w = args.w or (96 * 1.3)
    args.h = args.h or args.w or (96 * 1.3)

    ---@class JM.GUI.VirtualStick
    local obj = Component:new(args)
    setmetatable(obj, self)
    Stick.__constructor__(obj, args)
    return obj
end

function Stick:__constructor__(args)
    self.radius = self.w * 0.5
    self.max_dist = self.radius * 1.2

    self.cx = self.x + self.w * 0.5
    self.cy = self.y + self.h * 0.5

    self.half_x = self.x + self.w * 0.5
    self.half_y = self.y + self.h * 0.5

    self.is_mobile = args.is_mobile

    self.bounds_left = args.bound_left or 0
    self.bounds_top = args.bound_top or 0
    self.bounds_width = args.bound_width or (lgx.getWidth() * 0.25)
    self.bounds_height = args.bound_height or lgx.getHeight()

    self.init_x = self.x
    self.init_y = self.y

    self.opacity = args.opacity or 1

    self.dpad_list = self.dpad_list or false

    self.update = Stick.update
    self.draw = Stick.draw
    self.get_direction = Stick.get_direction
    self.get_angle = Stick.get_angle
    self.get_angle2 = Stick.get_angle2
    self.is_pressing = Stick.is_pressing
end

function Stick:init()
    local w, h = lgx.getDimensions()
    return self:__constructor__ {
        is_mobile = self.is_mobile,
        bound_left = 0,
        bound_top = h * 0.25,
        bound_width = w * 0.35,
        bound_height = h * 0.75,
        opacity = self.opacity,
    }
end

function Stick:set_dimensions(w, h)
    Component.set_dimensions(self, w, h)

    local list = self.dpad_list
    if list then
        local w, h = (self.w * 0.5), (self.h * 0.5)
        for i = 1, #list do
            local obj = list[i]
            obj:set_dimensions(w, h)
        end
    end
end

function Stick:use_dpad(value)
    if not value then
        self.dpad_list = false
        return
    end

    if self.dpad_list then return end

    local draw = function(bt)
        if self.__mouse_pressed or self.__touch_pressed then
            return
        end
        lgx.setColor(1, 1, 1, self.opacity)
        lgx.circle("fill", bt.x + bt.w * 0.5, bt.y + bt.h * 0.5, bt.w * 0.25)

        lgx.setColor(1, 1, 1, self.opacity + self.opacity * 0.1)
        lgx.circle("line", bt.x + bt.w * 0.5, bt.y + bt.h * 0.5, bt.w * 0.25)
        -- lgx.setColor(1, 0, 0, 0.5)
        -- lgx.rectangle("line", self:rect())
    end

    local right = TouchButton:new {
        on_focus = true,
        text = "dpleft",
        -- use_radius = true,
        draw = draw,
    }

    local left = TouchButton:new {
        on_focus = true,
        text = "dpright",
        -- use_radius = true,
        draw = draw,
    }

    local up = TouchButton:new {
        on_focus = true,
        text = "dpup",
        -- use_radius = true,
        draw = draw,
    }

    local down = TouchButton:new {
        on_focus = true,
        text = "dpdown",
        -- use_radius = true,
        draw = draw,
    }

    self.dpad_right = right
    self.dpad_left = left
    self.dpad_up = up
    self.dpad_down = down
    self.dpad_list = { right, left, up, down }

    self:set_dpad_position()
end

function Stick:turn_off_dpad()
    return self:use_dpad(false)
end

function Stick:turn_on_dpad()
    return self:use_dpad(true)
end

function Stick:set_dpad_position()
    local list = self.dpad_list
    if not list then return end

    local half_x = self.half_x
    local half_y = self.half_y
    local max_dist = self.max_dist
    local size = self.dpad_down.w
    local half_size = size * 0.5

    self.dpad_right:set_position(half_x + max_dist, half_y - half_size)

    self.dpad_left:set_position(half_x - max_dist - size, half_y - half_size)

    self.dpad_up:set_position(half_x - half_size, half_y - max_dist - size)

    self.dpad_down:set_position(half_x - half_size, half_y + max_dist)
end

function Stick:using_dpad()
    return self.dpad_list
end

function Stick:set_position(x, y, capture)
    Component.set_position(self, x, y)
    self.cx = self.x + self.w * 0.5
    self.cy = self.y + self.h * 0.5

    self.half_x = self.x + self.w * 0.5
    self.half_y = self.y + self.h * 0.5

    if capture then
        self.init_x = self.x
        self.init_y = self.y
    end

    return self:set_dpad_position()
end

function Stick:set_bounds(l, t, w, h)
    self.bounds_left = l or self.bounds_left
    self.bounds_top = t or self.bounds_top
    self.bounds_width = w or self.bounds_width
    self.bounds_height = h or self.bounds_height
end

function Stick:grow()
    self:set_effect_transform("sx", 1.2)
    self:set_effect_transform("sy", 1.2)
end

function Stick:shrink()
    self:set_effect_transform("sx", 1)
    self:set_effect_transform("sy", 1)
end

function Stick:check_dpad_collision(x, y)
    local list = self.dpad_list
    if not list then return end

    for i = 1, #list do
        local obj = list[i]
        if obj:__check_collision__(x, y) then return obj end
    end
end

-- function Stick:check_dpad_touchpressed(x, y)
--     local list = self.dpad_list
--     if not list then return end

--     for i = 1, #list do
--         local obj = list[i]
--         if obj:__check_collision__(x, y) then return obj end
--     end
-- end

function Stick:mousepressed(x, y, button, istouch, presses)
    if self.__mouse_pressed then return end

    do
        local obj = self:check_dpad_collision(x, y)

        if obj then
            self:refresh_position(x, y)

            Component.mousepressed(self, self.half_x, self.half_y, button, istouch, presses)

            if self.__mouse_pressed then
                self:grow()
            end
            return
        end
    end

    if self.is_mobile then
        local r = Component.collision(x, y, 0, 0,
            self.bounds_left, self.bounds_top,
            self.bounds_width, self.bounds_height
        )

        if r then
            self:set_position(x - self.w * 0.5, y - self.h * 0.5)
        end
    end

    local dx = x - (self.half_x)
    local dy = y - (self.half_y)
    local dist = math_sqrt(dx ^ 2 + dy ^ 2)

    if dist <= self.radius then
        Component.mousepressed(self, x, y, button, istouch, presses)
        if self.__mouse_pressed then
            self:grow()
        end
    end
end

function Stick:mousereleased(x, y, button, istouch, presses)
    if self.__mouse_pressed then
        Component.mousereleased(self, x, y, button, istouch, presses)
        self:release()
    end
end

function Stick:touchpressed(id, x, y, dx, dy, pressure)
    if self.__touch_pressed then return false end

    do
        local obj = self:check_dpad_collision(x, y)

        if obj then
            self:refresh_position(x, y)
            Component.touchpressed(self, id, self.half_x, self.half_y, dx, dy, pressure)
            if self.__touch_pressed then
                self:grow()
            end
            return
        end
    end

    if self.is_mobile then
        local r = Component.collision(x, y, 0, 0,
            self.bounds_left, self.bounds_top,
            self.bounds_width, self.bounds_height
        )

        if r then
            self:set_position(x - self.w * 0.5, y - self.h * 0.5)
        end
    end

    local distx = x - (self.x + self.w * 0.5)
    local disty = y - (self.y + self.h * 0.5)
    local dist = math.sqrt(distx ^ 2 + disty ^ 2)

    if dist <= self.radius then
        Component.touchpressed(self, id, x, y, dx, dy, pressure)
        if self.__touch_pressed then self:grow() end
    end
end

function Stick:touchreleased(id, x, y, dx, dy, pressure)
    if id ~= self.__touch_pressed then return false end

    if self.__touch_pressed then
        Component.touchreleased(self, id, x, y, dx, dy, pressure)
        self:release()
    end
end

function Stick:release()
    self:shrink()
    self:set_position(self.init_x, self.init_y)
    self.cx = self.half_x
    self.cy = self.half_y
    self.__mouse_pressed = false
    self.__touch_pressed = false
    self.time_press = false
    self.angle = 0
    self.dist = 0
end

function Stick:is_pressed()
    return (self.__mouse_pressed or self.__touch_pressed)
    -- and self.time_press == 0.0
end

---@param direction "left"|"right"|"up"|"down"
function Stick:is_pressing(direction, constraint, angle_limit)
    constraint = constraint or 0.1  --0.2
    angle_limit = angle_limit or 55 --50

    local dx, dy = self:get_direction()

    if dx == 0 and dy == 0 or not self.dist or not self.angle then
        return false
    end

    local angle = self:get_angle2()

    if direction == "left" or direction == "right" then
        if math_abs(dx) < constraint then return false end

        local abs_angle = math_abs(angle)
        if (direction == "right" and abs_angle > angle_limit) or
            (direction == "left" and abs_angle < 180 - angle_limit)
        then
            return false
        end

        return (direction == "left" and dx < 0) or (direction == "right" and dx > 0)
    else
        if math_abs(dy) < constraint then return false end

        angle_limit = angle_limit * 1.25

        local abs_angle = math_abs(angle)
        if (direction == "up" and (abs_angle > 90 + angle_limit
                or abs_angle < 90 - angle_limit))
            or (direction == "down" and (abs_angle > 90 + angle_limit
                or abs_angle < 90 - angle_limit))
        then
            return false
        end

        return (direction == "up" and dy < 0)
            or (direction == "down" and dy > 0)
    end
end

function Stick:get_direction()
    local angle = self.angle
    local dist = self.dist

    if not angle or not dist
        or (self.cx == self.half_x and self.cy == self.half_y)
    then
        return 0, 0
    end

    local value = dist / self.max_dist

    return value * (math_cos(angle) > 0 and 1 or -1),
        value * (math_sin(angle) > 0 and 1 or -1)
end

function Stick:get_angle()
    return self.angle or 0
end

function Stick:get_angle2()
    local angle = self.angle or 0
    angle = angle * 180.0 / math.pi
    return angle
end

function Stick:set_opacity(value)
    self.opacity = value or self.opacity
end

function Stick:refresh_position(x, y)
    local ldirx, ldiry = self:get_direction()
    local pressing_left = self:is_pressing("left")
    local pressing_right = not pressing_left and self:is_pressing("right")
    local pressing_up = self:is_pressing("up")
    local pressing_down = not pressing_up and self:is_pressing("down")

    local half_x = self.half_x
    local half_y = self.half_y
    local dx = x - half_x
    local dy = y - half_y
    local angle = math_atan2(dy, dx)
    local dist = math_sqrt(dx ^ 2 + dy ^ 2)
    dist = Utils:clamp(dist, 0, self.max_dist)

    self.cx = half_x + dist * math_cos(angle)
    self.cy = half_y + dist * math_sin(angle)

    self.angle = angle
    self.dist = dist


    local dirx, diry = self:get_direction()

    local left = self:is_pressing("left")
    local right = not left and self:is_pressing("right")
    local up = self:is_pressing("up")
    local down = not up and self:is_pressing("down")

    local condx = (ldirx ~= dirx and (left or right))
        or ((pressing_left or not pressing_right) and right)
        or ((pressing_right or not pressing_left) and left)

    local condy = (ldiry ~= diry and (up or down))
        or ((pressing_up or not pressing_down) and down)
        or ((pressing_down or not pressing_up) and up)

    if (condx or condy) then
        local scene = JM.SceneManager.scene
        local vpadaxis = scene and scene.__param__.vpadaxis
        if vpadaxis then
            if condx then
                vpadaxis(self.text == "left" and "leftx" or "rightx", dirx)
            end
            if condy then
                vpadaxis(self.text == "left" and "lefty" or "righty", diry)
            end
        end
    end
    ---
end

function Stick:mousemoved(x, y)
    if self.__mouse_pressed then
        return self:refresh_position(x, y)
        ---
        -- else
        --     if love.mouse.isDown(1) and self:check_dpad_collision(x, y) then
        --         return self:mousepressed(x, y, 1, false)
        --     end
    end
end

function Stick:touchmoved(id, x, y)
    local __id = self.__touch_pressed
    if not __id or __id ~= id then return end
    return self:refresh_position(x, y)
end

function Stick:update(dt)
    Component.update(self, dt)

    -- local mx, my = lmouse.getPosition()

    -- if self:touch_is_active() then
    --     mx, my = ltouch.getPosition(self.__touch_pressed)
    -- elseif self.__touch_pressed then
    --     self:release()
    -- end

    if self.__touch_pressed and not self:touch_is_active() then
        self:release()
    end

    if self.__mouse_pressed and not lmouse.isDown(1) then
        self:release()
    end
end

function Stick:draw_dpad()
    local list = self.dpad_list
    if not list then return false end

    for i = 1, #list do
        local obj = list[i]
        obj:draw()
    end
end

function Stick:__custom_draw__()
    local opacity = self.opacity
    local radius = self.radius
    local x, y, w, h = self.x, self.y, self.w, self.h

    lgx.setColor(0, 0, 0, 0.4 * opacity)
    lgx.circle("fill", x + w * 0.5, y + h * 0.5, radius)
    lgx.setColor(1, 1, 1, opacity)
    lgx.circle("line", x + w * 0.5, y + h * 0.5, radius)
end

function Stick:draw()
    if not self.is_visible then return end
    Component.draw(self)

    local cx, cy = self.cx, self.cy
    local opacity = self.opacity
    local radius = self.radius

    lgx.setColor(1, 1, 1, opacity)
    lgx.circle("fill", cx, cy, radius * 0.7)
    lgx.setColor(.3, .3, .3, .2)
    local rm = radius * 0.7 * 0.6
    lgx.circle("fill", cx, cy, rm)

    lgx.setColor(0, 0, 0, 0.4 * opacity)
    lgx.circle("fill", cx - rm - 3, cy, 4)
    lgx.circle("fill", cx, cy - rm - 3, 4)
    lgx.circle("fill", cx + rm + 3, cy, 4)
    lgx.circle("fill", cx, cy + rm + 3, 4)

    -- love.graphics.setColor(1, 1, 0)
    -- love.graphics.rectangle("line", self.bounds_left, self.bounds_top, self.bounds_width, self.bounds_height)

    self:draw_dpad()

    -- font:push()
    -- font:set_font_size(32)
    -- ---@type string|number, string|number
    -- local dx, dy = self:get_direction()
    -- dx = string.format("%.2f", dx)
    -- dy = string.format("%.2f", dy)
    -- font:print("dx:" .. dx .. "  dy:" .. dy, 500, self.y - 100)
    -- local angle = string.format("%.2f", self:get_angle2())
    -- font:print(angle, self.x, self.y - 100)
    -- -- font:print(tostring(self:is_pressing("left")), self.x, self.y + self.h + 30)
    -- font:pop()

    -- local dx, dy = self:get_direction()
    -- lgx.setColor(1, 1, 0)
    -- lgx.print(string.format("%.2f %.2f", dx, dy), self.x, self.y - self.max_dist - 12)

    -- if self.time_press then
    --     lgx.print(string.format("%.2f", self.time_press), self.x, self.bottom + 3)
    -- end
end

return Stick
