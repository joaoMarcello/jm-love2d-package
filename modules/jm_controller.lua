---@enum JM.Controller.Buttons
local Buttons = {
    ------- Axis -------
    left_stick_x = 0,
    right_stick_x = 1,
    left_stick_y = 2,
    right_stick_y = 3,
    L2 = 4,
    R2 = 5,
    --====================
    home = 6,
    stick_1_left = 7,
    stick_1_right = 8,
    stick_1_up = 9,
    stick_1_down = 10,
    dpad_left = 11,
    dpad_right = 12,
    dpad_up = 13,
    dpad_down = 14,
    A = 15,
    B = 16,
    X = 17,
    Y = 18,
    L = 19,
    L3 = 20,
    R = 21,
    R3 = 22,
    start = 23,
    select = 24,
}

local function default_joystick_map()
    return {
        [Buttons.home] = "guide",
        [Buttons.dpad_left] = "dpleft",
        [Buttons.dpad_right] = "dpright",
        [Buttons.dpad_up] = "dpup",
        [Buttons.dpad_down] = "dpdown",
        [Buttons.A] = "a",
        [Buttons.B] = "b",
        [Buttons.X] = "x",
        [Buttons.Y] = "y",
        [Buttons.L] = "leftshoulder",
        [Buttons.R] = "rightshoulder",
        [Buttons.L2] = "triggerleft",
        [Buttons.R2] = "triggerright",
        [Buttons.L3] = "leftstick",
        [Buttons.R3] = "rightstick",
        [Buttons.start] = "start",
        [Buttons.select] = "back",
        ---
        [Buttons.left_stick_x] = "leftx",
        [Buttons.left_stick_y] = "lefty",
        [Buttons.right_stick_x] = "rightx",
        [Buttons.right_stick_y] = "righty",
        ---
        [Buttons.stick_1_left] = "leftx",
        [Buttons.stick_1_right] = "leftx",
        [Buttons.stick_1_down] = "lefty",
        [Buttons.stick_1_up] = "lefty",
    }
end

---@param b JM.Controller.Buttons
local function is_axis(b)
    return b <= Buttons.R2
end

local function default_keymap()
    local k = {
        [Buttons.dpad_left] = { 'left', 'a' },
        [Buttons.dpad_right] = { 'right', 'd' },
        [Buttons.dpad_down] = { 'down', 's' },
        [Buttons.dpad_up] = { 'up', 'w' },
        [Buttons.A] = { 'space', 'up', 'w' },
        [Buttons.X] = { 'e', 'q', 'f' },
        [Buttons.start] = { 'return' },
    }
    k[Buttons.B] = k[Buttons.A]
    k[Buttons.Y] = k[Buttons.X]
    k[Buttons.stick_1_left] = k[Buttons.dpad_left]
    k[Buttons.stick_1_right] = k[Buttons.dpad_right]
    k[Buttons.stick_1_up] = k[Buttons.dpad_up]
    k[Buttons.stick_1_down] = k[Buttons.dpad_down]
    return k
end

---@enum JM.Controller.States
local States = {
    keyboard = 1,
    joystick = 2,
    touch = 3,
    mouse = 4,
    vpad = 5,
}

local keyboard_is_down = love.keyboard.isScancodeDown
local type = type

---@param self JM.Controller
---@param button JM.Controller.Buttons
local function pressing_key(self, button)
    local button_is_axis = is_axis(button)

    if self.state ~= States.keyboard then
        return button_is_axis and 0 or false
    end

    local field = self.button_to_key[button]
    if not field then
        return button_is_axis and 0 or false
    end

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
    local button_is_axis = is_axis(button)

    if self.state ~= States.keyboard then
        return button_is_axis and 0 or false
    end

    local field = self.button_to_key[button]
    if not field then
        return button_is_axis and 0 or false
    end

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
local function pressing_vpad(self, button)
    local button_is_axis = is_axis(button)

    if not self.vpad or self.state ~= States.vpad then
        return button_is_axis and 0 or false
    end

    ---@type JM.GUI.VirtualStick | JM.GUI.TouchButton | any
    local pad_button = (button == Buttons.dpad_left
            or button == Buttons.dpad_right)
        and self.vpad.Stick

    pad_button = not pad_button and button == Buttons.A and self.vpad.A or pad_button
    if not pad_button then return button_is_axis and 0 or false end

    if pad_button == self.vpad.Stick then
        return pad_button:is_pressing(button == Buttons.dpad_left and "left" or "right")
    elseif pad_button == self.vpad.A then

    end
end

---@param self JM.Controller
---@param button JM.Controller.Buttons
local function pressed_vpad(self, button)
    local button_is_axis = is_axis(button)

    if not self.vpad or self.state ~= States.vpad then
        return button_is_axis and 0 or false
    end

    local bt = button == Buttons.A and self.vpad.A
    bt = not bt and button == Buttons.X and self.vpad.B or bt

    if not bt then
        return button_is_axis and 0 or false
    end

    return bt:is_pressed()
end

---@param self JM.Controller
---@param button JM.Controller.Buttons
local function released_vpad(self, button)
    local button_is_axis = is_axis(button)

    if not self.vpad or self.state ~= States.vpad then
        return button_is_axis and 0 or false
    end

    local bt = button == Buttons.A and self.vpad.A
    bt = not bt and button == Buttons.X and self.vpad.B or bt

    if not bt then
        return button_is_axis and 0 or false
    end

    return bt:is_released()
end

---@param self JM.Controller
---@param button JM.Controller.Buttons
local function pressing_joystick(self, button)
    local button_is_axis = is_axis(button)

    if self.state ~= States.joystick then
        return button_is_axis and 0 or false
    end

    ---@type love.Joystick
    local joy = self.joystick

    if not joy or not joy:isConnected() then return false end

    local bt = self.button_string[button]
    if not bt then return button_is_axis and 0 or false end

    if button_is_axis then
        ---@diagnostic disable-next-line: param-type-mismatch
        return joy:getGamepadAxis(bt)
        ---
    elseif button == Buttons.stick_1_left then
        local r = joy:getGamepadAxis("leftx")
        return r < 0
    elseif button == Buttons.stick_1_right then
        return joy:getGamepadAxis("leftx") > 0
        ---
    elseif button == Buttons.stick_1_up then
        return joy:getGamepadAxis("lefty") < 0
        ---
    elseif button == Buttons.stick_1_down then
        return joy:getGamepadAxis("lefty") > 0
        ---
    else
        ---@diagnostic disable-next-line: param-type-mismatch
        return joy:isGamepadDown(bt)
    end
end

---@param self JM.Controller
---@param button JM.Controller.Buttons
local function pressed_joystick(self, button)

end

local dummy = function()

end
--==========================================================================

---@class JM.Controller
---@field vpad JM.GUI.VPad
---@field joystick love.Joystick | any
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
    self.button_to_key = args.keys or default_keymap()
    self.button_string = args.button_string or default_joystick_map()
    self:set_state(args.state or States.keyboard)
end

---@param state JM.Controller.States | any
function Controller:set_state(state)
    if self.state == state or not state then
        return false
    end

    if state == States.keyboard then
        self.pressing = pressing_key
        self.pressed = pressed_key
        self.released = pressed_key
        ---
    elseif state == States.joystick then
        self.pressed = pressed_joystick
        self.pressing = pressing_joystick
        self.released = dummy
        ---
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

---@param joystick love.Joystick
function Controller:set_joystick(joystick, force)
    if self.joystick and not force then
        return false
    end
    self.joystick = joystick
    return true
end

function Controller:remove_joystick()
    if self.joystick then
        self.joystick = false
        return true
    end
    return false
end

return Controller