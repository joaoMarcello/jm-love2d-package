---@type JM.GUI.Component
local Component = require(string.gsub(..., "touch_button", "component"))

local font = _G.JM_Font.current

local mouse_get_position = love.mouse.getPosition
local touch_getPosition = love.touch.getPosition
local love_setColor, love_circle = love.graphics.setColor, love.graphics.circle

---@class JM.GUI.TouchButton : JM.GUI.Component
local Button = setmetatable({}, Component)
Button.__index = Button

---@return JM.GUI.TouchButton
function Button:new(args)
    args = args or {}
    local obj = Component:new(args)
    setmetatable(obj, self)
    Button.__constructor__(obj, args)
    return obj
end

---@param new_font JM.Font.Font
function Button:set_font(new_font)
    font = new_font
end

function Button:__constructor__(args)
    self.x = args.x or 0
    self.y = args.y or 0
    self.w = args.w or 64
    self.h = args.h or 64

    self.font_size = math.floor(self.h * 0.5)

    self.radius = args.radius or (self.w / 2)
    self.use_radius = args.use_radius

    self.opacity = args.opacity or 1
    self:set_color2(nil, nil, nil, self.opacity)

    if args.text then
        font:push()
        font:set_color(self.color)
        self.font_obj = font:generate_phrase(args.text, self.x, self.y, self.x + self.w, "center")
        font:pop()
    end
end

function Button:set_opacity(opacity)
    self.opacity = opacity or 1
    self:set_color2(nil, nil, nil, self.opacity)
    if self.font_obj then
        font:push()
        font:set_color(self.color)
        self.font_obj = font:generate_phrase(self.font_obj.text, self.x, self.y, self.x + self.w, "center")
        font:pop()
    end
end

function Button:mousepressed(x, y, button, istouch, presses)
    local dx = x - (self.x + self.w / 2)
    local dy = y - (self.y + self.h / 2)
    local dist = math.sqrt(dx ^ 2 + dy ^ 2)

    if self.use_radius and dist <= self.radius or not self.use_radius then
        Component.mousepressed(self, x, y, button, istouch, presses)
        if self.__mouse_pressed then
            self:grow()
        end
    end
end

function Button:mousereleased(x, y, button, istouch, presses)
    local dx = x - (self.x + self.w / 2)
    local dy = y - (self.y + self.h / 2)
    local dist = math.sqrt(dx ^ 2 + dy ^ 2)

    if self.__mouse_pressed then
        self:shrink()
    end

    if self.use_radius and dist <= self.radius then
        Component.mousereleased(self, x, y, button, istouch, presses)
    end

    self.__mouse_pressed = false
end

function Button:touchpressed(id, x, y, dx, dy, pressure)
    local distx = x - (self.x + self.w / 2)
    local disty = y - (self.y + self.h / 2)
    local dist = math.sqrt(distx ^ 2 + disty ^ 2)

    if self.use_radius and dist <= self.radius or not self.use_radius then
        Component.touchpressed(self, id, x, y, dx, dy, pressure)
        if self.__touch_pressed then
            self:grow()
        end
    end
end

function Button:touchreleased(id, x, y, dx, dy, pressure)
    if id ~= self.__touch_pressed then return end

    local distx = x - (self.x + self.w / 2)
    local disty = y - (self.y + self.h / 2)
    local dist = math.sqrt(distx ^ 2 + disty ^ 2)

    if self.__touch_pressed then
        self:shrink()
    end

    if self.use_radius and dist <= self.radius or not self.use_radius then
        Component.touchreleased(self, id, x, y, dx, dy, pressure)
    end

    self.__touch_pressed = false
end

function Button:grow()
    self:set_effect_transform("sx", 1.25)
    self:set_effect_transform("sy", 1.25)
end

function Button:shrink()
    self:set_effect_transform("sx", 1)
    self:set_effect_transform("sy", 1)
end

function Button:is_pressed()
    return self.__mouse_pressed or self.__touch_pressed
end

function Button:is_released()
    return self.__mouse_released or self.__touch_released
end

function Button:update(dt)
    Component.update(self, dt)

    if self.__mouse_pressed then
        local mx, my = mouse_get_position()

        if not self:check_collision(mx, my, 0, 0) then
            self.__mouse_pressed = false
            self:shrink()
        end
    end

    if self.__touch_pressed then
        if not self:touch_is_active() then
            self.__touch_pressed = false
            self:shrink()
        else
            local tx, ty = touch_getPosition(self.__touch_pressed)

            if not self:check_collision(tx, ty, 0, 0) then
                self.__touch_pressed = false
                self:shrink()
            end
        end
    end -- End touch pressed
end

function Button:__custom_draw__()
    love_setColor(self.color)

    if not self.use_radius then
        love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
    else
        local px, py = self.x + self.w / 2, self.y + self.h / 2
        love_setColor(0, 0, 0, 0.4 * self.opacity)
        love_circle("fill", px, py, self.radius)

        love_setColor(self.color)
        love_circle("line", px, py, self.radius)
        -- love_circle("line", px, py, self.radius + 1)
        -- love.graphics.circle("line", px, py, self.radius + 2)
    end

    if self.font_obj then
        font:push()
        font:set_font_size(self.font_size)
        -- self.font_obj.__bounds.right = self.x + self.w
        self.font_obj.__bounds.right = self.w
        self.font_obj:draw(self.x, self.y + self.h / 2 - (font.__font_size + 2) / 2, "center")
        font:pop()
    end
end

-- function Button:draw()
--     Component.draw(self)
-- end

return Button
