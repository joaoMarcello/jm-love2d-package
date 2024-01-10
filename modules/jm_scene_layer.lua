local lgx = love.graphics
local ceil = math.ceil
local floor = math.floor
-- local round = function(x)
--     return math.floor(x + .5)
-- end

local function round(x)
    local f = floor(x + .5)
    if (x == f) or (x % 2.0 == .5) then
        return f
    else
        return floor(x + .5)
    end
end

---@class JM.SceneLayer
---@field custom_draw function
local Layer = {}
Layer.__index = Layer

---@param state JM.Scene
---@return JM.SceneLayer
function Layer:new(state, args)
    ---@type JM.SceneLayer
    local obj = setmetatable({}, Layer)
    Layer.__constructor__(obj, state, args or {})
    return obj
end

local default = function(...) end
local default_color = { .8, .8, .8, 0 }

---@param state JM.Scene
---@param args table
function Layer:__constructor__(state, args)
    self.factor_x = args.factor_x or 1
    self.factor_y = args.factor_y or 1
    self.scale = 1
    self.angle = args.angle
    self.width = args.width or 64
    self.height = args.height or 64
    self.infinity_scroll_x = args.infinity_scroll_x or false
    self.infinity_scroll_y = args.infinity_scroll_y or false
    self.keep_proportions = args.keep_proportions or false
    self.px = args.x or 0
    self.py = args.y or 0
    self.gamestate = state
    self.lock_shake = args.lock_shake
    self.clear_color = args.clear_color
    -- if args.lock_shake then
    --     self.shake_factor_x = 1
    --     self.shake_factor_y = 1
    -- else
    --     self.shake_factor_x = args.shake_factor_x or 0
    --     self.shake_factor_y = args.shake_factor_y or 0
    -- end

    self.is_visible = true
    self.skip_clear = args.skip_clear
    self.skip_draw = args.skip_draw
    self.shader = args.shader

    -- self.lock_py = args.lock_py
    -- self.lock_px = args.lock_px
    self.custom_draw = args.custom_draw or args.draw or default
    self.update = args.custom_update or args.update or default
end

---@param self JM.SceneLayer
---@param cam JM.Camera.Camera
local function draw_scroll_x(self, cam, qx, qi)
    local scale = self.scale
    local draw = self.custom_draw
    local width = self.width
    local push, pop = lgx.push, lgx.pop
    local translate, love_scale = lgx.translate, lgx.scale

    qi = -1
    for i = qi or 0, qx - 1 do
        push()
        translate(width * i * scale, 0)
        love_scale(scale, scale)

        draw(cam)

        pop()
    end
end

---@param self JM.SceneLayer
---@param cam JM.Camera.Camera
local function draw_scroll_y(self, cam, qy, qx, qix, qiy)
    local scale = self.scale
    local draw = self.custom_draw
    local height = self.height
    local push, pop = lgx.push, lgx.pop
    local translate, love_scale = lgx.translate, lgx.scale
    local infinity_scroll_x = self.infinity_scroll_x

    for i = -1, qy - 1 do
        push()

        if not infinity_scroll_x then
            translate(0, height * i * scale)
            love_scale(scale, scale)

            draw(cam)
        else
            translate(0, height * i * scale)
            draw_scroll_x(self, cam, qx)
        end

        pop()
    end
end

---@param shader love.Shader|table
---@param action function|any
---@return love.Shader|table
function Layer:set_shader(shader, action)
    self.shader = shader
    if shader then
        self.shader_action = action
    end
    return shader
end

local function draw(self, cam, qx, qy)
    if self.infinity_scroll_y then
        -- return draw_scroll_y(self, cam, qy, qx, cx > vx and -1)
        return draw_scroll_y(self, cam, qy, qx, -1)
        ---
    elseif self.infinity_scroll_x then
        -- return draw_scroll_x(self, cam, qx, cx > vx and -1)
        return draw_scroll_x(self, cam, qx, -1)
    else
        local sc = self.scale
        lgx.push()
        lgx.scale(sc, sc)
        self.custom_draw(cam)
        return lgx.pop()
    end
end

local tr = love.math.newTransform()

---@param cam JM.Camera.Camera
---@param canvas1 love.Canvas|any
---@param canvas2 love.Canvas|any
function Layer:draw(cam, canvas1, canvas2)
    if not self.is_visible then return end

    -- local last_canvas = lgx.getCanvas()
    local shader = self.shader

    if canvas1 then
        lgx.setCanvas(canvas1)
        if not self.skip_clear then lgx.clear(self.clear_color or default_color) end
    end

    local state = self.gamestate
    local cx, cy = cam.x, cam.y
    local scale = cam.scale

    -- if self.keep_proportions then
    --     self.scale = 1 / scale
    -- end

    local angle = cam.angle
    local subpixel = state.subpixel
    local scix, sciy, sciw, scih = lgx.getScissor()
    local vx, vy, vw, vh = cam:get_drawing_viewport()

    local qx = ceil(vw / self.width) + 1
    local qy = ceil(vh / self.height) + 1

    do
        local rx = (cx * self.factor_x) - self.px
        local ry = (cy * self.factor_y) - self.py

        if self.infinity_scroll_y then
            -- cam:set_position(
            --     self.infinity_scroll_x
            --     and (rx % (self.width * self.scale) - vx * 0 + cam.viewport_x * 0)
            --     or (rx - cx * 0),
            --     ry % (self.height * self.scale) - vy * 0 + cam.viewport_y * 0
            -- )
            cam:set_position(
                self.infinity_scroll_x
                and (rx % (self.width))
                or (rx),
                ry % (self.height)
            )
        elseif self.infinity_scroll_x then
            cam:set_position(
                rx % (self.width),
                ry
            )
        else
            cam:set_position(
                rx,
                ry
            )
        end

        -- cam.x = round(cam.x)
        -- cam.y = round(cam.y)
    end

    cam.scale = self.scale
    cam.angle = self.angle or angle

    lgx.push()

    lgx.replaceTransform(tr)
    lgx.scale(subpixel, subpixel)

    cam:attach(nil, subpixel, self.lock_shake and -1.0 or 1.0)

    -- not using canvas
    if not canvas1 then
        lgx.setShader(self.shader)
        draw(self, cam, qx, qy)
        lgx.setShader()
    else
        draw(self, cam, qx, qy)
    end

    cam:detach()
    lgx.setScissor(scix, sciy, sciw, scih)

    if canvas1 and not self.skip_draw then
        local sc = 1.0 / subpixel -- / scale
        local px = 0              -- cx * 0 + cam.viewport_x --/ scale
        local py = 0              --cy * 0 + cam.viewport_y --/ scale

        if self.lock_shake then
            px = px + cam.controller_shake_x.value
            py = py + cam.controller_shake_y.value
        end

        px = round(px)
        py = round(py)

        if not shader or type(shader) ~= "table" then
            lgx.setCanvas(self.gamestate.canvas)
            lgx.setColor(1, 1, 1)
            -- lgx.setBlendMode("alpha", "premultiplied")

            lgx.setShader(shader)
            do
                local action = self.shader_action
                if action then
                    action(shader, 1)
                end
            end
            lgx.draw(canvas1, px, py, 0, sc, sc)
            lgx.setShader()
            ---
        else
            local list = shader
            local n = #list
            local filter = self.gamestate.canvas_filter

            lgx.setColor(1, 1, 1)

            for i = 1, n - 1 do
                local cur_shader = list[i]

                canvas1:setFilter(filter, filter)
                canvas2:setFilter("nearest", "nearest")

                lgx.setCanvas(canvas2)
                lgx.clear()

                do
                    lgx.setShader(cur_shader)
                    local action = self.shader_action
                    if action then action(cur_shader, n) end
                end

                lgx.draw(canvas1, 0, 0, 0, sc, sc)

                canvas1, canvas2 = canvas2, canvas1
            end
            canvas1:setFilter(filter, filter)
            canvas2:setFilter(filter, filter)

            lgx.setShader()

            lgx.setCanvas(self.gamestate.canvas)
            do
                local cur_shader = list[n]
                lgx.setShader(cur_shader)
                local action = self.shader_action
                if action then action(cur_shader, n) end
            end

            lgx.draw(canvas1, px, py, 0, sc, sc)
            lgx.setShader()
        end

        -- lgx.setBlendMode("alpha")
    end
    lgx.pop()

    cam.x, cam.y = cx, cy
    cam.scale = scale
    cam.angle = angle
end

return Layer
