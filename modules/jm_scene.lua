--[[
    This modules need the 'jm_camera.lua' to work.
]]
local path = (...)

local lgx = love.graphics
local set_canvas = lgx.setCanvas
local get_canvas = lgx.getCanvas
local clear_screen = lgx.clear
local setBlendMode = lgx.setBlendMode
local translate = lgx.translate
local scale = lgx.scale
local push = lgx.push
local pop = lgx.pop
local setColor = lgx.setColor
local love_draw = lgx.draw
local setShader = lgx.setShader
local get_delta_time = love.timer.getDelta
local mouseGetPosition = love.mouse.getPosition
local abs, min, floor, ceil = math.abs, math.min, math.floor, math.ceil
local getScissor = lgx.getScissor
local setScissor = lgx.setScissor
local love_rect = lgx.rectangle
local mousePosition = love.mouse.getPosition
local collectgarbage = collectgarbage
local tab_insert, tab_sort, tab_remove = table.insert, table.sort, table.remove

local Transitions = {
    cartoon = require(string.gsub(path, "jm_scene", "transitions.cartoon")),
    curtain = require(string.gsub(path, "jm_scene", "transitions.curtain")),
    diamond = require(string.gsub(path, "jm_scene", "transitions.diamond")),
    door = require(string.gsub(path, "jm_scene", "transitions.door")),
    fade = require(string.gsub(path, "jm_scene", "transitions.fade")),
    masker = require(string.gsub(path, "jm_scene", "transitions.masker")),
    pass = require(string.gsub(path, "jm_scene", "transitions.pass")),
    stripe = require(string.gsub(path, "jm_scene", "transitions.stripe")),
    tile = require(string.gsub(path, "jm_scene", "transitions.tile")),
}

---@alias JM.Transitions.TypeNames "cartoon"|"curtain"|"diamond"|"door"|"fade"|"masker"|"pass"|"stripe"|"tile"

local SceneManager = _G.JM_SceneManager

---@type JM.GUI.VPad
local VPad = require(string.gsub(path, "jm_scene", "jm_virtual_pad"))

local Controllers = JM.ControllerManager

---@alias JM.Scene.Layer {draw:function, update:function, factor_x:number, factor_y:number, name:string, fixed_on_ground:boolean, fixed_on_ceil:boolean, top:number, bottom:number, shader:love.Shader, name:string, lock_shake:boolean, infinity_scroll_x:boolean, infinity_scroll_y:boolean, pos_x:number, pos_y:number, scroll_width:number, scroll_height:number, speed_x:number, speed_y: number, cam_px:number, cam_py:number, use_canvas:boolean, adjust_shader:function, skip_clear:boolean, skip_draw:boolean}

local function round(value)
    local absolute = abs(value)
    local decimal = absolute - floor(absolute)

    if decimal >= 0.5 then
        return value > 0 and ceil(value) or floor(value)
    else
        return value > 0 and floor(value) or ceil(value)
    end
end

---@param self  JM.Scene
local function draw_tile(self)
    local tile, qx, qy

    tile = self.tile_size_x * 4 * self.camera.scale
    qx = (self.screen_w) / tile
    qy = (self.screen_h) / tile

    clear_screen(0.35, 0.35, 0.35, 1)
    setColor(0.9, 0.9, 0.9, 0.3)

    for i = 0, qx, 2 do
        local x = tile * i

        for j = 0, qy, 2 do
            love_rect("fill", x, tile * j, tile, tile)
            love_rect("fill", x + tile, tile * j + tile, tile, tile)
        end
    end
end

local function create_canvas(width, height, filter, subpixel)
    local canvas = love.graphics.newCanvas(width * subpixel, height * subpixel, { dpiscale = 1 })
    canvas:setFilter(filter, filter)
    -- canvas:setWrap("clampzero", "clampzero", "clampzero")
    return canvas
end
--===========================================================================

---@class JM.Scene
---@field load function
---@field init function
---@field keypressed function
---@field keyreleased function
---@field mousepressed function
---@field mousereleased function
---@field mousemoved function
---@field finish function
---@field touchpressed function
---@field touchreleased function
---@field touchmoved function
---@field joystickpressed function
---@field joystickreleased function
local Scene = {
    ---@param config JM.GameState.Config
    change_gamestate = function(self, new_state, config)
        SceneManager:change_gamestate(new_state, config)
    end,
    --
    is_current_active = function(self)
        return SceneManager.scene == self
    end,
    --
    __is_scene = true,
}
Scene.__index = Scene

---@param self JM.Scene
---@return JM.Scene
function Scene:new(x, y, w, h, canvas_w, canvas_h, bounds, config)
    if type(x) == "table" then return self:new2(x) end

    local obj = {}
    setmetatable(obj, self)

    Scene.__constructor__(obj, x, y, w, h, canvas_w, canvas_h, bounds, config)

    return obj
end

---@param self JM.Scene
---@return JM.Scene
function Scene:new2(args)
    local bounds
    if args.bound_left or args.bound_right or args.bound_top or args.bound_bottom then
        bounds = {
            left = args.bound_left,
            right = args.bound_right,
            top = args.bound_top,
            bottom = args.bound_bottom,
        }
    end

    args.x = args.x or 0
    args.y = args.y or 0
    args.w = args.w and (args.x + args.w) or love.graphics.getWidth()
    args.h = args.h and (args.y + args.h) or love.graphics.getHeight()
    -- args.w = args.w - args.x
    -- args.h = args.h - args.y

    return self:new(args.x, args.y, args.w, args.h, args.canvas_w or args.canvas_width,
        args.canvas_h or args.canvas_height, bounds, args)
end

function Scene:__constructor__(x, y, w, h, canvas_w, canvas_h, bounds, conf)
    bounds = bounds or {
        left = -32 * 0,
        right = 32 * 60,
        top = -32 * 0,
        bottom = 32 * 12,
    }

    conf = conf or {}

    -- the dispositive's screen dimensions
    self.dispositive_w = love.graphics.getWidth()
    self.dispositive_h = love.graphics.getHeight()

    local dispositive_w = love.graphics.getWidth()
    local dispositive_h = love.graphics.getHeight()

    self.prev_state = nil

    -- the scene position coordinates
    self.x = x or 0
    self.y = y or 0

    -- the scene dimensions
    self.w = w or dispositive_w
    self.h = h or dispositive_h

    -- self.h = self.h - self.y
    -- self.w = self.w - self.x

    -- the game's screen dimensions
    self.screen_w = canvas_w or self.w
    self.screen_h = canvas_h or self.h

    self.tile_size_x = conf.tile or 32
    self.tile_size_y = conf.tile or 32

    self.world_left = bounds.left or 0
    self.world_right = bounds.right or 0
    self.world_top = bounds.top or (32 * 50)
    self.world_bottom = bounds.bottom or (32 * 50)

    do
        -- main camera's default configuration
        local config = {
            --
            name = "main",
            scene = self,
            --
            -- camera's viewport in desired game screen coordinates
            x = 0,
            y = 0,
            w = self.screen_w,
            h = self.screen_h,
            --
            -- world bounds
            bounds = {
                left = self.world_left,
                right = self.world_right,
                top = self.world_top,
                bottom = self.world_bottom
            },
            --
            -- Device screen's dimensions
            device_width = self.w - self.x,
            device_height = self.h - self.y,
            --
            -- The in-game screen's dimensions
            desired_canvas_w = self.screen_w,
            desired_canvas_h = self.screen_h,
            --
            --
            tile_size = conf.cam_tile or self.tile_size_x,
            color = { 43 / 255, 78 / 255, 108 / 255, 1 },
            border_color = conf.cam_border_color or nil, -- { 1, 1, 0, 1 },
            --
            --
            scale = conf.cam_scale or 1,
            type = conf.cam_type,
            --
            --
            show_grid = conf.cam_show_grid or false,
            grid_tile_size = (conf.cam_tile or self.tile_size_x) * 2,
            --
            show_world_bounds = conf.cam_show_world_bounds or false
        }

        self.cameras_list = {}
        self.amount_cameras = 0

        self.camera = self:add_camera(config)

        self.offset_x = 0
        self.offset_y = 0
    end


    self.n_layers      = 0
    self.shader        = nil

    -- used when scene is in frame skip mode
    self.__skip        = nil

    self.subpixel      = conf.subpixel or 4
    self.canvas_filter = conf.canvas_filter or 'linear'

    self.canvas        = create_canvas(
        self.screen_w,
        self.screen_h,
        self.canvas_filter,
        self.subpixel
    )

    self.canvas_scale  = 1

    self:implements {}

    self:calc_canvas_scale()

    self.capture_mode = false

    self.canvas_layer = nil

    self.use_vpad = conf.use_vpad or false

    self.show_border = conf.show_border or false

    self.use_stencil = conf.use_stencil or nil

    self.game_objects = {}
end

function Scene:get_vpad()
    return VPad
end

function Scene:change_game_screen(w, h)
    w = w or self.screen_w
    h = h or self.screen_h

    if w ~= self.screen_w or h ~= self.screen_h then
        for i = 1, self.amount_cameras do
            ---@type JM.Camera.Camera
            local cam = self.cameras_list[i]

            local prop_x = cam.viewport_x / self.screen_w
            local prop_y = cam.viewport_y / self.screen_h
            local prop_w = cam.viewport_w / self.screen_w
            local prop_h = cam.viewport_h / self.screen_h

            cam:set_viewport(w * prop_x, h * prop_y, w * prop_w, h * prop_h)
        end
        self.canvas:release()
        if self.canvas_layer then self.canvas_layer:release() end

        self.screen_w = w
        self.screen_h = h
        self.canvas = nil
        self.canvas_layer = nil
        self:restaure_canvas()
        self:calc_canvas_scale()

        collectgarbage()
        return true
    end
    return false
end

function Scene:restaure_canvas()
    if not self.canvas then
        self.canvas = create_canvas(self.screen_w, self.screen_h, self.canvas_filter, self.subpixel)
        self:calc_canvas_scale()
    end

    if self.using_canvas_layer and not self.canvas_layer then
        local w, h        = self.canvas:getDimensions()
        self.canvas_layer = love.graphics.newCanvas(w, h, { dpiscale = self.canvas:getDPIScale() })
        self.canvas_layer:setFilter(self.canvas_filter, self.canvas_filter)
    end
end

---@param config table
-- -@param name string
function Scene:add_camera(config)
    assert(config.name, "\n>> Error: You not inform the Camera's name.")

    assert(not self.cameras_list[config.name],
        "\n>> Error: A camera with the name '" .. tostring(config.name) .. "' already exists!")

    assert(not self.cameras_list[self.amount_cameras + 1])

    ---@type JM.Camera.Camera|nil
    local Camera = require(string.gsub(path, "jm_scene", "jm_camera"))

    assert(
        Camera,
        [[
        >> Error: Camera module not found. Make sure the file 'jm_camera.lua' is in same directory.
        ]]
    )

    if self.camera then
        -- config.device_width = self.camera.device_width
        -- config.device_height = self.camera.device_height

        config.desired_canvas_w = self.screen_w
        config.desired_canvas_h = self.screen_h

        config.bounds = {
            left = self.camera.bounds_left,
            right = self.camera.bounds_right,
            top = self.camera.bounds_top,
            bottom = self.camera.bounds_bottom
        }

        config.tile_size = self.camera.tile_size

        -- config.x = config.x + self.offset_x / self.camera.desired_scale
    end

    local camera = Camera:new(config)
    camera.scene = self

    self.amount_cameras = self.amount_cameras + 1

    -- local w = (self.w - self.x - camera.viewport_w) / 2
    -- if name ~= "main" then w = 0 end

    -- camera.viewport_x = camera.viewport_x + (self.x + w)
    -- camera.viewport_y = camera.viewport_y + (self.y)
    camera:set_bounds()

    self.cameras_list[self.amount_cameras] = camera

    self.cameras_list[config.name] = camera

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
---@param camera JM.Camera.Camera|nil
---@return integer x Mouse position in x-axis in world coordinates.
---@return integer y Mouse position in y-axis in world coordinates.
function Scene:get_mouse_position(camera)
    camera = camera or self.camera

    local x, y = mouseGetPosition()
    local ds --= self.camera.desired_scale

    ds = min((self.w - self.x) / self.screen_w,
        (self.h - self.y) / self.screen_h
    )

    local offset_x = self.offset_x
    local off_y = self.offset_y

    -- turning the mouse position into Camera's screen coordinates
    x, y = x / ds, y / ds
    x, y = x - (self.x + offset_x) / ds, y - (self.y + off_y) / ds

    x, y = camera:screen_to_world(x, y)

    return x - camera.viewport_x / camera.scale, y - camera.viewport_y / camera.scale
end

---@param camera JM.Camera.Camera|nil
function Scene:point_monitor_to_world(x, y, camera)
    camera = camera or self.camera
    x = x or 0
    y = y or 0

    local ds = min((self.w - self.x) / self.screen_w,
        (self.h - self.y) / self.screen_h
    )

    local offset_x = self.offset_x
    local off_y = self.offset_y

    -- turning the mouse position into Camera's screen coordinates
    x, y = x / ds, y / ds
    x, y = x - (self.x + offset_x) / ds, y - (self.y + off_y) / ds

    x, y = camera:screen_to_world(x, y)

    return x - camera.viewport_x / camera.scale, y - camera.viewport_y / camera.scale
end

---@param value number|nil number in monitor coordinates size
---@param cam JM.Camera.Camera|nil
---@return number v the value scaled to camera's coordinates
function Scene:monitor_length_to_world(value, cam)
    value = value or 0
    cam = cam or self.camera

    local ds = min((self.w - self.x) / self.screen_w,
        (self.h - self.y) / self.screen_h
    )
    return value / ds / cam.scale
end

function Scene:to_camera_screen(x, y)
    x, y = x or 0, y or 0

    local ds --= self.camera.desired_scale

    ds = min((self.w - self.x) / self.screen_w,
        (self.h - self.y) / self.screen_h
    )

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

function Scene:pause(time, action, draw)
    if not self:is_current_active() then
        return
    end

    if self.time_pause then
        return
    end
    self.time_pause = time
    self.pause_action = action or nil
    self.pause_draw = draw or nil
    collectgarbage("step")
end

function Scene:unpause()
    self.time_pause = nil
    self.pause_action = nil
    self.pause_draw = nil
end

function Scene:is_paused()
    return self.time_pause
end

---@param type_ JM.Transitions.TypeNames
---@param mode "in"|"out"
function Scene:add_transition(type_, mode, config, action, endAction, camera)
    type_ = type_ or "fade"
    mode = mode or "out"
    config = config or {}
    config.mode = config.mode or mode

    ---@type JM.Transition
    local Tran = Transitions[type_]

    if Tran then
        local x, y, w, h
        if camera then
            x, y, w, h = camera:get_viewport()
        else
            x, y, w, h = 0, 0, self.screen_w, self.screen_h
        end

        config.subpixel = self.subpixel
        -- config.anima = JM_Anima:new { img = '/data/image/baiacu.png' }
        -- config.anima:apply_effect("clockWise", { speed = 3 })
        local transition = Tran:new(config, x, y, w, h)

        ---@type JM.Transition
        self.transition = transition

        self.trans_action = action
        self.trans_end_action = endAction

        return transition
    end
end

function Scene:calc_canvas_scale()
    local windowWidth, windowHeight = (self.w - self.x), (self.h - self.y)
    local canvasWidth, canvasHeight = self.canvas:getDimensions()
    self.canvas_scale               = min(windowWidth / canvasWidth, windowHeight / canvasHeight)

    local canvasWidthScaled         = canvasWidth * self.canvas_scale
    local canvasHeightScaled        = canvasHeight * self.canvas_scale

    self.offset_x                   = floor((windowWidth - canvasWidthScaled) / 2)
    self.offset_y                   = floor((windowHeight - canvasHeightScaled) / 2)
end

---@param scene JM.Scene
---@param camera JM.Camera.Camera
function Scene:draw_capture(scene, camera, x, y, rot, sx, sy, ox, oy, kx, ky)
    local last_canvas = get_canvas()
    x = x or 0
    y = y or 0
    rot = rot or 0
    sx = sx or 1
    sy = sy or sx or 1
    ox = ox or 0
    oy = oy or 0
    kx = kx or 0
    ky = ky or 0

    local subpix = self.subpixel

    sx = sx / subpix * scene.subpixel
    sy = sy / subpix * scene.subpixel

    x = (x - camera.x) * scene.subpixel
    y = (y - camera.y) * scene.subpixel

    -- local scale = math_min((scene.w - scene.x) / scene.screen_w,
    --     768 / scene.screen_h
    -- )

    -- x = x + camera.viewport_x * subpix
    -- y = y + camera.viewport_y * scene.subpixel

    -- sx = sx * camera.scale
    -- sy = sy * camera.scale

    self.__transf = self.__transf or love.math.newTransform()
    self.capture_mode = true
    push()
    love.graphics.replaceTransform(self.__transf)

    local scx, scy, scw, sch = getScissor()

    if camera == scene.camera then
        setScissor()
        self:draw()
    end
    setColor(1, 1, 1, 1)
    setBlendMode("alpha", "premultiplied")


    setScissor(0, 0, camera.viewport_w * subpix, camera.viewport_h * subpix)
    love_draw(self.canvas, x, y, rot, sx, sy, ox, oy, kx, ky)

    setBlendMode("alpha")
    pop()
    self.capture_mode = false
    set_canvas(last_canvas)
    setScissor(scx, scy, scw, sch)
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
            if scene.time_pause --or scene.fadeout_time
                or (scene.transition and scene.transition.pause_scene)
            then
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

---@param self JM.Scene
---@param camera JM.Camera.Camera
---@param layer JM.Scene.Layer
local function infinity_scroll_x(self, camera, layer)
    if not layer.infinity_scroll_x then return false end

    local sum = layer.pos_x + camera.x
    local r

    local width = layer.scroll_width

    push()
    if abs(sum) >= width then
        translate(width * floor(sum / width), 0)
    end
    r = layer.draw and layer:draw(camera)

    local qx = floor((self.screen_w / camera.scale)
        / width) + 1

    --==================================================
    if abs(layer.pos_x + camera.x)
        < width
    then
        translate(-width, 0)
        r = layer.draw and layer:draw(camera)
        translate(width, 0)
    end
    --==================================================
    for i = 1, qx do
        translate(width, 0)
        r = layer.draw and layer:draw(camera)
    end

    pop()
end

---@param self JM.Scene
---@param camera JM.Camera.Camera
---@param layer JM.Scene.Layer
local function infinity_scroll_y(self, camera, layer)
    local sum = layer.pos_y + camera.y
    local height = layer.scroll_height

    push()

    if abs(sum) >= height then
        translate(0, height
            * floor(sum / height))
    end

    local r = layer.draw and not layer.infinity_scroll_x
        and layer:draw(camera)
    infinity_scroll_x(self, camera, layer)

    local qy = floor((self.screen_h / camera.scale)
        / height) + 1

    if abs(sum) < height then
        translate(0, -height)

        r = layer.draw and not layer.infinity_scroll_x
            and layer:draw(camera)
        infinity_scroll_x(self, camera, layer)

        translate(0, height)
    end

    for i = 1, qy do
        translate(0, height)
        r = layer.draw and not layer.infinity_scroll_x
            and layer:draw(camera)

        infinity_scroll_x(self, camera, layer)
    end

    pop()
end

---@param self JM.Scene
local update = function(self, dt)
    self:calc_canvas_scale()

    if self.use_vpad then
        VPad:update(dt)
    end

    if self.time_pause then
        self.time_pause = self.time_pause - dt

        if self.time_pause <= 0 then
            self.time_pause = nil
            self.pause_action = nil
            self.pause_draw = nil
        else
            local r = self.pause_action and self.pause_action(dt)
            return
        end
    end

    if self.transition then
        local dt = dt > (1 / 15) and (1 / 15) or dt
        self.transition:__update__(dt)
        local r = self.trans_action and self.trans_action(dt)

        r = not self.transition:is_paused()
            and self.transition:update(dt)

        if self.transition and self.transition.pause_scene
            and not self.transition:finished()
        then
            return
        end

        if self.transition:finished() then
            self.transition = nil
            self.trans_action = nil
            r = self.trans_end_action and self.trans_end_action(dt)
            self.trans_end_action = nil
            return
        end
    end

    local param = self.__param__

    self.__skip = frame_skip_update(self)
    if self.__skip then return end

    if param.layers then
        for i = 1, self.n_layers, 1 do
            ---@type JM.Scene.Layer
            local layer = param.layers[i]

            if layer.update then
                layer:update(dt)
            end
        end
    end



    local r = param.update and param.update(dt)

    Controllers.P1:update(dt)
    Controllers.P2:update(dt)


    for i = 1, self.amount_cameras do
        ---@type JM.Camera.Camera
        local camera = self.cameras_list[i]
        camera:update(dt)
    end
end

---@param self JM.Scene
local draw = function(self)
    local last_canvas = get_canvas()
    push()

    if self.use_stencil then
        set_canvas { self.canvas, stencil = true }
    else
        set_canvas(self.canvas)
    end

    if self.color_r then
        clear_screen(self.color_r, self.color_g, self.color_b, self.color_a)
    end

    scale(self.subpixel, self.subpixel)
    setBlendMode("alpha")
    setColor(1, 1, 1, 1)

    local sx, sy, sw, sh = getScissor()

    if not self.color_r then
        draw_tile(self)
    end

    -- local temp = self.draw_background and self.draw_background()

    --=====================================================
    local param = self.__param__

    for i = 1, self.amount_cameras do
        --
        ---@type JM.Camera.Camera
        local camera = self.cameras_list[i]
        local cam_is_visible = camera.is_visible

        if param.layers then
            for i = 1, self.n_layers, 1 do
                if not cam_is_visible then break end
                --
                ---@type JM.Scene.Layer
                local layer = param.layers[i]

                local last_canvas = self.canvas

                if layer.use_canvas then
                    set_canvas(self.canvas_layer)

                    local r = not layer.skip_clear
                        and clear_screen(.8, .8, .8, 0)
                    ---
                elseif layer.shader then
                    setShader(layer.shader)
                end

                local last_cam_px = camera.x
                local last_cam_py = camera.y
                local last_cam_scale = camera.scale

                camera:set_position(layer.cam_px, layer.cam_py)

                camera:attach(layer.lock_shake, self.subpixel)

                push()

                local px = -camera.x * layer.factor_x
                -- * (layer.factor_x > 0 and camera.scale or 1)
                local py = -camera.y * layer.factor_y
                -- * (layer.factor_y > 0 and camera.scale or 1)

                if layer.fixed_on_ground and layer.top then
                    if layer.top <= (camera.y + layer.top) / camera.scale
                    then
                        py = 0
                    end
                end

                if layer.fixed_on_ceil and layer.bottom then
                    if py >= layer.bottom then
                        py = 0
                    end
                end

                layer.pos_x = round(camera.x * layer.factor_x)
                layer.pos_y = round(camera.y * layer.factor_y)

                translate(round(px), round(py))

                if layer.infinity_scroll_y then
                    infinity_scroll_y(self, camera, layer)
                    --
                elseif layer.infinity_scroll_x then
                    --
                    infinity_scroll_x(self, camera, layer)
                    --
                else
                    --
                    layer:draw(camera)
                end

                if layer.use_canvas and not layer.skip_draw then
                    set_canvas(last_canvas)
                    local r = layer.shader and setShader(layer.shader)
                    setColor(1, 1, 1, 1)
                    -- set_blend_mode("alpha")
                    local px = camera.x + (px ~= 0 and layer.pos_x or 0)
                        - camera.viewport_x / camera.scale
                    px = round(px)

                    local py = camera.y + (py ~= 0 and layer.pos_y or 0)
                        - camera.viewport_y / camera.scale
                    py = round(py)

                    local scale = 1 / self.subpixel / camera.scale

                    love_draw(self.canvas_layer, px, py, 0, scale)

                    if layer.shader and layer.adjust_shader then
                        layer:adjust_shader(px, py, scale, camera)
                    end
                    setShader()
                end

                camera:set_position(last_cam_px, last_cam_py)
                camera.scale = last_cam_scale

                if layer.use_canvas and layer.skip_draw then

                else
                    set_canvas(last_canvas)
                end
                setShader()

                pop()

                -- local condition = not param.draw and i == self.n_layers
                -- if condition then
                --     camera:draw_info()
                -- end

                camera:detach()
                --
            end -- END FOR Layers
        end

        if param.draw and cam_is_visible then
            --
            camera:attach(nil, self.subpixel)

            param.draw(camera)

            camera:draw_info()

            camera:detach()
            --
        end

        if self.time_pause and self.pause_draw and cam_is_visible then
            camera:attach(nil, self.subpixel)
            self.pause_draw()
            camera:detach()
        end
    end -- END FOR CAMERAS


    if self.transition then
        self.transition:draw()
    end



    pop()
    set_canvas(last_canvas)

    if self.capture_mode then return end

    setColor(1, 1, 1, 1)
    setBlendMode("alpha", 'premultiplied')
    setShader(self.shader)

    do
        local canvas_scale = self.canvas_scale
        love_draw(self.canvas,
            self.x + self.offset_x,
            self.y + self.offset_y,
            0, canvas_scale, canvas_scale
        )
    end

    setBlendMode("alpha")
    setShader()

    if self.use_vpad and self:is_current_active() then
        VPad:draw()
    end
    -- love.graphics.setScissor(self.x,
    --     math_abs(self.h - self.dispositive_h),
    --     self.w, self.h
    -- )
    -- set_canvas()
    -- set_color_draw(1, 1, 1, 1)
    -- -- set_shader(self.shader)
    -- set_blend_mode("alpha", "premultiplied")
    -- self.canvas:setFilter("nearest", "nearest")
    -- love_draw(self.canvas)
    -- -- set_shader()
    -- set_blend_mode("alpha")
    -- love.graphics.setScissor()

    do
        local draw_foreground = self.draw_foreground
        if draw_foreground then draw_foreground(self) end
    end
    -- local r = self.draw_foreground and self.draw_foreground()

    setScissor(sx, sy, sw, sh)

    if self.show_border then
        setColor(1, 1, 1, 1)
        love_rect('line', self.x, self.y, self.w - self.x, self.h - self.y)
    end
end

---@param self JM.Scene
local init = function(self, ...)
    for i = 1, self.amount_cameras do
        ---@type JM.Camera.Camera
        local cam = self.cameras_list[i]
        cam:init()
        cam:set_type(cam.type)
    end

    if self.time_pause
        or (self.transition and self.transition.pause_scene)
    then
        return
    end

    if self.use_vpad then
        Controllers.P1:set_vpad(self:get_vpad())
    end

    local param = self.__param__
    local r = param.init and param.init(unpack { ... })
end

---@param self JM.Scene
local mousepressed = function(self, x, y, button, istouch, presses)
    if self.use_vpad and not istouch then
        Controllers.P1:set_state(Controllers.State.vpad)
        local mx, my = mousePosition()
        VPad:mousepressed(mx, my, button, istouch, presses)
    end

    if self.time_pause
        or (self.transition and self.transition.pause_scene)
    then
        return
    end

    local param = self.__param__

    x, y = self:get_mouse_position()

    local r = param.mousepressed and param.mousepressed(x, y, button, istouch, presses)
end

---@param self JM.Scene
local mousereleased = function(self, x, y, button, istouch, presses)
    if self.use_vpad and not istouch then
        Controllers.P1:set_state(Controllers.State.vpad)

        local mx, my = mousePosition()
        VPad:mousereleased(mx, my, button, istouch, presses)
    end

    if self.time_pause
        or (self.transition and self.transition.pause_scene)
    then
        return
    end

    x, y = self:get_mouse_position()

    local param = self.__param__
    local r = param.mousereleased and param.mousereleased(x, y, button, istouch, presses)
end

---@param self JM.Scene
local mousemoved = function(self, x, y, dx, dy, istouch)
    if self.time_pause
        or (self.transition and self.transition.pause_scene)
    then
        return
    end

    x, y = self:get_mouse_position()

    local param = self.__param__

    local r = param.mousemoved and param.mousemoved(x, y, dx, dy, istouch)
end

---@param self JM.Scene
local mousefocus = function(self, f)
    local param = self.__param__
    local r = param.mousefocus and param.mousefocus(f)
end

---@param self JM.Scene
local focus = function(self, f)
    local param = self.__param__
    local r = param.focus and param.focus(f)
end

---@param self JM.Scene
local visible = function(self, v)
    local param = self.__param__
    local r = param.visible and param.visible(v)
end

---@param self JM.Scene
local touchpressed = function(self, id, x, y, dx, dy, pressure)
    if self.use_vpad then
        Controllers.P1:set_state(Controllers.State.vpad)
        VPad:touchpressed(id, x, y, dx, dy, pressure)
    end

    if self.time_pause
        or (self.transition and self.transition.pause_scene)
    then
        return
    end

    -- x, y = self:point_monitor_to_world(x, y)

    local param = self.__param__
    local r = param.touchpressed and param.touchpressed(id, x, y, dx, dy, pressure)
end

---@param self JM.Scene
local touchreleased = function(self, id, x, y, dx, dy, pressure)
    if self.use_vpad then
        Controllers.P1:set_state(Controllers.State.vpad)
        VPad:touchreleased(id, x, y, dx, dy, pressure)
    end

    if self.time_pause
        or (self.transition and self.transition.pause_scene)
    then
        return
    end

    -- x, y = self:point_monitor_to_world(x, y)

    local param = self.__param__
    local r = param.touchreleased and param.touchreleased(id, x, y, dx, dy, pressure)
end

---@param self JM.Scene
local touchmoved = function(self, id, x, y, dx, dy, pressure)
    if self.time_pause
        or (self.transition and self.transition.pause_scene)
    then
        return
    end

    -- x, y = self:point_monitor_to_world(x, y)

    local param = self.__param__
    local r = param.touchmoved and param.touchmoved(id, x, y, dx, dy, pressure)
end

---@param self JM.Scene
local keypressed = function(self, key, scancode, isrepeat)
    if self.time_pause
        or (self.transition and self.transition.pause_scene)
    then
        return
    end

    local keyboard_owner = Controllers.keyboard_owner
    if keyboard_owner then
        keyboard_owner:set_state(Controllers.State.keyboard)
    end

    Controllers.P1:keypressed(key)
    Controllers.P2:keypressed(key)

    local param = self.__param__
    local r = param.keypressed and param.keypressed(key, scancode, isrepeat)
end

---@param self JM.Scene
local keyreleased = function(self, key, scancode)
    if self.time_pause
        or (self.transition and self.transition.pause_scene)
    then
        return
    end

    local keyboard_owner = Controllers.keyboard_owner
    if keyboard_owner then
        keyboard_owner:set_state(Controllers.State.keyboard)
    end

    Controllers.P1:keyreleased(key)
    Controllers.P2:keyreleased(key)

    local param = self.__param__
    local r = param.keyreleased and param.keyreleased(key, scancode)
end

local joystickpressed = function(self, joy, bt)
    if self.time_pause
        or (self.transition and self.transition.pause_scene)
    then
        return
    end

    local param = self.__param__
    local r = param.joystickpressed and param.joystickpressed(joy, bt)
end

local joystickreleased = function(self, joy, bt)
    if self.time_pause
        or (self.transition and self.transition.pause_scene)
    then
        return
    end

    local param = self.__param__
    local r = param.joystickreleased and param.joystickreleased(joy, bt)
end

local joystickadded = function(self, joy)
    local i = 1
    while i <= Controllers.n do
        ---@type JM.Controller
        local joystick = Controllers[i]

        local r = joystick:set_joystick(joy)
        if r then
            joystick:set_state(Controllers.State.joystick)
            Controllers.joy_to_controller[joy] = joystick

            Controllers:switch_keyboard_owner(Controllers[i + 1])
            break
        end
        i = i + 1
    end

    local param = self.__param__
    local r = param.joystickadded and param.joystickadded(joy)
end

local joystickremoved = function(self, joy)
    local i = 1

    while i <= Controllers.n do
        ---@type JM.Controller
        local controller = Controllers[i]

        if controller.joystick == joy then
            controller:remove_joystick()
            Controllers.joy_to_controller[joy] = nil
            Controllers:switch_keyboard_owner(Controllers.P1)
            controller:set_state(controller.State.keyboard)
            -- Controllers.keyboard_owner = Controllers.P1
            -- Controllers.P1.is_keyboard_owner = true
            break
        end
        i = i + 1
    end

    local param = self.__param__
    local r = param.joystickremoved and param.joystickremoved(joy)
end

local gamepadpressed = function(self, joy, bt)
    if self.time_pause
        or (self.transition and self.transition.pause_scene)
    then
        return
    end

    ---@type JM.Controller
    local vcontroller = Controllers.joy_to_controller[joy]

    if vcontroller then
        vcontroller:set_state(Controllers.State.joystick)
    end

    local param = self.__param__
    local r = param.gamepadpressed and param.gamepadpressed(joy, bt)
end

local gamepadreleased = function(self, joy, bt)
    if self.time_pause
        or (self.transition and self.transition.pause_scene)
    then
        return
    end

    ---@type JM.Controller
    local vcontroller = Controllers.joy_to_controller[joy]

    if vcontroller then
        vcontroller:set_state(Controllers.State.joystick)
    end

    local param = self.__param__
    local r = param.gamepadreleased and param.gamepadreleased(joy, bt)
end

local gamepadaxis = function(self, joy, axis, value)
    if self.time_pause
        or (self.transition and self.transition.pause_scene)
    then
        return
    end

    ---@type JM.Controller
    local vcontroller = Controllers.joy_to_controller[joy]

    if vcontroller then
        vcontroller:set_state(Controllers.State.joystick)
    end

    local param = self.__param__
    local r = param.gamepadaxis and param.gamepadaxis(joy, axis, value)
end

---@param self JM.Scene
local resize = function(self, w, h)
    local prop_x = self.x / self.dispositive_w
    local prop_y = self.y / self.dispositive_h
    local prop_w = self.w / self.dispositive_w
    local prop_h = self.h / self.dispositive_h

    self.w = w * prop_w
    self.h = h * prop_h
    self.x = w * prop_x
    self.y = h * prop_y

    self:calc_canvas_scale()
    self.dispositive_w, self.dispositive_h = w, h

    local param = self.__param__
    local r = param.resize and param.resize(w, h)
end

---
---@param param {load:function, init:function, update:function, draw:function, unload:function, keypressed:function, keyreleased:function, mousepressed:function, mousereleased: function, mousemoved: function, layers:table, touchpressed:function, touchreleased:function, touchmoved:function, resize:function, mousefocus:function, focus:function, visible:function}
---
function Scene:implements(param)
    assert(param, "\n>> Error: No parameter passed to method.")
    assert(type(param) == "table", "\n>> Error: The method expected a table. Was given " .. type(param) .. ".")

    local love_callbacks = {
        "displayrotated",
        -- "draw",
        "errorhandler",
        "filedropped",
        "finish",
        -- "gamepadaxis",
        -- "gamepadpressed",
        -- "gamepadreleased",
        "init",
        -- "joystickadded",
        "joystickaxis",
        "joystickhat",
        -- "joystickpressed",
        -- "joystickreleased",
        -- "joystickremoved",
        -- "keypressed",
        -- "keyreleased",
        "load",
        -- "mousefocus",
        -- "mousemoved",
        -- "mousepressed",
        -- "mousereleased",
        -- "resize",
        "textedited",
        "textinput",
        "threaderror",
        -- "touchpressed",
        -- "touchreleased",
        -- "touchmoved",
        "unload",
        -- "update",
        -- "visible",
        "wheelmoved",
        "quit",
    }

    self.__layers = param.layers
    self.__param__ = param

    param.draw = param.draw or (function()
    end)

    for _, callback in ipairs(love_callbacks) do
        self[callback] = generic(param[callback])
    end


    if param.layers then
        local name = 1
        self.n_layers = #(param.layers)

        local generic = function()
        end

        for i = 1, self.n_layers, 1 do
            local layer = param.layers[i]

            layer.x = layer.x or 0
            layer.y = layer.y or 0

            layer.factor_x = layer.factor_x or 0
            layer.factor_y = layer.factor_y or 0

            layer.pos_x = 0
            layer.pos_y = 0

            layer.cam_px = layer.speed_x and 0 or layer.cam_px
            layer.cam_py = layer.speed_y and 0 or layer.cam_py

            layer.scroll_width = layer.scroll_width or self.screen_w
            layer.scroll_height = layer.scroll_height or self.screen_h

            layer.draw = layer.draw or generic

            layer.index = i

            if layer.skip_draw then
                layer.use_canvas = true
                local next = self.__layers[i + 1]
                if next then
                    next.skip_clear = true
                    next.use_canvas = true
                end
            end

            if layer.shader or layer.use_canvas then
                self.using_canvas_layer = true

                self:restaure_canvas()
                -- self.canvas_layer = self.canvas_layer
                --     or love.graphics.newCanvas(self.canvas:getDimensions())

                -- self.canvas_layer:setFilter(self.canvas_filter,
                --     self.canvas_filter)
            end

            if not layer.name then
                layer.name = layer.name or ("layer " .. name)
                name = name + 1
            end
        end
    end

    self.update = update

    self.draw = draw

    self.init = init

    self.mousepressed = mousepressed

    self.mousereleased = mousereleased

    self.mousemoved = mousemoved

    self.mousefocus = mousefocus

    self.focus = focus

    self.visible = visible

    self.touchpressed = touchpressed

    self.touchreleased = touchreleased

    self.touchmoved = touchmoved

    self.keypressed = keypressed

    self.keyreleased = keyreleased

    self.joystickpressed = joystickpressed

    self.joystickreleased = joystickreleased

    self.joystickadded = joystickadded

    self.joystickremoved = joystickremoved

    -- self.joystickreleased = joystickreleased

    self.gamepadpressed = gamepadpressed

    self.gamepadreleased = gamepadreleased

    self.gamepadaxis = gamepadaxis

    self.resize = resize
end

---@param action function
function Scene:set_background_draw(action)
    self.draw_background = action
end

---@param action function
function Scene:set_foreground_draw(action)
    self.draw_foreground = action
end

function Scene:set_shader(shader)
    self.shader = shader
end

function Scene:rect_is_on_view(x, y, w, h)
    local N = self.amount_cameras

    if N == 1 then
        return self.camera:rect_is_on_view(x, y, w, h)
    else
        for i = 1, N do
            ---@type JM.Camera.Camera
            local cam = self.cameras_list[i]
            if cam:rect_is_on_view(x, y, w, h) then
                return true
            end
        end
    end

    return false
end

local sort_update = function(a, b) return a.update_order > b.update_order end
local sort_draw = function(a, b) return a.draw_order < b.draw_order end
local pairs = pairs

local ObjectRecycler = setmetatable({}, { __mode = 'k' })

local function push_object(obj)
    ObjectRecycler[obj] = true
end

local function pop_object(skip_clear)
    for obj, _ in pairs(ObjectRecycler) do
        ObjectRecycler[obj] = nil

        if not skip_clear then
            for key, v in pairs(obj) do
                obj[key] = nil
            end
        end

        return obj
    end
    return nil
end

Scene.ObjectRecycler = ObjectRecycler
Scene.push_object = push_object
Scene.pop_object = pop_object

function Scene:remove_object(index)
    ---@type GameObject | BodyObject
    local obj = self.game_objects[index]

    if obj then
        if obj.body then obj.body.__remove = true end

        return tab_remove(self.game_objects, index)
    end
end

function Scene:add_object(obj)
    tab_insert(self.game_objects, obj)
    return obj
end

function Scene:update_game_objects(dt)
    local list = self.game_objects
    tab_sort(list, sort_update)

    for i = #list, 1, -1 do
        ---@type GameObject
        local gc = list[i]

        if gc.__remove then
            self:remove_object(i)
            Scene.push_object(gc)
        else
            if gc.update and gc.is_enable then
                gc:update(dt)
            end

            if gc.__remove then
                gc.update_order = -100000
            end
            --
        end
        -- if gc.is_enable and not gc.__remove then
        --     gc:update(dt)
        -- end

        -- if gc.__remove then
        --     self:remove_object(i)
        -- end
    end
end

---@param camera JM.Camera.Camera | any
function Scene:draw_game_object(camera)
    local list = self.game_objects
    tab_sort(list, sort_draw)

    for i = 1, #list do
        ---@type GameObject
        local gc = list[i]

        if gc.draw and not gc.__remove then
            gc:draw(camera)
        end
    end
end

---@return any
function Scene:__get_data__()
    return false
end

return Scene
