local Transition = {}
Transition.__index = Transition

---@param scene JM.Scene
function Transition:new(scene, args)
    local obj = {}
    setmetatable(obj, self)
    Transition.__constructor__(obj, scene, args)
    return obj
end

---@param scene JM.Scene
function Transition:__constructor__(scene, args)
    self.mode_out = args.mode == "out"
    self.scene = scene
    self.color = args.color or { 1, 1, 1, 1 }

    self.time = 0
    self.duration = args.duration or 2

    if not self.mode_out then
        self.time = self.duration
    end
end

function Transition:update(dt)
    if self.mode_out then
        self.time = self.time + dt
    else
        self.time = self.time - dt
    end
end

function Transition:draw()
    local r, g, b = unpack(self.color)
    local w = self.scene.screen_w
    local h = self.scene.screen_h

    love.graphics.setColor(r, g, b, self.time / self.duration)
    love.graphics.rectangle("fill", 0, 0, w, h)
end

return Transition
