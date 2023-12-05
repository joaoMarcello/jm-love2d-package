---@class JM.Camera.ShakeController
local Controller = {}
Controller.__index = Controller

---@param camera JM.Camera.Camera
---@return JM.Camera.ShakeController
function Controller:new(camera, amplitude, speed, duration, modifier)
    local o = setmetatable({}, Controller)
    Controller.__constructor__(o, camera, amplitude, speed, duration, modifier)
    return o
end

---@param camera JM.Camera.Camera
function Controller:__constructor__(camera, amplitude, speed, duration, modifier)
    self.camera = camera

    self.amplitude = amplitude or 5
    self.max_amplitude = self.amplitude
    self.time = modifier or 0
    self.speed = speed or 0.5
    self.duration = duration or 3.0
    self.value = 0
end

function Controller:refresh(amplitude, speed, duration, modifier)
    self:__constructor__(self.camera, amplitude, speed, duration, modifier)
end

function Controller:update(dt)
    if self.amplitude <= 0 then return end

    local PI = math.pi
    self.time = self.time + ((PI * 2) / self.speed) * dt

    if self.time > PI * 2 then
        self.time = self.time % (PI * 2)
    end

    self.value = self.amplitude * self.camera.scale * math.sin(self.time)

    if self.duration then
        self.amplitude = self.amplitude
            - ((self.max_amplitude) / self.duration) * dt

        if self.amplitude < 0 then self.amplitude = 0 end
    end
end

function Controller:finish()
    return self.amplitude <= 0
end

return Controller
