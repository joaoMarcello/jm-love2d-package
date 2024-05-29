-- do
--     local jit = require "jit"
--     jit.off(true, true)
-- end

local GC = _G.JM.GameObject

--========================================================================
local sort_draw = function(a, b) return a.draw_order < b.draw_order end

local tab_sort, tab_remove, tab_insert = table.sort, table.remove, table.insert

local pairs = pairs

-- local mode_k = { __mode = 'k' }
-- local mode_v = { __mode = 'v' }
--========================================================================


---@class JM.Emitter : GameObject
---@field __custom_update__ function
local Emitter = setmetatable({}, GC)
Emitter.__index = Emitter
Emitter.__is_emitter = true

Emitter.Animas = {}
Emitter.AnimaRecycler = {}    --setmetatable({}, mode_k)
Emitter.ParticleRecycler = {} --setmetatable({}, mode_k)

---@param _world JM.Physics.World
---@param _gamestate JM.Scene | any
function Emitter:init_module(_world, _gamestate)
    Emitter.gamestate = _gamestate
    Emitter.world = _world
end

---@param anima JM.Anima
---@param nick string|any
function Emitter:register_anima(anima, nick)
    if not Emitter.Animas[nick] then
        Emitter.Animas[nick] = anima
        Emitter.AnimaRecycler[nick] = {} --setmetatable({}, mode_k)
    end
end

---@return JM.Emitter
function Emitter:new(
    x, y, w, h, draw_order, lifetime,
    update_action, action_args, reuse_tab
)
    ---@class JM.Emitter
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
    self.shader = nil
    self.time = 0.0
    self.duration = 0.0

    self.fr = 0.2      -- frequency
    self.delay = 0.0
    self.__obj__ = nil -- track object

    self.__custom_update__ = update_action
    self.update_args = action_args

    self.gamestate = GC.gamestate
    self.world = GC.world

    self.update = Emitter.update
    self.draw = Emitter.draw
end

function Emitter:set_shader(shader)
    self.shader = shader
end

---@param obj GameObject|BodyObject|any
function Emitter:set_track_obj(obj)
    self.__obj__ = obj
end

function Emitter:track_obj()
    local obj = self.__obj__
    if not obj then return end

    if obj.__remove or not obj.w or not obj.h then
        self.__obj__ = nil
        return
    end

    local bd = obj.body

    if bd then
        self.x, self.y = bd.x, bd.y
        self.w, self.h = bd.w, bd.h
    else
        self.x, self.y = obj.x, obj.y
        self.w, self.h = obj.w, obj.h
    end
end

function Emitter:set_gamestate(gamestate)
    self.gamestate = gamestate
end

function Emitter:set_world(world)
    self.world = world
end

function Emitter:pop_anima(id)
    -- local rec = Emitter.AnimaRecycler[id]
    -- if rec then
    --     for obj, _ in next, rec do
    --         rec[obj] = nil
    --         obj:reset()
    --         return obj
    --     end
    -- end

    local rec = Emitter.AnimaRecycler[id]
    if rec then
        ---@type JM.Anima
        local obj = table.remove(rec)
        if obj then
            obj.speed = Emitter.Animas[id].speed
            return obj
        end
    end

    return Emitter.Animas[id]:copy()
end

---@param anima JM.Anima
function Emitter:push_anima(anima, id)
    if not id then return false end
    -- local rec = Emitter.AnimaRecycler[id]
    -- if rec then
    --     -- anima.events = nil
    --     rec[anima] = true
    -- end
    -- return true

    local rec = Emitter.AnimaRecycler[id]
    if rec then
        anima:reset()
        table.insert(rec, anima)
        return true
    end
end

---@type function
local clear_table
do
    local success, result = pcall(function()
        require "table.clear"
        return true
    end)

    ---@diagnostic disable-next-line: undefined-field
    if success then
        ---@diagnostic disable-next-line: undefined-field
        clear_table = table.clear
    else
        clear_table = function(t)
            for k, _ in next, t do
                rawset(t, k, nil)
            end
        end
    end
end

---@param p JM.Particle
function Emitter:push_particle(p)
    -- p.prop = false
    -- Emitter.ParticleRecycler[p] = true
    -- return clear_table(p)
    p.prop = nil
    tab_insert(Emitter.ParticleRecycler, p)
end

function Emitter:pop_particle_reuse_table()
    -- for tab, _ in next, Emitter.ParticleRecycler do
    --     Emitter.ParticleRecycler[tab] = nil
    --     return tab
    -- end

    -- local list = Emitter.ParticleRecycler
    -- local n = #list
    -- if n > 0 then
    --     local t = tab_remove(list, n)
    --     return t
    -- end

    return tab_remove(Emitter.ParticleRecycler)
end

local getTime = love.timer.getTime
local timer = getTime()

function Emitter:flush()
    timer = getTime()

    for key, tab in pairs(Emitter.AnimaRecycler) do
        -- for anima, _ in pairs(tab) do
        --     tab[anima] = nil
        -- end

        JM_Utils.clear_table(tab)

        -- if getTime() - timer > 0.0005 then
        --     break
        -- end
    end

    timer = getTime()

    for key, _ in pairs(Emitter.ParticleRecycler) do
        Emitter.ParticleRecycler[key] = nil
        if getTime() - timer > 0.0005 then
            break
        end
    end
end

function Emitter:do_the_thing()
    self.pause = false
    local r
    if self.__custom_update__ then
        r = self:__custom_update__(love.timer:getDelta(), self.update_args)
    end
    self.pause = true
    return r
end

---@param p JM.Particle
function Emitter:add_particle(p)
    tab_insert(self.particles, p)
    self.N = self.N + 1
    return p
end

function Emitter:destroy()
    self.lifetime = -10000
    self.__obj__ = nil
end

function Emitter:update(dt)
    -- local temp_g, temp_w = GC:get_gamestate_and_world()
    -- GC:init_state(self.gamestate, self.world)

    local list = self.particles
    local N = self.N

    if self.lifetime ~= math.huge then
        self.lifetime = self.lifetime - dt
    end

    if self.duration ~= 0.0 then
        self.duration = self.duration - dt
        if self.duration < 0.0 then
            self.duration = 0.0
        end
    end

    self:track_obj()

    if self.lifetime <= 0.0 then
        if N <= 0 then
            self.__remove = true
            -- GC:init_state(temp_g, temp_w)
            return
        end
        --
    elseif self.__custom_update__ and not self.pause then
        self:__custom_update__(dt, self.update_args)
        N = self.N
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
                Emitter:push_anima(p.anima, p.id)
                p.anima = nil
                p.id = false
            end

            self:push_particle(p)
            --
        else
            --
            if p.delay then
                p.delay = p.delay - dt
                if p.delay <= 0.0 then p.delay = false end
            end

            if not p.delay then
                p:update(dt)
            end

            if p.__remove then
                p.draw_order = 100000
            end
        end
    end

    -- GC:init_state(temp_g, temp_w)
end

local setShader = love.graphics.setShader
function Emitter:draw(cam)
    local list = self.particles

    for i = 1, self.N do
        if i == 1 and self.shader then
            setShader(self.shader)
        end
        ---@type JM.Particle
        local p = list[i]

        if not p.__remove and not p.delay then
            p:draw(cam)
        end
    end
    setShader()
end

return Emitter
