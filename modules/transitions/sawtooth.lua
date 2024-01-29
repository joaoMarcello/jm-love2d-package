---@type JM.Transition
local Transition = require((...):gsub("sawtooth", "transition"))

---@class JM.Transition.Sawtooth : JM.Transition
local Saw = setmetatable({}, Transition)
Saw.__index = Saw

---@return JM.Transition.Sawtooth
function Saw:new(args, x, y, w, h)
    local obj = setmetatable(Transition:new(args, x, y, w, h), Saw)
    return Saw.__constructor__(obj, args)
end

function Saw:__constructor__(args)
    local Utils = JM.Utils
    self.move_type = (args.move_type and Utils.MoveTypes[args.move_type])
        or Utils.MoveTypes.fast_smooth

    self.domain = Utils.Domain[self.move_type]
    self.action = Utils.Behavior[self.move_type]
    self.speed = args.speed or args.duration or 1
    self.axis = args.axis or "x"

    if self.mode_out then
        -- covering the scene
        self.value = 0
        self.time = 0.0
    else
        -- mode in (entering the scene)
        self.value = 1
        self.time = 0.0
    end

    self.segments = args.segments or 4
    self.len = args.len or 32

    return self
end

function Saw:finished()
    if self.mode_out then
        return self.value >= 1
    else
        return self.value <= 0
    end
end

function Saw:update(dt)
    local r = self.action(self.time)
    self.time = self.time + (self.domain / self.speed) * dt
    if not self.mode_out then
        r = 1 - r
    end
    self.value = r
end

function Saw:draw_sawtooth()
    local lgx = love.graphics
    local py = 0
    local width = self.len
    local height = self.h / self.segments

    for _ = 1, self.segments + 1 do
        lgx.polygon("fill",
            0, py,
            width, py + height * 0.5,
            0, py + height * 0.5 * 2
        )
        py = py + height * 0.5 * 2
    end
end

function Saw:draw()
    local lgx = love.graphics
    lgx.setColor(0, 0, 0)
    -- lgx.setColor(JM_Utils:hex_to_rgba_float("d96c21"))

    local len = self.len

    if self.mode_out then
        lgx.push()
        lgx.translate((self.w + len) * self.value - len, -(self.h / self.segments) * 0.5)
        self:draw_sawtooth()
        lgx.pop()

        -- lgx.setColor(0, 0, 0, 0.5)
        lgx.rectangle("fill", self.x, self.y, (self.w + len) * self.value - len, self.h)
        ---
    else
        local w = -len + (self.w + len) * self.value
        lgx.rectangle("fill", self.x, self.y, w, self.h)

        -- lgx.setColor(0, 0, 0)
        lgx.push()
        lgx.translate(w, -(self.h / self.segments) * 0.5)
        self:draw_sawtooth()
        lgx.pop()
    end

    -- lgx.setColor(0, 0, 0)
    -- lgx.print(tostring(self.value), 6, 6)
    -- lgx.print(tostring(self.mode_out and "out" or "in"), 6, 22)
end

return Saw
