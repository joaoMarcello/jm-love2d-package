--[[
    This modules need the 'jm_camera.lua' to work.
]]

local path = (...)

local set_canvas = love.graphics.setCanvas
local clear_screen = love.graphics.clear
local set_blend_mode = love.graphics.setBlendMode
local translate = love.graphics.translate
local scale = love.graphics.scale
local push = love.graphics.push
local pop = love.graphics.pop
local set_color_draw = love.graphics.setColor
local love_draw = love.graphics.draw
local set_shader = love.graphics.setShader
local get_delta_time = love.timer.getDelta
local love_mouse_position = love.mouse.getPosition
local math_abs = math.abs
local love_set_scissor = love.graphics.setScissor

---@alias JM.Scene.Layer {draw:function, update:function, factor_x:number, factor_y:number, name:string, fixed_on_ground:boolean, fixed_on_ceil:boolean, top:number, bottom:number, shader:love.Shader, name:string}

local function round(value)
    local absolute = math.abs(value)
    local decimal = absolute - math.floor(absolute)

    if decimal >= 0.5 then
        return value > 0 and math.ceil(value) or math.floor(value)
    else
        return value > 0 and math.floor(value) or math.ceil(value)
    end
end

-- ---@param self JM.Scene
-- local function to_world(self, x, y, camera)
--     x = x / self.scale_x
--     y = y / self.scale_y

--     x = x - self.x
--     y = y - self.y

--     return x - camera.viewport_x, y - camera.viewport_y
-- end

---@param self  JM.Scene
local function draw_tile(self)
    local tile, qx, qy

    tile = self.tile_size_x * 4 * self.camera.scale * self.camera.desired_scale
    qx = (self.w - self.x) / tile
    qy = (self.h - self.y) / tile

    clear_screen(0.35, 0.35, 0.35, 1)
    set_color_draw(0.9, 0.9, 0.9, 0.3)

    for i = 0, qx, 2 do
        local x = self.x + tile * i + self.offset_x

        for j = 0, qy, 2 do
            love.graphics.rectangle("fill", x, self.y + tile * j, tile, tile)
            love.graphics.rectangle("fill", x + tile, self.y + tile * j + tile, tile, tile)
        end
    end
end

---@class JM.Scene
---@field load function
---@field init function
---@field keypressed function
---@field keyreleased function
---@field mousepressed function
---@field mousereleased function
---@field finish function
local Scene = {}
Scene.__index = Scene

---@param self JM.Scene
---@return JM.Scene
function Scene:new(x, y, w, h, canvas_w, canvas_h, bounds)
    local obj = {}
    setmetatable(obj, self)

    Scene.__constructor__(obj, x, y, w, h, canvas_w, canvas_h, bounds)

    return obj
end

function Scene:__constructor__(x, y, w, h, canvas_w, canvas_h, bounds)

    bounds = bounds or {
        left = -32 * 0,
        right = 32 * 60,
        top = -32 * 0,
        bottom = 32 * 12,
    }

    -- cam_config = cam_config or {
    --     color = { 1, 1, 1, 1 },
    --     border_color = { 0, 1, 1, 1 },
    --     scale = 1.0,
    --     show_grid = true,
    --     show_world_bounds = true,
    --     debug = true
    -- }

    -- the dispositive's screen dimensions
    self.dispositive_w = love.graphics.getWidth()
    self.dispositive_h = love.graphics.getHeight()

    -- the scene position coordinates
    self.x = x or 0
    self.y = y or 0

    -- the scene dimensions
    self.w = w or self.dispositive_w
    self.h = h or self.dispositive_h

    -- self.h = self.h - self.y
    -- self.w = self.w - self.x

    -- the game's screen dimensions
    self.screen_w = canvas_w or self.w
    self.screen_h = canvas_h or self.h

    self.tile_size_x = 32
    self.tile_size_y = 32

    self.world_left = bounds.left or 0
    self.world_right = bounds.right or 0
    self.world_top = bounds.top or (32 * 50)
    self.world_bottom = bounds.bottom or (32 * 50)

    do
        -- main camera's default configuration
        local config = {
            -- camera's viewport in desired game screen coordinates
            x = 0, --self.screen_w * 0,
            y = 0,
            w = self.screen_w - self.x * 0,
            h = self.screen_h - self.y * 0,

            -- world bounds
            bounds = {
                left = self.world_left,
                right = self.world_right,
                top = self.world_top,
                bottom = self.world_bottom
            },

            -- Device screen's dimensions
            device_width = self.dispositive_w,
            device_height = self.dispositive_h - math.abs(self.dispositive_h - self.h + self.y),

            -- The in-game screen's dimensions
            desired_canvas_w = self.screen_w,
            desired_canvas_h = self.screen_h,

            tile_size = self.tile_size_x,

            color = { 43 / 255, 78 / 255, 108 / 255, 1 },

            border_color = { 1, 1, 0, 1 },

            scale = 1.0,

            type = "metroid",

            show_grid = true,
            grid_tile_size = self.tile_size_x * 2,

            show_world_bounds = true
        }

        self.cameras_list = {}
        self.amount_cameras = 0

        self.camera = self:add_camera(config, "main")

        self.offset_x = (self.w - self.x - self.camera.viewport_w) / 2.0
    end


    self.n_layers = 0

    -- self.canvas = love.graphics.newCanvas(self.w, self.h)

    self.shader = nil

    -- used when scene is in frame skip mode
    self.__skip = nil

    self:implements({})
end

---@param config table
---@param name string
function Scene:add_camera(config, name)
    assert(name, "\n>> Error: You not inform the Camera's name.")

    assert(not self.cameras_list[name], "\n>> Error: A camera with the name '" .. tostring(name) .. "' already exists!")

    assert(not self.cameras_list[self.amount_cameras + 1])

    local Camera
    ---@type JM.Camera.Camera
    Camera = require(string.gsub(path, "jm_scene", "jm_camera"))

    assert(
        Camera,
        [[
        >> Error: Camera module not found. Make sure the file 'jm_camera.lua' is in same directory.
        ]]
    )

    if self.camera then
        config.device_width = self.camera.device_width
        config.device_height = self.camera.device_height

        config.desired_canvas_w = self.screen_w
        config.desired_canvas_h = self.screen_h

        config.bounds = {
            left = self.camera.bounds_left,
            right = self.camera.bounds_right,
            top = self.camera.bounds_top,
            bottom = self.camera.bounds_bottom
        }

        config.tile_size = self.camera.tile_size

        config.x = config.x + self.offset_x / self.camera.desired_scale
    end

    local camera = Camera:new(config)

    self.amount_cameras = self.amount_cameras + 1

    local w = (self.w - self.x - camera.viewport_w) / 2
    if name ~= "main" then w = 0 end

    camera.viewport_x = camera.viewport_x + (self.x + w)
    camera.viewport_y = camera.viewport_y + (self.y)
    camera:set_bounds()

    --camera:set_viewport(nil, nil, nil, self.screen_h - self.y / camera.desired_scale)
    -- camera:set_viewport(nil, nil, self.screen_w / camera.desired_scale, nil)

    -- camera.viewport_x = self.x / camera.desired_scale
    -- camera.viewport_y = self.y / camera.desired_scale

    self.cameras_list[self.amount_cameras] = camera

    self.cameras_list[name] = camera

    Camera = nil
    return camera
end

function Scene:get_color()
    return self.color_r, self.color_g, self.color_b, self.color_a
end

function Scene:set_color(r, g, b, a)
    self.color_r = r or self.color_r
    self.color_g = g or self.color_g
    self.color_b = b or self.color_b
    self.color_a = a or self.color_a
end

--- Converts the mouse position to Camera's World coordinates.
---@return integer x Mouse position in x-axis in world coordinates.
---@return integer y Mouse position in y-axis in world coordinates.
function Scene:get_mouse_position()
    local x, y = love_mouse_position()
    local ds = self.camera.desired_scale

    local offset = self.offset_x

    -- turning the mouse position into Camera's screen coordinates
    x, y = x / ds, y / ds
    x, y = x - (self.x + offset) / ds, y - self.y / ds

    x, y = self.camera:screen_to_world(x, y)

    return x, y
end

function Scene:to_camera_screen(x, y)
    x, y = x or 0, y or 0

    local ds = self.camera.desired_scale
    x, y = x / ds, y / ds
    --x, y = x - self.x, y - self.y

    return x, y
end

---@param index integer|string # Name or index of the camera.
---@return JM.Camera.Camera camera
function Scene:get_camera(index)
    return self.cameras_list[index]
end

---@return JM.Camera.Camera
function Scene:main_camera()
    return self.camera
end

function Scene:pause(time, action)
    if self.time_pause then
        return
    end
    self.time_pause = time
    self.pause_action = action or nil
end

function Scene:is_paused()
    return self.time_pause
end

---@param duration number|nil
---@param color table|nil
---@param delay number|nil
---@param action function|nil
---@param endAction function|nil
function Scene:fadeout(duration, color, delay, action, endAction)
    if self.fadeout_time then return end

    self.fadein_time = nil
    self.fadeout_time = 0.0
    self.fadeout_delay = delay or 0.5
    self.fadeout_duration = duration or 1.0
    self.fadeout_action = action or nil
    self.fadeout_end_action = endAction or nil
    self.fadeout_color = color or { 0, 0, 0 }
end

---@param duration number|nil
---@param color table|nil
---@param delay number|nil
---@param action function|nil
---@param endAction function|nil
function Scene:fadein(duration, color, delay, action, endAction)
    if self.fadein_time then return end

    self.fadeout_time = nil
    self.fadein_time = 0.0
    self.fadein_delay = delay or 0
    self.fadein_duration = duration or 0.3
    self.fadein_action = action or nil
    self.fadein_end_action = endAction or nil
    self.fadein_color = color or { 0, 0, 0 }
end

---@param self JM.Scene
local function fadein_out_draw(self, color, time, duration, fadein)
    local r, g, b = unpack(color)
    local alpha = time / duration
    set_color_draw(r, g, b, fadein and (1.0 - alpha) or alpha)

    love.graphics.rectangle("fill", 0, 0, self.dispositive_w, self.dispositive_h)
end

---@param skip integer
---@param duration number|nil
---@param on_skip_action function|nil
function Scene:set_frame_skip(skip, duration, on_skip_action)
    if skip <= 0 then
        self.frame_skip = nil
        self.frame_skip_duration = nil
        self.frame_count = nil
        self.on_skip_action = nil
        return
    end

    self.frame_count = 0
    self.frame_skip = skip
    self.frame_skip_duration = duration
    self.on_skip_action = on_skip_action
end

function Scene:turn_off_frame_skip()
    return self:set_frame_skip(0)
end

---@param self JM.Scene
---@return boolean should_skip
local function frame_skip_update(self)
    if self.frame_skip then
        -- dt = dt * self.frame_skip

        if self.frame_skip_duration then
            self.frame_skip_duration = self.frame_skip_duration - get_delta_time()

            if self.frame_skip_duration <= 0 then
                self.frame_skip_duration = 0.2
                self.frame_skip = self.frame_skip - 1
                if self.frame_skip <= 0 then self:set_frame_skip(0) end
            end
        end

        if self.frame_count then
            self.frame_count = self.frame_count + 1
            if self.frame_count < self.frame_skip then
                local r = self.on_skip_action and self.on_skip_action()
                return true
            else
                self.frame_count = 0
            end
        end
    end
    return false
end

local memo = setmetatable({}, { __mode = 'k' })

local function generic(callback)
    local result = callback and memo[callback]
    if result then return result end

    result =
    ---@param scene JM.Scene
    (function(scene, ...)
        if scene.time_pause or scene.fadeout_time then
            return
        end

        if (...) then
            local r = callback and callback(unpack { ... })
        else
            local r = callback and callback()
        end
        return true
    end)

    if callback then memo[callback] = result end

    return result
end

---
---@param param {load:function, init:function, update:function, draw:function, unload:function, keypressed:function, keyreleased:function, mousepressed:function, mousereleased: function, layers:table}
---
function Scene:implements(param)
    assert(param, "\n>> Error: No parameter passed to method.")
    assert(type(param) == "table", "\n>> Error: The method expected a table. Was given " .. type(param) .. ".")

    local love_callbacks = {
        "displayrotated",
        "draw",
        "errorhandler",
        "filedropped",
        "finish",
        "gamepadaxis",
        "gamepadpressed",
        "gamepadreleased",
        "init",
        "joystickadded",
        "joystickaxis",
        "joystickhat",
        "joystickpressed",
        "joystickreleased",
        "joystickremoved",
        "keypressed",
        "keyreleased",
        "load",
        "mousefocus",
        "mousemoved",
        "mousepressed",
        "mousereleased",
        "textedited",
        "textinput",
        "threaderror",
        "unload",
        "update",
        "visible",
        "wheelmoved",
        "quit",
    }

    for _, callback in ipairs(love_callbacks) do
        self[callback] = generic(param[callback])
    end

    if param.layers then
        local name = 1
        self.n_layers = #(param.layers)

        for i = 1, self.n_layers, 1 do
            local layer = param.layers[i]
            layer.x = layer.x or 0
            layer.y = layer.y or 0
            layer.factor_y = layer.factor_y or 0
            layer.factor_x = layer.factor_x or 0

            if not layer.name then
                layer.name = layer.name or ("layer " .. name)
                name = name + 1
            end

        end
    end

    self.update = function(self, dt)

        if self.time_pause then
            self.time_pause = self.time_pause - dt

            if self.time_pause <= 0 then
                self.time_pause = nil
                self.pause_action = nil
            else
                local r = self.pause_action and self.pause_action(dt)
                return
            end
        end

        if self.fadeout_time then
            if self.fadeout_delay > 0 then
                self.fadeout_delay = self.fadeout_delay - dt
            else
                self.fadeout_time = self.fadeout_time + dt
            end

            if self.fadeout_time <= self.fadeout_duration + 0.5
            then
                local r = self.fadeout_action and self.fadeout_action(dt)
                return
            else
                self.fadeout_time = nil
                local r = self.fadeout_end_action and self.fadeout_end_action()
            end
        end

        if self.fadein_time then
            if self.fadein_delay > 0 then
                self.fadein_delay = self.fadein_delay - dt
            else
                self.fadein_time = self.fadein_time + dt
            end

            if self.fadein_time <= self.fadein_duration + 0.5
            then
                local r = self.fadein_action and self.fadein_action(dt)
            else
                self.fadein_time = nil
                local r = self.fadein_end_action and self.fadein_end_action()
            end
        end

        self.__skip = frame_skip_update(self)
        if self.__skip then return end

        if param.layers then
            for i = 1, self.n_layers, 1 do
                local layer

                ---@type JM.Scene.Layer
                layer = param.layers[i]

                if layer.update then
                    layer:update(dt)
                end
                layer = nil
            end
        end

        local r = param.update and param.update(dt)

        for i = 1, self.amount_cameras do
            local camera
            ---@type JM.Camera.Camera
            camera = self.cameras_list[i]
            camera:update(dt)
            camera = nil
        end
    end

    self.draw = function(self)
        --set_canvas(self.canvas)
        -- set_blend_mode("alpha")
        -- set_color_draw(1, 1, 1, 1)

        love_set_scissor(self.x + self.offset_x, self.y, self.w - self.x - self.offset_x * 2, self.h - self.y)
        if self:get_color() then
            clear_screen(self:get_color())
        else
            draw_tile(self)
        end
        love_set_scissor()

        local temp = self.draw_background and self.draw_background()

        --=====================================================

        for i = 1, self.amount_cameras, 1 do
            local camera, r

            ---@type JM.Camera.Camera
            camera = self.cameras_list[i]

            if param.layers then
                for i = 1, self.n_layers, 1 do
                    local layer

                    ---@type JM.Scene.Layer
                    layer = param.layers[i]

                    -- camera:set_shader(self.shader)

                    if i == 1 then
                        camera:draw_background()
                    end

                    camera:attach()

                    push()

                    local px = -camera.x * layer.factor_x * (layer.factor_x > 0 and camera.scale or 1)
                    local py = -camera.y * layer.factor_y * (layer.factor_y > 0 and camera.scale or 1)

                    if layer.fixed_on_ground and layer.top then
                        if layer.top <= camera.y + layer.top then
                            py = 0
                        end
                    end

                    if layer.fixed_on_ceil and layer.bottom then
                        if py >= layer.bottom then
                            py = 0
                        end
                    end

                    translate(round(px), round(py))

                    r = layer.draw and layer:draw(camera)

                    pop()

                    local condition = not param.draw and i == self.n_layers
                    if condition then
                        camera:draw_grid()
                        camera:draw_world_bounds()
                    end

                    camera:detach()

                    if condition then
                        love.graphics.setScissor(camera:get_viewport())
                        camera:draw_info()
                        love.graphics.setScissor()
                    end

                    -- camera:set_shader()

                    layer = nil
                end -- END FOR Layers
            end

            if param.draw then
                -- set_blend_mode("alpha")
                -- set_color_draw(1, 1, 1, 1)

                if camera.color and not param.layers then
                    camera:draw_background()
                end

                camera:attach()

                r = param.draw and param.draw(camera)

                camera:draw_grid()
                camera:draw_world_bounds()

                camera:detach()

                love.graphics.setScissor(camera:get_viewport())
                camera:draw_info()
                love.graphics.setScissor()
            end

            camera = nil
        end

        -- love.graphics.setScissor(self.x,
        --     math_abs(self.h - self.dispositive_h),
        --     self.w, self.h
        -- )
        -- set_canvas()
        -- set_color_draw(1, 1, 1, 1)
        -- set_shader(self.shader)
        -- set_blend_mode("alpha", "premultiplied")
        -- love_draw(self.canvas)
        -- set_shader()
        -- set_blend_mode("alpha")
        -- love.graphics.setScissor()

        temp = self.draw_foreground and self.draw_foreground()

        if self.fadeout_time then
            fadein_out_draw(self, self.fadeout_color, self.fadeout_time, self.fadeout_duration)
        elseif self.fadein_time then
            fadein_out_draw(self, self.fadein_color,
                self.fadein_time,
                self.fadein_duration,
                true)
        end

        -- love.graphics.setColor(1, 1, 1, 1)
        -- love.graphics.rectangle("line", self.x, self.y, self.w - self.x, self.h - self.y)
    end

    self.mousepressed = function(self, x, y, button, istouch, presses)
        if self.time_pause then
            return
        end

        x, y = self:get_mouse_position()

        local r = param.mousepressed and param.mousepressed(x, y, button, istouch, presses)
    end

    self.mousereleased = function(self, x, y, button, istouch, presses)
        if self.time_pause then
            return
        end

        x, y = self:get_mouse_position()

        local r = param.mousereleased and param.mousereleased(x, y, button, istouch, presses)
    end

    self.keypressed = function(self, key, scancode, isrepeat)
        if self.time_pause then
            return
        end

        local r = param.keypressed and param.keypressed(key, scancode, isrepeat)
    end

    self.keyreleased = function(self, key, scancode)
        if self.time_pause then
            return
        end

        local r = param.keyreleased and param.keyreleased(key, scancode)
    end

end

function Scene:set_background_draw(action)
    self.draw_background = action
end

function Scene:set_foreground_draw(action)
    self.draw_foreground = action
end

function Scene:set_shader(shader)
    self.shader = shader
end

return Scene
