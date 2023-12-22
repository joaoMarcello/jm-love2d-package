local lgx = love.graphics
local love_translate = lgx.translate
local love_pop = lgx.pop
local love_push = lgx.push
local love_scale = lgx.scale
local love_set_scissor = lgx.setScissor

local love_set_color = lgx.setColor
local love_rect = lgx.rectangle
local love_line = lgx.line
local sin, cos = math.sin, math.cos
local mfloor, mceil = math.floor, math.ceil
local m_min, m_max = math.min, math.max

---@type JM.Camera.Controller
local Controller = require((...):gsub("jm_camera", "cam_controllers.controller"))

---@type JM.Camera.ShakeController
local ShakeController = require((...):gsub("jm_camera", "cam_controllers.controller_shake"))

---@type JM.Camera.ZoomController
local ZoomController = require((...):gsub("jm_camera", "cam_controllers.controller_zoom"))

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

---@param self JM.Camera.Camera
local function draw_grid(self)
    local tile = self.grid_desired_tile
    local vx, vy, vw, vh = self:get_viewport_in_world_coord()
    local qx = mceil((self.bounds_right - self.bounds_left) / tile)
    local qy = mceil((self.bounds_bottom - self.bounds_top) / tile)

    local size = self.grid_num_tile

    for i = mfloor(self.x / tile), qx do
        local px = tile * i
        if px > vx + vw then break end

        if px % (tile * size) == 0 then
            love_set_color(0, 0, 0, 0.9)
            -- love.graphics.setLineWidth(2)
        else
            love_set_color(0, 0, 0, 0.3)
        end

        love_line(px, vy, px, vy + vh)
        love.graphics.setLineWidth(1)
    end

    for j = mfloor(self.y / tile), qy do
        local py = tile * j
        if py > vy + vh then break end
        if py % (tile * size) == 0 then
            love_set_color(0, 0, 0, 0.9)
            -- love.graphics.setLineWidth(2)
        else
            love_set_color(0, 0, 0, 0.3)
        end
        love_line(self.x, py, vx + vw, py)
        love.graphics.setLineWidth(1)
    end
end

---@param self JM.Camera.Camera
local function draw_bounds(self)
    local tile = self.tile_size
    local vx, vy, vw, vh = self:get_viewport_in_world_coord()
    vx = round(vx)
    vy = round(vy)
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
    local vx, vy, vw, vh = self:get_viewport_in_world_coord()
    local foc_x, foc_y = self.focus_x / self.scale, self.focus_y / self.scale

    -- Focus guide lines
    love_set_color(0, 0, 0, 0.1)
    love_rect("fill",
        vx + foc_x,
        vy, 2, vh
    )
    love_rect("fill", vx,
        vy + foc_y,
        vw,
        2
    )
    --=============================================================
    local target = self.controller_x.target
    if target then
        self.debug_trgt_rad = self.debug_trgt_rad + (math.pi * 2) / 0.3 * love.timer.getDelta()

        if self:target_on_focus() then
            love_set_color(0, 0.8, 0, 1)
        else
            love_set_color(0, 0.8, 0,
                0.7 + 0.7 * cos(self.debug_trgt_rad)
            )
        end

        -- local px, py = self:world_to_screen(self.target.x or self.target.last_x, self.target.y or self.target.last_y)

        local px = target.x or target.last_x
        local py = target.y or target.last_y

        px = px + foc_x
        py = py + foc_y
        love.graphics.circle("fill", px, py, 5)
    end

    -- Camera's focus
    if not self:target_on_focus() then
        love_set_color(0.7, 0, 0, 1)
    else
        love_set_color(1, 0, 0, 1)
    end
    love.graphics.circle("fill",
        vx + foc_x,
        vy + foc_y,
        3
    )

    local corner_esp = 2
    local corner_length = self.tile_size / 32 * 16

    if self:target_on_focus() then
        love_set_color(1, 1, 1, 1)
    elseif self:hit_border()
    then
        love_set_color(1, 0, 0, 1)
    else
        love_set_color(1, 1, 1, 0.6)
    end

    if true then
        -- Left-Top Corner
        love_rect("fill",
            vx + foc_x - self.deadzone_w / 2,
            vy + foc_y - self.deadzone_h / 2,
            corner_length,
            corner_esp)
        love_rect("fill",
            vx + foc_x - self.deadzone_w / 2,
            vy + foc_y - self.deadzone_h / 2,
            corner_esp,
            corner_length)

        -- Top-Right Corner
        love_rect("fill",
            vx + foc_x + self.deadzone_w / 2 - corner_length,
            vy + foc_y - self.deadzone_h / 2,
            corner_length,
            corner_esp)
        love_rect("fill",
            vx + foc_x + self.deadzone_w / 2,
            vy + foc_y - self.deadzone_h / 2,
            corner_esp,
            corner_length)

        --- Bottom-Right Corner
        love_rect("fill",
            vx + foc_x + self.deadzone_w / 2 - corner_length + corner_esp,
            vy + foc_y + self.deadzone_h / 2,
            corner_length,
            corner_esp)
        love_rect("fill",
            vx + foc_x + self.deadzone_w / 2,
            vy + foc_y + self.deadzone_h / 2 - corner_length,
            corner_esp,
            corner_length)

        --- Bottom-Left Corner
        love_rect("fill",
            vx + foc_x - self.deadzone_w / 2,
            vy + foc_y + self.deadzone_h / 2 - corner_length,
            corner_esp,
            corner_length)
        love_rect("fill",
            vx + foc_x - self.deadzone_w / 2,
            vy + foc_y + self.deadzone_h / 2,
            corner_length,
            corner_esp)
    end


    love_set_color(0.1, 0.1, 0.1, 1)
    local len_bar = corner_length
    local len_half = len_bar / 2

    -- Deadzone Right-Middle
    love_rect("fill",
        vx + foc_x + self.deadzone_w / 2 - len_half,
        vy + foc_y,
        len_bar,
        corner_esp)

    -- Deadzone Left-Middle
    love_rect("fill",
        vx + foc_x - self.deadzone_w / 2 - len_half,
        vy + foc_y,
        len_bar,
        corner_esp)

    -- Deadzone Top-Middle
    love_rect("fill",
        vx + foc_x,
        vy + foc_y - self.deadzone_h / 2 - len_half,
        corner_esp,
        len_bar)
    -- Deadzone Bottom-Middle
    love_rect("fill",
        vx + foc_x,
        vy + foc_y + self.deadzone_h / 2 - len_half,
        corner_esp,
        len_bar)
end

---@param self JM.Camera.Camera
local function show_border(self)
    if self.border_color[4] == 0 then return end

    local len = 2

    -- Drawind a border in the camera's viewport
    love_set_color(self.border_color)

    local vx, vy, vw, vh = self:get_viewport_in_world_coord()

    -- left
    love_rect("fill", vx, vy, len, vh)

    -- Right
    love_rect("fill", vx + vw - len, vy, len, vh)

    -- Top
    love_rect("fill", vx, vy, vw, len)

    -- -- Bottom
    love_rect("fill", vx, vy + vh - len, vw, len)
end

---@enum JM.Camera.Type
local TYPES = {
    Free = 0,
    SuperMarioWorld = 1,
    Metroid = 2,
    SuperMarioBros = 3,
    Zelda_ALTTP = 4,
    Zelda_GBC = 5,
    Metroidvania = 6,
    ModernMetroidVania = 7,
    FollowBoss = 8,
    MegaMan = 9,
    NewSuperMarioBros = 10,
}

---@class JM.Camera.Camera
local Camera = {
    Controller = Controller,
    Types = TYPES,
}
Camera.__index = Camera


---@param self JM.Camera.Camera
---@return JM.Camera.Camera
function Camera:new(args)
    local obj = {}
    setmetatable(obj, self)

    Camera.__constructor__(obj,
        args.x, args.y, args.w, args.h, args.bounds,
        args.device_width, args.device_height,
        args.desired_canvas_w, args.desired_canvas_h,
        args.tile_size, args.color, args.scale, args.type,
        args.show_grid, args.grid_tile_size, args.show_world_bounds,
        args.border_color, args.scene, args.min_zoom, args.max_zoom
    )

    return obj
end

function Camera:__constructor__(
    x, y, w, h, bounds,
    device_width, device_height, desired_canvas_w, desired_canvas_h,
    tile_size, color, scale, type_,
    allow_grid, grid_tile_size, show_world_bounds, border_color, scene, min_zoom, max_zoom
)
    local device_width = love.graphics.getWidth()
    local device_height = love.graphics.getHeight()

    ---@type JM.Scene
    self.scene = scene

    self.scale = scale or 1.0

    --- Viewport in real-screen coordinates
    self.viewport_x = x or 0
    self.viewport_y = y or 0

    self.viewport_w = w or device_width  -- self.device_width
    self.viewport_h = h or device_height -- self.device_height

    self.tile_size = tile_size or 32

    self.x = 0
    self.y = 0

    self.dx = 0
    self.dy = 0

    self.angle = 0

    self.controller_x = Controller:new(self, "x")
    self.controller_y = Controller:new(self, "y")

    self.controller_shake_x = ShakeController:new(self, 0)
    self.controller_shake_y = ShakeController:new(self, 0)

    self.controller_zoom = ZoomController:new(self, nil)

    self.focus_x = 0
    self.focus_y = 0
    self:set_focus_x(self.viewport_w * 0.5)
    self:set_focus_y(self.viewport_h * 0.5)

    self.deadzone_w = self.tile_size * 1.5
    self.deadzone_h = self.tile_size * 1.5

    self.bounds_left = bounds and bounds.left or 0
    self.bounds_top = bounds and bounds.top or 0
    self.bounds_right = bounds and bounds.right or self.viewport_w
    self.bounds_bottom = bounds and bounds.bottom or self.viewport_h / self.scale
    self:set_bounds()

    self.lock_x = false
    self.lock_y = false

    self.color = false --color and true or false
    self.color_r = color and color[1] or 0.5
    self.color_g = color and color[2] or 0.9
    self.color_b = color and color[3] or 0.9
    self.color_a = color and color[4] or 1

    self.debug = nil
    self.debug_msg_rad = 0
    self.debug_trgt_rad = 0

    self.show_world_boundary = show_world_bounds or self.debug
    self.show_focus = false or self.debug
    self.border_color = border_color --or { 1, 0, 0, 1 }
    self.is_showing_grid = self.debug or nil
    self.grid_desired_tile = self.tile_size * 1
    self.grid_num_tile = 4

    self.min_zoom = min_zoom or 0.5
    self.max_zoom = max_zoom or 1.5

    self.zoom_rad = 0

    self.is_visible = true

    self.custom_update = nil

    self.type = type_ or TYPES.SuperMarioWorld
    self:set_type(self.type)
end

function Camera:init()
    self.controller_shake_x.amplitude = 0
    self.controller_shake_y.amplitude = 0
    self.controller_x:reset()
    self.controller_y:reset()
    if self.__state then self.__state = "capture" end
end

---@param s JM.Camera.Controller.Types|"super mario world"|"metroid"|"metroidvania"|"modern metroidvania"|"follow boss"|"super mario bros"|"zelda gbc"|"megaman"|"new super mario bros"
function Camera:set_type(s)
    if type(s) == "string" then s = string.lower(s) end

    local cx = self.controller_x
    local cy = self.controller_y

    self.type = s

    if s == "super mario world" or s == TYPES.SuperMarioWorld then
        cx.focus_1 = 0.35
        cx.focus_2 = 1.0 - cx.focus_1
        cx.type = Controller.Type.dynamic
        cx.delay = 0.0
        cx:set_move_behavior(Controller.MoveTypes.smooth_dash)

        cy.type = Controller.Type.chase_when_not_moving
        cy.focus_1 = 0.5
        cy.focus_2 = 0.5
        cy.delay = 0.25
        self.deadzone_h = self.tile_size * 4
        cy:set_move_behavior(Controller.MoveTypes.fast_smooth)

        -- self.custom_update = function(self, dt)
        --     self.controller_y.speed = 0.9
        -- end

        return self:set_focus(self.viewport_w * cx.focus_1, self.viewport_h * cy.focus_2)
    elseif s == "new super mario bros" or s == TYPES.NewSuperMarioBros then
        cx.focus_1 = 0.4
        cx.focus_2 = 1.0 - cx.focus_1
        cx.delay = 0.0
        cx.type = Controller.Type.dynamic
        cx:set_move_behavior(Controller.MoveTypes.smooth_dash)

        cy.type = Controller.Type.normal
        cy.focus_1 = 0.5
        cy.focus_2 = 0.5
        cy.delay = 0.6
        cy:set_move_behavior(Controller.MoveTypes.fast_smooth)

        return self:set_focus(self.viewport_w * cx.focus_1, self.viewport_h * cy.focus_1)
    elseif s == "metroid" or s == TYPES.Metroid then
        cx.focus_1 = 0.5
        cx.focus_2 = 0.5
        cx.delay = 0.0
        cx.type = Controller.Type.normal

        cy.focus_1 = 0.5
        cy.focus_2 = 0.5
        cy.delay = 0.0
        cy.type = Controller.Type.normal

        return self:set_focus(self.viewport_w * cx.focus_1)
    elseif s == "metroidvania" or s == TYPES.Metroidvania then
        cx.focus_1 = 0.5
        cx.focus_2 = 0.5
        cx.delay = 0.0
        cx.type = Controller.Type.normal

        cy.focus_1 = 0.5
        cy.focus_2 = 0.8
        cy.delay = 0.0
        cy.type = Controller.Type.dynamic

        return self:set_focus(self.viewport_w * cx.focus_1, self.viewport_h * cy.focus_1)
    elseif s == "modern metroidvania" or s == TYPES.ModernMetroidVania then
        cx.focus_1 = 0.5
        cx.focus_2 = 0.5
        cx.type = Controller.Type.normal
        cx.delay = 0.0

        cy.focus_1 = 0.5
        cy.focus_2 = 0.5
        cy.type = Controller.Type.normal
        cy.delay = 0.5

        return self:set_focus(self.viewport_w * cx.focus_1, self.viewport_h * cy.focus_1)
        ---
    elseif s == "follow boss" or s == TYPES.FollowBoss then
        cx.focus_2 = 0.4
        cx.focus_1 = 1.0 - cx.focus_2
        cx.delay = 0.0
        cx.type = Controller.Type.dynamic

        cy.focus_2 = 0.4
        cy.focus_1 = 1 - cy.focus_2
        cy.delay = 0.0
        cy.type = Controller.Type.dynamic

        return self:set_focus(self.viewport_w * cx.focus_2, self.viewport_h * cy.focus_2)
    elseif s == "super mario bros" or s == TYPES.SuperMarioBros then
        cx.focus_1 = 0.4
        cx.focus_2 = 0.4
        cx.delay = 0.0
        cx.type = Controller.Type.normal

        self.custom_update = function(self, dt)
            if self.x < self.bounds_right - self.viewport_w / self.scale then
                self.bounds_left = round(self.x)
            end
            self.bounds_top = round(self.y)
            self.bounds_bottom = self.y + self.viewport_h / self.scale
        end

        return self:set_focus(self.viewport_w * cx.focus_1, self.viewport_h * cy.focus_1)
        ---
    elseif s == "zelda gbc" or s == TYPES.Zelda_GBC then
        cx.focus_1 = 0.5
        cx.focus_2 = 0.5
        cx.delay = 0.0
        cx.type = Controller.Type.normal
        cx:set_move_behavior(2)

        cy.focus_1 = 0.5
        cy.focus_2 = 0.5
        cy.delay = 0.0
        cy.type = Controller.Type.normal
        cy:set_move_behavior(2)

        self.bounds_left = round(self.x)
        self.bounds_top = round(self.y)
        self.bounds_right = self.bounds_left + self.viewport_w / self.scale
        self.bounds_bottom = self.bounds_top + self.viewport_h / self.scale

        self.__state = "capture"

        self.custom_update = function(self, dt)
            local cx = self.controller_x
            local cy = self.controller_y
            local target = cx.target
            if not target then return end

            if self.__state == "waiting" then
                self:set_focus(self.viewport_w * 0.5, self.viewport_h * 0.5)
                cx:set_state(1)
                cy:set_state(1)
                cx.speed = 2.0
                cy.speed = 2.0
                if target.rx > self.bounds_right
                    and target.range_x > 0
                then
                    self.__state = "allow_x"
                    self.bounds_right = self.bounds_right + self.viewport_w
                    self:set_focus_x(0)
                    cx:reset()
                elseif target.rx < self.bounds_left
                    and target.range_x < 0
                then
                    self.__state = "allow_x"
                    self.bounds_left = round(self.bounds_left - self.viewport_w)
                    self:set_focus_x(self.viewport_w)
                    cx:reset()
                    return
                elseif target.ry > self.bounds_bottom
                    and target.range_y > 0
                then
                    self.__state = "allow_y"
                    self.bounds_bottom = round(self.bounds_bottom + self.viewport_h)
                    self:set_focus_y(0)
                    cy:reset()
                elseif target.ry < self.bounds_top
                    and target.range_y < 0
                then
                    self.__state = "allow_y"
                    self.bounds_top = round(self.bounds_top - self.viewport_h)
                    self:set_focus_y(self.viewport_h)
                    cy:reset()
                    return
                end
            end

            if self.__state:match("allow") then
                local axis = self.__state:match("x") and "x" or "y"

                if axis == "x" then
                    cx:set_target(round(self.bounds_right - self.viewport_w), target.ry)
                else
                    cy:set_target(target.rx, round(self.bounds_bottom - self.viewport_h))
                end



                if (axis == "x" and cx:is_on_target())
                    or (axis == "y" and cy:is_on_target())
                then
                    self.__state = "capture"
                    return
                end
            end

            if self.__state == "capture" then
                cx:set_state(4)
                cy:set_state(4)

                self.bounds_left = round(self.x)
                self.bounds_top = round(self.y)
                self.bounds_right = self.bounds_left + self.viewport_w / self.scale
                self.bounds_bottom = self.bounds_top + self.viewport_h / self.scale
                self.__state = "waiting"
            end
        end
    end
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
    -- if not self.on_dynimac_zoom then return end

    -- local r = self:get_state():match("blocked") and self.zoom_final < 1
    -- if self.scale == self.zoom_final or r then
    --     self.on_dynimac_zoom = false
    --     return
    -- end

    -- self.scale = self.scale + (self.zoom_speed * dt) + self.zoom_acc * dt * dt / 2.0
    -- self.zoom_speed = self.zoom_speed + self.zoom_acc * dt

    -- if self.zoom_acc < 0 or self.zoom_speed < 0 then
    --     self.scale = clamp(self.scale, self.zoom_final, self.max_zoom)
    -- else
    --     self.scale = clamp(self.scale, self.min_zoom, self.zoom_final)
    -- end
    -- self:set_bounds()
end

function Camera:set_scale_dynamic(scale, duration)
    -- assert(scale and scale ~= 0, ">> Error: Scale cannot be nil or zero!")
    -- duration = duration or 1.0

    -- self.zoom_final = clamp(scale, self.min_zoom, self.max_zoom)

    -- local direction = (self.scale > self.zoom_final and -1 or 1)
    -- self.zoom_speed = speed and (speed * direction) or 0
    -- self.zoom_acc = not speed and math.abs(self.scale - self.zoom_final) / duration or 0
    -- self.zoom_acc = self.zoom_acc * direction
    -- self.on_dynimac_zoom = true

    self.controller_zoom:refresh(scale, duration)
end

function Camera:set_viewport(x, y, w, h)
    self.viewport_x = x or self.viewport_x
    self.viewport_y = y or self.viewport_y
    self.viewport_w = w or self.viewport_w
    self.viewport_h = h or self.viewport_h

    -- self.viewport_x = round(self.viewport_x)
    -- self.viewport_y = round(self.viewport_y)
    -- self.viewport_w = round(self.viewport_w)
    -- self.viewport_h = round(self.viewport_h)

    self:set_type(self.type)
    self:set_bounds()
end

--- Returns left, top, right and bottom!!!
function Camera:get_viewport_in_world_coord()
    local sx = self.controller_shake_x.value
    local sy = self.controller_shake_y.value

    return self.x - sx, self.y - sy, self.viewport_w / self.scale,
        self.viewport_h / self.scale
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

function Camera:follow(x, y, id)
    self.controller_x:set_target(x, y, id)
    self.controller_y:set_target(x, y, id)
end

function Camera:target_on_focus()
    local target = self.controller_x.target
    if not target then return false end

    return target.x == self.x and target.y == self.y
end

function Camera:set_focus_x(value)
    return self:set_focus(value, nil)
end

function Camera:set_focus_y(value)
    return self:set_focus(nil, value)
end

---@param x any value in screen coordinates
---@param y any value in screen coordinates
function Camera:set_focus(x, y)
    local lfx, lfy = self.focus_x, self.focus_y

    x = x and round(x) or lfx
    y = y and round(y) or lfy

    self.focus_x = x
    self.focus_y = y

    if self.focus_x ~= lfx then
        local controller = self.controller_x
        if controller and controller.target then
            controller:set_state(Controller.State.chasing, true)
        end
    end

    if self.focus_y ~= lfy then
        local controller = self.controller_y
        if controller and controller.target then
            controller:set_state(Controller.State.chasing, true)
        end
    end
end

function Camera:set_position(x, y, do_round)
    self.x = (not self.lock_x and x) or self.x
    self.y = (not self.lock_y and y) or self.y
    if do_round then
        self.x = round(self.x)
        self.y = round(self.y)
    end
end

function Camera:set_zoom(value, clamp_to_minscale)
    if value <= 0 then return false end
    local cur_scale = self.scale

    value = clamp(value, self.min_zoom, self.max_zoom)

    local offx = (self.focus_x / self.scale)
    local offy = (self.focus_y / self.scale)

    if value < cur_scale then
        local width = (self.bounds_right - self.bounds_left)
        local height = (self.bounds_bottom - self.bounds_top)

        local minscale = m_max(self.viewport_w / width, self.viewport_h / height)

        if value < minscale then
            self.scale = clamp_to_minscale and minscale or cur_scale
            self:keep_on_bounds()
            return false
        end
    end
    self.scale = value

    assert(self.scale and self.scale ~= 0, ">> Error: Scale cannot be zero or nil !!!")

    local x = offx - (self.focus_x / self.scale)
    local y = offy - (self.focus_y / self.scale)
    self.x = (self.x + x)
    self.y = (self.y + y)

    self:keep_on_bounds()

    return true
end

function Camera:set_scale(value)
    if not value then return end
    assert(value ~= 0)
    self.scale = value
end

function Camera:jump_to(x, y)
    self:set_position(
        x - self.focus_x / self.scale,
        y - self.focus_y / self.scale
    )
end

-- --- TODO
-- function Camera:look_at(x, y)
--     if self.target then
--         self.target.x = x
--         self.target.y = y
--         self.target.last_x = x
--         self.target.last_y = y
--     end
--     self:follow(x, y)
-- end

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

    if self.bounds_bottom - self.bounds_top < self.viewport_h / self.scale then
        self.bounds_bottom = self.bounds_top + self.viewport_h / self.scale
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
    -- cx = cx + self.viewport_x
    -- cy = cy + self.viewport_y
    local cw, ch = self.viewport_w,
        self.viewport_h
    -- local cw, ch = self.desired_canvas_w,
    --     self.desired_canvas_h

    -- do
    --     -- cx = cx + 32
    --     -- cy = cy + 32
    --     -- cw = cw - 32
    --     -- ch = ch - 32
    -- end

    return x + w >= cx and x <= cx + cw
        and y + h >= cy and y <= cy + ch
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

function Camera:is_locked_in_x()
    return self.lock_x
end

function Camera:is_locked_in_y()
    return self.lock_y
end

function Camera:keep_on_bounds()
    local px = clamp(self.x, self.bounds_left, self.bounds_right - self.viewport_w / self.scale)

    local py = clamp(self.y, self.bounds_top, self.bounds_bottom - self.viewport_h / self.scale)

    self.x = round(px)
    self.y = round(py)
end

---@param duration any
---@param amplitude any
---@param factor any
---@param speed any
function Camera:shake_in_x(duration, amplitude, factor, speed)
    return self:shake_x(amplitude, speed, duration, factor)
end

---
---@param duration any
---@param amplitude any
---@param factor any
---@param speed any
function Camera:shake_in_y(duration, amplitude, factor, speed)
    return self:shake_y(amplitude, speed, duration, factor)
end

function Camera:shake_x(amplitude, speed, duration, modifier)
    amplitude = amplitude or 0
    if amplitude < self.controller_shake_x.amplitude then return end
    return self.controller_shake_x:refresh(amplitude, speed, duration, modifier)
end

function Camera:shake_y(amplitude, speed, duration, modifier)
    amplitude = amplitude or 0
    if amplitude < self.controller_shake_y.amplitude then return end
    return self.controller_shake_y:refresh(amplitude, speed, duration, modifier)
end

---@param self JM.Camera.Camera
local function debbug(self)
    --Drawing a yellow rectangle
    if not self:hit_border() then
        love_set_color(1, 1, 0, 1)
    else
        love_set_color(1, 1, 0, 0.5)
    end

    local border_len = self.tile_size --/ self.scale

    local vx, vy, vw, vh = self:get_viewport_in_world_coord()
    vx = round(vx)
    vy = round(vy)
    do
        love.graphics.rectangle("line",
            vx + border_len,
            vy + border_len,
            vw - border_len * 2,
            vh - border_len * 2
        )

        -- Top-Middle
        love.graphics.line(
            vx + vw / 2,
            vy,
            vx + vw / 2,
            vy + border_len
        )

        --Bottom-Middle
        love.graphics.line(
            vx + vw / 2,
            vy + vh - border_len,
            vx + vw / 2,
            vy + vh
        )

        --Left-Middle
        love.graphics.line(
            vx,
            vy + vh / 2,
            vx + border_len,
            vy + vh / 2
        )

        love.graphics.line(
            vx + vw - border_len,
            vy + vh / 2,
            vx + vw,
            vy + vh / 2
        )
    end
    --===========================================================

    -- Showing the current state
    local r, g, b, a
    r, g, b, a = 1, 0, 0, 1

    local Font = JM:get_font() --_G.JM_Font

    love_set_color(r, g, b, a)

    if Font then
        Font:push()
        Font:set_font_size(8)
        local state = '<color>' .. self:get_state()
        Font:print(state,
            vx + border_len + 2,
            vy + vh - border_len - 20)
        Font:pop()

        -- Showing the message DEBUG MODE
        Font:push()
        Font:set_font_size(8)

        lgx.push()
        lgx.translate(vx, vy)
        Font:printx("<color><effect=ghost, min=0.4, max=1.0, speed=0.5>DEBUG MODE", 0, border_len + 10,
            vw - border_len - 10, "right")
        lgx.pop()
        Font:pop()
    end
end

function Camera:set_shader(shader)
    self.shader = shader
end

function Camera:draw_background()
    if not self.color then return end
    love_set_color(self.color_r, self.color_g, self.color_b, self.color_a)
    love_rect("fill", self.viewport_x, self.viewport_y, self.viewport_w,
        self.viewport_h)
end

-- Used after attach and before detach
function Camera:draw_info()
    local r
    r = self.is_showing_grid and draw_grid(self)
    r = self.show_world_boundary and draw_bounds(self)
    r = self.debug and debbug(self)
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

function Camera:scissor_transform(x, y, w, h, subpixel)
    subpixel = subpixel or 1

    -- Camera's default scissor
    local cx, cy, cw, ch = self.viewport_x,
        self.viewport_y,
        self.viewport_w,
        self.viewport_h

    cx = cx * subpixel
    cy = cy * subpixel
    cw = cw * subpixel
    ch = ch * subpixel

    --- The object scissor
    local sx, sy, sw, sh =
        (self.viewport_x / self.scale - self.x + x) * self.scale,
        (self.viewport_y / self.scale - self.y + y) * self.scale,
        w * self.scale,
        h * self.scale

    sx = sx * subpixel
    sy = sy * subpixel
    sw = sw * subpixel
    sh = sh * subpixel

    local rx = clamp(sx, cx, cx + cw)
    local ry = clamp(sy, cy, cy + ch)

    local rr = clamp(sx + sw, cx, cx + cw)
    local rb = clamp(sy + sh, cy, cy + ch)

    local rw = rr - rx
    local rh = rb - ry

    return rx, ry, rw, rh
end

function Camera:get_state()
    if not self.controller_x.target then
        return "no target"
    else
        local target = self.controller_x.target

        if self.x == target.x and self.y == target.y then
            return "on target"
        end

        local s = "chasing"

        if self.x <= self.bounds_left
            or self.x >= self.bounds_right - self.viewport_w / self.scale
            or self.y <= self.bounds_top
            or self.y >= self.bounds_bottom - self.viewport_h / self.scale
        then
            s = s .. " - blocked by"
        end

        if target.x ~= self.x then
            if self.x <= self.bounds_left
                and self.x >= self.bounds_right - self.viewport_w / self.scale
            then
                s = s .. " x axis"
            elseif self.x <= self.bounds_left then
                s = s .. " left"
            elseif self.x >= self.bounds_right - self.viewport_w / self.scale then
                s = s .. " right"
            end
        end

        if target.y ~= self.y then
            if self.y <= self.bounds_top
                and self.y >= self.bounds_bottom - self.viewport_h / self.scale
            then
                if s:match("left") or s:match("right") or s:match("axis") then
                    s = s .. " and y axis"
                else
                    s = s .. " y axis"
                end
            elseif self.y <= self.bounds_top then
                if s:match("left") or s:match("right") or s:match("axis") then
                    s = s .. " and top"
                else
                    s = s .. " top"
                end
            elseif self.y >= self.bounds_bottom - self.viewport_h / self.scale then
                if s:match("left") or s:match("right") or s:match("axis") then
                    s = s .. " and bottom"
                else
                    s = s .. " bottom"
                end
            end
        end

        if s:match("x axis") and s:match("y axis") then
            return "out of bounds"
        end

        return s
    end
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

function Camera:update(dt)
    assert(self.scale and self.scale ~= 0, ">> Error: Scale cannot be zero or nil !!!")

    local last_x, last_y = self.x, self.y

    self.controller_zoom:update(dt)

    self:keep_on_bounds()

    if self.custom_update then
        self:custom_update(dt)
    end

    self.controller_x:update(dt)
    self.controller_y:update(dt)

    self.controller_shake_x:update(dt)
    self.controller_shake_y:update(dt)


    self.dx = self.x - last_x
    self.dy = self.y - last_y
end

function Camera:attach(lock_shake, subpixel)
    local x, y, w, h = self:get_viewport()

    if subpixel then
        x = x * subpixel
        y = y * subpixel
        h = h * subpixel
        w = w * subpixel
    end

    love_set_scissor(x, y, w, h)

    love_push()
    love_scale(self.scale)

    local shake_x, shake_y = 0, 0
    if not lock_shake then
        shake_y = self.controller_shake_y.value
        shake_x = self.controller_shake_x.value
    end

    local tx = -round(self.x) + (self.viewport_x / self.scale) + shake_x
    local ty = -round(self.y) + (self.viewport_y / self.scale) + shake_y

    return love_translate(tx, ty)
end

function Camera:detach()
    self.controller_x:draw()
    self.controller_y:draw()
    love_pop()
    return love_set_scissor()
end

return Camera
