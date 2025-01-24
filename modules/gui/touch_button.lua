---@type JM.GUI.Component
local Component = require(string.gsub(..., "touch_button", "component"))

---@type JM.Font.Font
local font -- = JM:get_font() --_G.JM_Font.current

local mouse_get_position = love.mouse.getPosition
local touch_getPosition = love.touch.getPosition
local love_setColor, love_circle = love.graphics.setColor, love.graphics.circle
local sqrt = math.sqrt

---@class JM.GUI.TouchButton : JM.GUI.Component
local Button = setmetatable({}, Component)
Button.__index = Button

---@return JM.GUI.TouchButton
function Button:new(args)
    args = args or {}
    ---@class JM.GUI.TouchButton
    local obj = Component:new(args)
    setmetatable(obj, self)
    Button.__constructor__(obj, args)
    return obj
end

---@param new_font JM.Font.Font
function Button:set_font(new_font)
    font = new_font
end

function Button:get_font()
    return font
end

function Button:__constructor__(args)
    self.x = args.x or 0
    self.y = args.y or 0
    self.w = args.w or 64
    self.h = args.h or 64

    self.font_size = math.floor(self.h * 0.5)

    self.radius = args.radius or (self.w * 0.5)
    self.use_radius = args.use_radius

    self.opacity = args.opacity or 1
    self:set_color2(1, 1, 1, self.opacity)

    self.back_to_normal = true
    ---@type boolean|number
    self.time_press = self.time_press or false

    if not self.time_press then
        self:shrink()
    end

    self.update = Button.update
    self.draw = Component.draw
    self.is_pressed = Button.is_pressed
    self.is_pressing = Button.is_pressing
    self.rect = Component.rect
    self.touchpressed = Button.touchpressed
    self.touchreleased = Button.touchreleased
end

function Button:init()
    local color = self.color
    Button.__constructor__(self, {
        x = self.x,
        y = self.y,
        w = self.w,
        h = self.h,
        -- radius = self.radius,
        use_radius = self.use_radius,
        opacity = self.opacity,
        text = self.text,
    })
    self.color = color
    return self
end

function Button:set_opacity(opacity)
    self.opacity = opacity or 1

    local r, g, b, _ = unpack(self.color)
    self:set_color2(r, g, b, self.opacity)
end

function Button:__check_collision__(x, y)
    if not self.use_radius then
        return self:check_collision(x, y, 0, 0)
    end

    local dx = x - (self.x + self.w * 0.5)
    local dy = y - (self.y + self.h * 0.5)
    local dist = sqrt(dx ^ 2 + dy ^ 2)
    return dist <= self.radius
end

function Button:mousepressed(x, y, button, istouch, presses)
    local dx = x - (self.x + self.w * 0.5)
    local dy = y - (self.y + self.h * 0.5)
    local dist = sqrt(dx ^ 2 + dy ^ 2)

    if self.use_radius and dist <= self.radius or not self.use_radius then
        Component.mousepressed(self, x, y, button, istouch, presses)
        if self.__mouse_pressed then
            self:grow()
        end
    end
end

function Button:mousereleased(x, y, button, istouch, presses)
    local dx = x - (self.x + self.w * 0.5)
    local dy = y - (self.y + self.h * 0.5)
    local dist = sqrt(dx ^ 2 + dy ^ 2)

    if self.__mouse_pressed then
        self:shrink()
    end

    if self.use_radius and dist <= self.radius or not self.use_radius then
        Component.mousereleased(self, x, y, button, istouch, presses)
    end

    self.__mouse_pressed = false
    self.back_to_normal = true
    self.time_press = false
end

function Button:touchpressed(id, x, y, dx, dy, pressure)
    local distx = x - (self.x + self.w * 0.5)
    local disty = y - (self.y + self.h * 0.5)
    local dist = sqrt(distx ^ 2 + disty ^ 2)

    if self.use_radius and dist <= self.radius or not self.use_radius then
        Component.touchpressed(self, id, x, y, dx, dy, pressure)
        if self.__touch_pressed then
            self:grow()
        end
    end
end

function Button:touchreleased(id, x, y, dx, dy, pressure)
    if id ~= self.__touch_pressed then return end

    local distx = x - (self.x + self.w * 0.5)
    local disty = y - (self.y + self.h * 0.5)
    local dist = sqrt(distx ^ 2 + disty ^ 2)

    if self.__touch_pressed then
        self:shrink()
    end

    if self.use_radius and dist <= self.radius or not self.use_radius then
        Component.touchreleased(self, id, x, y, dx, dy, pressure)
    end

    self.__touch_pressed = false
    self.time_press = false
    self.back_to_normal = true
end

function Button:grow()
    self:set_effect_transform("sx", 1.15) --1.25
    self:set_effect_transform("sy", 1.15)
end

function Button:shrink()
    self:set_effect_transform("sx", 0.8)
    self:set_effect_transform("sy", 0.8)
end

function Button:is_pressed()
    return (self.__mouse_pressed or self.__touch_pressed)
        and self.time_press == 0.0
end

function Button:is_pressing()
    return self.__mouse_pressed or self.__touch_pressed
end

function Button:is_released()
    return self.__mouse_released or self.__touch_released
end

function Button:update(dt)
    Component.update(self, dt)

    local back_to_normal = self.back_to_normal

    if self.__mouse_pressed and back_to_normal then
        local mx, my = mouse_get_position()

        if not self:check_collision(mx, my, 0, 0) then
            self.__mouse_pressed = false
            self:shrink()
            self.time_press = false
        end
    end

    if self.__touch_pressed and back_to_normal then
        if not self:touch_is_active() then
            self.__touch_pressed = false
            self:shrink()
        else
            local tx, ty = touch_getPosition(self.__touch_pressed)

            if not self:check_collision(tx, ty, 0, 0) then
                self.__touch_pressed = false
                self:shrink()
                self.time_press = false
            end
        end
    end -- End touch pressed
end

-- function Button:__pos_draw__()
--     if not self.is_visible then return end
--     love_setColor(1, 1, 1, self.opacity)
--     love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
-- end

local white = { 1, 1, 1, 1 }

function Button:__custom_draw__()
    white[4] = self.opacity

    love_setColor(self.color)
    -- love.graphics.rectangle("line", self.x, self.y, self.w, self.h)

    local x, y, w, h = self.x, self.y, self.w, self.h

    if not self.use_radius then
        love.graphics.rectangle("line", x, y, w, h)
    else
        local px, py = (x + w * 0.5), (y + h * 0.5)

        do
            local r, g, b = unpack(self.color)
            love_setColor(r, g, b, self.opacity) --0.4
            love_circle("fill", px, py, self.radius)
        end

        love_setColor(white)
        love_circle("line", px, py, self.radius)
    end


    -- if self.font_obj then
    do
        font = font or JM:has_default_font()
        font:push()
        font:set_font_size(self.font_size)
        font:set_color(white)

        -- self.font_obj.__bounds.right = self.w + 40
        -- self.font_obj:draw(self.x - 20, self.y + self.h * 0.5 - (font.__font_size + 2) * 0.5, "center")

        font:printf(self.text, x, y + h * 0.5 - (font.__font_size) * 0.5, w, "center")

        -- font:printx(self.text, self.x - 20, self.y, self.w + 40, "center")
        font:pop()
    end
end

return Button
