---@type JM.Transition
local Transition = require((...):gsub("diamond", "transition"))

local Utils = _G.JM_Utils
local Affectable = _G.JM_Affectable

local rect = love.graphics.rectangle

---@class JM.Transition.Diamond.Piece : JM.Template.Affectable
local Piece = setmetatable({}, Affectable)
Piece.__index = Piece

function Piece:new(x, y, w, h)
    local obj = Affectable:new()
    setmetatable(obj, self)
    Piece.__constructor__(obj, x, y, w, h)
    return obj
end

function Piece:__constructor__(x, y, w, h)
    self.w = w
    self.h = h
    self.x = x - self.w / 2
    self.y = y - self.h / 2

    self.ox = self.w / 2
    self.oy = self.h / 2

    self:set_effect_transform("rot", math.pi / 4)
    -- self:apply_effect("clockWise")
end

function Piece:update(dt)
    Affectable.update(self, dt)
end

function Piece:my_draw()
    love.graphics.setColor(0, 0, 0, 1)
    rect("fill", self.x, self.y, self.w, self.h)
end

function Piece:draw()
    Affectable.draw(self, self.my_draw)
end

--=======================================================================

---@class JM.Transition.Diamond : JM.Transition
local Diamond = setmetatable({}, Transition)
Diamond.__index = Diamond

function Diamond:new(args, x, y, w, h)
    local obj = Transition:new(args, x, y, w, h)
    setmetatable(obj, self)
    Diamond.__constructor__(obj, args)
    return obj
end

function Diamond:__constructor__(args)
    self.color = Utils:get_rgba(0, 0, 0, 1)
    self.rad = 0.0 --math.pi / 2
    self.speed = args.duration or 6
    self.direction = 1

    if not self.mode_out then
        self.rad = 3.0
        self.direction = -1
        self.speed = args.duration or 1
    end

    self.axis = args.axis or "x"
    self.left_to_right = args.type == "left-right"
    self.up_to_down = args.type == "top-bottom" or args.type == "up-down"

    self.mult = self.tanh(self.rad) + 0.02

    self.pieces = {}
    local qx = math.floor(self.w / 46)
    local qy = math.floor(self.h / 46)

    for i = 0, qx - 1 do
        for j = 0, qy - 1 do
            table.insert(self.pieces, Piece:new(self.x + 64 * i,
                self.y + 64 * j,
                46, 46))
        end

        for j = 0, qy - 1 do
            table.insert(self.pieces, Piece:new(self.x + 64 * i + 32,
                self.y + 64 * j + 32,
                46, 46))
        end
    end

    -- table.insert(self.pieces, Piece:new(64, 64, 46, 46))
    -- table.insert(self.pieces, Piece:new(64 + 64, 64, 46, 46))
    -- table.insert(self.pieces, Piece:new(64 + 32, 64 + 32, 46, 46))
end

function Diamond:finished()
    do
        return false
    end
    if self.mode_out then
        return self.mult and self.mult >= 1
    else
        return self.mult and self.mult <= 0
    end
end

function Diamond:update(dt)
    self.rad = self.rad + (3.0 / self.speed) * dt * self.direction
    local tanh = self.tanh(self.rad) + 0.007 + 1
    local mult = tanh / 2.0

    self.mult = self.tanh(self.rad) + 0.1
    self.mult = self.clamp(self.mult, 0, 1)

    for i = 1, #self.pieces do
        ---@type JM.Transition.Diamond.Piece
        local piece = self.pieces[i]

        local mult = 1 + (i - 1) * 0.01
        mult = 1

        piece:set_effect_transform("sx", self.mult * mult + 0.00001)
        piece:set_effect_transform("sy", self.mult * mult + 0.00001)
        piece:update(dt)
    end
end

function Diamond:draw()
    for i = 1, #self.pieces do
        local piece = self.pieces[i]
        piece:draw()
    end
    -- local font = JM_Font
    -- font:print("<color, 1, 1, 1>tanh: " .. self.tanh(self.rad), 100, 200)
    -- font:print("<color, 1, 1, 1>rad: " .. self.rad, 100, 250)
    -- font:print("<color, 1, 1, 1>mult: " .. self.mult, 100, 300)
end

return Diamond
