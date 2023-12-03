local Utils = JM.Utils

---@class JM.Camera.Controller.Target
local Target = {}
Target.__index = Target

do
    ---@return JM.Camera.Controller.Target
    function Target:new(x, y, camera)
        local o = setmetatable({}, Target)
        Target.__constructor__(o, x, y, camera)
        return o
    end

    ---@param camera  JM.Camera.Camera
    function Target:__constructor__(x, y, camera)
        self.camera = camera
        self:refresh(x, y)
    end

    function Target:refresh(x, y)
        self.rx = x
        self.ry = y

        local cam = self.camera

        x = x - cam.focus_x / cam.scale
        y = y - cam.focus_y / cam.scale

        -- x = JM.Utils:round(x)
        -- y = JM.Utils:round(y)

        self.last_x = self.x or x
        self.last_y = self.y or y

        self.x = x
        self.y = y

        self.range_x = x - self.last_x
        self.range_y = y - self.last_y

        self.diff_x = x - cam.x
        self.diff_y = y - cam.y

        self.last_direction_x = self.direction_x ~= 0 and self.direction_x or self.last_direction_x or 1

        self.last_direction_y = self.direction_y ~= 0 and self.direction_y or self.last_direction_y or 1

        self.direction_x = (self.range_x > 0 and 1)
            or (self.range_x < 0 and -1) or 0

        self.direction_y = (self.range_y > 0 and 1)
            or (self.range_y < 0 and -1) or 0

        local target_distance_x = self.x - cam.x
        local target_distance_y = self.y - cam.y

        self.distance = math.sqrt(target_distance_x ^ 2 + target_distance_y ^ 2)

        self.angle = math.atan2(target_distance_y, target_distance_x)
    end
end
--===========================================================================
local States = {
    chasing = 1,
    on_target = 2,
    no_target = 3,
    deadzone = 4,
}

local StateToName = {
    [1] = "chasing",
    [2] = "on_target",
    [3] = "no_target",
    [4] = "deadzone",
}
--===========================================================================

---@param self JM.Camera.Controller
local function update_chasing(self, dt)
    local axis           = self.axis

    self.speed           = 10

    local vx, vy, vw, vh = self.camera:get_viewport_in_world_coord()

    if axis == "x" and self.target.rx > vx + vw then
        local diff = 0
        diff = (self.target.rx) - (vx + vw)

        self.init_pos = self.init_pos + diff
    elseif axis == "y" then

    end

    self.time = self.time + (math.pi) / self.speed * dt

    if self.time < 0 then
        return
    end

    self.time         = Utils:clamp(self.time, 0, math.pi)

    local mult        = (1 - (1 + math.cos(self.time)) / 2)
    local diff        = self.target[axis] - self.init_pos

    self.camera[axis] = self.init_pos + diff * mult



    if self.target[axis] > self.init_pos and self.init_dir < 0 then
        self:set_state(States.on_target)
    end

    if self.target[axis] < self.init_pos and self.init_dir > 0 then
        self:set_state(States.on_target)
    end

    if self.time == math.pi then
        return self:set_state(States.on_target)
    end
end

---@param self JM.Camera.Controller
local function update_on_target(self, dt)
    self.camera[self.axis] = self.target[self.axis]
end

---@class JM.Camera.Controller
local Controller = {}
Controller.__index = Controller
--===========================================================================

---@param camera JM.Camera.Camera
---@param axis "x"|"y"|nil
---@return JM.Camera.Controller
function Controller:new(camera, axis)
    local o = setmetatable({}, Controller)
    Controller.__constructor__(o, camera, axis)
    return o
end

---@param camera JM.Camera.Camera
function Controller:__constructor__(camera, axis)
    self.camera = camera
    ---@type JM.Camera.Controller.Target
    self.target = nil

    self.axis = axis or "x"

    self.focus_1 = 0.4
    self.focus_2 = 0.6

    self.speed = 10

    self.delay = 0.0

    self:set_state(States.no_target)
end

function Controller:set_target(x, y)
    if not self.target then
        self.target = Target:new(x, y, self.camera)
        self:set_state(States.chasing)
    else
        self.target:refresh(x, y)
    end
end

function Controller:reset()
    self.state    = nil
    self.init_pos = nil
    self.target   = nil
end

function Controller:set_state(new_state)
    if new_state == self.state then return false end
    local last = self.state
    self.state = new_state
    local cam = self.camera

    if new_state == States.chasing then
        self.init_pos = cam[self.axis]
        self.init_dir = self.target[self.axis] > self.init_pos and 1 or -1
        self.init_dist = self.init_pos - self.target["r" .. self.axis]
        self.time = -self.delay
    elseif new_state == States.on_target then
        self.init_pos = cam[self.axis]
    elseif new_state == States.no_target then
        self.target = nil
    elseif new_state == States.deadzone then
        self.target = nil
    end

    return true
end

function Controller:target_position_x()
    if not self.target then return "error" end

    local fx = self.init_pos
    if self.target.x < self.camera.x + self.camera.focus_x then return "right" end
    if self.target.x < self.camera.x + self.camera.focus_x then return "left" end
    return "equal"
end

function Controller:update(dt)
    if self.state == States.chasing then
        update_chasing(self, dt)
    elseif self.state == States.on_target then
        update_on_target(self, dt)
    end
end

function Controller:draw()
    if self.target then
        love.graphics.setColor(0, 1, 0)
        love.graphics.circle("fill", self.target.rx, self.target.ry, 3)

        local cam = self.camera
        local print = love.graphics.print
        love.graphics.setColor(0, 0, 0)

        print(string.format("%.2f", self.time), cam.x + 10, cam.y + 10)
        print(string.format("%.2f", 1 - (1 + math.cos(self.time)) / 2), cam.x + 10, cam.y + 10 + 16)
        print("State: " .. StateToName[self.state], cam.x + 10, cam.y + 26 + 16)
        -- print("TP= " .. self:target_position_x(), cam.x + 10, cam.y + 42 + 16)
        print("rx= " .. self.target.rx, cam.x + 10, cam.y + 58 + 16)
        print("x= " .. self.target.x, cam.x + 10, cam.y + 74 + 16)
        print("focus_x= " .. self.camera.focus_x, cam.x + 10, cam.y + 90 + 16)
        print("init_x= " .. self.init_pos, cam.x + 10, cam.y + 106 + 16)
        print("init_distx= " .. self.init_dist, cam.x + 10, cam.y + 124 + 16)
        print("cam_x= " .. cam.x, cam.x + 10, cam.y + 140 + 16)
        print("trgt_dx= " .. self.target.direction_x, cam.x + 10, cam.y + 156 + 16)
        print("trgt_last_dx= " .. self.target.last_direction_x, cam.x + 10, cam.y + 172 + 16)
    end

    if self.axis == "x" then
        local cam = self.camera
        love.graphics.setColor(0, 1, 1, 0.6)
        local px = cam.x + (cam.viewport_w / cam.scale) * self.focus_1
        love.graphics.line(px, cam.y, px, cam.y + cam.viewport_h / cam.scale)

        love.graphics.setColor(1, 1, 0, 0.6)
        local px2 = cam.x + (cam.viewport_w / cam.scale) * self.focus_2
        love.graphics.line(px2, cam.y, px2, cam.y + cam.viewport_h / cam.scale)
    end
end

return Controller
