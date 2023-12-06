---@class JM.Camera.ZoomController
local Controller = {}
Controller.__index = Controller

---@param camera JM.Camera.Camera
---@return JM.Camera.ZoomController
function Controller:new(camera, zoom, speed)
    local o = setmetatable({}, Controller)
    Controller.__constructor__(o, camera, zoom, speed)
    return o
end

---@param camera JM.Camera.Camera
function Controller:__constructor__(camera, zoom, speed)
    self.camera = camera

    self.desired_scale = zoom
    self.init_scale = camera.scale
    self.time = 0.0
    self.speed = speed or 2.0

    if zoom then
        self.diff = math.abs(self.camera.scale - zoom)
        self.direction = self.camera.scale > zoom and -1 or 1
    end
end

function Controller:refresh(zoom, duration)
    return self:__constructor__(self.camera, zoom, duration)
end

function Controller:update(dt)
    local cam = self.camera
    if not self.desired_scale or cam.scale == self.desired_scale then
        return
    end

    self.time = self.time + (1.0 / self.speed) * dt
    if self.time > 1 then self.time = 1 end

    cam:set_zoom(self.init_scale + self.diff * self.time * self.direction, true)

    if cam.controller_x:is_on_target() then
        local targ = cam.controller_x.target
        targ.last_direction_x = targ.direction_x
        targ.last_direction_y = targ.direction_y
        targ.last_x = targ.x
        targ.last_y = targ.y
        -- targ.range_y = 0
        -- targ.range_x = 0
        cam.controller_x.target:refresh(targ.rx, targ.ry, targ.id)
        cam.controller_y.target:refresh(targ.rx, targ.ry, targ.id)
    end

    if self.time >= 1 then
        self.desired_scale = nil
    end
end

return Controller
