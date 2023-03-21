---@type JM.Transition
local Transition = require((...):gsub("tile", "transition"))

local Utils = _G.JM_Utils

---@class JM.Transition.Tile : JM.Transition
local Tile = setmetatable({}, Transition)
Tile.__index = Tile

function Tile:new(args, x, y, w, h)
    local obj = Transition:new(args, x, y, w, h)
    setmetatable(obj, self)
    Tile.__constructor__(obj, args)
    return obj
end

function Tile:__constructor__(args)
    self.mode_out = args.mode == "out"
    -- self.scene = scene
    self.color = args.color or { 0, 0, 0, 1 }
    self.segment = args.segment or 6

    self.acc = 4
    self.speed = 0
    self.mult = 0

    self.right_to_left = args.type and args.type == "right-left" or false

    self.up_to_down = args.type and args.type == "up-down" or false
    self.axis = args.axis or "x"
end

function Tile:finished()
    return self.mult >= 2
end

function Tile:update(dt)
    self.mult = self.mult + self.speed * dt + self.acc * dt * dt / 2
    self.speed = self.speed + self.acc * dt
end

function Tile:draw()
    love.graphics.setColor(self.color)

    if self.mode_out then
        if self.axis == "x" then
            local size = (self.h / self.segment)

            if not self.right_to_left then
                for i = 1, self.segment do
                    local py = (i - 1) * size

                    local w = self.w * self.mult
                    w = Utils:clamp(w, 0, self.w + size * 1.5 * self.segment)
                    love.graphics.rectangle("fill", self.x, self.y + py,
                        Utils:clamp(w - (i - 1) * size * 1.5, 0, self.w),
                        size)
                end
            else
                for i = 0, self.segment - 1 do
                    local w = self.w * self.mult
                    w = Utils:clamp(w, 0, self.w + size * 1.5 * self.segment)

                    local py = self.y + i * size
                    local px = Utils:clamp(self.x + self.w - w + size * i * 1.5, self.x, self.x + self.w)

                    love.graphics.rectangle("fill",
                        px,
                        py,
                        self.x + self.w - px,
                        size)
                end
            end
        else
            local size = self.w / self.segment

            if self.up_to_down then
                for i = 0, self.segment do
                    local px = i * size
                    local hh = self.h * self.mult
                    hh = Utils:clamp(hh, 0, self.h + size * self.segment)

                    love.graphics.rectangle("fill", px, 0, size, hh - size * i)
                end
            else
                for i = 0, self.segment - 1 do
                    local px = i * size
                    local hh = self.h * self.mult
                    hh = Utils:clamp(hh, 0, self.h + size * self.segment)

                    love.graphics.rectangle("fill", px, self.h - hh + i * size, size, hh)
                end
            end
        end
    else
        if self.axis == "x" then
            local size = (self.h / self.segment)

            if not self.right_to_left and false then
                for i = 0, self.segment - 1 do
                    local py = self.y + i * size

                    local w = self.w * self.mult
                    w = Utils:clamp(w, 0, self.w + size * 1.5 * self.segment)

                    local px = Utils:clamp(self.x + w - size * i * 1.5, self.x, self.x + self.w)

                    love.graphics.rectangle("fill",
                        px,
                        py,
                        self.x + self.w - px,
                        size)
                end
            else
                for i = 0, self.segment - 1 do
                    local w = (self.w) * self.mult
                    w = Utils:clamp(w, 0, self.w + size * self.segment * 1.5)

                    local py = self.y + i * size

                    love.graphics.rectangle("fill",
                        self.x,
                        py,
                        Utils:clamp(self.w - w + i * size * 1.5, 0, self.w),
                        size)
                end
            end
        else
            local size = self.w / self.segment

            if not self.up_to_down then
                for i = 0, self.segment do
                    local px = i * size
                    local hh = self.h * self.mult
                    hh = Utils:clamp(hh, 0, self.h + size * self.segment)

                    love.graphics.rectangle("fill", px, 0, size, self.h - hh + i * size)
                end
            else
                for i = 0, self.segment do
                    local px = i * size
                    local hh = self.h * self.mult
                    hh = Utils:clamp(hh, 0, self.h + size * self.segment)

                    love.graphics.rectangle("fill", px, hh - i * size, size, self.h + self.segment * size)
                end
            end
        end
    end

    local font = JM_Font.current
    font:print("<color, 1, 1, 1>" .. tostring(self:finished()), 100, 100)
end

return Tile
