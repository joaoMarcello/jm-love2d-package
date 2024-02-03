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
    if type(args.move_type) == "number" then
        for k, v in next, Utils.MoveTypes do
            if v == args.move_type then
                args.move_type = k
                break
            end
        end
    end

    self.move_type = (args.move_type and Utils.MoveTypes[args.move_type])
        or Utils.MoveTypes.fast_smooth

    -- self.move_type = Utils.MoveTypes.linear

    self.domain = Utils.Domain[self.move_type]
    self.action = Utils.Behavior[self.move_type]
    self.speed = args.speed or args.duration or 1
    self.axis = args.axis or "x"
    self.direction = args.type or "" --"bottom-top"
    self.color = args.color or { 0, 0, 0 }

    if self.direction == "bottom-up" or self.direction == "down-up" then
        self.direction = "bottom-top"
    end

    if self.mode_out then
        -- covering the scene
        self.value = 0
        self.time = 0.0
    else
        -- mode in (entering the scene)
        self.value = 1
        self.time = 0.0
    end


    self.segments = args.segments or (self.axis == "x" and 5 or 10)
    self.len = args.len or (self.axis == "x" and 32 or 24)

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

    if self.mode_out then
        ---
    else
        r = 1 - r
    end

    self.value = r
end

function Saw:draw_sawtooth(mod, axis)
    axis = axis or "x"

    local lgx = love.graphics
    local pos = 0
    local len = self.len
    local height = (axis == "x" and self.h or self.w) / self.segments
    local half = height * 0.5

    if axis == "x" then
        if not mod then
            for _ = 1, self.segments + 1 do
                lgx.polygon("fill",
                    0, pos,
                    len, pos + half,
                    0, pos + height
                )
                pos = pos + height
            end
            ---
        else
            for _ = 1, self.segments + 1 do
                lgx.polygon("fill",
                    len, pos,
                    0, pos + half,
                    len, pos + height
                )
                pos = pos + height
            end
        end --
        --- end is x axis
    else
        if not mod then
            for _ = 1, self.segments + 1 do
                lgx.polygon("fill",
                    pos, 0,
                    pos + half, len,
                    pos + height, 0
                )
                pos = pos + height
            end
            ---
        else
            for _ = 1, self.segments + 1 do
                lgx.polygon("fill",
                    pos, len,
                    pos + half, 0,
                    pos + height, len
                )
                pos = pos + height
            end
        end
    end
end

function Saw:draw()
    local lgx = love.graphics
    lgx.setColor(self.color)
    -- lgx.setColor(JM_Utils:hex_to_rgba_float("d96c21"))

    local len = self.len

    if self.mode_out then
        -- covering the scene
        if self.axis == "x" then
            local mod = self.direction == "right-left"
            local value = mod and (1.0 - self.value) or (self.value)

            local w = (self.w + len) * value - len
            lgx.push()
            lgx.translate(w, -(self.h / self.segments) * 0.5)
            self:draw_sawtooth(mod)
            lgx.pop()

            -- lgx.setColor(0, 0, 0, 0.5)
            if mod then
                local px = self.x + w + len
                lgx.rectangle("fill", px, self.y, self.w - px, self.h)
            else
                lgx.rectangle("fill", self.x, self.y, w, self.h)
            end
            --- end is x axis
        else
            local mod = self.direction == "bottom-top"
            local value = mod and (1.0 - self.value) or self.value

            local h = (self.h + len) * value - len
            lgx.push()
            lgx.translate(-(self.w / self.segments) * 0.5, h)
            self:draw_sawtooth(mod, "y")
            lgx.pop()

            if mod then
                local py = self.y + h + len
                lgx.rectangle("fill", self.x, py, self.w, self.h - py)
            else
                lgx.rectangle("fill", self.x, self.y, self.w, h)
            end
            ---
        end -- end is y axis
        ---
    else
        if self.axis == "x" then
            local mod = not (self.direction == "right-left")
            local value = mod and (1 - self.value) or (self.value)

            local w = -len + (self.w + len) * value
            lgx.push()
            lgx.translate(w, -(self.h / self.segments) * 0.5)
            self:draw_sawtooth(mod)
            lgx.pop()

            -- lgx.setColor(0, 0, 0, 0.5)
            if mod then
                local px = self.x + w + len
                lgx.rectangle("fill", px, self.y, self.w - px, self.h)
            else
                lgx.rectangle("fill", self.x, self.y, w, self.h)
            end
            ---
        else
            local mod = self.direction == "bottom-top"
            local value = mod and (self.value) or (1.0 - self.value)

            local h = -len + (self.h + len) * value
            lgx.push()
            lgx.translate(-(self.w / self.segments) * 0.5, h)
            self:draw_sawtooth(not mod, "y")
            lgx.pop()

            -- lgx.setColor(0, 0, 0, 0.6)
            if mod then
                lgx.rectangle("fill", self.x, self.y, self.w, h)
            else
                local py = self.y + h + len
                lgx.rectangle("fill", self.x, py, self.w, self.h - py)
            end
            ---
        end
    end

    -- lgx.setColor(0, 0, 0)
    -- lgx.print(tostring(self.value), 6, 6)
    -- lgx.print(tostring(self.mode_out and "out" or "in"), 6, 22)
end

return Saw
