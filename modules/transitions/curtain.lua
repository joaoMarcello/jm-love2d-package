---@type JM.Transition
local Transition = require((...):gsub("curtain", "transition"))

local Utils = _G.JM_Utils

local rect = love.graphics.rectangle

--- Euler's number
local E = 2.718281828459
local function sigmoid(x)
    return 1.0 / (1.0 + (E ^ (-x)))
end

local function tanh(x)
    local E_x = E ^ x
    local E_minus_x = E ^ (-x)

    return (E_x - E_minus_x) / (E_x + E_minus_x)
end

---@class JM.Transition.Curtain : JM.Transition
local Curtain = setmetatable({}, Transition)
Curtain.__index = Curtain

function Curtain:new(args, x, y, w, h)
    local obj = Transition:new(args, x, y, w, h)
    setmetatable(obj, self)
    Curtain.__constructor__(obj, args)
    return obj
end

function Curtain:__constructor__(args)
    self.color = Utils:get_rgba(0, 0, 0, 1)
    self.rad = 0 --math.pi / 2
    self.speed = args.duration or 0.8
    self.direction = 1

    if not self.mode_out then
        self.rad = E
        self.direction = -1
        self.speed = args.duration or 0.7
    end

    self.axis = args.axis or "x"
    self.left_to_right = args.type == "left-right"
    self.up_to_down = args.type == "up-down"

    self.mult = tanh(self.rad)
end

function Curtain:finished()
    if self.mode_out then
        return self.mult and self.mult >= 1
    else
        return self.mult and self.mult <= 0
    end
end

function Curtain:update(dt)
    self.rad = self.rad + ((E) / self.speed) * dt * self.direction
    self.mult = tanh(self.rad) + 0.007
    self.mult = Utils:clamp(self.mult, 0, 1)
end

function Curtain:draw()
    love.graphics.setColor(self.color)

    if self.axis == "x" then
        local w = self.w * self.mult

        if self.left_to_right then
            if self.mode_out then
                rect("fill", self.x, self.y, Utils:clamp(w, 0, self.w), self.h)
            else
                local px = Utils:clamp(self.x + self.w - w,
                    self.x,
                    self.x + self.w)
                rect("fill", px, self.y, self.x + self.w - px, self.h)
            end
        else
            if self.mode_out then
                rect("fill", self.x + self.w - w, self.y, w, self.h)
            else
                rect("fill", self.x, self.y, w, self.h)
            end
        end
        --
    else
        local h = self.h * self.mult

        if self.up_to_down then
            if self.mode_out then
                rect("fill", self.x, self.y, self.w, h)
            else
                local py = self.y + self.h - h
                rect("fill", self.x, py, self.w, self.y + self.h - py)
            end
        else
            if self.mode_out then
                local py = self.y + self.h - h
                rect("fill", self.x, py, self.w, self.y + self.h - py)
            else
                rect("fill", self.x, self.y, self.w, h)
            end
        end
    end

    -- local font = JM_Font
    -- font:print(self:finished(), 100, 100)
end

return Curtain
