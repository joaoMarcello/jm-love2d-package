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
---@enum JM.Camera.Controller.States
local States = {
    chasing = 1,
    on_target = 2,
    no_target = 3,
    deadzone = 4,
}

---@enum JM.Camera.Controller.Types
local Types = {
    normal = 1,
    dynamic = 2,
    chase_when_not_moving = 3
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
    local cam            = self.camera
    local targ           = self.target

    local vx, vy, vw, vh = cam:get_viewport_in_world_coord()

    if self.time < 0 then
        self.time = self.time + dt
        if self.time > 0 then
            self.time = 0
            self.init_pos = self.camera[axis]
        else
            targ:refresh(targ.rx, targ.ry)
            return
        end
    end

    if axis == "x" and targ.rx > vx + vw then
        local diff = 0
        diff = (targ.rx) - (vx + vw)
        self.init_pos = self.init_pos + diff
        ---
    elseif axis == "y" and targ.ry > vy + vh then
        local diff = 0
        diff = (targ.ry) - (vy + vh)
        self.init_pos = self.init_pos + diff
    end

    self.time = self.time + (math.pi) / self.speed * dt

    if self.time < 0 then
        cam[axis] = self.init_pos
        return
    end

    self.time = Utils:clamp(self.time, 0, math.pi)

    local mult = (1 - (1 + math.cos(self.time)) / 2)
    local diff = targ[axis] - self.init_pos


    cam[axis] = self.init_pos + diff * mult

    if self.type == Types.dynamic then
        if self:target_changed_direction() then
            local viewport = "viewport_" .. (axis == "x" and "w" or "h")
            local direction = "direction_" .. axis

            if targ[direction] < 0 then
                cam["set_focus_" .. axis](cam, cam[viewport] * self.focus_2)
            else
                cam["set_focus_" .. axis](cam, cam[viewport] * self.focus_1)
            end

            self.state = nil
            self:set_state(States.chasing)
        end
        ---
    elseif self.type == Types.normal then
        -- if targ[axis] > self.init_pos and self.init_dir < 0 then
        --     self:set_state(States.on_target)
        -- end

        -- if targ[axis] < self.init_pos and self.init_dir > 0 then
        --     self:set_state(States.on_target)
        -- end
    end

    cam:keep_on_bounds()

    do
        local is_x = axis == "x"
        local lim_1 = is_x and "bounds_left" or "bounds_top"
        local lim_2 = is_x and "bounds_right" or "bounds_bottom"
        local viewport = is_x and "viewport_w" or "viewport_h"

        if cam[axis] <= cam[lim_1]
            or cam[axis] >= cam[lim_2] - cam[viewport] / cam.scale
        then
            -- self.time = math.pi
        end
    end

    if self.time == math.pi and self.target[axis] == cam[axis] then
        return self:set_state(States.on_target)
    end
end

---@param self JM.Camera.Controller
local function update_on_target(self, dt)
    local targ = self.target
    local type = self.type

    if not targ then return end

    if type == Types.dynamic then
        if self:target_changed_direction() then
            self:set_state(States.deadzone)
        end
    elseif type == Types.normal then
        if self.delay ~= 0 then
            if self:target_changed_direction() then
                self:set_state(States.chasing)
                -- self.speed = 2
                -- self.time = 0
                return
            end
        end
    end
    self.camera[self.axis] = targ[self.axis]
end

---@param self JM.Camera.Controller
local function update_on_deadzone(self, dt)
    local targ = self.target
    local cam  = self.camera

    if targ and self.type == Types.dynamic then
        local axis = self.axis
        local dimension = (axis == "x" and "w" or "h")
        local focus = "focus_" .. axis
        local deadzone = "deadzone_" .. dimension
        local real_pos = "r" .. axis

        local lim = cam[axis] + cam[focus] / cam.scale
        lim = lim - cam[deadzone] / 2

        if targ[real_pos] < lim then
            local targ_focus = cam["viewport_" .. dimension] * self.focus_2
            targ_focus = Utils:round(targ_focus)

            self:set_state(States.chasing)

            if cam[focus] ~= targ_focus then
                cam["set_focus_" .. axis](cam, targ_focus)
                self.speed = 1.5
            else
                self.speed = 1
            end
        elseif targ[real_pos] > lim + cam[deadzone] then
            local targ_focus = cam["viewport_" .. dimension] * self.focus_1
            targ_focus = Utils:round(targ_focus)

            self:set_state(States.chasing)

            if cam[focus] ~= targ_focus then
                cam["set_focus_" .. axis](cam, targ_focus)
                self.speed = 1.5
            else
                self.speed = 1
            end
        end
    end
end

---@class JM.Camera.Controller
local Controller = {
    Type = Types,
    State = States,
}
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
function Controller:__constructor__(camera, axis, delay, type)
    self.camera = camera
    ---@type JM.Camera.Controller.Target
    self.target = nil

    self.axis = axis or "x"

    self.focus_1 = 0.4
    self.focus_2 = 0.6

    self.delay = delay or 0.0
    self.speed = 10
    self.type = type or Types.normal

    if self.axis == "y" then
        self.focus_1 = 0.25
        self.focus_2 = 0.5
        self.delay = 0.5
    else
        self.type = Types.dynamic
    end
    self.delay = math.abs(self.delay)

    if self.type == Types.dynamic then
        camera["set_focus_" .. self.axis](camera,
            (self.axis == "x" and camera.viewport_w
                or camera.viewport_h) * self.focus_1
        )
    end


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

function Controller:target_changed_direction()
    local targ = self.target
    if targ then
        local axis = self.axis
        local dir = "direction_" .. axis
        local last_dir = "last_direction_" .. axis

        if (targ[dir] == -1 and targ[last_dir] > 0)
            or (targ[dir] == 1 and targ[last_dir] < 0)
        then
            return true
        end
    end
    return false
end

function Controller:reset()
    self.state    = nil
    self.init_pos = nil
    self.target   = nil
end

---@param new_state JM.Camera.Controller.States
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
        self.speed = 1.5
    elseif new_state == States.on_target then
        self.init_pos = cam[self.axis]
    elseif new_state == States.no_target then
        -- self.target = nil
    elseif new_state == States.deadzone then
        -- self.target = nil
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
    elseif self.state == States.deadzone then
        update_on_deadzone(self, dt)
    end

    self.camera:keep_on_bounds()
end

function Controller:draw()
    if self.target and self.axis == 'y' then
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

    local cam = self.camera
    local lgx = love.graphics
    if self.axis == "x" then
        lgx.setColor(0, 1, 1, 0.6)
        local px = cam.x + (cam.viewport_w / cam.scale) * self.focus_1
        lgx.line(px, cam.y, px, cam.y + cam.viewport_h / cam.scale)

        lgx.setColor(1, 1, 0, 0.6)
        local px2 = cam.x + (cam.viewport_w / cam.scale) * self.focus_2
        lgx.line(px2, cam.y, px2, cam.y + cam.viewport_h / cam.scale)
    else
        lgx.setColor(0, 1, 1, 0.6)
        local py = cam.y + (cam.viewport_h / cam.scale) * self.focus_1
        lgx.line(cam.x, py, cam.x + cam.viewport_w / cam.scale, py)

        lgx.setColor(1, 0, 1, 0.6)
        py = cam.y + (cam.viewport_h / cam.scale) * self.focus_2
        lgx.line(cam.x, py, cam.x + cam.viewport_w / cam.scale, py)
    end
end

return Controller
