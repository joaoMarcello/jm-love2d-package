---@type JM.GUI.Component
local Component = require(string.gsub(..., "touch_button", "component"))

local font = _G.JM_Font.current

local mouse_get_position = love.mouse.getPosition
local love_setColor, love_circle = love.graphics.setColor, love.graphics.circle

---@class JM.GUI.TouchButton : JM.GUI.Component
local Button = setmetatable({}, Component)
Button.__index = Button

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

    if args.text then
        font:push()
        font:set_color(self.color)
        self.font_obj = font:generate_phrase(args.text, self.x, self.y, self.x + self.w, "center")
        font:pop()
    end
end

function Button:mouse_pressed(x, y, button, istouch, presses)
    local dx = x - (self.x + self.w / 2)
    local dy = y - (self.y + self.h / 2)
    local dist = math.sqrt(dx ^ 2 + dy ^ 2)

    if self.use_radius and dist <= self.radius or not self.use_radius then
        Component.mouse_pressed(self, x, y, button, istouch, presses)
        if self:is_pressed() then
            self:grow()
        end
    end
end

function Button:mouse_released(x, y, button, istouch, presses)
    local dx = x - (self.x + self.w / 2)
    local dy = y - (self.y + self.h / 2)
    local dist = math.sqrt(dx ^ 2 + dy ^ 2)

    if self:is_pressed() then
        self:shrink()
    end

    if self.use_radius and dist <= self.radius then
        Component.mouse_released(self, x, y, button, istouch, presses)
    end

    self.__mouse_pressed = false
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
    return self.__mouse_pressed
end

function Button:update(dt)
    Component.update(self, dt)

    local mx, my = mouse_get_position()

    if self:check_collision(mx, my, 0, 0) then

    else
        if self:is_pressed() then
            self.__mouse_pressed = false
            self:shrink()
        end
    end
end

function Button:__custom_draw__()
    love_setColor(self.color)

    if not self.use_radius then
        love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
    else
        local px, py = self.x + self.w / 2, self.y + self.h / 2
        love_setColor(0, 0, 0, 0.4)
        love_circle("fill", px, py, self.radius)

        love_setColor(self.color)
        love_circle("line", px, py, self.radius)
        love_circle("line", px, py, self.radius + 1)
        -- love.graphics.circle("line", px, py, self.radius + 2)
    end

    if self.font_obj then
        font:push()
        font:set_font_size(self.font_size)
        self.font_obj.__bounds.right = self.x + self.w
        self.font_obj:draw(self.x, self.y + self.h / 2 - (font.__font_size + 2) / 2, "center")
        font:pop()
    end
end

-- function Button:draw()
--     Component.draw(self)
-- end

return Button
