---@type JM.GUI
local GUI = require(string.gsub(..., "jm_virtual_pad", "jm_gui"))
--_G.JM_Love2D_Package.GUI
local TouchButton = GUI.TouchButton
local VirtualStick = GUI.VirtualStick

local width, height = love.graphics.getDimensions()

local size = math.floor(height / 5)

--==========================================================================
local Bt_A = TouchButton:new {
    x = 32,
    y = 32,
    w = size,
    h = size,
    use_radius = true,
    text = "A",
    opacity = 0.5,
    on_focus = true,
}
Bt_A:set_position(width - 30 - size, height - 30 - size)

--==========================================================================
local Bt_B = TouchButton:new {
    x = 32,
    y = 32,
    w = size,
    h = size,
    use_radius = true,
    text = "B",
    opacity = 0.5,
    on_focus = true,
}
Bt_B:set_position(Bt_A.x - size - 20, Bt_A.y - size * 0.5 - 20)

--==========================================================================
local stick = VirtualStick:new {
    on_focus = true,
    w = height / 4,
    is_mobile = true,
    bound_top = height * 0.25,
    bound_width = 1366 / 4,
    bound_height = height * 0.75,
    opacity = 0.5,
}
stick:set_position(stick.max_dist, height - stick.h - 50, true)
--==========================================================================


---@class JM.GUI.VPad
local Pad = {
    A = Bt_A,
    [1] = Bt_A,
    B = Bt_B,
    [2] = Bt_B,
    Stick = stick,
    [3] = stick,
    N = 3
}

function Pad:mousepressed(x, y, button, istouch, presses)
    for i = 1, self.N do
        self[i]:mouse_pressed(x, y, button, istouch, presses)
    end
end

function Pad:mousereleased(x, y, button, istouch, presses)
    for i = 1, self.N do
        self[i]:mouse_released(x, y, button, istouch, presses)
    end
end

function Pad:touchpressed(id, x, y, dx, dy, pressure)
    for i = 1, self.N do
        self[i]:touch_pressed(id, x, y, dx, dy, pressure)
    end
end

function Pad:touchreleased(id, x, y, dx, dy, pressure)
    for i = 1, self.N do
        self[i]:touch_released(id, x, y, dx, dy, pressure)
    end
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

return Pad
