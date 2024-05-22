local GC = _G.JM.GameObject

---@class GenericObject : GameObject
local Object = setmetatable({}, GC)
Object.__index = Object

---@return GenericObject|table
function Object:new(x, y, w, h, draw_order, update_order, reuse_tab)
    local obj = GC:new(x, y, w, h, draw_order, update_order, reuse_tab)
    setmetatable(obj, self)
    return Object.__constructor__(obj)
end

function Object:__constructor__()
    --
    self.update = Object.update
    self.draw = Object.draw
    return self
end

function Object:load()

end

function Object:init()

end

function Object:update(dt)
    GC.update(self, dt)
end

---@param self GenericObject
local function my_draw(self)

end

function Object:draw()
    return GC.draw(self, my_draw)
end

return Object
