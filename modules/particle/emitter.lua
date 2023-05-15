---@type GameObject
local GC = require(_G.JM_Path .. "modules.gamestate.game_object")

-- ---@type JM.Particle
-- local Particle = require((...):gsub("emitter", "particle"))
--========================================================================
local sort_draw = function(a, b) return a.draw_order < b.draw_order end

local tab_sort, tab_remove, tab_insert = table.sort, table.remove, table.insert

local pairs = pairs

local mode_k = { __mode = 'k' }
--========================================================================


---@class JM.Emitter : GameObject
---@field __custom_update__ function
local Emitter = setmetatable({}, GC)
Emitter.__index = Emitter
-- Emitter.Particle = Particle
Emitter.Animas = {}
Emitter.AnimaRecycler = {}
Emitter.ParticleRecycler = {} --setmetatable({}, { __mode = 'v' })
Emitter.N_PartRecy = 0

---@param _world JM.Physics.World
---@param _gamestate JM.Scene | any
function Emitter:init_module(_world, _gamestate)
    -- Particle:init_module(imgs_dir, _world, _gamestate)
    Emitter.gamestate = _gamestate
    Emitter.world = _world
end

---@param anima JM.Anima
---@param nick string|any
function Emitter:register_anima(anima, nick)
    if not Emitter.Animas[nick] then
        Emitter.Animas[nick] = anima
        Emitter.AnimaRecycler[nick] = setmetatable({}, mode_k)
    end
end

function Emitter:flush()
    for key, tab in pairs(Emitter.AnimaRecycler) do
        for anima, _ in pairs(tab) do
            tab[anima] = nil
        end
    end
end

---@return JM.Emitter
function Emitter:new(
    x, y, w, h, draw_order, lifetime,
    update_action, action_args, reuse_tab
)
    local obj = GC:new(x, y, w, h, draw_order, 0, reuse_tab)
    setmetatable(obj, self)
    Emitter.__constructor__(obj, lifetime, update_action, action_args)
    return obj
end

function Emitter:__constructor__(lifetime, update_action, action_args)
    self.particles = {}
    self.N = 0
    self.lifetime = lifetime or 1.0
    self.pause = false
    self.time = 0.0
    self.fr = 0.2
    self.__custom_update__ = update_action
    self.update_args = action_args

    self.update = Emitter.update
    self.draw = Emitter.draw
end

function Emitter:pop_anima(id)
    local rec = Emitter.AnimaRecycler[id]
    if rec then
        for obj, _ in pairs(rec) do
            rec[obj] = nil
            obj:reset()
            return obj
        end
    end

    return Emitter.Animas[id]:copy()
end

function Emitter:push_anima(anima, id)
    if not id then return false end
    local rec = Emitter.AnimaRecycler[id]
    if rec then
        rec[anima] = true
    end
    return true
end

function Emitter:push_particle(p)
    tab_insert(Emitter.ParticleRecycler, p)
    Emitter.N_PartRecy = Emitter.N_PartRecy + 1
end

function Emitter:pop_particle_reuse_table()
    if Emitter.N_PartRecy > 0 then
        local tab = tab_remove(Emitter.ParticleRecycler, Emitter.N_PartRecy)
        Emitter.N_PartRecy = Emitter.N_PartRecy - 1
        return tab
    end
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
        if N <= 0 then
            self.__remove = true
            return
        end
        --
    elseif self.__custom_update__ and not self.pause then
        self:__custom_update__(dt, self.update_args)
    end

    tab_sort(list, sort_draw)

    for i = N, 1, -1 do
        ---@type JM.Particle
        local p = list[i]

        if p.__remove then
            tab_remove(list, i)
            self.N = self.N - 1

            if p.body then p.body.__remove = true end

            if p.anima then
                self:push_anima(p.anima, p.id)
            end

            self:push_particle(p)
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
