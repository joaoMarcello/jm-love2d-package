---@type JM.GUI
local GUI = require(string.gsub(..., "jm_virtual_pad", "jm_gui"))
local TouchButton = GUI.TouchButton
local VirtualStick = GUI.VirtualStick

local push, pop = love.graphics.push, love.graphics.pop
local setLineWidth = love.graphics.setLineWidth
local setLineStyle = love.graphics.setLineStyle

--==========================================================================
local Bt_A = TouchButton:new {
    use_radius = true,
    text = "A",
    on_focus = true,
}
Bt_A:set_color2(JM_Utils:hex_to_rgba_float("21d940"))
--==========================================================================
local Bt_B = TouchButton:new {
    use_radius = true,
    text = "B",
    on_focus = true,
}
Bt_B:set_color2(JM_Utils:hex_to_rgba_float("bf3526"))


local Bt_X = TouchButton:new {
    use_radius = true,
    text = "X",
    on_focus = true,
}
Bt_X:set_color2(JM_Utils:hex_to_rgba_float("213ad9"))


local Bt_Y = TouchButton:new {
    use_radius = true,
    text = "Y",
    on_focus = true,
}
Bt_Y:set_color2(JM_Utils:hex_to_rgba_float("d9ab21"))

local list_buttons_ABXY = { Bt_A, Bt_B, Bt_X, Bt_Y }
--==========================================================================
local rect_rx = 20

---@param self JM.GUI.TouchButton
local bt_draw = function(self)
    local lgx = love.graphics
    local color = self.color
    local x, y, w, h = self.x, self.y, self.w, self.h

    lgx.setColor(0, 0, 0, 0.4 * self.opacity)
    lgx.rectangle("fill", x, y, w, h, rect_rx, rect_rx)
    lgx.setColor(color)
    lgx.rectangle("line", x, y, w, h, rect_rx, rect_rx)


    local font = self:get_font()
    font:push()
    font:set_color(color)
    font:set_font_size(self.h * 0.4)
    font:printf((self.text):upper(), x - 20, y + h * 0.5 - font.__font_size * 0.5, w + 40, "center")
    font:pop()
end

local Bt_Start = TouchButton:new {
    text = "start",
    on_focus = true,
    draw = bt_draw,
}

local Bt_Select = TouchButton:new {
    text = "select",
    on_focus = true,
    draw = bt_draw,
}
--==========================================================================
local dpad_pos_x = 0.05
local dpad_pos_y = 0.8 --0.95

---@param self JM.GUI.TouchButton
local dpad_draw = function(self)
    local lgx = love.graphics

    lgx.setColor(0, 0, 0, 0.4 * self.opacity)
    lgx.rectangle("fill", self.x, self.y, self.w, self.h)

    lgx.setColor(self.color)
    lgx.rectangle("line", self.x, self.y, self.w, self.h)

    -- local font = self:get_font()
    -- font:push()
    -- font:set_color(JM.Utils:get_rgba(1, 1, 1, self.opacity))
    -- font:set_font_size(self.h * 0.75)
    -- font:printf(self.text, self.x - 20, self.y + self.h * 0.5 - font.__font_size * 0.5, self.w + 40, "center")
    -- font:pop()

    local w = self.h * 0.5
    local x = self.x + self.w * 0.5 * 0.5
    local y = x - self.x + self.y

    lgx.polygon("fill",
        x, y,
        x + w, y + w * 0.5,
        x, y + w
    )
end

local dpad_left = TouchButton:new {
    text = "dpleft",
    on_focus = true,
    draw = dpad_draw,
}

local dpad_right = TouchButton:new {
    text = "dpright",
    on_focus = true,
    draw = dpad_draw,
}

local dpad_up = TouchButton:new {
    text = "dpup",
    on_focus = true,
    draw = dpad_draw,
}
-- dpad_up:set_effect_transform("rot", math.pi)

local dpad_down = TouchButton:new {
    text = "dpdown",
    on_focus = true,
    draw = dpad_draw,
}

local list_dpad = {
    dpad_left, dpad_up, dpad_right, dpad_down
}
--==========================================================================
---@param self JM.GUI.TouchButton
local trigger_draw = function(self)
    local lgx = love.graphics
    local color = self.color
    local x, y, w, h = self.x, self.y, self.w, self.h

    lgx.setColor(0, 0, 0, 0.4 * self.opacity)
    lgx.rectangle("fill", x, y, w, h, rect_rx, rect_rx)
    lgx.setColor(color)
    lgx.rectangle("line", x, y, w, h, rect_rx, rect_rx)

    local font = self:get_font()

    font:push()
    font:set_color(self.color)
    font:set_font_size(self.h * 0.5)

    if self.text == "L" then
        font:printf(self.text, self.x + self.w * 0.25, self.y + self.h * 0.5 - font.__font_size * 0.5, self.w, "left")
    else
        font:printf(self.text, self.x + self.w * 0.75 - self.w, self.y + self.h * 0.5 - font.__font_size * 0.5, self.w,
            "right")
    end
    font:pop()
end

local Bt_L = TouchButton:new {
    text = "L",
    on_focus = true,
    draw = trigger_draw,
}

local Bt_R = TouchButton:new {
    text = "R",
    on_focus = true,
    draw = trigger_draw,
}
--==========================================================================
local Home = TouchButton:new {
    text = "guide",
    on_focus = true,
    draw =
    ---@param self JM.GUI.TouchButton
        function(self)
            local lgx = love.graphics
            local px, py, pw, ph = self.x, self.y, self.w, self.h
            local rx = rect_rx

            lgx.setColor(0, 0, 0, 0.4 * self.opacity)
            lgx.rectangle("fill", px, py, pw, ph, rx, rx)
            lgx.setColor(self.color)
            lgx.rectangle("line", px, py, pw, ph, rx, rx)

            local line_width = lgx.getLineWidth()
            lgx.setLineWidth(3)

            local w = pw * 0.6
            local y = py + ph * 0.3
            local x = (px + (pw - w)) - (pw - w) * 0.5
            for i = 0, 2 do
                lgx.line(x, y, x + w, y)
                y = y + (ph * 0.7) * 0.333333
            end

            lgx.setLineWidth(line_width)
        end,
}

--==========================================================================
local stick = VirtualStick:new {
    on_focus = true,
    is_mobile = true,
}
-- stick:set_position(stick.max_dist, height - stick.h - 130, true)
--==========================================================================

local allow_dpad_diagonal = true

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
    X = Bt_X,
    [6] = Bt_X,
    Y = Bt_Y,
    [7] = Bt_Y,
    Dpad_left = dpad_left,
    [8] = dpad_left,
    Dpad_right = dpad_right,
    [9] = dpad_right,
    Dpad_up = dpad_up,
    [10] = dpad_up,
    Dpad_down = dpad_down,
    [11] = dpad_down,
    L = Bt_L,
    [12] = Bt_L,
    R = Bt_R,
    [13] = Bt_R,
    Home = Home,
    [14] = Home,
    N = 14
}

local function dpad_is_pressed()
    -- local r = dpad_down:is_pressing() and dpad_up:is_pressing()
    --     and dpad_left:is_pressing() and dpad_right:is_pressing()
    -- return r
    for i = 1, 4 do
        local r = list_dpad[i]:is_pressing()
        if r then return true end
    end
    return false
end

local function ABXY_button_is_pressed()
    for i = 1, 4 do
        local r = list_buttons_ABXY[i]:is_pressing()
        if r then return true end
    end
    return false
end

local function check_collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 + w1 > x2
        and x1 < x2 + w2
        and y1 + h1 > y2
        and y1 < y2 + h2
end

---@param self JM.GUI.VPad
local function check_dpad_diagonal_press(self, x, y, skip_press)
    if allow_dpad_diagonal and dpad_up.on_focus and dpad_up.is_visible
    then
        -- if true or not dpad_is_pressed() then
        do
            local w = dpad_down.w * 0.75

            if check_collision(x, y, 0, 0,
                    dpad_right.x, dpad_down.y, w, w
                )
            then
                if skip_press then
                    return dpad_down, dpad_right
                end

                dpad_down:mousepressed(dpad_down.x + 1, dpad_down.y + 1, 1, false)
                dpad_right:mousepressed(dpad_right.x + 1, dpad_right.y + 1, 1, false)
                dpad_down.back_to_normal = false
                dpad_right.back_to_normal = false

                return true
                ---
            elseif check_collision(x, y, 0, 0,
                    dpad_down.x - w, dpad_down.y, w, w)
            then
                if skip_press then
                    return dpad_left, dpad_down
                end

                dpad_left:mousepressed(dpad_left.x + 1, dpad_left.y + 1, 1, false)
                dpad_down:mousepressed(dpad_down.x + 1, dpad_down.y + 1, 1, false)
                dpad_left.back_to_normal = false
                dpad_down.back_to_normal = false

                return true
                ---
            elseif check_collision(x, y, 0, 0,
                    dpad_right.x, dpad_right.y - w, w, w
                )
            then
                if skip_press then
                    return dpad_right, dpad_up
                end

                dpad_right:mousepressed(dpad_right.x + 1, dpad_right.y + 1, 1, false)
                dpad_up:mousepressed(dpad_up.x + 1, dpad_up.y + 1, 1, false)
                dpad_right.back_to_normal = false
                dpad_up.back_to_normal = false

                return true
                ---
            elseif check_collision(x, y, 0, 0,
                    dpad_left.right - w, dpad_left.y - w, w, w
                )
            then
                if skip_press then
                    return dpad_left, dpad_up
                end

                dpad_left:mousepressed(dpad_left.x + 1, dpad_left.y + 1, 1, false)
                dpad_up:mousepressed(dpad_up.x + 1, dpad_up.y + 1, 1, false)
                dpad_left.back_to_normal = false
                dpad_up.back_to_normal = false

                return true
                ---
            end
        end
    end -- END diagonal dpad checks
end

---@param self JM.GUI.VPad
local function check_dpad_diagonal_press_touch(self, id, x, y, dx, dy, pressure, skip_press)
    if allow_dpad_diagonal
        and dpad_up.on_focus
        and dpad_up.is_visible
    then
        -- if not dpad_is_pressed() then
        do
            local w = dpad_down.w * 0.75

            if check_collision(x, y, 0, 0,
                    dpad_right.x, dpad_down.y, w, w
                )
            then
                if skip_press then
                    return dpad_down, dpad_right
                end

                dpad_down:touchpressed(id,
                    dpad_down.x + dpad_down.w * 0.5,
                    dpad_down.y + dpad_down.h * 0.5,
                    dx, dy, pressure
                )
                dpad_right:touchpressed(id,
                    dpad_right.x + dpad_right.w * 0.5,
                    dpad_right.y + dpad_right.h * 0.5,
                    dx, dy, pressure
                )
                dpad_down.back_to_normal = false
                dpad_right.back_to_normal = false

                return true
                ---
            elseif check_collision(x, y, 0, 0,
                    dpad_down.x - w, dpad_down.y, w, w)
            then
                if skip_press then
                    return dpad_left, dpad_down
                end

                dpad_left:touchpressed(id,
                    dpad_left.x + dpad_left.w * 0.5,
                    dpad_left.y + dpad_left.h * 0.5,
                    dx, dy, pressure
                )
                dpad_down:touchpressed(id,
                    dpad_down.x + dpad_down.w * 0.5,
                    dpad_down.y + dpad_down.h * 0.5,
                    dx, dy, pressure
                )
                dpad_left.back_to_normal = false
                dpad_down.back_to_normal = false

                return true
                ---
            elseif check_collision(x, y, 0, 0,
                    dpad_right.x, dpad_right.y - w, w, w
                )
            then
                if skip_press then
                    return dpad_right, dpad_up
                end

                dpad_right:touchpressed(id,
                    dpad_right.x + dpad_right.w * 0.5,
                    dpad_right.y + dpad_right.h * 0.5,
                    dx, dy, pressure
                )
                dpad_up:touchpressed(id,
                    dpad_up.x + dpad_up.w * 0.5,
                    dpad_up.y + dpad_up.h * 0.5,
                    dx, dy, pressure
                )
                dpad_right.back_to_normal = false
                dpad_up.back_to_normal = false

                return true
                ---
            elseif check_collision(x, y, 0, 0,
                    dpad_left.right - w, dpad_left.y - w, w, w
                )
            then
                if skip_press then
                    return dpad_left, dpad_up
                end

                dpad_left:touchpressed(id,
                    dpad_left.x + dpad_left.w * 0.5,
                    dpad_left.y + dpad_left.h * 0.5,
                    dx, dy, pressure
                )
                dpad_up:touchpressed(id,
                    dpad_up.x + dpad_up.w * 0.5,
                    dpad_up.y + dpad_up.h * 0.5,
                    dx, dy, pressure
                )
                dpad_left.back_to_normal = false
                dpad_up.back_to_normal = false

                return true
                ---
            end
        end
    end -- END diagonal dpad checks
    return false
end

function Pad:is_dpad(obj)
    return obj == dpad_left or obj == dpad_right
        or obj == dpad_up or obj == dpad_down
end

function Pad:mousepressed(x, y, button, istouch, presses)
    for i = 1, self.N do
        ---@type JM.GUI.TouchButton|any
        local obj = self[i]
        obj:mousepressed(x, y, button, istouch, presses)

        if obj:is_pressing() and self:is_dpad(obj) then
            obj.back_to_normal = false
        end
    end

    return check_dpad_diagonal_press(self, x, y)
end

function Pad:mousereleased(x, y, button, istouch, presses)
    for i = 1, self.N do
        self[i]:mousereleased(x, y, button, istouch, presses)
    end
end

---@return JM.GUI.TouchButton|nil
function Pad:dpad_is_pressed()
    for i = 1, 4 do
        local obj = list_dpad[i]
        if obj:is_pressing() then
            return obj
        end
    end
end

---@return JM.GUI.TouchButton|nil
function Pad:check_dpad_collision(x, y)
    for i = 1, 4 do
        local obj = list_dpad[i]
        if check_collision(x, y, 0, 0, obj:rect()) then
            return obj
        end
    end
end

---@return JM.GUI.TouchButton|nil
function Pad:check_ABXY_collision(x, y)
    for i = 1, 4 do
        local obj = list_buttons_ABXY[i]
        if obj:__check_collision__(x, y) then
            return obj
        end
    end
end

function Pad:unpress_dpad_mouse(x, y)
    for i = 1, 4 do
        list_dpad[i]:mousereleased(x, y, 1, false)
    end
end

function Pad:unpress_dpad_touch(id, x, y, dx, dy, pressure)
    for i = 1, 4 do
        local obj = list_dpad[i]
        obj:touchreleased(obj.__touch_pressed, x, y, dx, dy, pressure)
    end
end

function Pad:mousemoved(x, y, dx, dy, istouch)
    local pressed = self:dpad_is_pressed()

    -- if all dpad buttons are on_focus
    if dpad_up.on_focus and dpad_up.is_visible and pressed then
        ---
        local obj = self:check_dpad_collision(x, y)

        do
            local off = dpad_left.w * 0.5
            -- if mouse is out of bounds
            if (x < dpad_left.x - off
                    or x > dpad_right.right + off
                    or y < dpad_up.y - off
                    or y > dpad_down.bottom + off)
            then
                return self:unpress_dpad_mouse(x, y)
            end
        end

        if obj and not obj:is_pressing() then
            self:unpress_dpad_mouse(x, y)
            obj:mousepressed(obj.x + 1, obj.y + 1, 1, false)
            obj.back_to_normal = false

            if obj.time_press == 0 then
                local scene = JM.SceneManager.scene
                self:verify_pressed(scene)
                -- local mousepressed = scene and scene.__param__.mousepressed
                -- if mousepressed then mousepressed(x, y, 1, false) end
            end
            ---
        else
            local b1, b2 = check_dpad_diagonal_press(self, x, y, true)

            if b1 and b2 then
                local t1, t2 = b1.time_press, b2.time_press

                self:unpress_dpad_mouse(x, y)
                check_dpad_diagonal_press(self, x, y)

                b1.time_press = t1 or b1.time_press
                b2.time_press = t2 or b2.time_press

                if b1.time_press == 0 or b2.time_press == 0 then
                    local scene = JM.SceneManager.scene
                    self:verify_pressed(scene)

                    -- local mousepressed = scene and scene.__param__.mousepressed
                    -- if mousepressed then mousepressed(x, y, 1, false) end
                end
                ---
            elseif obj then
                ---
                for i = 1, 4 do
                    local bt = list_dpad[i]
                    if bt ~= obj and bt:is_pressing() then
                        bt:mousereleased(x, y, 1, false)
                    end
                end
                ---
            end
            ---
        end
    end --- END dpad mousemove
    ---
end

local touch_id_button = {}
local n_touchs_button = 0

local touch_id_dpad = {}
local n_touchs_dpad = 0

function Pad:touchmoved(id, x, y, dx, dy, pressure)
    local pressed = self:dpad_is_pressed()

    if dpad_up.on_focus and dpad_up.is_visible and pressed
        and (pressed.__touch_pressed == id)
    then
        ---
        local obj = self:check_dpad_collision(x, y)

        do
            local off = dpad_left.w * 0.5
            -- if touch is out of bounds
            if (x < (dpad_left.x - off)
                    or x > (dpad_right.right + off)
                    or y < (dpad_up.y - off)
                    or y > (dpad_down.bottom + off))
            then
                return self:unpress_dpad_touch(id, x, y, dx, dy, pressure)
            end
        end

        if obj and not obj:is_pressing() then
            self:unpress_dpad_touch(id, x, y, dx, dy, pressure)
            obj:touchpressed(id, obj.x + 1, obj.y + 1, dx, dy, pressure)
            obj.back_to_normal = false

            if obj.time_press == 0.0 then
                local scene = JM.SceneManager.scene
                self:verify_pressed(scene)
                love.system.vibrate(0.1)

                -- local touchpressed = scene and scene.__param__.touchpressed
                -- if touchpressed then
                --     touchpressed(id, x, y, dx, dy, pressure)
                --     love.system.vibrate(0.1)
                -- end
            end
            ---
        else
            local b1, b2 = check_dpad_diagonal_press_touch(
                self, id, x, y, dx, dy, pressure, true
            )

            if b1 and b2 then
                local t1, t2 = b1.time_press, b2.time_press

                self:unpress_dpad_touch(id, x, y, dx, dy, pressure)

                check_dpad_diagonal_press_touch(
                    self, id, x, y, dx, dy, pressure
                )

                b1.time_press = t1 or b1.time_press
                b2.time_press = t2 or b2.time_press

                if b1.time_press == 0.0 or b2.time_press == 0.0 then
                    local scene = JM.SceneManager.scene
                    self:verify_pressed(scene)
                    love.system.vibrate(0.1)

                    -- local touchpressed = scene and scene.__param__.touchpressed
                    -- if touchpressed then
                    --     touchpressed(id, x, y, dx, dy, pressure)
                    --     love.system.vibrate(0.1)
                    -- end
                end
                ---
            elseif obj then
                ---
                for i = 1, 4 do
                    local bt = list_dpad[i]
                    if bt ~= obj and bt:is_pressing() then
                        bt:touchreleased(bt.__touch_pressed, x, y, dx, dy, pressure)
                    end
                end
                ---
            end
        end
    end
    ---

    if n_touchs_button > 0
        and touch_id_button[id]
    then
        local obj = self:check_ABXY_collision(x, y)

        if obj and not obj:is_pressing() then
            obj:touchpressed(id, x, y, dx, dy, pressure)

            if obj:is_pressed() then
                local scene = JM.SceneManager.scene
                local touchpressed = scene and scene.__param__.touchpressed

                if touchpressed then
                    touchpressed(id, x, y, dx, dy, pressure)
                    love.system.vibrate(0.1)
                end
            end
        end
        ---
    end

    if n_touchs_dpad > 0 and touch_id_dpad[id] then
        ---@type JM.GUI.TouchButton|any
        local obj1, obj2 = check_dpad_diagonal_press_touch(
            self, id, x, y, dx, dy, pressure, true)

        if obj1 and obj2 then
            ---
            if not obj1:is_pressing() and not obj2:is_pressing() then
                ---
                if check_dpad_diagonal_press_touch(
                        self, id, x, y, dx, dy, pressure)
                then
                    local scene = JM.SceneManager.scene
                    local touchpressed = scene and scene.__param__.touchpressed
                    if touchpressed then
                        touchpressed(id, x, y, dx, dy, pressure)
                        love.system.vibrate(0.1)
                    end
                end
            end
            ---
        else
            ---@type JM.GUI.TouchButton|boolean|any
            local obj = self:check_dpad_collision(x, y)

            if obj and not obj:is_pressing() then
                obj:touchpressed(id, x, y, dx, dy, pressure)
                if obj:is_pressed() then
                    local scene = JM.SceneManager.scene
                    local touchpressed = scene and scene.__param__.touchpressed
                    if touchpressed then
                        touchpressed(id, x, y, dx, dy, pressure)
                        love.system.vibrate(0.1)
                    end
                end
            end
        end

        ---
    end
    ---
end

function Pad:touchpressed(id, x, y, dx, dy, pressure)
    local vibrate = false

    for i = 1, self.N do
        local obj = self[i]
        obj:touchpressed(id, x, y, dx, dy, pressure)

        if not vibrate
            and obj ~= stick
            and obj:is_pressed()
        then
            love.system.vibrate(0.1)
            vibrate = true
        end

        if obj:is_pressed() and self:is_dpad(obj) then
            obj.back_to_normal = false
        end
    end

    local r = check_dpad_diagonal_press_touch(self, id, x, y, dx, dy, pressure)
    if r and not vibrate then
        love.system.vibrate(0.1)
    end

    if ABXY_button_is_pressed() then
        for i = 1, 4 do
            local __id = list_buttons_ABXY[i].__touch_pressed

            if __id
                and id == __id
                and not touch_id_button[__id]
            then
                touch_id_button[__id] = true
                n_touchs_button = n_touchs_button + 1
            end
        end
        ---
    end

    if dpad_is_pressed() then
        for i = 1, 4 do
            local __id = list_dpad[i].__touch_pressed

            if __id and id == __id and not touch_id_dpad[__id] then
                touch_id_dpad[__id] = true
                n_touchs_dpad = n_touchs_dpad + 1
            end
        end
    end
    ---
end

function Pad:touchreleased(id, x, y, dx, dy, pressure)
    for i = 1, self.N do
        self[i]:touchreleased(id, x, y, dx, dy, pressure)
    end

    if n_touchs_button > 0 then
        if touch_id_button[id] then
            touch_id_button[id] = nil
            n_touchs_button = n_touchs_button - 1
        end
    end

    if n_touchs_dpad > 0 then
        if touch_id_dpad[id] then
            touch_id_dpad[id] = nil
            n_touchs_dpad = n_touchs_dpad - 1
        end
    end
end

function Pad:flush()
    for k, v in next, touch_id_button do
        touch_id_button[k] = nil
    end
end

function Pad:set_button_size(value)
    value = value or (math.min(love.graphics.getDimensions()) * 0.2)
    Bt_A:set_dimensions(value, value)
    Bt_A:init()
    Bt_B:set_dimensions(value, value)
    Bt_B:init()
    Bt_X:set_dimensions(value, value)
    Bt_X:init()
    Bt_Y:set_dimensions(value, value)
    Bt_Y:init()
end

---@alias JM.GUI.VPad.ButtonNames "X"|"Y"|"A"|"B"|"Dpad-left"|"Dpad-right"|"Dpad-up"|"Dpad-down"|"Stick"

---@param button JM.GUI.VPad.ButtonNames
function Pad:get_button_by_str(button)
    local bt = nil
    if button == "A" then
        bt = Bt_A
    elseif button == "B" then
        bt = Bt_B
    elseif button == "X" then
        bt = Bt_X
    elseif button == "Y" then
        bt = Bt_Y
    elseif button == "Dpad-left" then
        bt = dpad_left
    elseif button == "Dpad-right" then
        bt = dpad_right
    elseif button == "Dpad-up" then
        bt = dpad_up
    elseif button == "Dpad-down" then
        bt = dpad_down
    elseif button == "Stick" then
        bt = stick
    end
    return bt
end

function Pad:toggle_button(button)
    local bt = self:get_button_by_str(button)

    if bt then
        bt:set_visible(not bt.is_visible)
        bt:set_focus(not bt.on_focus)
    end
end

---@param button JM.GUI.VPad.ButtonNames
function Pad:turn_off_button(button)
    local bt = self:get_button_by_str(button)

    if bt then
        bt:set_visible(false)
        bt:set_focus(false)
    end
end

---@param button JM.GUI.VPad.ButtonNames
function Pad:turn_on_button(button)
    local bt = self:get_button_by_str(button)

    if bt then
        bt:set_visible(true)
        bt:set_focus(true)
    end
end

function Pad:turn_off_dpad()
    self:turn_off_button("Dpad-left")
    self:turn_off_button("Dpad-right")
    self:turn_off_button("Dpad-up")
    self:turn_off_button("Dpad-down")
end

function Pad:allow_dpad_diagonal(value)
    allow_dpad_diagonal = value
end

function Pad:set_dpad_position(x, y)
    dpad_pos_x = x or dpad_pos_x
    dpad_pos_y = y or dpad_pos_y
end

local color_blue = Bt_X.color
local color_red = Bt_B.color
local color_green = Bt_A.color

function Pad:use_all_buttons(value)
    if value then
        self:turn_on_button("X")
        self:turn_on_button("Y")
        ---
        Bt_B.text = "X"
        Bt_X.text = "B"

        Bt_B.color, Bt_X.color = color_blue, color_red
        Bt_A.color = color_green
        ---
    else
        self:turn_off_button("X")
        self:turn_off_button("Y")

        Bt_B.text = "B"
        Bt_X.text = "X"

        Bt_B.color = color_red
        Bt_A.color = color_blue
    end
end

function Pad:fix_positions()
    local w, h = love.graphics.getDimensions()
    local min, max = math.min(w, h), math.max(w, h)
    local border_w = (w * 0.5) * 0.1
    local border_button_y = h * 0.2
    local space = 15
    local space_bt_y = 10
    local space_bt_x = 5
    local sfx, sfy, sfw, sfh = love.window.getSafeArea()

    Bt_A:set_position(
        (sfx + sfw) - border_w - Bt_A.w,
        (sfy + sfh) - border_button_y - Bt_A.h
    )
    Bt_B:set_position(Bt_A.x - Bt_B.w - space_bt_x, Bt_A.y - Bt_B.h * 0.5)

    Bt_X:set_position(Bt_A.x, Bt_A.y - (space_bt_y) - Bt_X.h)
    Bt_Y:set_position(Bt_B.x, Bt_B.y - (space_bt_y) - Bt_Y.h)

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

        Bt_Select:set_position(w * 0.5 + space * 2, Bt_Start.y)
    end

    do
        local size = min * 0.15

        Home:set_dimensions(size, size)
        Home:set_position(w * 0.5 - size * 0.5, sfy)
    end

    do
        local size = w * 0.2
        local border = 15
        Bt_L:set_dimensions(size, size * 0.3)
        Bt_L:set_position(sfx + border, sfy + border)

        Bt_R:set_dimensions(size, size * 0.3)
        Bt_R:set_position((sfx + sfw) - border - Bt_R.w, sfy + border)
    end

    do
        stick:set_dimensions(min * 0.2, min * 0.2)
        stick:init()
        stick:set_position(
        -- stick.bounds_width * 0.5 - stick.w * 0.5,
            stick.max_dist + w * 0.015,
            stick.bounds_top + stick.bounds_height * 0.4,
            true
        )
    end

    do
        local size = min * 0.175
        dpad_left:set_dimensions(size, size)
        dpad_right:set_dimensions(size, size)
        dpad_up:set_dimensions(size, size)
        dpad_down:set_dimensions(size, size)

        local ox = dpad_left.w * 0.5
        dpad_up.ox, dpad_up.oy = ox, ox
        dpad_up:set_effect_transform("rot", -math.pi * 0.5)
        dpad_down.ox, dpad_down.oy = ox, ox
        dpad_down:set_effect_transform("rot", math.pi * 0.5)
        dpad_left.ox, dpad_left.oy = ox, ox
        dpad_left:set_effect_transform("rot", math.pi)

        -- local sx, sy, sw, sh = love.window.getSafeArea()

        local anchor_x = sfx + 10 -- w * dpad_pos_x + size
        local anchor_y = h * dpad_pos_y - size
        -- local space_x = not stick.is_visible and (space * 4) or (space * 2)

        dpad_left:set_position(anchor_x, anchor_y - size * 0.5)
        dpad_right:set_position(dpad_left.right + size, dpad_left.y)

        dpad_up:set_position(
            dpad_left.right,
            dpad_left.y - dpad_up.h
        )
        dpad_down:set_position(dpad_up.x, dpad_left.bottom)
    end
end

function Pad:B_is_pressed()
    local bt = (Bt_X.on_focus and Bt_X.is_visible and Bt_X) or Bt_B
    return bt:is_pressed()
end

function Pad:X_is_pressed()
    -- local bt = (Bt_X.on_focus and Bt_X.is_visible and Bt_X) or Bt_B
    return Bt_B:is_pressed()
end

---@param font JM.Font.Font
function Pad:set_font(font)
    TouchButton:set_font(font)
end

function Pad:get_font()
    return TouchButton:get_font()
end

function Pad:get_ABXY_list()
    return list_buttons_ABXY
end

function Pad:get_dpad_list()
    return list_dpad
end

---@param obj JM.GUI.TouchButton
function Pad:get_button_name(obj)
    if self:is_dpad(obj) then
        return obj.text
    end

    if obj == Bt_L then return "leftshoulder" end
    if obj == Bt_R then return "rightshoulder" end
    if obj == Bt_Start then return "start" end
    if obj == Bt_Select then return "back" end
    if obj == Home then return "guide" end

    if obj == Bt_A then return "a" end
    if obj == Bt_Y then return "y" end
    if obj == Bt_B then
        if Bt_X.on_focus then return "x" end
        return "b"
    end
    if obj == Bt_X then return "b" end
end

---@param scene JM.Scene
function Pad:verify_pressed(scene)
    do
        local list = self:get_ABXY_list()
        for i = 1, 4 do
            local obj = list[i]
            if obj:is_pressed() then
                scene:vpadpressed(self:get_button_name(obj))
            end
        end
    end
    ---
    do
        local list = self:get_dpad_list()
        for i = 1, 4 do
            local obj = list[i]
            if obj:is_pressed() then
                scene:vpadpressed(obj.text:lower())
            end
        end
    end
    ---
    do
        local L = Bt_L
        if L:is_pressed() then scene:vpadpressed("leftshoulder") end

        local R = Bt_R
        if R:is_pressed() then scene:vpadpressed("rightshoulder") end
    end
    ---
    do
        local start = Bt_Start
        if start:is_pressed() then scene:vpadpressed("start") end

        local select = Bt_Select
        if select:is_pressed() then scene:vpadpressed("back") end

        local home = Home
        if home:is_pressed() then scene:vpadpressed("guide") end
    end
    ---
end

function Pad:resize(w, h)
    self:set_button_size((math.min(w, h) * 0.2))
    self:fix_positions()
end

function Pad:set_opacity(value)
    value = value or 0.5
    for i = 1, self.N do
        local gc = self[i]
        gc:set_opacity(value)
    end
end

function Pad:update(dt)
    for i = 1, self.N do
        self[i]:update(dt)
    end
end

function Pad:draw()
    push("all")
    setLineWidth(2)
    setLineStyle("smooth")

    for i = 1, self.N do
        self[i]:draw()
    end

    pop()
end

Pad:set_button_size()
Pad:fix_positions()
Pad:set_opacity(0.45)

Pad:use_all_buttons(true)
-- Pad:turn_off_dpad()
Pad:turn_off_button("Stick")
-- Pad:turn_on_button("Dpad-left")
-- Pad:turn_on_button("Dpad-right")

return Pad
