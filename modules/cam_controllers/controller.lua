local Utils = JM.Utils

---@enum JM.Camera.Controller.MoveTypes
local MoveTypes = {
    smooth = 1,
    linear = 2,
    fast_smooth = 3,
    balanced = 4,
}

local Behavior = {
    [MoveTypes.smooth] = function(x)
        return (1.0 - (1.0 + math.cos(x)) * 0.5)
    end,
    ---
    [MoveTypes.linear] = function(x)
        return x
    end,
    ---
    [MoveTypes.fast_smooth] = function(x)
        x = x - 2.718281828459
        local E_2x = 2.718281828459 ^ (2.0 * x)
        local r = (1.0 + (E_2x - 1.0) / (E_2x + 1.0)) * 0.5
        if x < 2.718281828459 then
            return r
        else
            return 1.0
        end
    end,
    ---
    [MoveTypes.balanced] = function(x)
        x = x - 4.0
        local r = (1 + (1.0 / (1.0 + (2.718281828459 ^ (-x))))) * 0.5
        do
            -- return 1.0
        end
        if x < 3.0 then
            return r
        else
            return 1.0
        end
    end,
    ---
}

local Domain = {
    [MoveTypes.smooth] = math.pi,
    [MoveTypes.linear] = 1.0,
    [MoveTypes.fast_smooth] = 2.718281828459 * 2.0,
    [MoveTypes.balanced] = 4 + 2.718281828459 * 2.0,
}
--==========================================================================

---@class JM.Camera.Controller.Target
local Target = {}
Target.__index = Target

do
    ---@return JM.Camera.Controller.Target
    function Target:new(x, y, camera, id)
        local o = setmetatable({}, Target)
        Target.__constructor__(o, x, y, camera, id)
        return o
    end

    ---@param camera  JM.Camera.Camera
    function Target:__constructor__(x, y, camera, id)
        self.camera = camera
        self:refresh(x, y, id)
    end

    function Target:refresh(x, y, id)
        self.rx = x
        self.ry = y

        local cam = self.camera

        x = x - cam.focus_x / cam.scale
        y = y - cam.focus_y / cam.scale

        x = Utils:round(x)
        y = Utils:round(y)

        self.last_x = self.x or x
        self.last_y = self.y or y

        self.x = x
        self.y = y

        self.last_id = self.id or self.last_id
        self.id = id

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

        -- local target_distance_x = self.x - cam.x
        -- local target_distance_y = self.y - cam.y

        -- self.distance = math.sqrt(target_distance_x ^ 2 + target_distance_y ^ 2)

        -- self.angle = math.atan2(target_distance_y, target_distance_x)
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

    -- if axis == "x" then self.speed = 8 end

    -- Dont allow target run off the screen
    if axis == "x" and targ.rx > vx + vw then
        local diff = targ.rx - (vx + vw)
        cam.x = cam.x + diff
        self.init_pos = self.init_pos + diff
        ---
    elseif axis == "x" and targ.rx < vx then
        local diff = targ.rx - vx
        cam.x = cam.x + diff
        self.init_pos = self.init_pos + diff
        ---
    elseif axis == "y" and targ.ry > vy + vh then
        local diff = (targ.ry) - (vy + vh)
        cam.y = cam.y + diff
        self.init_pos = self.init_pos + diff
        ---
    elseif axis == "y" and targ.ry < vy then
        local diff = targ.ry - vy
        cam.y = cam.y + diff
        self.init_pos = self.init_pos + diff
        ---
    end

    if self.type == Types.chase_when_not_moving then
        local range = axis == "x" and "range_x" or "range_y"

        if targ[range] ~= 0 then
            self.time = -self.delay

            if axis == "y" then
                local lim = vy + vh * 0.25
                if targ.ry < lim then
                    cam.y = cam.y + (targ.ry - lim)
                end

                lim = vy + vh * 0.75
                if targ.ry > lim then
                    cam.y = cam.y + (targ.ry - lim)
                end
            end

            local set_focus = "set_focus_" .. axis
            local viewport = (axis == "x" and "viewport_w" or "viewport_h")
            cam[set_focus](cam, self.focus_1 * cam[viewport])

            self.init_pos = cam[axis]
            targ:refresh(targ.rx, targ.ry)
            return
        end
    end


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


    self.time = self.time + (self.factor_domain / self.speed) * dt

    if self.get_factor ~= MoveTypes.balanced
        and self.get_factor ~= MoveTypes.fast_smooth
    then
        self.time = Utils:clamp(self.time, 0, self.factor_domain)
    end

    local diff = targ[axis] - self.init_pos

    local last = targ[axis] > cam[axis] and 1 or 0
    last = targ[axis] < cam[axis] and -1 or last

    cam[axis] = self.init_pos + diff * self.get_factor(self.time)

    if self.type == Types.dynamic then
        if self:target_changed_direction() then
            local viewport = "viewport_" .. (axis == "x" and "w" or "h")
            local direction = "direction_" .. axis

            if self.focus_1 <= self.focus_2 then
                if targ[direction] < 0 then
                    cam["set_focus_" .. axis](cam, cam[viewport] * self.focus_2)
                elseif targ[direction] > 0 then
                    cam["set_focus_" .. axis](cam, cam[viewport] * self.focus_1)
                end
            else
                if targ[direction] < 0 and targ[axis] > cam[axis] then
                    cam["set_focus_" .. axis](cam, cam[viewport] * self.focus_2)
                elseif targ[direction] >= 0 and targ[axis] < cam[axis] then
                    cam["set_focus_" .. axis](cam, cam[viewport] * self.focus_1)
                end
            end

            cam:keep_on_bounds()
            return self:set_state(States.chasing, true)
        end
        ---
    elseif self.type == Types.normal then
        -- local dir = targ[axis] > cam[axis] and 1 or 0
        -- dir = targ[axis] < cam[axis] and -1 or 0
        -- local range = targ["range_" .. axis]

        -- if (dir < 0 and last > 0)
        --     or (dir > 0 and last < 0)
        -- then
        --     cam[axis] = targ[axis]
        --     self:set_state(States.on_target)
        -- end
    end


    do
        local is_x = axis == "x"
        local lim_1 = is_x and "bounds_left" or "bounds_top"
        local lim_2 = is_x and "bounds_right" or "bounds_bottom"
        local viewport = is_x and "viewport_w" or "viewport_h"

        if cam[axis] < cam[lim_1]
            or cam[axis] > cam[lim_2] - cam[viewport] / cam.scale
        then
            self.time = self.factor_domain --math.pi
        end
    end

    cam:keep_on_bounds()

    if (self.time >= self.factor_domain and self.target[axis] == cam[axis])
        or targ[axis] == cam[axis]
    then
        return self:set_state(States.on_target)
    end
end

---@param self JM.Camera.Controller
local function update_on_target(self, dt)
    local targ = self.target
    local type = self.type
    local axis = self.axis

    if type == Types.dynamic then
        if self:target_changed_direction() then
            self:set_state(States.deadzone)
        end
    elseif type == Types.normal then
        if self.delay ~= 0 then
            if self:target_changed_direction()
                and not self:camera_hit_bounds()
            then
                self:set_state(States.chasing)
                self.speed = 1.5
                return
            end
        end
    elseif type == Types.chase_when_not_moving then
        local range = "range_" .. axis
        if targ[range] < 0 then
            self:set_state(States.chasing)
            self.speed = 2.0 * (math.abs(targ["diff_" .. axis]) / self.camera.tile_size)
            if self.speed < 0.9 then self.speed = 0.9 end
            if self.speed > 2 then self.speed = 2 end
            return
        end
    end

    self.camera[axis] = targ[axis]
    self.camera:keep_on_bounds()
end

---@param self JM.Camera.Controller
local function update_on_deadzone(self, dt)
    local targ = self.target
    local cam  = self.camera

    if self.type == Types.dynamic then
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
--===========================================================================


---@class JM.Camera.Controller
local Controller = {
    Type = Types,
    State = States,
    MoveTypes = MoveTypes,
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

    self.focus_1 = 0.5
    self.focus_2 = 1 - self.focus_1

    self.delay = delay or 0.0
    self.delay = math.abs(self.delay)

    self.speed = 10
    self.type = type or Types.normal

    -- self.targ_dir = nil

    self:set_move_behavior()

    self:set_state(States.no_target)
end

function Controller:set_target(x, y, id)
    if not self.target then
        self.target = Target:new(x, y, self.camera, id)
        self:set_state(States.chasing)
    else
        self.target:refresh(x, y, id)
    end
end

---@param b JM.Camera.Controller.MoveTypes|nil
function Controller:set_move_behavior(b)
    b = b or MoveTypes.smooth
    self.get_factor = Behavior[b]
    self.factor_domain = Domain[b]
end

---@param new_type JM.Camera.Controller.Types|string|"normal"|"dynamic"|"chase_when_not_moving"
function Controller:set_type(new_type)
    if new_type == self.type or not new_type then return false end

    if type(new_type) == "string" then
        return self:set_type(Types[new_type:lower()])
    end

    self.type = new_type

    local axis = self.axis
    local set_focus = "set_focus_" .. axis
    local cam = self.camera
    local viewport = axis == "x" and "viewport_w" or "viewport_h"

    cam[set_focus](cam, self.focus_1 * cam[viewport])

    return true
end

function Controller:get_target_relative_position()
    local axis = self.axis
    local target_pos = self.target[axis]
    local cam_pos = self.camera[axis]

    if target_pos > cam_pos then
        return 1
    elseif target_pos < cam_pos then
        return -1
    else
        return 0
    end
end

function Controller:camera_hit_bounds()
    local axis = self.axis
    local cam = self.camera
    local is_x = axis == "x"
    local lim_1 = is_x and "bounds_left" or "bounds_top"
    local lim_2 = is_x and "bounds_right" or "bounds_bottom"
    local viewport = is_x and "viewport_w" or "viewport_h"

    if cam[axis] <= cam[lim_1]
        or cam[axis] >= cam[lim_2] - cam[viewport] / cam.scale
    then
        return true
    end
    return false
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

function Controller:skip_delay()
    if self.time < 0 then self.time = 0 end
end

function Controller:is_on_target()
    if not self.target then return false end
    local axis = self.axis
    local cam = self.camera
    return cam[axis] == self.target[axis]
end

function Controller:reset()
    self.state    = nil
    self.init_pos = nil
    if not self.target then return end
    self.target = nil

    -- local target = self.target
    -- target.last_direction_x = nil
    -- target.last_direction_y = nil
    -- target.last_x = nil
    -- target.last_y = nil
    -- target.last_id = nil
    -- target:refresh(target.rx, target.ry, target.id)
    -- self:set_state(States.chasing, true)
end

---@param new_state JM.Camera.Controller.States
function Controller:set_state(new_state, force)
    if (new_state == self.state and not force)
        or not new_state
    then
        return false
    end

    self.state = new_state
    local cam = self.camera

    if not self.target then return end

    if new_state == States.chasing then
        self.init_pos = cam[self.axis]
        self.init_dist = self.init_pos - self.target["r" .. self.axis]
        self.time = -self.delay
        self.speed = 1.5
    elseif new_state == States.on_target then
        -- self.init_pos = cam[self.axis]
        self.target:refresh(self.target.rx, self.target.ry)
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
    local state = self.state

    if not self.target then
        return
    end

    if state == States.chasing then
        update_chasing(self, dt)
    elseif state == States.on_target then
        update_on_target(self, dt)
    elseif state == States.deadzone then
        update_on_deadzone(self, dt)
    end

    self.camera:keep_on_bounds()
end

function Controller:draw()
    local print = love.graphics.print
    local cam = self.camera
    if self.axis == 'y' and self.target then
        self.tt = self.tt or -2.71
        self.tt = self.tt + ((2.71 * 2) / 5.0) * love.timer.getDelta()
        print(Behavior[4](self.time), cam.x + 10, cam.y + 20)
        print("time: " .. self.time, cam.x + 10, cam.y + 36)
        print("diff_X: " .. self.target.diff_y, cam.x + 10, cam.y + 52)
    end
    do
        return
    end
    if self.target and self.axis == 'x' then
        -- love.graphics.setColor(0, 1, 0)
        -- love.graphics.circle("fill", self.target.rx, self.target.ry, 3)

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
        -- print(
        --     "trgt_dir= " ..
        --     (self.targ_dir and ((self.targ_dir == 1 and "right") or (self.targ_dir == -1 and "left") or (self.targ_dir == 0 and "on_focus")) or ""),
        --     cam.x + 10, cam.y + 172 + 16)
        print("range=" .. self.target.range_y, cam.x + 10, cam.y + 188 + 16)
    end

    local cam = self.camera
    local lgx = love.graphics
    do
        return
    end
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
