---@type JM.Transition
local Transition = require((...):gsub("door", "transition"))

local Utils = _G.JM_Utils

local rect = love.graphics.rectangle

---@class JM.Transition.Door : JM.Transition
local Door = setmetatable({}, Transition)
Door.__index = Door

function Door:new(args, x, y, w, h)
    local obj = Transition:new(args, x, y, w, h)
    setmetatable(obj, self)
    Door.__constructor__(obj, args)
    return obj
end

function Door:__constructor__(args)
    self.color = Utils:get_rgba(0, 0, 0, 1)
    self.rad = 0
    self.speed = args.duration or 1.5
    self.direction = 1

    if not self.mode_out then
        self.rad = math.pi / 2
        self.direction = -1
        self.speed = args.duration or 1
    end

    self.axis = args.axis or "y"
end

function Door:finished()
    if self.mode_out then
        return self.mult and self.mult >= 1
    else
        return self.mult and self.mult <= 0
    end
end

function Door:update(dt)
    self.rad = self.rad + (math.pi / self.speed) * dt * self.direction
    self.rad = Utils:clamp(self.rad, 0, math.pi / 2)
    self.mult = math.sin(self.rad)
end

function Door:draw()
    love.graphics.setColor(self.color)

    if self.axis == "x" then
        local w = self.w / 2 * self.mult
        local h = self.h

        rect("fill", self.x, self.y, w, h)
        local px = self.x + self.w - w
        rect("fill", px, self.y, self.x + self.w - px, h)
    else
        local h = self.h / 2 * self.mult
        local w = self.w

        rect("fill", self.x, self.y, w, h)
        local py = self.y + self.h - h
        rect("fill", self.x, py, w, self.y + self.h - py)
    end

    -- local font = JM_Font
    -- font:print(self:finished(), 100, 100)
end

return Door
