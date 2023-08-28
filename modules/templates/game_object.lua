local GC = _G.JM_Package.GameObject

---@class GenericObject : GameObject
local Object = setmetatable({}, GC)
Object.__index = Object

function Object:new(x, y, w, h, draw_order, update_order, reuse_tab)
    local obj = GC:new(x, y, w, h, draw_order, update_order, reuse_tab)
    setmetatable(obj, self)
    Object.__constructor__(obj)
    return obj
end

function Object:__constructor__()
    --
    self.update = Object.update
    self.draw = Object.draw
end

function Object:load()

end

function Object:init()

end

function Object:update(dt)

end

function Object:my_draw()

end

function Object:draw()
    GC.draw(self, self.my_draw)
end

return Object
