local love_setColor = love.graphics.setColor
local love_draw = love.graphics.draw

---@class JM.Tile
local Tile = {}
Tile.__index = Tile

function Tile:new(id, img, x, y, w, h)
    local obj = setmetatable({}, self)

    Tile.__constructor__(obj, id, img, x, y, w, h)

    return obj
end

---@param img love.Image
function Tile:__constructor__(id, img, px, py, size_x, size_y)
    size_y = size_y or size_x
    self.id = id
    self.img = img
    self.qx = px
    self.qy = py
    self.qw = size_x
    self.qh = size_y

    self.quad = love.graphics.newQuad(self.qx, self.qy, self.qw, self.qh, img:getDimensions())
end

local white = { 1, 1, 1 }
function Tile:draw(x, y, color)
    love_setColor(color or white)
    love_draw(self.img, self.quad, x, y)
end

return Tile
