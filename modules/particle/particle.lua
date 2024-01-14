do
    local jit = require "jit"
    jit.off(true, true)
end
---@type JM.Physics
local Phys = require(_G.JM_Path .. "modules.jm_physics")
local Utils = _G.JM_Utils

-- local IMG = {}
local QUADS = {}

---@type JM.Physics.World
local world

---@type JM.Scene
local gamestate

---@type JM.Emitter
local Emitter = require(_G.JM_Path .. "modules.particle.emitter")
--=========================================================================
local floor = math.floor
local function round(x)
    local f = floor(x + 0.5)
    if (x == f) or (x % 2.0 == 0.5) then
        return f
    else
        return floor(x + 0.5)
    end
end

local generic = function()
end

local lgx = love.graphics
local setColor = lgx.setColor
local draw = lgx.draw
local random = math.random
local str_format = string.format
local abs = math.abs
--=========================================================================


---@class JM.Particle
---@field x number
---@field y number
---@field w number
---@field h number
---@field rot number
---@field sx number
---@field sy number
---@field ox number
---@field oy number
---@field angle number
---@field lifetime number
---@field delay number|boolean
---@field color JM.Color
---@field gravity number
---@field speed_x number
---@field speed_y number
---@field acc_x number
---@field acc_y number
---@field max_speed_x number | any
---@field max_speed_y number | any
---@field mass number
---@field img love.Image
---@field quad love.Quad
---@field anima JM.Anima
---@field body JM.Physics.Body
---@field __custom_update__ function
---@field __custom_draw__ function
---@field draw function
---@field __remove boolean
---@field draw_order number
---@field id string|any
---@field prop any
---@field direction number
---@field var1 any
---@field var2 any
---@field var3 any
---@field var4 any
---@field var5 any
local Particle = {}
Particle.__index = Particle

---@param _world JM.Physics.World
---@param _gamestate JM.Scene
function Particle:init_module(_world, _gamestate)
    world = _world
    gamestate = _gamestate
end

local white = Utils:get_rgba(1, 1, 1, 1)

function Particle:new(
    img, x, y, w, h,
    qx, qy, qw, qh,
    rot, sx, sy, ox, oy,
    angle, lifetime, gravity, speed_x, speed_y, acc_x, acc_y, mass,
    draw_order, delay, color, id, max_speed_x, max_speed_y
)
    local quad

    if img then
        -- IMG[img_dir] = IMG[img_dir] or love.graphics.newImage(img_dir)
        -- img = IMG[img_dir]

        local key = str_format("%d-%d-%d-%d", qx, qy, qw, qh)

        QUADS[img] = QUADS[img] or {}
        QUADS[img][key] = QUADS[img][key]
            or love.graphics.newQuad(qx, qy, qw, qh, img:getDimensions())

        quad = QUADS[img][key]
    end
    --
    w = w or 16
    h = h or 16
    ox = ox or (w * 0.5)
    oy = oy or (h * 0.5)

    local reuse_table = Emitter:pop_particle_reuse_table()

    if reuse_table then
        --
        reuse_table.img = img
        reuse_table.quad = quad
        reuse_table.x = x
        reuse_table.y = y
        reuse_table.w = w
        reuse_table.h = h
        reuse_table.rot = rot or 0
        reuse_table.sx = sx or 1
        reuse_table.sy = sy or 1
        reuse_table.ox = ox or 0
        reuse_table.oy = oy or 0
        reuse_table.color = color or white
        --
        reuse_table.id = id or false
        reuse_table.angle = angle or 0
        reuse_table.lifetime = lifetime or 1
        reuse_table.delay = delay or false
        reuse_table.gravity = gravity or world.gravity
        reuse_table.speed_x = speed_x or 0.0
        reuse_table.speed_y = speed_y or 0.0
        reuse_table.acc_x = acc_x or 0.0
        reuse_table.acc_y = acc_y or 0.0
        reuse_table.max_speed_x = max_speed_x or false
        reuse_table.max_speed_y = max_speed_y or false
        reuse_table.mass = mass or world.default_mass
        reuse_table.direction = 1
        --
        reuse_table.__remove = false
        reuse_table.__custom_update__ = false
        --
        reuse_table.draw_order = draw_order and (draw_order + random())
            or random()
        --
        reuse_table.update = Particle.update
        reuse_table.draw = Particle.draw_normal

        if reuse_table.anima then
            reuse_table.anima = false
        end

        if reuse_table.body then
            reuse_table.body = false
        end

        reuse_table.prop = false

        reuse_table.var1 = 0
        reuse_table.var2 = 0
        reuse_table.var3 = 0
        reuse_table.var4 = 0
        reuse_table.var5 = 0

        reuse_table.__custom_update__ = generic
    end

    local obj = setmetatable(reuse_table or {
        img = img,
        quad = quad,
        x = x,
        y = y,
        w = w,
        h = h,
        rot = rot or 0,
        sx = sx or 1,
        sy = sy or 1,
        ox = ox or 0,
        oy = oy or 0,
        color = color or white,
        --
        id = id or false,
        angle = angle or 0,
        lifetime = lifetime or 1,
        delay = delay or 0.0,
        gravity = gravity or world.gravity,
        speed_x = speed_x or 0.0,
        speed_y = speed_y or 0.0,
        acc_x = acc_x or 0.0,
        acc_y = acc_y or 0.0,
        max_speed_x = max_speed_x or false,
        max_speed_y = max_speed_y or false,
        mass = mass or world.default_mass,
        direction = 1,
        --
        __remove = false,
        __custom_update__ = generic,
        --
        draw_order = draw_order and (draw_order + random())
            or random(),
        --
        prop = false,

        var1 = false,
        var2 = false,
        var3 = false,
        var4 = false,
        var5 = false,
        --
        update = Particle.update,
        draw = Particle.draw_normal,
        --
    }, Particle)



    return obj
end

function Particle:copy()
    local p = Particle:new()
    for k, v in next, self do
        -- p[k] = v
        rawset(p, k, v)
    end

    if self.prop then
        local prop = {}
        for k, v in next, self.prop do
            -- prop[k] = v
            rawset(prop, k, v)
        end
        p.prop = prop
    end
    return p
end

function Particle:newAnimated(
    anima, x, y, w, h,
    lifetime, angle, gravity, speed_x, speed_y, acc_x, acc_y, delay, mass,
    draw_order, id
)
    --
    local obj = self:new(nil, x, y, w or 16, h or 16, nil, nil, nil, nil, nil, nil, nil, nil, nil, angle, lifetime,
        gravity, speed_x,
        speed_y, acc_x, acc_y, mass, draw_order, delay, nil, id)

    obj.anima = anima
    obj.draw = Particle.draw_anima
    return obj
end

function Particle:newBodyAnimated(anima, x, y, w, h, lifetime, angle, id)
    local obj = self:new(nil, x, y, w, h, nil, nil, nil, nil, nil, nil, nil, nil, nil, angle, lifetime, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, id)

    obj.body = Phys:newBody(world, x, y, w, h, "dynamic")
    obj.anima = anima
    obj.draw = Particle.draw_anima
    return obj
end

function Particle:set_color(r, g, b, a)
    self.color = Utils:get_rgba(r, g, b, a)
end

function Particle:update(dt)
    if self.__custom_update__ then
        self:__custom_update__(dt)
    end

    if self.anima then
        self.anima:update(dt)
    end

    local bd = self.body
    if bd then
        self.x = round(bd.x)
        self.y = round(bd.y)
    end

    --===================================================
    if self.acc_y ~= 0 or self.speed_y ~= 0 then
        local goaly = self.y + (self.speed_y * dt)
            + (self.acc_y * dt * dt) * 0.5

        self.speed_y = self.speed_y + self.acc_y * dt
        if self.max_speed_y and abs(self.speed_y) > self.max_speed_y then
            if self.speed_y > 0 then
                self.speed_y = self.max_speed_y
            else
                self.speed_y = -(self.max_speed_y)
            end
        end

        self.y = goaly
    end
    --===================================================

    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0.0 then
        self.__remove = true
        -- if self.body then
        --     self.body.__remove = true
        -- end
    end
end

function Particle:draw_anima()
    local anima = self.anima
    anima:set_scale(self.sx, self.sy)
    anima:set_rotation(self.rot)

    local bd = self.body
    if bd then
        anima:draw_rec(self.x, self.y, bd.w, bd.h)
    else
        anima:draw(self.x + self.ox, self.y + self.oy)
    end
end

function Particle:draw_normal()
    setColor(self.color)
    draw(self.img, self.quad, self.x, self.y, self.rot, self.sx, self.sy, self.ox, self.oy)
end

return Particle
