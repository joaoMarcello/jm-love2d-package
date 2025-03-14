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
    stick_2_left = 25,
    stick_2_right = 26,
    stick_2_up = 27,
    stick_2_down = 28,
}

---@alias JM.Controller.ButtonsNames "left_stick_x"|"right_stick_x"|"left_stick_y"|"right_stick_y"|"L2"|"R2"|"home"|"stick_1_left"|"stick_1_right"|"stick_1_up"|"stick_1_down"|"dpad_left"|"dpad_right"|"dpad_up"|"dpad_down"|"A"|"B"|"X"|"Y"|"L"|"L3"|"R"|"R3"|"start"|"select"|"stick_2_left"|"stick_2_right"|"stick_2_up"|"stick_2_down"

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

---@class JM.Controller.ButtonParam
local ButtonParam = {}
ButtonParam.__index = ButtonParam

---@return JM.Controller.ButtonParam
function ButtonParam:new()
    local o = setmetatable({}, ButtonParam)
    ButtonParam.__constructor__(o)
    return o
end

function ButtonParam:__constructor__()
    self.time_press_interval = 0.0
    self.interval_value = 0.25

    self.press_count = 0
    self.time_press_count = 0.0
    self.value_reset_press_count = 0.2

    self.time_pressing = 0.0

    self.tilt_count = 0
    self.time_reset_tilt = 0.0
    self.tilt_min_pressing_time = 0.5
    self.value_reset_tilt_count = 0.2
end

--==========================================================================

local keyboard_is_down = love.keyboard.isScancodeDown
local type, abs = type, math.abs

---@param self JM.Controller
---@param button JM.Controller.Buttons
local function pressing_key(self, button)
    local button_is_axis = is_axis(button)

    do
        local prev = self.prev_state
        if prev then
            local temp = self.state
            self.prev_state = nil
            self:set_state(prev)

            local r = self:pressing(button)

            self:set_state(temp)
            self.prev_state = prev
            return r
        end
    end

    if self.state ~= States.keyboard or not self.is_keyboard_owner then
        return button_is_axis and 0 or false
    end

    if button_is_axis
        and button ~= Buttons.L2
        and button ~= Buttons.R2
    then
        if button == Buttons.left_stick_x then
            if self:pressing(Buttons.stick_1_right) then return 1 end
            if self:pressing(Buttons.stick_1_left) then return -1 end
            ---
        elseif button == Buttons.left_stick_y then
            if self:pressing(Buttons.stick_1_down) then return 1 end
            if self:pressing(Buttons.stick_1_up) then return -1 end
            ---
        elseif button == Buttons.right_stick_x then
            if self:pressing(Buttons.stick_2_right) then return 1 end
            if self:pressing(Buttons.stick_2_left) then return -1 end
            ---
        elseif button == Buttons.right_stick_y then
            if self:pressing(Buttons.stick_2_down) then return 1 end
            if self:pressing(Buttons.stick_2_up) then return -1 end
            ---
        end

        return 0
    end

    local field = self.button_to_key[button]

    if not field then
        return button_is_axis and 0 or false
    end

    local r
    if type(field) == "string" then
        r = keyboard_is_down(field)
    else
        r = keyboard_is_down(field[1])
            or (field[2] and keyboard_is_down(field[2]))
            or (field[3] and keyboard_is_down(field[3]))
    end

    if button_is_axis then
        return r and 1 or 0
    end

    return r
end

---@param self JM.Controller
---@param button JM.Controller.Buttons
---@param key string
local function pressed_key(self, button, key)
    local button_is_axis = is_axis(button)

    if self.state ~= States.keyboard or not self.is_keyboard_owner then
        return button_is_axis and 0 or false
    end

    if button_is_axis
        and button ~= Buttons.L2
        and button ~= Buttons.R2
    then
        if button == Buttons.left_stick_x then
            if self:pressed(Buttons.stick_1_right, key) then return 1 end
            if self:pressed(Buttons.stick_1_left, key) then return -1 end
            ---
        elseif button == Buttons.left_stick_y then
            if self:pressed(Buttons.stick_1_down, key) then return 1 end
            if self:pressed(Buttons.stick_1_up, key) then return -1 end
            ---
        elseif button == Buttons.right_stick_x then
            if self:pressed(Buttons.stick_2_right, key) then return 1 end
            if self:pressed(Buttons.stick_2_left, key) then return -1 end
            ---
        elseif button == Buttons.right_stick_y then
            if self:pressed(Buttons.stick_2_down, key) then return 1 end
            if self:pressed(Buttons.stick_2_up, key) then return -1 end
            ---
        end

        return 0
    end

    local field = self.button_to_key[button]

    if not field then
        return button_is_axis and 0 or false
    end

    local r
    if type(field) == "string" then
        r = key == field
    else
        r = key == field[1]
            or key == field[2]
            or key == field[3]
    end

    if button_is_axis then
        return r and 1 or 0
    end

    return r
end

---@param self JM.Controller
---@param button JM.Controller.Buttons
local function pressing_vpad(self, button)
    -- do
    --     local prev = self.prev_state
    --     if prev and prev == States.vpad then
    --         local temp = self.state
    --         self.prev_state = nil
    --         self:set_state(States.vpad)

    --         local r = self:pressing(button)

    --         self:set_state(temp)
    --         self.prev_state = prev
    --         return r
    --     end
    -- end

    local button_is_axis = is_axis(button)

    if not self.vpad or self.state ~= States.vpad then
        return button_is_axis and 0 or false
    end

    local vpad = self.vpad

    ---@type JM.GUI.VirtualStick | JM.GUI.TouchButton | any
    local bt = nil

    if vpad.Stick.on_focus then
        if button == Buttons.stick_1_right then
            local r = self:pressing(Buttons.left_stick_x)
            return r >= 1 and true or false
        elseif button == Buttons.stick_1_left then
            local r = self:pressing(Buttons.left_stick_x)
            return r <= -1 and true or false
        end

        if false and (not vpad.Dpad_left.on_focus
                and not vpad.Dpad_right.on_focus)
        then
            ---@type JM.GUI.VirtualStick | JM.GUI.TouchButton | any
            bt = button >= 11 and button <= 14 and vpad.Stick
        end

        if button == Buttons.left_stick_x
            or button == Buttons.left_stick_y
        then
            bt = vpad.Stick
        end
    end

    bt = (not bt and button == Buttons.A and vpad.A) or bt

    if not bt and button == Buttons.X then
        local X = vpad.X
        if X.on_focus and X.is_visible then
            bt = vpad.B
        else
            bt = X
        end
    end

    if not bt and button == Buttons.Y then
        local Y = vpad.Y
        if Y.on_focus and Y.is_visible then
            bt = Y
        end
    end

    bt = (not bt and button == Buttons.B and vpad.B) or bt

    if not bt then
        bt = button == Buttons.dpad_left and vpad.Dpad_left
        bt = not bt and button == Buttons.dpad_right and vpad.Dpad_right or bt
    end

    if not bt then
        bt = button == Buttons.dpad_up and vpad.Dpad_up
        bt = not bt and button == Buttons.dpad_down and vpad.Dpad_down or bt
    end

    if not bt then
        bt = button == Buttons.L and vpad.L
        bt = not bt and button == Buttons.R and vpad.R or bt
    end

    if not bt then
        bt = button == Buttons.start and vpad.Start
        bt = not bt and button == Buttons.select and vpad.Select or bt
        bt = not bt and button == Buttons.home and vpad.Home or bt
    end

    if not bt then return button_is_axis and 0 or false end

    if bt == vpad.Stick then
        ---
        if button == Buttons.dpad_left then
            return bt:is_pressing("left")
            ---
        elseif button == Buttons.dpad_right then
            return bt:is_pressing("right")
            ---
        elseif button == Buttons.dpad_up then
            return bt:is_pressing("up")
            ---
        elseif button == Buttons.dpad_down then
            return bt:is_pressing("down")
            ---
        elseif button == Buttons.left_stick_x then
            local r = bt:is_pressing("right")
            r = (not r) and bt:is_pressing("left") or r

            if r then
                local dx = bt:get_direction()
                return dx
            else
                return 0
            end
            ---
        elseif button == Buttons.left_stick_y then
            local r = bt:is_pressing("up")
            r = (not r) and bt:is_pressing("down") or r

            if r then
                local _, dy = bt:get_direction()
                return dy
            else
                return 0
            end
        end
        ---
    else
        return bt:is_pressing()
        ---
    end
end

---@param self JM.Controller
---@param button JM.Controller.Buttons
local function pressed_vpad(self, button)
    local button_is_axis = is_axis(button)

    local vpad = self.vpad

    if not vpad or self.state ~= States.vpad then
        return button_is_axis and 0 or false
    end

    ---@type JM.GUI.VirtualStick | JM.GUI.TouchButton | any
    local bt = nil

    -- if button == Buttons.stick_1_right then
    --     local r = self:pressing(Buttons.left_stick_x)
    --     return r >= 1 and true or false
    -- elseif button == Buttons.stick_1_left then
    --     local r = self:pressing(Buttons.left_stick_x)
    --     return r <= -1 and true or false
    -- end

    if false and (not vpad.Dpad_left.on_focus
            and not vpad.Dpad_right.on_focus)
    then
        bt = button >= 11 and button <= 14 and vpad.Stick
        ---
    end

    if button == Buttons.left_stick_x
        or button == Buttons.left_stick_y
    then
        bt = vpad.Stick
    end

    bt = not bt and button == Buttons.A and vpad.A or bt

    if not bt and button == Buttons.X then
        local X = vpad.X
        if X.on_focus and X.is_visible then
            bt = vpad.B
        else
            bt = X
        end
    end

    if not bt and button == Buttons.Y then
        local Y = vpad.Y
        if Y.on_focus and Y.is_visible then
            bt = Y
        end
    end

    bt = not bt and button == Buttons.B and vpad.B or bt

    if not bt then
        bt = button == Buttons.dpad_left and vpad.Dpad_left
        bt = not bt and button == Buttons.dpad_right and vpad.Dpad_right or bt
    end
    if not bt then
        bt = button == Buttons.dpad_up and vpad.Dpad_up.on_focus and vpad.Dpad_up
        bt = not bt and button == Buttons.dpad_down and vpad.Dpad_down.on_focus and vpad.Dpad_down or bt
    end

    if not bt then
        bt = button == Buttons.L and vpad.L
        bt = not bt and button == Buttons.R and vpad.R or bt
        bt = not bt and button == Buttons.home and vpad.Home or bt
    end

    if not bt then
        bt = button == Buttons.start and vpad.Start
        bt = not bt and button == Buttons.select and vpad.Select or bt
    end

    if not bt then
        return button_is_axis and 0 or false
    end

    if bt == vpad.Stick then
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
    do
        local prev = self.prev_state
        if prev and prev == States.joystick then
            local temp = self.state
            self.prev_state = nil
            self:set_state(States.joystick)

            local r = self:pressing(button)

            self:set_state(temp)
            self.prev_state = prev
            return r
        end
    end

    local button_is_axis = is_axis(button)

    if self.state ~= States.joystick then
        return button_is_axis and 0 or false
    end

    ---@type love.Joystick
    local joy = self.joystick

    if not joy or not joy:isConnected() then
        return button_is_axis and 0 or false
    end

    local bt = self.button_string[button]
    if not bt then return button_is_axis and 0 or false end

    if button_is_axis then
        -- if self.time_button[button] ~= 0.0 and not force then return 0 end

        ---@diagnostic disable-next-line: param-type-mismatch
        local r = joy:getGamepadAxis(bt)

        -- if math.abs(r) > 0 and not force then
        --     self.time_button[button] = self.time_delay_button[button]
        -- end

        return r
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

local function released_joystick(self, button, joy)

end

---@param self JM.Controller
---@param button JM.Controller.Buttons
---@param joy love.Joystick
---@param bt love.GamepadButton|love.GamepadAxis
---@param value number|any
local function pressed_joystick(self, button, joy, bt, value)
    local button_is_axis = is_axis(button)
    local gamepad_bt = self.virtual_to_gamepad[button]

    if self.state ~= States.joystick or not gamepad_bt
        or self.joystick ~= joy or bt ~= gamepad_bt
    then
        return button_is_axis and 0 or false
    end

    if button_is_axis then
        if not value then
            ---@diagnostic disable-next-line: param-type-mismatch
            return self.joystick:getAxis(gamepad_bt)
        elseif abs(value) > 0.5 then
            return value
        else
            return 0
        end
    elseif button == Buttons.stick_1_left then
        return value < 0.5
    elseif button == Buttons.stick_1_right then
        return value > 0.5
    elseif button == Buttons.stick_1_up then
        return value < 0.5
    elseif button == Buttons.stick_1_down then
        return value > 0.5
    else
        return bt == gamepad_bt
    end
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
    self.is_keyboard_owner = false
    self.prev_state = false

    self.virtual_to_gamepad = {
        [Buttons.A] = 'a',
        [Buttons.B] = 'b',
        [Buttons.X] = 'x',
        [Buttons.Y] = 'y',
        [Buttons.L] = 'leftshoulder',
        [Buttons.R] = 'rightshoulder',
        [Buttons.L3] = 'leftstick',
        [Buttons.R3] = 'rightstick',
        [Buttons.dpad_up] = 'dpup',
        [Buttons.dpad_down] = 'dpdown',
        [Buttons.dpad_left] = 'dpleft',
        [Buttons.dpad_right] = 'dpright',
        [Buttons.select] = 'back',
        [Buttons.start] = 'start',
        [Buttons.home] = 'guide',
        ---
        [Buttons.left_stick_x] = 'leftx',
        [Buttons.left_stick_y] = 'lefty',
        [Buttons.right_stick_x] = 'rightx',
        [Buttons.right_stick_y] = 'righty',
        [Buttons.L2] = 'triggerleft',
        [Buttons.R2] = 'triggerright',
    }

    self.time_button = {}
    self.time_delay_button = {}
    for i = 0, 28 do
        self.time_button[i] = 0
        self.time_delay_button[i] = 0
    end

    self.button_param = {}
    for id = 0, 28 do
        self.button_param[id] = ButtonParam:new()
    end

    self.key_to_button = {}

    self:set_state(args.state or States.keyboard)
end

---@param state JM.Controller.States | any
function Controller:set_state(state)
    if self.state == state or not state then
        return false
    end

    if state == States.keyboard then
        self.is_keyboard_owner = true
        self.pressing = pressing_key
        self.pressed = pressed_key
        self.released = pressed_key
        ---
    elseif state == States.joystick then
        self.pressed = pressed_joystick
        self.pressing = pressing_joystick
        self.released = pressed_joystick
        ---
    elseif state == States.touch then
        ---
    elseif state == States.vpad then
        self.pressing = pressing_vpad
        self.pressed = pressed_vpad
        self.released = released_vpad
    end

    self.state = state

    return true
end

function Controller:switch_to_keyboard()
    return self:set_state(States.keyboard)
end

function Controller:switch_to_joystick()
    return self:set_state(States.joystick)
end

function Controller:switch_to_vpad()
    if not self.vpad then return false end
    self:set_state(States.vpad)
    return true
end

function Controller:is_on_keyboard_mode()
    return self.state == States.keyboard
end

function Controller:is_on_joystick_mode()
    local joystick = States.joystick
    do
        local prev_state = self.prev_state
        if prev_state == joystick then return true end
    end
    return self.state == joystick
end

function Controller:is_on_vpad_mode()
    local vpad = States.vpad
    do
        local prev_state = self.prev_state
        if prev_state == vpad then return true end
    end

    return self.state == vpad
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

-- ---@param value boolean?
-- function Controller:set_temp_keyboard_mode(value)
--     if value then
--         if not self.prev_state then
--             self.on_temp_keyboard_mode = value
--             self.prev_state = self.state
--         end
--     elseif self.prev_state then
--         self.on_temp_keyboard_mode = false
--         self:set_state(self.prev_state)
--         self.prev_state = nil
--     end
-- end

function Controller:capture_state()
    if not self.prev_state then
        self.on_temp_keyboard_mode = true
        self.prev_state = self.state
    end
end

function Controller:restaure_state()
    local prev = self.prev_state
    if prev then
        self.on_temp_keyboard_mode = false
        self:set_state(prev)
        self.prev_state = nil
    end
end

---@param bt JM.Controller.Buttons
function Controller:pressing_time(bt)
    if self.state ~= States.joystick or not self.joystick or not self.joystick:isConnected() then
        return false
    end

    if self.time_button[bt] ~= 0 then return false end

    local r = self:pressing(bt)
    if type(r) == "number" and math.abs(r) > 0 then
        self.time_button[bt] = self.time_delay_button[bt]
    end

    return r --self:pressing(bt)
end

---@param bt JM.Controller.Buttons|JM.Controller.ButtonsNames
---@param speed number?
function Controller:pressing_interval(bt, speed)
    if type(bt) == "string" then
        return self:pressing_interval(Buttons[bt])
    end

    local button_is_axis = is_axis(bt)

    ---@type JM.Controller.ButtonParam
    local param = self.button_param[bt]

    if not param
        or param.time_press_interval ~= 0
    then
        return button_is_axis and 0 or false
    end

    local r = self:pressing(bt)
    if (type(r) == "number" and math.abs(r) > 0)
        or (not button_is_axis and r)
    then
        if param.time_pressing == 0 then
            param.time_press_interval = 0.6
        else
            param.time_press_interval = speed or param.interval_value
        end
    end

    if param.time_pressing == 0.0 then
        return button_is_axis and 0 or false
    end

    return r
end

---@param bt JM.Controller.Buttons
function Controller:pressed_count(bt)
    ---@type JM.Controller.ButtonParam
    local param = self.button_param[bt]
    return param and param.press_count or 0
end

---@param bt JM.Controller.Buttons
function Controller:tilt_button_count(bt)
    ---@type JM.Controller.ButtonParam
    local param = self.button_param[bt]
    return param and param.tilt_count or 0
end

function Controller:tilt_count_reset(bt)
    ---@type JM.Controller.ButtonParam
    local param = self.button_param[bt]
    if param then
        param.time_reset_tilt = 0.0
        param.tilt_count = 0.0
    end
end

---@return JM.Controller.Buttons|nil
function Controller:keyboard_to_button(key)
    do
        local r = self.key_to_button[key]
        if r then
            if r < 0 then return end
            return r
        end
    end

    for id = 0, 28 do
        local t = self.button_to_key[id]

        if t then
            if type(t) == "table" then
                for i = 1, #t do
                    if t[i] == key then
                        self.key_to_button[key] = id
                        return id
                    end
                end
            else
                if t == key then
                    self.key_to_button[key] = id
                    return id
                end
            end
        end
    end

    self.key_to_button[key] = -1
end

function Controller:keypressed(key)
    local bt = self:keyboard_to_button(key)

    if bt then
        ---@type JM.Controller.ButtonParam
        local param = self.button_param[bt]
        param.press_count = param.press_count + 1
        param.time_press_count = param.value_reset_press_count
    end
end

function Controller:keyreleased(key)
    local bt = self:keyboard_to_button(key)
    if bt then
        ---@type JM.Controller.ButtonParam
        local param = self.button_param[bt]

        if param.time_pressing <= param.value_reset_tilt_count then
            param.tilt_count = param.tilt_count + 1
            param.time_reset_tilt = param.value_reset_tilt_count
        else
            param.tilt_count = 0
            param.time_reset_tilt = 0.0
        end
    end
end

---@param button string
function Controller:vpadreleased(button)
    local bt
    if button == 'a' then
        bt = Buttons.A
    elseif button == 'x' then
        bt = Buttons.X
    elseif button == 'y' then
        bt = Buttons.Y
    elseif button == 'b' then
        bt = Buttons.B
    elseif button == 'dpright' then
        bt = Buttons.dpad_right
    elseif button == 'dpleft' then
        bt = Buttons.dpad_left
    elseif button == 'dpup' then
        bt = Buttons.dpad_up
    elseif button == 'dpdown' then
        bt = Buttons.dpad_down
    elseif button == 'leftshoulder' then
        bt = Buttons.L
    elseif button == 'rightshoulder' then
        bt = Buttons.R
    elseif button == 'start' then
        bt = Buttons.start
    elseif button == 'back' then
        bt = Buttons.select
    elseif button == 'guide' then
        bt = Buttons.home
    end
    if bt then
        local param = self.button_param[bt] --[[@as JM.Controller.ButtonParam]]
        if param then
            param.time_pressing = 0.0
            param.time_press_interval = 0.0
        end
    end
end

function Controller:update(dt)
    local i = 0
    while i <= Buttons.R2 do
        local r = self:pressing(i)
        if type(r) == "number" and math.abs(r) == 0 then
            self.time_button[i] = 0.0
        end

        if self.time_button[i] > 0.0 then
            self.time_button[i] = self.time_button[i] - dt
            if self.time_button[i] < 0.0 then
                self.time_button[i] = 0.0
            end
        end
        i = i + 1
    end

    local temp = self.state

    -- for button_name, id in next, Buttons do
    for id = 0, 28 do
        local button_is_axis = is_axis(id)
        local r = self:pressing(id)

        local button_is_pressed = (type(r) == "number" and abs(r) ~= 0)
            or (not button_is_axis and r)

        ---@type JM.Controller.ButtonParam
        local param = self.button_param[id]

        --===============================================================
        if button_is_pressed then
            param.time_pressing = param.time_pressing + dt
        else
            param.time_pressing = 0.0
        end
        --===============================================================
        if not button_is_pressed then
            param.time_press_interval = 0.0
        end

        if param.time_press_interval > 0.0 then
            param.time_press_interval = param.time_press_interval - dt

            if param.time_press_interval < 0.0 then
                param.time_press_interval = 0.0
            end
        end
        --===============================================================
        if param.time_press_count ~= 0.0 then
            param.time_press_count = param.time_press_count - dt

            if param.time_press_count < 0.0 then
                param.time_press_count = 0
                param.press_count = 0
            end
        end
        --===============================================================
        if param.time_reset_tilt ~= 0 then
            param.time_reset_tilt = param.time_reset_tilt - dt
            if param.time_reset_tilt < 0.0 then
                param.time_reset_tilt = 0.0
                param.tilt_count = 0
            end
        end
    end

    self:set_state(temp)
end

return Controller
