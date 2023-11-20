local GC = _G.JM.GameObject

---@class JM.GameMap : GameObject
local Object = setmetatable({}, GC)
Object.__index = Object

---@return JM.GameMap
function Object:new(x, y, w, h, draw_order, update_order, reuse_tab)
    local obj = GC:new(x, y, w, h, draw_order, update_order, reuse_tab)
    setmetatable(obj, self)
    Object.__constructor__(obj)
    return obj
end

function Object:__constructor__()
    self.camera = JM.Camera:new {
        x = 64 * 4,
        y = 64 * 4,
        w = 64 * 8,
        h = 64 * 4,
        tile_size = 16,
        bounds = { left = -math.huge, right = math.huge, top = -math.huge, bottom = math.huge },
        border_color = { 1, 0, 0, 1 },
    }
    self.camera:toggle_grid()
    self.camera:toggle_debug()
    self.camera:toggle_world_bounds()

    --
    self.update = Object.update
    self.draw = Object.draw
end

function Object:load()

end

function Object:init()

end

function Object:mousepressed(x, y, button, istouch, presses)
    if button == 3 then
        self.camera:toggle_debug()
        self.camera:toggle_grid()
        self.camera:toggle_world_bounds()
    end
end

function Object:mousereleased(x, y, button, istouch, presses)

end

function Object:mousemoved(x, y, dx, dy, istouch)
    local mx, my = self.gamestate:get_mouse_position(self.camera)
    self.camera:set_focus(self.camera:world_to_screen(mx, my))

    if ((dx and math.abs(dx) > 1) or (dy and math.abs(dy) > 1))
        and love.mouse.isDown(1)
        and self:mouse_is_on_view()
    then
        local qx = self.gamestate:monitor_length_to_world(dx, self.camera)
        local qy = self.gamestate:monitor_length_to_world(dy, self.camera)

        self.camera:move(-qx, -qy)
    end
end

function Object:wheelmoved(x, y, force)
    if not self:mouse_is_on_view() and not force then return false end

    local zoom
    local speed = 0.1
    if y > 0 then
        zoom = self.camera.scale + speed
    else
        zoom = self.camera.scale - speed
    end

    self.camera:set_zoom(zoom)
end

function Object:mouse_is_on_view()
    local mx, my = self.gamestate:get_mouse_position(self.camera)
    return self.camera:point_is_on_view(mx, my)
end

function Object:update(dt)
    local speed = 96 / self.camera.scale
    if love.keyboard.isDown("up") then
        self.camera:move(0, -speed * dt)
    elseif love.keyboard.isDown("down") then
        self.camera:move(0, speed * dt)
    end

    if love.keyboard.isDown("left") then
        self.camera:move(-speed * dt, 0)
    elseif love.keyboard.isDown("right") then
        self.camera:move(speed * dt, 0)
    end
end

function Object:my_draw()
    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, 64 * 3, 64 * 3)

    local mx, my = self.gamestate:get_mouse_position(self.camera)
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.rectangle("fill", mx, my, 16, 16)
end

function Object:draw()
    self.camera:attach(nil, self.gamestate.subpixel)
    GC.draw(self, self.my_draw)
    self.camera:draw_info()
    self.camera:detach()

    local font = JM:get_font()
    local r = self:mouse_is_on_view()
    font:print(r and "on view" or "out", self.camera.viewport_x, self.camera.viewport_y - 20)
end

return Object
