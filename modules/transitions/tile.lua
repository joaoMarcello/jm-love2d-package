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

    self.acc = 4
    self.speed = 0
    self.mult = 0

    self.right_to_left = args.type and args.type == "right-left" or false

    self.up_to_down = args.type and args.type == "up-down" or false
    self.axis = args.axis or "x"
end

function Transition:finished()
    return self.mult >= 2
end

function Transition:update(dt)
    self.mult = self.mult + self.speed * dt + self.acc * dt * dt / 2
    self.speed = self.speed + self.acc * dt
end

function Transition:draw()
    love.graphics.setColor(self.color)

    if self.mode_out then
        if self.axis == "x" then
            local size = (self.scene.screen_h / self.segment)

            if not self.right_to_left then
                for i = 1, self.segment do
                    local px = -(i - 1) * size * 1.5
                    local py = (i - 1) * size

                    local w = self.scene.screen_w * self.mult
                    w = Utils:clamp(w, 0, self.scene.screen_w * 2)
                    love.graphics.rectangle("fill", px, py, w, size)
                end
            else
                for i = 1, self.segment do
                    local w = self.scene.screen_w * self.mult
                    w = Utils:clamp(w, 0, self.scene.screen_w * 2)

                    local py = (i - 1) * size

                    love.graphics.rectangle("fill", self.scene.screen_w - w + (i - 1) * size * 1.5, py, w, size)
                end
            end
        else
            local size = self.scene.screen_w / self.segment

            if self.up_to_down then
                for i = 0, self.segment do
                    local px = i * size
                    local hh = self.scene.screen_h * self.mult
                    hh = Utils:clamp(hh, 0, self.scene.screen_h + size * self.segment)

                    love.graphics.rectangle("fill", px, 0, size, hh - size * i)
                end
            else
                for i = 0, self.segment - 1 do
                    local px = i * size
                    local hh = self.scene.screen_h * self.mult
                    hh = Utils:clamp(hh, 0, self.scene.screen_h + size * self.segment)

                    love.graphics.rectangle("fill", px, self.scene.screen_h - hh + i * size, size, hh)
                end
            end
        end
    else
        if self.axis == "x" then
            local size = (self.scene.screen_h / self.segment)

            if not self.right_to_left then
                for i = 1, self.segment do
                    local px = -(i - 1) * size * 1.5
                    local py = (i - 1) * size

                    local w = self.scene.screen_w * self.multi
                    w = Utils:clamp(w, 0, self.scene.screen_w * 2)

                    love.graphics.rectangle("fill", w + px, py, self.scene.screen_w * 2, size)
                end
            else
                for i = 1, self.segment do
                    local w = (self.scene.screen_w) * self.mult
                    w = Utils:clamp(w, 0, self.scene.screen_w * 5)

                    local py = (i - 1) * size

                    love.graphics.rectangle("fill", 0, py, self.scene.screen_w - w + (i - 1) * size * 1.5, size)
                end
            end
        else
            local size = self.scene.screen_w / self.segment

            if not self.up_to_down then
                for i = 0, self.segment do
                    local px = i * size
                    local hh = self.scene.screen_h * self.mult
                    hh = Utils:clamp(hh, 0, self.scene.screen_h + size * self.segment)

                    love.graphics.rectangle("fill", px, 0, size, self.scene.screen_h - hh + i * size)
                end
            else
                for i = 0, self.segment do
                    local px = i * size
                    local hh = self.scene.screen_h * self.mult
                    hh = Utils:clamp(hh, 0, self.scene.screen_h + size * self.segment)

                    love.graphics.rectangle("fill", px, hh - i * size, size, self.scene.screen_h + self.segment * size)
                end
            end
        end
    end

    local font = JM_Font.current
    font:print("<color, 1, 1, 1>" .. tostring(self:finished()), 100, 100)
end

return Transition
