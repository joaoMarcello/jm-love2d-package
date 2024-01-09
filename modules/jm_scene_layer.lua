local lgx = love.graphics
local ceil = math.ceil

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

---@param state JM.Scene
---@param args table
function Layer:__constructor__(state, args)
    self.factor_x = args.factor_x or 1
    self.factor_y = args.factor_y or 1
    self.scale = 1
    self.width = args.width or 64
    self.height = args.height or 64
    self.infinity_scroll_x = args.infinity_scroll_x or nil
    self.infinity_scroll_y = args.infinity_scroll_y or nil
    self.px = args.x or 0
    self.py = args.y or 0
    self.state = state
    self.lock_shake = args.lock_shake or nil
    self.lock_py = args.lock_py or nil
    self.lock_px = args.lock_px or nil
    self.custom_draw = args.custom_draw or args.draw or default
    self.update = args.custom_update or args.update or default
end

-- function Layer:update(dt)

-- end

---@param self JM.SceneLayer
---@param cam JM.Camera.Camera
local function draw_scroll_x(self, cam, qx)
    local scale = self.scale
    local draw = self.custom_draw
    local width = self.width
    local push, pop = lgx.push, lgx.pop
    local translate, love_scale = lgx.translate, lgx.scale

    for i = 0, qx - 1 do
        push()
        translate(width * i * scale, 0)
        love_scale(scale, scale)

        draw(cam)

        pop()
    end
end

---@param self JM.SceneLayer
---@param cam JM.Camera.Camera
local function draw_scroll_y(self, cam, qy, qx)
    local scale = self.scale
    local draw = self.custom_draw
    local height = self.height
    local push, pop = lgx.push, lgx.pop
    local translate, love_scale = lgx.translate, lgx.scale
    local infinity_scroll_x = self.infinity_scroll_x

    for i = 0, qy - 1 do
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


---@param cam JM.Camera.Camera
function Layer:draw(cam)
    local state = self.state
    local cx, cy = cam.x, cam.y
    local scale = cam.scale
    local angle = cam.angle
    local subpixel = state.subpixel
    local scix, sciy, sciw, scih = lgx.getScissor()
    local vx, vy, vw, vh = cam:get_drawing_viewport()

    local qx = ceil(vw / self.width) + 1
    local qy = ceil(vh / self.height) + 1

    do
        -- self.px = self.px - 64 * love.timer.getDelta() * self.factor_x
        -- self.py = self.py - 64 * love.timer.getDelta() * self.factor_y

        -- px = math.floor(cam.x + 0.5)
        -- py = math.floor(cam.y + 0.5)

        if self.lock_py then
            self.py = math.floor(cam.y + 0.5)
        end

        local rx = (cx * self.factor_x) - self.px
        local ry = (cy * self.factor_y) - self.py

        if self.infinity_scroll_y then
            cam:set_position(
                self.infinity_scroll_x
                and (rx % (self.width * self.scale) - vx + cam.viewport_x)
                or (rx - cx),
                ry % (self.height * self.scale) - vy + cam.viewport_y
            )
        elseif self.infinity_scroll_x then
            cam:set_position(
                rx % (self.width * self.scale) - vx + cam.viewport_x,
                ry - cy + cam.viewport_y
            )
        else
            cam:set_position(
                rx - cx + cam.viewport_x,
                ry - cy + cam.viewport_y
            )
        end
    end

    cam.scale = 1
    cam.angle = 0

    lgx.push()
    -- lgx.replaceTransform(tr)
    -- lgx.scale(subpixel, subpixel)
    cam:attach(nil, subpixel, self.lock_shake and -1.0 or 1.0)

    if self.infinity_scroll_y then
        draw_scroll_y(self, cam, qy, qx)
        ---
    elseif self.infinity_scroll_x then
        draw_scroll_x(self, cam, qx)
    else
        local sc = self.scale
        lgx.push()
        lgx.scale(sc, sc)
        self.custom_draw(cam)
        lgx.pop()
    end

    cam:detach()
    lgx.pop()

    cam.x, cam.y = cx, cy
    cam.scale = scale
    cam.angle = angle
    return lgx.setScissor(scix, sciy, sciw, scih)
end

return Layer
