--- Euler's number
local E = 2.718281828459
local function sigmoid(x)
    return 1.0 / (1.0 + (E ^ (-x)))
end

---@return number
local function tanh(x)
    -- local E_x = E ^ x
    -- local E_minus_x = E ^ (-x)
    local E_2x = E ^ (2 * x)

    -- return (E_x - E_minus_x) / (E_x + E_minus_x)
    return (E_2x - 1) / (E_2x + 1)
end

---@class JM.Transition
local Transition = {
    E = E,
    sigmoid = sigmoid,
    tanh = tanh,
    clamp = function(value, A, B)
        return math.min(math.max(value, A), B)
    end
}
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
    self.w = w or love.graphics.getWidth()
    self.h = h or love.graphics.getHeight()

    self.delay = args.delay or 0

    self.is_enabled = true

    self.pause_scene = args.pause_scene
end

function Transition:finished()
    return false
end

function Transition:is_paused()
    return not self.is_enabled or (self.delay and self.delay > 0)
end

function Transition:is_mode_in()
    return not self.mode_out
end

function Transition:__update__(dt)
    if self.delay then
        self.delay = self.delay - dt
        self.delay = self.delay < 0 and 0 or self.delay
    end
end

function Transition:update(dt)

end

function Transition:draw()

end

return Transition
