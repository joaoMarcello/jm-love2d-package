local Utils = _G.JM_Utils

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
    self.color = args.color or { 0, 0, 0, 1 }
    self.segment = args.segment or 6

    self.acc = 4 --self.scene.screen_w / 0.15
    self.speed = 0
    self.width = 0
    self.mult = 0
end

function Transition:update(dt)
    -- self.mult = (self.speed * dt + self.acc * dt * dt) / 2.0

    self.mult = self.mult + self.speed * dt + self.acc * dt * dt / 2

    self.width = self.scene.screen_w * self.mult
    self.width = Utils:clamp(self.width, 0, self.scene.screen_w)

    self.speed = self.speed + self.acc * dt
end

function Transition:draw()
    love.graphics.setColor(self.color)
    if self.mode_out then
        local px = 0
        local py = 0
        local size = (self.scene.screen_h / self.segment)

        for i = 1, self.segment do
            px = -(i - 1) * size * 1.5
            py = (i - 1) * size

            local w = self.scene.screen_w * self.mult
            w = Utils:clamp(w, 0, self.scene.screen_w - px)
            love.graphics.rectangle("fill", px, py, w, size)
        end
    else
        local size = (self.scene.screen_h / self.segment)

        for i = 1, self.segment do
            local px = -(i - 1) * size * 1.5
            local py = (i - 1) * size

            local w = self.scene.screen_w * self.mult
            w = Utils:clamp(w, 0, self.scene.screen_w * 2)

            love.graphics.rectangle("fill", w + px, py, self.scene.screen_w * 2, size)
        end
        -- love.graphics.rectangle("fill", self.width, 0, self.scene.screen_w - self.width, self.scene.screen_h)
    end
end

return Transition
