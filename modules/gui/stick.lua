---@type JM.GUI.Component
local Component = require(string.gsub(..., "stick", "component"))

local font = _G.JM_Font.current

local Utils = _G.JM_Utils

---@class JM.GUI.VirtualStick : JM.GUI.Component
local Stick = setmetatable({}, Component)
Stick.__index = Stick

function Stick:new(args)
    args = args or {}
    args.x = 250
    args.y = 250
    args.w = 96 * 1.3
    args.h = 96 * 1.3

    local obj = Component:new(args)
    setmetatable(obj, self)
    Stick.__constructor__(obj, args)
    return obj
end

function Stick:__constructor__(args)
    self.radius = self.w / 2
    self.max_dist = self.radius * 1.2

    self.cx = self.x + self.w / 2
    self.cy = self.y + self.h / 2

    self.half_x = self.x + self.w / 2
    self.half_y = self.y + self.h / 2
end

function Stick:grow()
    self:set_effect_transform("sx", 1.2)
    self:set_effect_transform("sy", 1.2)
end

function Stick:shrink()
    self:set_effect_transform("sx", 1)
    self:set_effect_transform("sy", 1)
end

function Stick:mouse_pressed(x, y, button, istouch, presses)
    local dx = x - (self.half_x)
    local dy = y - (self.half_y)
    local dist = math.sqrt(dx ^ 2 + dy ^ 2)

    if dist <= self.radius then
        Component.mouse_pressed(self, x, y, button, istouch, presses)
        if self:is_pressed() then
            self:grow()
        end
    end
end

function Stick:mouse_released(x, y, button, istouch, presses)
    if self:is_pressed() then
        self:release()
    end
    Component.mouse_released(self, x, y, button, istouch, presses)
end

function Stick:release()
    self:shrink()
    self.cx = self.half_x
    self.cy = self.half_y
    self.__mouse_pressed = false
end

function Stick:is_pressed()
    return self.__mouse_pressed
end

function Stick:get_direction()
    if not self.angle or not self.dist
        or (self.cx == self.half_x and self.cy == self.half_y)
    then
        return 0, 0
    end

    local value = self.dist / self.max_dist

    return value * (math.cos(self.angle) > 0 and 1 or -1), value * (math.sin(self.angle) > 0 and 1 or -1)
end

function Stick:update(dt)
    Component.update(self, dt)

    local mx, my = love.mouse.getPosition()

    if self:is_pressed() and not love.mouse.isDown(1) then
        self:release()
    end

    if self:is_pressed() then
        local dx = mx - self.half_x
        local dy = my - self.half_y
        local angle = math.atan2(dy, dx)
        local dist = math.sqrt(dx ^ 2 + dy ^ 2)
        dist = Utils:clamp(dist, 0, self.max_dist)

        self.cx = self.half_x + dist * math.cos(angle)
        self.cy = self.half_y + dist * math.sin(angle)

        self.angle = angle
        self.dist = dist
    end
end

function Stick:__custom_draw__()
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.circle("fill", self.x + self.w / 2, self.y + self.h / 2, self.radius)
end

function Stick:draw()
    Component.draw(self)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
    love.graphics.circle("fill", self.cx, self.cy, self.radius * 0.7)
    love.graphics.setColor(.3, .3, .3, .3)
    love.graphics.circle("fill", self.cx, self.cy, self.radius * 0.7 * 0.6)

    font:push()
    font:set_font_size(32)
    ---@type string|number, string|number
    local dx, dy = self:get_direction()
    dx = string.format("%.2f", dx)
    dy = string.format("%.2f", dy)
    font:print("dx:" .. dx .. "  dy:" .. dy, 500, self.y - 100)
    font:pop()
end

return Stick
