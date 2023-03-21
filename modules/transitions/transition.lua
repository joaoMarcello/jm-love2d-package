---@class JM.Transition
local Transition = {}
Transition.__index = Transition

function Transition:new(args, x, y, w, h)
    local obj = {}
    setmetatable(obj, self)
    Transition.__constructor__(obj, args, x, y, w, h)
    return obj
end

function Transition:__constructor__(args, x, y, w, h)
    self.mode_out = args.mode == "out"
    self.x = x or 0
    self.y = y or 0
    self.w = w or 1366
    self.h = h or 768
end

function Transition:finished()
    return false
end

function Transition:update(dt)

end

function Transition:draw()

end

return Transition
