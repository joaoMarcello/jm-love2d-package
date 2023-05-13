---@type GameObject
local GC = require(_G.JM_Path .. "modules.gamestate.game_object")

--========================================================================
local sort_draw = function(a, b) return a.draw_order < b.draw_order end

local tab_sort, tab_remove, tab_insert = table.sort, table.remove, table.insert
--========================================================================


---@class Emitter : GameObject
---@field __custom_update__ function
local Emitter = setmetatable({}, GC)
Emitter.__index = Emitter

function Emitter:new(x, y, w, h, draw_order, lifetime, reuse_tab)
    local obj = GC:new(x, y, w, h, draw_order, 0, reuse_tab)
    setmetatable(obj, self)
    Emitter.__constructor__(obj, lifetime)
    return obj
end

function Emitter:__constructor__(lifetime)
    self.particles = {}
    self.N = 0
    self.lifetime = lifetime or 1.0

    self.update = Emitter.update
    self.draw = Emitter.draw
end

---@param p JM.Particle
function Emitter:add_particle(p)
    tab_insert(self.particles, p)
    self.N = self.N + 1
end

function Emitter:update(dt)
    local list = self.particles
    local N = self.N

    self.lifetime = self.lifetime - dt

    if self.lifetime <= 0.0 then
        -- self.__remove = true
        -- return
        if N <= 0 then
            self.__remove = true
        end
        --
    elseif self.__custom_update__ then
        self:__custom_update__(dt)
    end

    tab_sort(list, sort_draw)

    for i = N, 1, -1 do
        ---@type JM.Particle
        local p = list[i]

        if p.__remove then
            tab_remove(list, i)
            self.N = self.N - 1

            if p.body then p.body.__remove = true end
            --
        else
            --
            p:update(dt)

            if p.__remove then
                p.draw_order = 100000
            end
        end
    end
end

function Emitter:draw()
    local list = self.particles

    for i = 1, self.N do
        ---@type JM.Particle
        local p = list[i]

        if not p.__remove then
            p:draw()
        end
    end
end

return Emitter
