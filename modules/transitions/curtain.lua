---@type JM.Transition
local Transition = require((...):gsub("curtain", "transition"))

local Utils = _G.JM_Utils

local rect = love.graphics.rectangle

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
    self.speed = args.duration or 1.5
    self.direction = 1

    if not self.mode_out then
        self.rad = math.pi / 2
        self.direction = -1
        self.speed = args.duration or 1
    end

    self.axis = "x" --args.axis or "x"
    self.left_to_right = args.type == "left-right"
    self.up_to_down = args.type == "up-down"

    self.mult = math.sin(self.rad)
end

function Curtain:finished()
    if self.mode_out then
        return self.mult and self.mult >= 1
    else
        return self.mult and self.mult <= 0
    end
end

function Curtain:update(dt)
    self.rad = self.rad + (math.pi / self.speed) * dt * self.direction
    self.rad = Utils:clamp(self.rad, 0, math.pi + math.pi / 2)
    self.mult = math.sin(self.rad)
end

function Curtain:draw()
    love.graphics.setColor(self.color)

    if self.axis == "x" then
        local w = self.w * self.mult

        if self.left_to_right or true then
            if self.mode_out then
                rect("fill", self.x, self.y, w, self.h)
            else
                local px = self.x + self.w - w
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
