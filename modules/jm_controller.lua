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

--==========================================================================

---@class JM.Controller
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

    end

    self.state = state

    return true
end

return Controller
