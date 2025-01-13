---@type string
local path = ...

---@type JM.GUI.Component
local Component = require(path:gsub("button", "component"))

---@class JM.GUI.Button: JM.GUI.Component, JM.Template.Affectable
local Button = setmetatable({}, Component)
Button.__index = Button

---@return JM.GUI.Button
function Button:new(args)
    ---@class JM.GUI.Button
    local obj = Component:new(args)
    setmetatable(obj, self)

    Button.__constructor__(obj, args)

    return obj
end

function Button:__constructor__(args)
    self.type_obj = self.TYPE.button
    self.text = args and args.text or "button"

    self:set_color2(0.3, 0.8, 0.3, 1.0)

    self:on_event("mousepressed", function(x, y)
        self:set_color2(math.random(), math.random(), math.random(), 1)
    end)

    -- self:on_event("gained_focus", function()
    --     self:set_color2(0.3, 0.8, 0.3, 1.0)

    --     self.text = "<color, 1,0,0>on <color, 1,1,0><italic>focus</italic><color, 0, 0, 0> did you hear me. " ..
    --         math.random(150) --.. " eh assim mesmo que eu vou fazer porque eu sou eh desses tá ligado mano doido???"

    --     self.__pulse_eff = self.__pulse_eff or self:generate_effect("pulse", { range = 0.03, speed = 0.5 })
    --     self.__pulse_eff:apply(self, true)
    -- end)


    -- self:on_event("lose_focus", function()
    --     self:set_color2(0.3 * 0.5, 0.8 * 0.5, 0.3 * 0.5, 1.0)

    --     self.text = "button"

    --     self.__pulse_eff.__remove = true
    -- end)

    self:on_event("mousereleased", function()
        self:set_color2(math.random(), math.random(), math.random(), 1)
    end)

    -- self:on_event("keypressed", function()
    --     --self:set_color2(math.random(), math.random(), math.random(), 1)
    -- end)
end

function Button:init()
    Component.init(self)
end

function Button:__custom_draw__()
    local lgx = love.graphics
    local x, y, w, h = self:rect()
    lgx.setColor(self.color)
    lgx.rectangle("fill", x, y, w, h)


    lgx.setColor(0, 0, 0, 1)
    lgx.rectangle("line", x, y, w, h)

    local font = JM:get_font()
    font:printf(self.text,
        x,
        y + h * 0.5 - font.__font_size * 0.5,
        "center",
        w
    )

    -- love.graphics.setColor(0, 0, 0, 1)
    -- love.graphics.printf(self.text, self.x, self.y, self.w, "center")
end

function Button:__pos_draw__()
    -- love.graphics.setColor(0, 0, 0, 0.1)
    -- love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
end

return Button
