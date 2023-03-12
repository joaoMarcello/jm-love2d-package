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

function Button:__constructor__(args)
    self.x = args.x or 0
    self.y = args.y or 0
    self.w = args.w or 64
    self.h = args.h or 64

    self.radius = args.radius or 32

    self.fontObj = font:generate_phrase(args.text or "A", self.x, self.y, self.x + self.w, "center")

    -- self:apply_effect("pulse")
end

function Button:mouse_pressed(x, y, button, istouch, presses)
    local dx = x - (self.x + self.w / 2)
    local dy = y - (self.y + self.h / 2)
    local dist = math.sqrt(dx ^ 2 + dy ^ 2)
    if dist > self.radius then return false end
    Component.mouse_pressed(self, x, y, button, istouch, presses)
end

function Button:update(dt)
    Component.update(self, dt)
end

function Button:__custom_draw__()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
    love.graphics.circle("line", self.x + self.w / 2, self.y + self.h / 2, self.radius)

    font:push()
    font:set_font_size(math.floor(self.h * 0.6))
    self.fontObj:draw(self.x, self.y + self.h / 2 - font.__font_size / 2, "center")
    font:pop()
end

function Button:draw()
    Component.draw(self)
end

return Button
