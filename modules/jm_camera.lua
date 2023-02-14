local love_translate = love.graphics.translate
local love_pop = love.graphics.pop
local love_push = love.graphics.push
local love_scale = love.graphics.scale
local love_get_scissor = love.graphics.getScissor
local love_set_scissor = love.graphics.setScissor
local love_set_blend_mode = love.graphics.setBlendMode
local love_get_blend_mode = love.graphics.getBlendMode
local love_set_color = love.graphics.setColor
local love_clear = love.graphics.clear
local love_get_canvas = love.graphics.getCanvas
local love_set_canvas = love.graphics.setCanvas
local love_draw = love.graphics.draw
local love_rect = love.graphics.rectangle
local love_line = love.graphics.line
local sin, cos, atan2, sqrt, abs = math.sin, math.cos, math.atan2, math.sqrt, math.abs
local mfloor, mceil = math.floor, math.ceil
local m_min, m_max = math.min, math.max

-- local function round(value)
--     local absolute = abs(value)
--     local decimal = absolute - mfloor(absolute)

--     if decimal >= 0.5 then
--         return value > 0 and mceil(value) or mfloor(value)
--     else
--         return value > 0 and mfloor(value) or mceil(value)
--     end
-- end

-- the round function from lua programming book
local function round(x)
    local f = mfloor(x + 0.5)
    if (x == f) or (x % 2.0 == 0.5) then
        return f
    else
        return mfloor(x + 0.5)
    end
end

local function clamp(value, min, max)
    return m_min(m_max(value, min), max)
end

local function rad2degr(value)
    return value * 180 / math.pi
end

local function deg2rad(value)
    return value * math.pi / 180
end

--- Moves the camera's position until reaches the target's position.
---@param self JM.Camera.Camera
local function chase_target(self, dt, chase_x_axis, chase_y_axis)
    local reach_objective_x, reach_objective_y = not chase_x_axis, not chase_y_axis

    -- Hello World

    if self.target then
        if chase_x_axis
            and (self.x ~= self.target.x or self.infinity_chase_x)
        then
            if self.constant_speed_x then
                self.follow_speed_x = self.constant_speed_x
            else
                self.follow_speed_x = self.follow_speed_x + self.acc_x * dt

                if self.max_speed_x and self.follow_speed_x > self.max_speed_x then
                    self.follow_speed_x = self.max_speed_x
                end
            end

            local cos_r = cos(self.target.angle_x)

            if self.y <= self.bounds_top
                or self.y >= self.bounds_bottom - self.viewport_h / self.scale
                or not self:point_is_on_screen(self.target.x, self.target.y)
            then
                cos_r = cos_r / abs(cos_r)
            end

            self:move(
                (self.follow_speed_x * dt + (self.acc_x * dt * dt) / 2)
                * cos_r)

            self:move(abs(self.target.range_x) * cos_r * self.delay_x)

            if (cos_r > 0 and self.x >= self.target.x)
                or (cos_r < 0 and self.x <= self.target.x)
            then
                self:set_position(self.target.x)
                self.follow_speed_x = sqrt(2 * self.acc_x * self.default_initial_speed_x)
            end

            -- if self.infinity_chase_x then

            --     -- if self.follow_speed_x < 0
            --     --     and self.x < self.target.x
            --     --     and not self.touch_target
            --     -- then
            --     --     self.touch_target = true
            --     --     self.follow_speed_x = sqrt(2 * self.acc_x * 32 * 5)
            --     -- else
            --     --     if self.follow_speed_x > 0
            --     --         and self.x > self.target.x
            --     --         and not self.touch_target
            --     --     then
            --     --         self.touch_target = true
            --     --         self.follow_speed_x = -sqrt(2 * self.acc_x * 32 * 5)

            --     --     else
            --     --         self.touch_target = false
            --     --     end
            --     -- end
            -- end

            reach_objective_x = self.x == self.target.x
        end

        if chase_y_axis and self.y ~= self.target.y then
            if self.constant_speed_y then
                self.follow_speed_y = self.constant_speed_y
            else
                self.follow_speed_y = self.follow_speed_y + self.acc_y * dt
            end

            local sin_r = sin(self.target.angle_y)

            if self.x <= self.bounds_left
                or self.x >= self.bounds_right - self.viewport_w / self.scale
                or not self:point_is_on_screen(self.target.x, self.target.y)
            then
                sin_r = sin_r / abs(sin_r)
            end

            self:move(nil,
                (self.follow_speed_y * dt + (self.acc_y * dt * dt) / 2)
                * sin_r)

            self:move(nil, abs(self.target.range_y) * self.target.direction_y * self.delay_y)

            if (sin_r > 0 and self.y > self.target.y)
                or (sin_r < 0 and self.y < self.target.y)
            then
                self:set_position(nil, self.target.y)
                self.follow_speed_y = sqrt(2 * self.acc_y * self.default_initial_speed_y)
            end

            reach_objective_y = self.y == self.target.y
        end
    end

    return reach_objective_x and reach_objective_y
end

---@param self JM.Camera.Camera
local function chase_target_y(self, dt)
    return chase_target(self, dt, nil, true)
end

---@param self JM.Camera.Camera
local function chase_target_x(self, dt)
    return chase_target(self, dt, true)
end

---@param self JM.Camera.Camera
local function dynamic_x_offset(self, dt)
    if not self.target then return end

    local deadzone_w = self.deadzone_w
    -- deadzone_w = deadzone_w / self.scale / self.desired_scale

    local inverted = self.invert_dynamic_focus_x

    local left_focus = self.desired_left_focus
        or self.viewport_w * 0.7

    local right_focus = self.desired_right_focus
        or self.viewport_w * 0.3

    local move_left_offset = ((not inverted and left_focus > right_focus)
        or (inverted and left_focus < right_focus))
        and left_focus or right_focus

    local move_right_offset = move_left_offset == right_focus and left_focus or right_focus

    if not self:is_locked_in_x() then
        local objective = chase_target_x(self, dt)

        self:set_lock_x_axis(objective
        and self.target.direction_x ~= self.target.last_direction_x
        )
    else
        self.follow_speed_x = sqrt(2 * self.acc_x * self.default_initial_speed_x)

        -- Target moving to right
        if self.target.direction_x > 0
        then
            local right = self.x + deadzone_w / 2
            right = self:screen_to_world(right)

            if not self.use_deadzone
                or self:screen_to_world(self.target.x) > right
            then
                self:set_lock_x_axis(false)
            end
        elseif self.target.direction_x <= 0 then
            local left = self.x - deadzone_w / 2
            left = self:screen_to_world(left)

            if not self.use_deadzone
                or self:screen_to_world(self.target.x) < left
            then
                self:set_lock_x_axis(false)
            end
        end
    end

    if self.target.direction_x < 0 and not self.lock_x then
        self:set_focus_x(move_left_offset)
    elseif self.target.direction_x > 0 and not self.lock_x then
        self:set_focus_x(move_right_offset)
    end
end

---@param self JM.Camera.Camera
local function dynamic_y_offset(self, dt)
    if not self.target then return end

    --=========================================================================
    local deadzone_h = self.deadzone_h
    -- deadzone_h = deadzone_h / self.scale / self.desired_scale

    local top_focus = self.desired_top_focus
        or self.viewport_h * 0.4
    local bottom_focus = self.desired_bottom_focus
        or self.viewport_h * 0.6
    --=========================================================================
    local inverted = self.invert_dynamic_focus_y

    local top_offset = ((not inverted and top_focus > bottom_focus)
        or (inverted and top_focus < bottom_focus))
        and top_focus or bottom_focus

    local bottom_offset = top_offset == top_focus and bottom_focus or top_focus

    if not self:is_locked_in_y() then
        local objective = chase_target_y(self, dt)

        self:set_lock_y_axis(objective
        and self.target.direction_y ~= self.target.last_direction_y
        )
    else
        self.follow_speed_y = sqrt(2 * self.acc_y * self.default_initial_speed_y)

        -- target is going down
        if self.target.direction_y > 0 then
            local bottom = self.y + deadzone_h / 2
            bottom = self:y_screen_to_world(bottom)

            local cy = self:y_screen_to_world(self.target.y)
            if not self.use_deadzone or
                cy > bottom
            then
                self:set_lock_y_axis(false)
            end
        elseif self.target.direction_y < 0 then
            local top = self.y - deadzone_h / 2
            top = self:y_screen_to_world(top)

            if not self.use_deadzone
                or self:y_screen_to_world(self.target.y) < top
            then
                self:set_lock_y_axis(false)
            end
        end
    end

    if self.target.direction_y < 0 and not self.lock_y then
        self:set_focus_y(top_offset)
    elseif self.target.direction_y > 0 and not self.lock_y then
        self:set_focus_y(bottom_offset)
    end
end

---@param self JM.Camera.Camera
local function chase_y_when_not_moving(self, dt)
    if not self.target then return end

    local deadzone_height = self.deadzone_h
    --=========================================================================

    local top_limit = self:y_screen_to_world(self.viewport_h / self.desired_scale * 0.2)
    local bottom = self:y_screen_to_world(self.y + deadzone_height / self.desired_scale)
    local cy = self:y_screen_to_world(self.target.y)

    if self.target.direction_y == 0 then
        chase_target_y(self, dt)
    elseif self.target.direction_y <= 0 then
        self.follow_speed_y = 0 --sqrt(2 * self.acc_y)
    end

    if self.target.y + self.focus_y / self.desired_scale / self.scale < top_limit then
        self:move(nil, -abs(self.target.range_y))
    end

    if cy > bottom and self.target.last_direction_y == 1 then
        self:move(nil, abs(self.target.range_y))
    end
end

---@param self JM.Camera.Camera
local function draw_grid(self)
    local tile = self.grid_desired_tile
    local vx, vy, vw, vh = self:get_viewport_in_world_coord()
    local qx = mceil((self.bounds_right - self.bounds_left) / tile)
    local qy = mceil((self.bounds_bottom - self.bounds_top) / tile)

    love_set_color(0, 0, 0, 0.05)
    for i = mfloor(self.x / tile), qx do
        local px = tile * i
        if px > vx + vw then break end

        if px % (tile * 4) == 0 then
            love_set_color(0, 0, 0, 0.7)
        else
            love_set_color(0, 0, 0, 0.3)
        end

        love_line(px, vy, px, vy + vh)
    end

    for j = mfloor(self.y / tile), qy do
        local py = tile * j
        if py > vy + vh then break end
        if py % (tile * 4) == 0 then
            love_set_color(0, 0, 0, 0.7)
        else
            love_set_color(0, 0, 0, 0.3)
        end
        love_line(self.x, py, vx + vw, py)
    end
end

---@param self JM.Camera.Camera
local function draw_bounds(self)
    local tile = self.tile_size
    local vx, vy, vw, vh = self:get_viewport_in_world_coord()
    local qx = mfloor((self.bounds_right - self.bounds_left) / tile)
    local qy = mfloor((self.bounds_bottom - self.bounds_top) / tile)

    love_set_color(0, 0, 0, 1)
    local line_width = tile * 0.5

    for i = mfloor(self.x / tile), qx do
        local px = i * tile

        if px > vx + vw then break end
        -- TOP
        love_line(
            px,
            self.bounds_top + tile,
            px + line_width,
            self.bounds_top + tile
        )

        -- BOTTOM
        love_line(
            px,
            self.bounds_bottom - tile,
            px + line_width,
            self.bounds_bottom - tile
        )
    end

    for j = mfloor(self.y / tile), qy do
        local py = tile * j
        if py > vy + vh then break end
        love_line(
            self.bounds_left + tile,
            py,
            self.bounds_left + tile,
            py + line_width
        )

        love_line(
            self.bounds_right - tile,
            py,
            self.bounds_right - tile,
            py + line_width
        )
    end

    -- X-axis
    if self.y <= 0 then
        love_set_color(0, 0, 1, 1)
        love_rect("fill", vx, 0, vw, 1 / self.scale)
    end

    -- Y-axis
    if self.x <= 0 then
        love_set_color(1, 0, 0, 1)
        love_rect("fill", 0, vy, 1 / self.scale, vh)
    end

    -- Point (0, 0)
    if self.x <= 0 and self.y <= 0 then
        love_set_color(0.1, 0.1, 0.1, 1)
        love.graphics.circle("fill", 0, 0, 2 / self.scale)
    end
end

---@param self JM.Camera.Camera
local function show_focus(self)
    -- Focus guide lines
    love_set_color(0, 0, 0, 0.1)
    love_rect("fill",
        self.viewport_x + self.focus_x,
        self.viewport_y, 2, self.viewport_h
    )
    love_rect("fill", self.viewport_x,
        self.viewport_y + self.focus_y,
        self.viewport_w,
        2
    )
    --=============================================================

    if self.target then
        self.debug_trgt_rad = self.debug_trgt_rad + (math.pi * 2) / 0.3 * love.timer.getDelta()

        if self:target_on_focus() then
            love_set_color(0, 0.8, 0, 1)
        else
            love_set_color(0, 0.8, 0,
                0.7 + 0.7 * cos(self.debug_trgt_rad)
            )
        end

        -- love.graphics.circle("fill",
        --     self.viewport_x / self.desired_scale / self.scale + self.focus_x / self.desired_scale
        --     + self:x_world_to_screen(
        --         (self.target.x or self.target.last_x)
        --     ),

        --     self.viewport_y / self.desired_scale / self.scale + self.focus_y / self.desired_scale / self.scale
        --     + self:y_world_to_screen(
        --         (self.target.y or self.target.last_y)
        --     ),
        --     7
        -- )

        local px, py = self:world_to_screen(self.target.x or self.target.last_x, self.target.y or self.target.last_y)

        px = px * self.desired_scale + self.focus_x
        py = py * self.desired_scale + self.focus_y
        love.graphics.circle("fill", self.viewport_x + px,
            self.viewport_y + py,
            7)
    end

    -- Camera's focus
    if not self:target_on_focus() then
        love_set_color(0.7, 0, 0, 1)
    else
        love_set_color(1, 0, 0, 1)
    end
    love.graphics.circle("fill",
        self.viewport_x + self.focus_x,
        self.viewport_y + self.focus_y,
        5
    )

    local scl = self.scale
    local corner_esp = 2
    local corner_length = 16

    if self:target_on_focus() then
        love_set_color(1, 1, 1, 1)
    elseif self:hit_border()
    then
        love_set_color(1, 0, 0, 1)
    else
        love_set_color(1, 1, 1, 0.6)
    end

    if self.use_deadzone or true then
        -- Left-Top Corner
        love_rect("fill",
            self.viewport_x + self.focus_x - self.deadzone_w / 2,
            self.viewport_y + self.focus_y - self.deadzone_h / 2,
            corner_length,
            corner_esp)
        love_rect("fill",
            self.viewport_x + self.focus_x - self.deadzone_w / 2,
            self.viewport_y + self.focus_y - self.deadzone_h / 2,
            corner_esp,
            corner_length)

        -- Top-Right Corner
        love_rect("fill",
            self.viewport_x + self.focus_x + self.deadzone_w / 2 - corner_length,
            self.viewport_y + self.focus_y - self.deadzone_h / 2,
            corner_length,
            corner_esp)
        love_rect("fill",
            self.viewport_x + self.focus_x + self.deadzone_w / 2,
            self.viewport_y + self.focus_y - self.deadzone_h / 2,
            corner_esp,
            corner_length)

        --- Bottom-Right Corner
        love_rect("fill",
            self.viewport_x + self.focus_x + self.deadzone_w / 2 - corner_length + corner_esp,
            self.viewport_y + self.focus_y + self.deadzone_h / 2,
            corner_length,
            corner_esp)
        love_rect("fill",
            self.viewport_x + self.focus_x + self.deadzone_w / 2,
            self.viewport_y + self.focus_y + self.deadzone_h / 2 - corner_length,
            corner_esp,
            corner_length)

        --- Bottom-Left Corner
        love_rect("fill",
            self.viewport_x + self.focus_x - self.deadzone_w / 2,
            self.viewport_y + self.focus_y + self.deadzone_h / 2 - corner_length,
            corner_esp,
            corner_length)

        love_rect("fill",
            self.viewport_x + self.focus_x - self.deadzone_w / 2,
            self.viewport_y + self.focus_y + self.deadzone_h / 2,
            corner_length,
            corner_esp)
    end


    love_set_color(0.1, 0.1, 0.1, 1)
    local len_bar = 16
    local len_half = len_bar / 2

    -- Deadzone Right-Middle
    love_rect("fill",
        self.viewport_x + self.focus_x + self.deadzone_w / 2 - len_half,
        self.viewport_y + self.focus_y,
        len_bar,
        corner_esp)

    -- Deadzone Left-Middle
    love_rect("fill",
        self.viewport_x + self.focus_x - self.deadzone_w / 2 - len_half,
        self.viewport_y + self.focus_y,
        len_bar,
        corner_esp)

    -- Deadzone Top-Middle
    love_rect("fill",
        self.viewport_x + self.focus_x,
        self.viewport_y + self.focus_y - self.deadzone_h / 2 - len_half,
        corner_esp,
        len_bar)
    -- Deadzone Bottom-Middle
    love_rect("fill",
        self.viewport_x + self.focus_x,
        self.viewport_y + self.focus_y + self.deadzone_h / 2 - len_half,
        corner_esp,
        len_bar)
end

---@param self JM.Camera.Camera
local function show_border(self)
    -- Drawind a border in the camera's viewport
    love_set_color(self.border_color)

    local vx, vy, vw, vh = self:get_viewport()

    -- left
    love_rect("fill", vx, vy, 3, vh)

    -- Right
    love_rect("fill", vx + vw - 3, vy, 3, vh)

    -- Top
    love_rect("fill", vx, vy, vw, 3)

    -- -- Bottom
    love_rect("fill", self.viewport_x, self.viewport_y + self.viewport_h - 3, self.viewport_w, 3)
end

---@param self JM.Camera.Camera
local function shake_update(self, dt)
    if self.shaking_in_x then
        self.shake_rad_x = self.shake_rad_x
            + (math.pi * 2)
            / self.shake_speed_x * dt

        self.shake_offset_x = round(self.shake_amplitude_x * self.scale
        * cos(self.shake_rad_x - math.pi * self.shake_y_factor))

        if self.shake_duration_x then
            self.shake_time_x = self.shake_time_x + dt

            if self.shake_time_x >= self.shake_duration_x then
                if abs(self.shake_offset_x) <= self.shake_amplitude_x * 0.05
                    or self.shake_time_x >= self.shake_duration_x
                    + self.shake_speed_x
                then
                    self.shaking_in_x = false
                end
            end
        end
        self.shake_rad_x = self.shake_rad_x % (math.pi * 2)
    end

    if self.shaking_in_y then
        self.shake_rad_y = self.shake_rad_y
            + (math.pi * 2)
            / self.shake_speed_y * dt

        self.shake_offset_y = round(self.shake_amplitude_y * self.scale
        * cos(self.shake_rad_y - math.pi * self.shake_y_factor))

        if self.shake_duration_y then
            self.shake_time_y = self.shake_time_y + dt

            if self.shake_time_y >= self.shake_duration_y then
                if abs(self.shake_offset_y) <= self.shake_amplitude_y * 0.05
                    or self.shake_time_y >= self.shake_duration_y
                    + self.shake_speed_y
                then
                    self.shaking_in_y = false
                end
            end
        end
        self.shake_rad_y = self.shake_rad_y % (math.pi * 2)
    end
end

---@enum JM.Camera.Type
local CAMERA_TYPES = {
    Free = 0,
    SuperMarioWorld = 1,
    Metroid = 2,
    SuperMarioBros = 3,
    Zelda_ALTTP = 4,
    Zelda_GBC = 5,
    Metroidvania = 6
}

---@class JM.Camera.Camera
local Camera = {}

---@param self JM.Camera.Camera
---@return JM.Camera.Camera
function Camera:new(args)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Camera.__constructor__(obj,
        args.x, args.y, args.w, args.h, args.bounds,
        args.device_width, args.device_height,
        args.desired_canvas_w, args.desired_canvas_h,
        args.tile_size, args.color, args.scale, args.type,
        args.show_grid, args.grid_tile_size, args.show_world_bounds,
        args.border_color
    )

    args = nil

    return obj
end

---@alias JM.Camera.Target  {x:number, y:number, angle_x:number, angle_y:number, distance:number, range_x:number, range_y:number, last_x:number, last_y:number, direction_x:number, direction_y:number, last_direction_x:number, last_direction_y:number}

function Camera:__constructor__(
    x, y, w, h, bounds,
    device_width, device_height, desired_canvas_w, desired_canvas_h,
    tile_size, color, scale, type_,
    allow_grid, grid_tile_size, show_world_bounds, border_color
)
    self.device_width = device_width or love.graphics.getWidth()
    self.device_height = device_height or love.graphics.getHeight()

    self.desired_canvas_w = desired_canvas_w or self.device_width
    self.desired_canvas_h = desired_canvas_h or self.device_height

    self.scale = scale or 1.0
    self.desired_scale = (self.device_height) / self.desired_canvas_h

    --- Viewport in real-screen coordinates
    self.viewport_x = x or 0
    self.viewport_y = y or 0

    self.viewport_x = self.viewport_x * self.desired_scale
    self.viewport_y = self.viewport_y * self.desired_scale

    self.viewport_w = (w and w * self.desired_scale)
        or self.device_width
    self.viewport_h = (h and h * self.desired_scale)
        or self.device_height

    self.tile_size = tile_size or 32

    self.x = 0
    self.y = 0

    self.angle = 0

    ---@type JM.Camera.Target
    self.target = nil

    self.focus_x = 0
    self.focus_y = 0
    self:set_focus_x(self.viewport_w * 0.5)
    self:set_focus_y(self.viewport_h * 0.5)

    self.deadzone_w = self.tile_size * 1.5
    self.deadzone_h = self.tile_size * 1.5

    self.bounds_left = bounds and bounds.left or 0
    self.bounds_top = bounds and bounds.top or 0
    self.bounds_right = bounds and bounds.right or self.viewport_w / self.scale / self.desired_scale
    self.bounds_bottom = bounds and bounds.bottom or self.viewport_h / self.scale / self.desired_scale
    self:set_bounds()

    self.acc_x = self.tile_size * 13
    self.acc_y = self.acc_x

    self.follow_speed_x = (self.tile_size * 8)
    self.follow_speed_y = (self.tile_size * 8)

    self.max_speed_x = false --sqrt(2 * self.acc_x * self.tile_size * 5)
    self.max_speed_y = false --sqrt(2 * self.acc_y * self.tile_size * 5)


    -- when delay equals 1, there's no delay
    self.delay_x = 1
    self.delay_y = 1

    self.lock_x = false
    self.lock_y = false

    self.color = false --color and true or false
    self.color_r = color and color[1] or 0.5
    self.color_g = color and color[2] or 0.9
    self.color_b = color and color[3] or 0.9
    self.color_a = color and color[4] or 1

    -- Configuration variables
    self.desired_top_focus = nil
    self.desired_bottom_focus = nil
    self.desired_left_focus = nil
    self.desired_right_focus = nil

    self.constant_speed_x = nil
    self.constant_speed_y = nil

    self.invert_dynamic_focus_x = nil
    self.invert_dynamic_focus_y = nil

    self.use_deadzone = true

    self.default_initial_speed_x = self.tile_size * 0 -- (in pixels per second)
    self.default_initial_speed_y = self.default_initial_speed_x

    self.infinity_chase_x = false
    self.infinity_chase_y = false
    -- End configuration variables

    self.type = type_ or CAMERA_TYPES.SuperMarioWorld
    self:set_type(self.type)

    self.debug = true
    self.debug_msg_rad = 0
    self.debug_trgt_rad = 0
    self.debug_color = {}


    self.show_world_boundary = show_world_bounds or self.debug
    self.show_focus = false or self.debug
    self.border_color = border_color or { 1, 0, 0, 1 }
    self.is_showing_grid = self.debug or false
    self.grid_desired_tile = self.tile_size * 1


    -- self:shake_in_x(nil, self.tile_size * 2 / 4, nil, 7.587)
    -- self:shake_in_y(nil, self.tile_size * 2.34 / 4, nil, 10.7564)

    self.min_zoom = 0.5
    self.max_zoom = 1.5

    -- self.canvas = love.graphics.newCanvas(
    --     self.viewport_w / self.desired_scale * (1 / self.min_zoom),
    --     self.viewport_h / self.desired_scale * (1 / self.min_zoom)
    -- )
    -- self.canvas:setFilter("linear", "nearest")

    self.zoom_rad = 0
end

function Camera:get_color()
    return self.color_r, self.color_g, self.color_b, self.color_a
end

function Camera:set_color(r, g, b, a)
    if not r then
        self.color = false
        return
    end
    self.color = true
    self.color_r = r or self.color_r
    self.color_g = g or self.color_g
    self.color_b = b or self.color_b
    self.color_a = a or self.color_a
end

function Camera:set_background_color(r, g, b, a)
    self.color = true
    self.color_r = r or 0.5
    self.color_g = g or 0
    self.color_b = b or 0
    self.color_a = a or 1
end

---@param self JM.Camera.Camera
local function dynamic_zoom_update(self, dt)
    if not self.on_dynimac_zoom then return end

    local r = self:get_state():match("blocked") and self.zoom_final < 1
    if self.scale == self.zoom_final or r then
        self.on_dynimac_zoom = false
        return
    end

    self.scale = self.scale + (self.zoom_speed * dt) + self.zoom_acc * dt * dt / 2.0
    self.zoom_speed = self.zoom_speed + self.zoom_acc * dt

    if self.zoom_acc < 0 or self.zoom_speed < 0 then
        self.scale = clamp(self.scale, self.zoom_final, self.max_zoom)
    else
        self.scale = clamp(self.scale, self.min_zoom, self.zoom_final)
    end
    self:set_bounds()
end

function Camera:set_scale_dynamic(scale, duration, speed)
    assert(scale and scale ~= 0, ">> Error: Scale cannot be nil or zero!")
    duration = duration or 1.0

    self.zoom_final = clamp(scale, self.min_zoom, self.max_zoom)

    local direction = (self.scale > self.zoom_final and -1 or 1)
    self.zoom_speed = speed and (speed * direction) or 0
    self.zoom_acc = not speed and math.abs(self.scale - self.zoom_final) / duration or 0
    self.zoom_acc = self.zoom_acc * direction
    self.on_dynimac_zoom = true
end

function Camera:set_type(s)
    if type(s) == "string" then s = string.lower(s) end

    if s == "super mario world" or s == CAMERA_TYPES.SuperMarioWorld then
        self.type = CAMERA_TYPES.SuperMarioWorld

        self.movement_x = dynamic_x_offset
        self.movement_y = chase_y_when_not_moving

        self:set_focus_y(self.viewport_h * 0.5)
        -- self.desired_deadzone_height =
        self.deadzone_h = self.tile_size * 6 * self.scale

        -- self.desired_deadzone_width =
        self.deadzone_w = self.tile_size * 2 * self.scale

        self.desired_left_focus = self.viewport_w * 0.4
        self.desired_right_focus = self.viewport_w * 0.6
        self:set_focus_x(self.desired_left_focus)

        self.use_deadzone = true
    elseif s == "metroid" or s == CAMERA_TYPES.Metroid then
        self.type = CAMERA_TYPES.Metroid
        self.movement_x = chase_target_x
        self.movement_y = chase_target_y

        self:set_focus_y(self.viewport_h * 0.5)
        self:set_focus_x(self.viewport_w * 0.5)
    elseif s == "metroidvania" or s == CAMERA_TYPES.Metroidvania then
        self.type = CAMERA_TYPES.Metroidvania
        self.movement_x = chase_target_x
        self.movement_y = dynamic_y_offset

        self.desired_top_focus = self.viewport_h * 0.5
        self:set_focus_y(self.viewport_h * 0.5)

        -- self.desired_bottom_focus = self.viewport_h * 0.8
    elseif s == "modern metroidvania" then
        self:set_type("metroidvania")
        self.delay_y = 0.1
    elseif s == "follow boss" then
        self.movement_x = dynamic_x_offset
        self.invert_dynamic_focus_x = true

        self.movement_y = chase_target_y
    else
        self.movement_x = chase_target_x --dynamic_x_offset
        self.movement_y = chase_target_y
        self.deadzone_h = 32 * 3 * self.scale

        self.delay_y = 0.02 / 2

        self.desired_top_focus = self.viewport_h * 0.25
        self.desired_bottom_focus = self.viewport_h * 0.75

        self.desired_left_focus = self.viewport_w * 0.5
        self.desired_right_focus = self.viewport_w * 0.5
        -- self.constant_speed_x = sqrt(2 * self.acc_x * 32 * 2)
        -- self.constant_speed_y = sqrt(2 * self.acc_y * 32 * 3)
        -- self.acc_x = 32 * 5
        self:set_focus_y(self.desired_top_focus)
    end
end

function Camera:set_viewport(x, y, w, h)
    self.viewport_x = x and x * self.desired_scale or self.viewport_x
    self.viewport_y = y and y * self.desired_scale or self.viewport_y
    self.viewport_w = w and w * self.desired_scale or self.viewport_w
    self.viewport_h = h and h * self.desired_scale or self.viewport_h
    self:set_type(self.type)
    self:set_bounds()
end

--- Returns left, top, right and bottom!!!
function Camera:get_viewport_in_world_coord()
    -- local vw, vh = self:screen_to_world(self.viewport_w / self.desired_scale, self.viewport_h / self.desired_scale)

    return self.x, self.y, self.viewport_w / self.desired_scale / self.scale,
        self.viewport_h / self.desired_scale / self.scale
    --return self.x, self.y, vw, vh
end

--- Viewport in Camera Screen coordinates.
function Camera:get_viewport()
    return round(self.viewport_x), round(self.viewport_y), round(self.viewport_w), round(self.viewport_h)
end

function Camera:screen_to_world(x, y)
    local cos_r, sin_r
    cos_r, sin_r = cos(self.angle), sin(self.angle)

    y = y or 0
    x = x or 0

    x = x / self.scale
    y = y / self.scale

    x = cos_r * x - sin_r * y
    y = sin_r * x + cos_r * y

    return round(x + self.x), round(y + self.y)
end

function Camera:world_to_screen(x, y)
    local cos_r, sin_r
    cos_r, sin_r = cos(self.angle), sin(self.angle)

    y = y or 0
    x = x or 0

    x = x - self.x
    y = y - self.y

    x = cos_r * x - sin_r * y
    y = sin_r * x + cos_r * y

    return round(x * self.scale), round(y * self.scale)
end

function Camera:follow(x, y, name)
    if not self.target then self.target = {} end

    x = x - self.focus_x / self.scale / self.desired_scale
    y = y - self.focus_y / self.scale / self.desired_scale

    x = round(x)
    y = round(y)

    self.target.last_name = self.target.name or name
    self.target.name = name or ""

    if self.target.name ~= self.target.last_name then
        self.target.x = nil
        self.target.y = nil
        self.follow_speed_y = sqrt(2 * self.acc_y * self.default_initial_speed_y)
        self.follow_speed_x = sqrt(2 * self.acc_x * self.default_initial_speed_x)
    end

    self.target.last_x = self.target.x or x
    self.target.last_y = self.target.y or y

    self.target.x = x
    self.target.y = y

    self.target.range_x = x - self.target.last_x
    self.target.range_y = y - self.target.last_y

    self.target.last_direction_x = self.target.direction_x ~= 0
        and self.target.direction_x
        or self.target.last_direction_x or 1
    self.target.last_direction_y = self.target.direction_y ~= 0
        and self.target.direction_y
        or self.target.last_direction_y or 1

    self.target.direction_x = (self.target.range_x > 0 and 1)
        or (self.target.range_x < 0 and -1)
        or 0
    self.target.direction_y = (self.target.range_y > 0 and 1)
        or (self.target.range_y < 0 and -1)
        or 0

    local target_distance_x = self.target.x - self.x
    local target_distance_y = self.target.y - self.y

    self.target.distance = sqrt(
        target_distance_x ^ 2 + target_distance_y ^ 2
    )

    -- if (self:target_on_focus())
    --     and abs(target.distance) > self.tile_size * 2
    -- then
    --     -- target.range_x = 0
    --     -- target.range_y = 0
    --     -- target_distance_y = 0
    --     -- target_distance_x = 0
    --     -- target.last_y = nil
    --     -- target.last_x = nil
    --     -- target.distance = 0
    -- end

    self.target.angle_x = atan2(
        target_distance_y,
        target_distance_x
    )

    self.target.angle_y = atan2(
        target_distance_y,
        target_distance_x
    )
end

function Camera:target_on_focus()
    if not self.target then return false end
    if not self.target.y or not self.target.x then return false end
    return self.x == round(self.target.x) and self.y == round(self.target.y)
end

function Camera:set_focus_x(value)
    value = round(value)
    if self.focus_x ~= value then
        if self.target then
            self.target.x = nil
            self.follow_speed_x = sqrt(2 * self.acc_x * self.default_initial_speed_x)
        end
        self.focus_x = value
    end
end

function Camera:set_focus_y(value)
    value = round(value)
    if self.focus_y ~= value then
        if self.target then
            self.target.y = nil
            self.follow_speed_y = sqrt(2 * self.acc_y * self.default_initial_speed_y)
        end
        self.focus_y = value
    end
end

function Camera:set_position(x, y)
    self.x = (not self.lock_x and (x and x)) or self.x
    self.y = (not self.lock_y and (y and y)) or self.y
    self.x = round(self.x)
    self.y = round(self.y)
end

function Camera:jump_to(x, y)
    self:set_position(
        x - self.focus_x / self.scale,
        y - self.focus_y / self.scale
    )
end

--- TODO
function Camera:look_at(x, y)
    if self.target then
        self.target.x = x
        self.target.y = y
        self.target.last_x = x
        self.target.last_y = y
    end
    self:follow(x, y)
end

function Camera:move(dx, dy)
    self:set_position(
        dx and self.x + dx or self.x,
        dy and self.y + dy or self.y
    )
end

function Camera:set_bounds(left, right, top, bottom)
    self.bounds_left = left or self.bounds_left
    self.bounds_right = right or self.bounds_right
    self.bounds_top = top or self.bounds_top
    self.bounds_bottom = bottom or self.bounds_bottom

    if self.bounds_right - self.bounds_left < self.viewport_w / self.scale then
        self.bounds_right = self.bounds_left + self.viewport_w / self.scale
    end

    if self.bounds_bottom - self.bounds_top < self.viewport_h / self.desired_scale / self.scale then
        self.bounds_bottom = self.bounds_top + self.viewport_h / self.scale / self.desired_scale
        -- self.bounds_top = self.bounds_bottom - self.viewport_h / self.scale / self.desired_scale
    end
end

--- Receive the rect parameters in world coordinates.
---@param x number
---@param y number
---@param w number|nil
---@param h number|nil
function Camera:rect_is_on_view(x, y, w, h)
    w = w or 0
    h = h or 0
    x, y = self:world_to_screen(x, y)
    w, h = w * self.scale, h * self.scale

    local cx, cy = self:world_to_screen(self.x, self.y)
    local cw, ch = self.desired_canvas_w,
        self.desired_canvas_h

    -- do
    --     -- cx = cx + 32
    --     -- cy = cy + 32
    --     -- cw = cw - 32
    --     -- ch = ch - 32
    -- end

    return x + w > cx and x < cx + cw
        and y + h > cy and y < cy + ch
end

--- Checks if point is on screen.
---@param x number # position in x-axis (world coordinates)
---@param y number # position in y-axis (world coordinates)
---@return boolean
function Camera:point_is_on_view(x, y)
    return self:rect_is_on_view(x, y)
end

function Camera:point_is_on_screen(x, y)
    return self:rect_is_on_view(x, y)
end

-- function Camera:rect_is_on_screen(left, right, top, bottom)
--     local left, top = self:screen_to_world(left, top)
--     local right, bottom = self:screen_to_world(right, bottom)

--     local cLeft, ctop = self:screen_to_world(self.x, self.y)
--     local cright, cbottom = self:screen_to_world(
--         self.x + (self.viewport_w / self.scale),
--         self.y + self.viewport_h / self.scale
--     )

--     return (right >= cLeft and left <= cright)
--         and (bottom >= ctop and top <= cbottom)
-- end

-- function Camera:point_is_on_screen(x, y)
--     return self:rect_is_on_screen(x, x, y, y)
-- end

function Camera:is_locked_in_x()
    return self.lock_x
end

function Camera:is_locked_in_y()
    return self.lock_y
end

function Camera:update(dt)
    assert(self.scale and self.scale ~= 0, ">> Error: Scale cannot be zero or nil !!!")

    if self.target then
        local r
        r = self.movement_x and self.movement_x(self, dt)
        r = self.movement_y and self.movement_y(self, dt)
    end

    -- if self.is_shaking then
    shake_update(self, dt)
    -- end

    dynamic_zoom_update(self, dt)
    -- local temp = self:target_on_focus()
    -- self.zoom_rad = self.zoom_rad + (math.pi * 2) / 4 * dt
    -- -- self.scale = 1.5 + 2.9 / 2.0 / 5.0 * cos(self.zoom_rad)
    -- self.scale = 1.2 + 0.5 / 5.0 * cos(self.zoom_rad)
    -- if true then
    --     -- local lx = self.lock_x
    --     -- self:unlock_x_axis()
    --     -- self:set_position(0, 0)
    --     -- self:set_position(self.target.x, self.target.y)
    --     -- self.target.last_x = self.x
    --     -- self.target.last_y = self.y
    --     self.deadzone_w = self.tile_size * 2 * self.scale
    --     -- self:set_lock_x_axis(lx)
    -- end

    -- self.zoom_rad = self.zoom_rad + (math.pi * 2) / 10 * dt
    -- self.angle = self.zoom_rad

    -- local left, top, right, bottom, lock, px, py

    -- left, top = self:screen_to_world(self.bounds_left, self.bounds_top)
    -- right, bottom = self:screen_to_world(
    --     self.bounds_right - self.viewport_w / self.scale / self.desired_scale,
    --     self.bounds_bottom - self.viewport_h / self.scale / self.desired_scale
    -- )
    -- px, py = self:screen_to_world(self.x, self.y)

    -- --===================================
    local px = clamp(self.x, self.bounds_left, self.bounds_right - self.viewport_w / self.desired_scale / self.scale)

    local py = clamp(self.y, self.bounds_top, self.bounds_bottom - self.viewport_h / self.desired_scale / self.scale)

    self.x = round(px)
    self.y = round(py)
end

---@param duration any
---@param amplitude any
---@param factor any
---@param speed any
function Camera:shake_in_x(duration, amplitude, factor, speed)
    self.is_shaking = true
    self.shake_duration_x = duration
    self.shake_time_x = 0
    self.shake_amplitude_x = amplitude or self.tile_size * 0.3
    self.shake_amplitude_x = self.shake_amplitude_x / self.scale
    self.shake_x_factor = factor or math.random()
    self.shake_speed_x = speed or (0.7 * math.random())
    self.shake_rad_x = (math.pi) * math.random()
    self.shaking_in_x = true
    self.shake_offset_x = 0
end

---
---@param duration any
---@param amplitude any
---@param factor any
---@param speed any
function Camera:shake_in_y(duration, amplitude, factor, speed)
    self.is_shaking = true
    self.shake_duration_y = duration
    self.shake_time_y = 0
    self.shake_amplitude_y = amplitude or self.tile_size * 0.3
    self.shake_amplitude_y = self.shake_amplitude_y / self.scale
    self.shake_y_factor = factor or math.random()
    self.shake_speed_y = speed or (0.7 * math.random())
    self.shake_rad_y = (math.pi) * math.random()
    self.shaking_in_y = true
    self.shake_offset_y = 0
end

function Camera:stop_shaking()
    self.shaking_in_x = false
    self.shaking_in_y = false
end

---@param self JM.Camera.Camera
local function debbug(self)
    --Drawing a yellow rectangle
    if not self:hit_border() then
        love_set_color(1, 1, 0, 1)
    else
        love_set_color(1, 1, 0, 0.5)
    end

    local border_len = self.tile_size * self.scale * self.desired_scale
    do
        love.graphics.rectangle("line",
            self.viewport_x + border_len,
            self.viewport_y + border_len,
            self.viewport_w - border_len * 2,
            self.viewport_h - border_len * 2
        )

        -- Top-Middle
        love.graphics.line(
            self.viewport_x + self.viewport_w / 2,
            self.viewport_y,
            self.viewport_x + self.viewport_w / 2,
            self.viewport_y + border_len
        )

        --Bottom-Middle
        love.graphics.line(
            self.viewport_x + self.viewport_w / 2,
            self.viewport_y + self.viewport_h - border_len,
            self.viewport_x + self.viewport_w / 2,
            self.viewport_y + self.viewport_h
        )

        --Left-Middle
        love.graphics.line(
            self.viewport_x,
            self.viewport_y + self.viewport_h / 2,
            self.viewport_x + border_len,
            self.viewport_y + self.viewport_h / 2
        )

        love.graphics.line(
            self.viewport_x + self.viewport_w - border_len,
            self.viewport_y + self.viewport_h / 2,
            self.viewport_x + self.viewport_w,
            self.viewport_y + self.viewport_h / 2
        )
    end
    --===========================================================

    -- Showing the current state
    local r, g, b, a
    r, g, b, a = 1, 0, 0, 1

    local Font = _G.JM_Font

    love_set_color(r, g, b, a)

    if Font then
        --Font.current:push()
        --Font.current:set_font_size(clamp(round(12 * self.scale), 10, 14))
        local state = '<color>' .. self:get_state()
        Font:print(state,
            self.viewport_x + border_len + 2,
            self.viewport_y + self.viewport_h - border_len - 20)
        --Font.current:pop()

        -- Showing the message DEBUG MODE
        Font.current:push()
        Font.current:set_font_size(12)
        local fr = Font:get_phrase("<color><effect=ghost, min=0.4, max=1.0, speed=0.5>DEBUG MODE")
        fr:draw(
            self.viewport_x + self.viewport_w - border_len - fr:width() - 10,
            self.viewport_y + border_len + 10,
            "left"
        )
        Font.current:pop()
    end
end

function Camera:set_shader(shader)
    self.shader = shader
end

function Camera:attach(lock_shake)
    love_set_scissor(self:get_viewport())

    love_push()
    love_scale(self.scale)
    love_scale(self.desired_scale, self.desired_scale)

    local shake_x = (not lock_shake and self.shaking_in_x and self.shake_offset_x) or 0

    local shake_y = (not lock_shake and self.shaking_in_y and self.shake_offset_y) or 0

    love_translate(
        -self.x + (self.viewport_x / self.desired_scale / self.scale)
        + shake_x,
        -self.y + (self.viewport_y / self.desired_scale / self.scale)
        + shake_y
    )
end

function Camera:detach()
    -- local r
    -- r = (self.is_showing_grid and show_grid) and draw_grid(self)
    -- r = (self.show_world_boundary and show_bounds) and draw_bounds(self)
    love_pop()

    -- if show_bounds then
    --     if self.debug then debbug(self) end
    --     r = self.show_focus and show_focus(self)
    --     r = self.border_color and show_border(self)
    -- end

    love_set_scissor()
end

function Camera:draw_background()
    if not self.color then return end
    love_set_color(self.color_r, self.color_g, self.color_b, self.color_a)
    love_rect("fill", self.viewport_x, self.viewport_y, self.viewport_w,
        self.viewport_h)
end

-- Used after attach and before detach
function Camera:draw_grid()
    if self.is_showing_grid then
        draw_grid(self)
    end
end

-- Used after attach and before detach
function Camera:draw_world_bounds()
    if self.show_world_boundary then
        draw_bounds(self)
    end
end

--- Used after detach
function Camera:draw_info()
    local r
    if self.debug then debbug(self) end
    r = self.show_focus and show_focus(self)
    r = self.border_color and show_border(self)
end

function Camera:toggle_grid()
    if self.is_showing_grid then
        self.is_showing_grid = false
    else
        self.is_showing_grid = true
    end
end

function Camera:toggle_debug()
    if self.debug then
        self.debug = false
        self.show_focus = false
    else
        self.debug = true
        self.show_focus = true
    end
end

function Camera:toggle_world_bounds()
    if self.show_world_boundary then
        self.show_world_boundary = false
    else
        self.show_world_boundary = true
    end
end

function Camera:scissor_transform(x, y, w, h)
    -- Camera's default scissor
    local cx, cy, cw, ch = self.viewport_x,
        self.viewport_y,
        self.viewport_w,
        self.viewport_h

    --- The object scissor
    local sx, sy, sw, sh =
        (self.viewport_x / self.desired_scale / self.scale - self.x + x) * self.scale * self.desired_scale,
        (self.viewport_y / self.desired_scale / self.scale - self.y + y) * self.scale * self.desired_scale,
        w * self.scale * self.desired_scale,
        h * self.scale * self.desired_scale

    local rx = clamp(sx, cx, cx + cw)
    local ry = clamp(sy, cy, cy + ch)

    local rr = clamp(sx + sw, cx, cx + cw)
    local rb = clamp(sy + sh, cy, cy + ch)

    local rw = rr - rx
    local rh = rb - ry

    return rx, ry, rw, rh
end

function Camera:get_state()
    local left, top, right, bottom, px, py, text

    left, top = self:screen_to_world(self.bounds_left, self.bounds_top)
    right, bottom = self:screen_to_world(
        self.bounds_right - (self.viewport_w) / self.scale / self.desired_scale,
        self.bounds_bottom - (self.viewport_h) / self.scale / self.desired_scale
    )
    px, py = self:screen_to_world(self.x, self.y)

    text = self:target_on_focus() and "on target" or "chasing"

    if not self:target_on_focus() then
        text = self.lock_x and "x locked" or text
        text = self.lock_y and "y locked" or text
        text = (self.lock_x and self.lock_y) and "xy locked" or text
    end

    if px <= left or px >= right or py <= top or py >= bottom then
        text = text .. " - blocked by "
    end

    if px <= left then text = text .. "left" end

    if px >= right then
        text = text .. (text:find("left") and "-" or "")
        text = text .. "right"
    end

    if py <= top then
        text = text .. ((text:find("left") or text:find("right")) and "-" or "")
        text = text .. "top"
    end

    if py >= bottom then
        text = text .. ((text:find("left") or text:find("right") or text:find("top")) and "-" or "")
        text = text .. "bottom"
    end

    if py <= top and py >= bottom and px <= left and px >= right then
        text = "out of bounds"
    end

    text = not self.target and "no target" or text

    left, top, right, bottom, px, py = nil, nil, nil, nil, nil, nil

    return text
end

function Camera:hit_border()
    local state = self:get_state()
    return state:find("left")
        or state:find("right")
        or state:find("top")
        or state:find("bottom")
        or state == "out of bounds"
end

function Camera:y_screen_to_world(y)
    local x
    x, y = self:screen_to_world(x, y)
    return y
end

function Camera:x_screen_to_world(x)
    local y
    x, y = self:screen_to_world(x, y)
    return x
end

function Camera:y_world_to_screen(y)
    local x
    x, y = self:world_to_screen(x, y)
    return y
end

function Camera:x_world_to_screen(x)
    local y
    x, y = self:world_to_screen(x, y)
    return x
end

function Camera:set_lock_x_axis(value)
    self.lock_x = (value and true) or false
end

function Camera:unlock_x_axis()
    self.lock_x = false
end

function Camera:lock_x_axis()
    self.lock_x = true
end

function Camera:set_lock_y_axis(value)
    self.lock_y = (value and true) or false
end

function Camera:unlock_y_axis()
    self.lock_y = false
end

function Camera:lock_y_axis()
    self.lock_y = true
end

function Camera:lock_movements()
    self:set_lock_x_axis(true)
    self:set_lock_y_axis(true)
end

function Camera:unlock_movements()
    self:set_lock_x_axis(false)
    self:set_lock_y_axis(false)
end

return Camera
