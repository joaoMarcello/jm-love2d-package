---@type JM.GUI
local GUI = require(string.gsub(..., "jm_virtual_pad", "jm_gui"))
--_G.JM_Love2D_Package.GUI
local TouchButton = GUI.TouchButton
local VirtualStick = GUI.VirtualStick

local width, height = love.graphics.getDimensions()

local size = math.floor(height * 0.2)

--==========================================================================
local Bt_A = TouchButton:new {
    x = 32,
    y = 32,
    w = 128,
    h = 128,
    use_radius = true,
    text = "A",
    opacity = 0.5,
    on_focus = true,
}
--==========================================================================
local Bt_B = TouchButton:new {
    x = 32,
    y = 32,
    w = 128,
    h = 128,
    use_radius = true,
    text = "B",
    opacity = 0.5,
    on_focus = true,
}
--==========================================================================
local rect_rx = 20

---@param self JM.GUI.TouchButton
local bt_draw = function(self)
    local lgx = love.graphics
    local color = self.color
    lgx.setColor(color)
    lgx.rectangle("line", self.x, self.y, self.w, self.h, rect_rx, rect_rx)

    local font = self:get_font()
    font:push()
    font:set_color(color)
    font:set_font_size(self.h * 0.4)
    font:printf((self.text):upper(), self.x - 20, self.y + self.h * 0.5 - font.__font_size * 0.5, self.w + 40, "center")
    font:pop()
end

local Bt_Start = TouchButton:new {
    x = 32,
    y = 32,
    w = 128,
    h = 128,
    text = "start",
    opacity = 0.5,
    on_focus = true,
    draw = bt_draw,
}

local Bt_Select = TouchButton:new {
    x = 32,
    y = 32,
    w = 128,
    h = 128,
    text = "select",
    opacity = 0.5,
    on_focus = true,
    draw = bt_draw,
}
--==========================================================================
local stick = VirtualStick:new {
    on_focus = true,
    w = height / 4,
    is_mobile = true,
    bound_top = height * 0.25,
    bound_width = width / 4,
    bound_height = height * 0.75,
    opacity = 0.5,
}
stick:set_position(stick.max_dist, height - stick.h - 130, true)
--==========================================================================


---@class JM.GUI.VPad
local Pad = {
    A = Bt_A,
    [1] = Bt_A,
    B = Bt_B,
    [2] = Bt_B,
    Stick = stick,
    [3] = stick,
    Start = Bt_Start,
    [4] = Bt_Start,
    Select = Bt_Select,
    [5] = Bt_Select,
    N = 5
}

function Pad:mousepressed(x, y, button, istouch, presses)
    for i = 1, self.N do
        self[i]:mousepressed(x, y, button, istouch, presses)
    end
end

function Pad:mousereleased(x, y, button, istouch, presses)
    for i = 1, self.N do
        self[i]:mousereleased(x, y, button, istouch, presses)
    end
end

function Pad:touchpressed(id, x, y, dx, dy, pressure)
    for i = 1, self.N do
        self[i]:touchpressed(id, x, y, dx, dy, pressure)
    end
end

function Pad:touchreleased(id, x, y, dx, dy, pressure)
    for i = 1, self.N do
        self[i]:touchreleased(id, x, y, dx, dy, pressure)
    end
end

function Pad:set_button_size(value)
    value = value or (math.min(love.graphics.getDimensions()) * 0.2)
    Bt_A:set_dimensions(value, value)
    Bt_A:init()
    Bt_B:set_dimensions(value, value)
    Bt_B:init()
end

function Pad:fix_positions()
    local w, h = love.graphics.getDimensions()
    local min, max = math.min(w, h), math.max(w, h)
    local border_w = w * 0.03
    local space = 20

    Bt_A:set_position(w - border_w - Bt_A.w, h - border_w - Bt_A.h)
    Bt_B:set_position(Bt_A.x - Bt_B.w - space, Bt_A.y - Bt_B.h * 0.5)

    do
        local size = w * 0.1
        local space = space * 0.5
        rect_rx = (20 * size) / (975 * 0.1)

        Bt_Start:set_dimensions(size, size * 0.4)
        Bt_Select:set_dimensions(size, size * 0.4)

        Bt_Start:set_position(
            w * 0.5 - space - Bt_Start.w,
            h - (space * 2) - Bt_Start.h
        )

        Bt_Select:set_position(w * 0.5 + space, Bt_Start.y)
    end
end

function Pad:resize()
    self:set_button_size()
    self:fix_positions()
end

function Pad:update(dt)
    for i = 1, self.N do
        self[i]:update(dt)
    end
end

function Pad:draw()
    for i = 1, self.N do
        self[i]:draw()
    end
end

Pad:set_button_size()
Pad:fix_positions()

return Pad
