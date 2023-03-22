---@type JM.Transition
local Transition = require((...):gsub("stripe", "transition"))

local Utils = _G.JM_Utils

local rect = love.graphics.rectangle

---@class JM.Transition.Stripe : JM.Transition
local Stripe = setmetatable({}, Transition)
Stripe.__index = Stripe

function Stripe:new(args, x, y, w, h)
    local obj = Transition:new(args, x, y, w, h)
    setmetatable(obj, self)
    Stripe.__constructor__(obj, args)
    return obj
end

function Stripe:__constructor__(args)
    self.color = Utils:get_rgba(0, 0, 0, 1)
    self.rad = 0
    self.speed = args.duration or 1
    self.direction = 1
    self.mult = 0

    if not self.mode_out then
        self.rad = math.pi / 2
        self.direction = -1
        self.speed = args.duration or 0.7
        self.mult = 1
    end

    self.axis = args.axis or "x"

    self.n = args.n or 3
end

function Stripe:finished()
    if self.mode_out then
        return self.mult and self.mult >= 1
    else
        return self.mult and self.mult <= 0
    end
end

function Stripe:update(dt)
    -- self.rad = self.rad + (math.pi / self.speed) * dt * self.direction
    -- self.rad = Utils:clamp(self.rad, 0, math.pi / 2)
    -- self.mult = math.sin(self.rad)

    self.mult = self.mult + 1 / self.speed * dt * self.direction
    self.mult = Utils:clamp(self.mult, 0, 1)
end

function Stripe:draw()
    love.graphics.setColor(self.color)

    if self.axis == "x" then
        local size = self.h / (self.n * 2)
        local w = self.w * self.mult

        if self.mode_out or true then
            local c = 0
            for i = 0, self.n - 1 do
                local ww = self.w + self.w * (self.n * 2 - c) * 0.3
                ww = ww * self.mult

                rect("fill", self.x, self.y + size * i * 2,
                    Utils:clamp(ww, 0, self.w),
                    size)
                c = c + 1

                ww = self.w + self.w * (self.n * 2 - c) * 0.3
                ww = ww * self.mult

                local px = self.x + self.w - ww
                rect("fill",
                    Utils:clamp(px, self.x, self.x + self.w),
                    self.y + size + size * i * 2,
                    Utils:clamp(self.x + self.w - px, 0, self.w),
                    size)
                c = c + 1
            end
            --
        end
    end

    -- local font = JM_Font
    -- font:print(self:finished(), 100, 100)
end

return Stripe
