---@type JM.GUI.Component
local Component = require(string.gsub(..., "stick", "component"))

local Utils = _G.JM_Utils

local math_abs, math_sin, math_cos = math.abs, math.sin, math.cos
local math_atan2, math_sqrt = math.atan2, math.sqrt
local lgx = love.graphics

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
end

function Stick:init()
    local w, h = love.graphics.getDimensions()
    return self:__constructor__ {
        is_mobile = self.is_mobile,
        bound_left = 0,
        bound_top = h * 0.25,
        bound_width = w * 0.25,
        bound_height = h * 0.75,
        opacity = self.opacity,
    }
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

function Stick:mousepressed(x, y, button, istouch, presses)
    if self.is_mobile then
        local r = Component.collision(x, y, 0, 0,
            self.bounds_left, self.bounds_top,
            self.bounds_width, self.bounds_height
        )

        if r then
            self:set_position(x - self.w / 2, y - self.h / 2)
        end
    end

    local dx = x - (self.half_x)
    local dy = y - (self.half_y)
    local dist = math_sqrt(dx ^ 2 + dy ^ 2)

    if dist <= self.radius then
        Component.mousepressed(self, x, y, button, istouch, presses)
        if self:is_pressed() then
            self:grow()
        end
    end
end

function Stick:mousereleased(x, y, button, istouch, presses)
    if self:is_pressed() then
        self:release()
    end
    Component.mousereleased(self, x, y, button, istouch, presses)
end

function Stick:touchpressed(id, x, y, dx, dy, pressure)
    if self.__touch_pressed then return false end

    if self.is_mobile then
        local r = Component.collision(x, y, 0, 0,
            self.bounds_left, self.bounds_top,
            self.bounds_width, self.bounds_height
        )

        if r then
            self:set_position(x - self.w / 2, y - self.h / 2)
        end
    end

    local distx = x - (self.x + self.w / 2)
    local disty = y - (self.y + self.h / 2)
    local dist = math.sqrt(distx ^ 2 + disty ^ 2)

    if dist <= self.radius then
        Component.touchpressed(self, id, x, y, dx, dy, pressure)
        if self:is_pressed() then self:grow() end
    end
end

function Stick:touchreleased(id, x, y, dx, dy, pressure)
    if id ~= self.__touch_pressed then return false end

    if self:is_pressed() then
        self:release()
    end
    Component.touchreleased(self, id, x, y, dx, dy, pressure)
end

function Stick:release()
    self:shrink()
    self:set_position(self.init_x, self.init_y)
    self.cx = self.half_x
    self.cy = self.half_y
    self.__mouse_pressed = false
    self.__touch_pressed = false
    self.angle = 0
    self.dist = 0
end

function Stick:is_pressed()
    return self.__mouse_pressed or self.__touch_pressed
end

---@param direction "left"|"right"|"up"|"down"
function Stick:is_pressing(direction, constraint, angle_limit)
    constraint = constraint or 0.1 --0.2
    angle_limit = angle_limit or 50

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
    if not self.angle or not self.dist
        or (self.cx == self.half_x and self.cy == self.half_y)
    then
        return 0, 0
    end

    local value = self.dist / self.max_dist

    return value * (math_cos(self.angle) > 0 and 1 or -1), value * (math_sin(self.angle) > 0 and 1 or -1)
end

function Stick:get_angle()
    return self.angle or 0
end

function Stick:get_angle2()
    local angle = self.angle or 0
    angle = angle * 180.0 / math.pi
    return angle
end

-- function Stick:touch_moved(id, x, y, dx, dy, pressure)
--     if id ~= self.__touch_pressed then return false end

--     local distx = x - self.half_x
--     local disty = y - self.half_y
--     local angle = math_atan2(disty, distx)
--     local dist = math_sqrt(dx ^ 2 + dy ^ 2)
--     dist = Utils:clamp(dist, 0, self.max_dist)

--     self.cx = self.half_x + dist * math_cos(angle)
--     self.cy = self.half_y + dist * math_sin(angle)

--     self.angle = angle
--     self.dist = dist
-- end

function Stick:set_opacity(value)
    self.opacity = value or self.opacity
end

function Stick:update(dt)
    Component.update(self, dt)

    local mx, my = love.mouse.getPosition()

    if self:touch_is_active() then
        mx, my = love.touch.getPosition(self.__touch_pressed)
    elseif self.__touch_pressed then
        self:release()
    end

    if self.__mouse_pressed and not love.mouse.isDown(1) then
        self:release()
    end

    if self:is_pressed() then
        local dx = mx - self.half_x
        local dy = my - self.half_y
        local angle = math_atan2(dy, dx)
        local dist = math_sqrt(dx ^ 2 + dy ^ 2)
        dist = Utils:clamp(dist, 0, self.max_dist)

        self.cx = self.half_x + dist * math_cos(angle)
        self.cy = self.half_y + dist * math_sin(angle)

        self.angle = angle
        self.dist = dist
    end
end

function Stick:__custom_draw__()
    lgx.setColor(0, 0, 0, 0.4 * self.opacity)
    lgx.circle("fill", self.x + self.w / 2, self.y + self.h / 2, self.radius)

    lgx.setColor(1, 1, 1, self.opacity)
    lgx.circle("line", self.x + self.w / 2, self.y + self.h / 2, self.radius)
end

function Stick:draw()
    if not self.is_visible then return end
    Component.draw(self)

    lgx.setColor(1, 1, 1, self.opacity)
    lgx.circle("fill", self.cx, self.cy, self.radius * 0.7)
    lgx.setColor(.3, .3, .3, .2)
    local rm = self.radius * 0.7 * 0.6
    lgx.circle("fill", self.cx, self.cy, rm)

    lgx.setColor(0, 0, 0, 0.4 * self.opacity)
    lgx.circle("fill", self.cx - rm - 3, self.cy, 4)
    lgx.circle("fill", self.cx, self.cy - rm - 3, 4)
    lgx.circle("fill", self.cx + rm + 3, self.cy, 4)
    lgx.circle("fill", self.cx, self.cy + rm + 3, 4)

    -- love.graphics.setColor(1, 1, 0)
    -- love.graphics.rectangle("line", self.bounds_left, self.bounds_top, self.bounds_width, self.bounds_height)

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
end

return Stick
