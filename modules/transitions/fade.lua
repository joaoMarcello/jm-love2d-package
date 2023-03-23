---@type JM.Transition
local Transition = require((...):gsub("fade", "transition"))

---@class JM.Transition.Fade : JM.Transition
local Fade = setmetatable({}, Transition)
Fade.__index = Fade

function Fade:new(args, x, y, w, h)
    local obj = Transition:new(args, x, y, w, h)
    setmetatable(obj, self)
    Fade.__constructor__(obj, args)
    return obj
end

function Fade:__constructor__(args)
    self.color = args.color or { 0, 0, 0, 1 }

    self.time = 0
    self.duration = args.duration or 1

    if not self.mode_out then
        self.time = self.duration
    end
end

function Fade:finished()
    if self.mode_out then
        return self.time / self.duration >= 1
    else
        return self.time / self.duration <= 0
    end
end

function Fade:update(dt)
    if self.mode_out then
        self.time = self.time + dt
    else
        self.time = self.time - dt
    end
end

function Fade:draw()
    local r, g, b = unpack(self.color)

    love.graphics.setColor(r, g, b, self.time / self.duration)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    -- local font = JM_Font.current
    -- font:print("<color, 1, 1, 1>" .. tostring(self:finished()), 100, 100)
end

return Fade
