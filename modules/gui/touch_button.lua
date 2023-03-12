---@type JM.GUI.Component
local Component = require(string.gsub(..., "touch_button", "component"))

local font = _G.JM_Font.current

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

    self.radius = args.radius or (self.w / 2)
    self.use_radius = args.use_radius

    if args.text then
        font:push()
        font:set_color(self.color)
        self.fontObj = font:generate_phrase(args.text, self.x, self.y, self.x + self.w, "center")
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

    local mx, my = love.mouse.getPosition()
    if self:check_collision(mx, my, 0, 0) then

    else
        if self:is_pressed() then
            self.__mouse_pressed = false
            self:shrink()
        end
    end
end

function Button:__custom_draw__()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
    love.graphics.circle("line", self.x + self.w / 2, self.y + self.h / 2, self.radius)
    love.graphics.circle("line", self.x + self.w / 2, self.y + self.h / 2, self.radius + 1)
    love.graphics.circle("line", self.x + self.w / 2, self.y + self.h / 2, self.radius + 2)

    if self.fontObj then
        font:push()
        font:set_font_size(math.floor(self.h * 0.6))
        self.fontObj.__bounds.right = self.x + self.w
        self.fontObj:draw(self.x, self.y + self.h / 2 - (font.__font_size + 2) / 2, "center")
        font:pop()
    end
end

function Button:draw()
    Component.draw(self)
end

return Button
