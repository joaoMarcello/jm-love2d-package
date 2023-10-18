---@enum JM.Controller.Buttons
local Buttons = {
    stick_left = 1,
    stick_right = 2,
    stick_up = 3,
    stick_down = 4,
    dpad_left = 5,
    dpad_right = 6,
    dpad_up = 7,
    dpad_down = 8,
    A = 9,
    B = 10,
    X = 11,
    Y = 12,
    L = 13,
    L2 = 14,
    L3 = 15,
    R = 16,
    R2 = 17,
    R3 = 18,
    start = 19,
    select = 20,
}

local Keys = {
    [Buttons.dpad_left] = { 'left', 'a' },
    [Buttons.dpad_right] = { 'right', 'd' },
    [Buttons.dpad_down] = { 'down', 's' },
    [Buttons.dpad_up] = { 'up', 'w' },
    [Buttons.A] = { 'space', 'up', 'w' },
    [Buttons.X] = { 'e', 'q', 'f' },
    [Buttons.start] = { 'return' },
}
Keys[Buttons.B] = Keys[Buttons.A]
Keys[Buttons.Y] = Keys[Buttons.X]

---@enum JM.Controller.States
local States = {
    keyboard = 1,
    joystick = 2,
    touch = 3,
    mouse = 4,
    vpad = 5,
}

local keyboard_is_down = love.keyboard.isDown
local type = type

---@param self JM.Controller
---@param button JM.Controller.Buttons
local function pressing_key(self, button)
    local field = self.button_to_key[button]
    if not field then return nil end

    if type(field) == "string" then
        return keyboard_is_down(field)
    else
        return keyboard_is_down(field[1])
            or (field[2] and keyboard_is_down(field[2]))
            or (field[3] and keyboard_is_down(field[3]))
    end
end

---@param self JM.Controller
---@param button JM.Controller.Buttons
---@param key_pressed string
local function pressed_key(self, button, key_pressed)
    local field = self.button_to_key[button]
    if not field then return nil end

    if type(field) == "string" then
        return key_pressed == field
    else
        return key_pressed == field[1]
            or key_pressed == field[2]
            or key_pressed == field[3]
    end
end

---@param self JM.Controller
---@param button JM.Controller.Buttons
local function pressing_vpad(self, button, x, y, b, istouch, presses)
    if not self.vpad then return false end

    ---@type JM.GUI.VirtualStick | JM.GUI.TouchButton | any
    local pad_button = (button == Buttons.dpad_left or button == Buttons.dpad_right)
        and self.vpad.Stick

    pad_button = not pad_button and button == Buttons.A and self.vpad.A or pad_button
    if not pad_button then return false end

    if pad_button == self.vpad.Stick then
        return pad_button:is_pressing(button == Buttons.dpad_left and "left" or "right")
    elseif pad_button == self.vpad.A then

    end
end

---@param self JM.Controller
---@param button JM.Controller.Buttons
local function pressed_vpad(self, button, x, y, b, istouch, presses)
    if not self.vpad then return false end

    local bt = button == Buttons.A and self.vpad.A
    bt = not bt and button == Buttons.X and self.vpad.B or bt
    if not bt then return false end

    return bt:is_pressed()
end

---@param self JM.Controller
---@param button JM.Controller.Buttons
local function released_vpad(self, button)
    if not self.vpad then return false end
    local bt = button == Buttons.A and self.vpad.A
    bt = not bt and button == Buttons.X and self.vpad.B or bt
    if not bt then return false end

    return bt:is_released()
end

--==========================================================================

---@class JM.Controller
---@field vpad JM.GUI.VPad
local Controller = {
    Button = Buttons,
    State = States,
}
Controller.__index = Controller

---@return JM.Controller
function Controller:new(args)
    local obj = setmetatable({}, Controller)
    Controller.__constructor__(obj, args or {})
    return obj
end

function Controller:__constructor__(args)
    self.button_to_key = args.keys or Keys
    self:set_state(args.state or States.keyboard)
end

---@param state JM.Controller.States
function Controller:set_state(state)
    if self.state == state then
        return false
    end

    if state == States.keyboard then
        self.pressing = pressing_key
        self.pressed = pressed_key
        ---
    elseif state == States.joystick then
        self.pressed = function()

        end
    elseif state == States.touch then

    elseif state == States.vpad then
        self.pressing = pressing_vpad
        self.pressed = pressed_vpad
        self.released = released_vpad
    end

    self.state = state

    return true
end

---@param vpad JM.GUI.VPad
function Controller:set_vpad(vpad)
    self.vpad = vpad
end

return Controller
