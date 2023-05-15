local Phys = _G.JM_Package.Physics
local Utils = _G.JM_Utils

local IMG = {}
local QUADS = {}

---@type JM.Physics.World
local world

---@type JM.Scene
local gamestate

-- local Emitter = require((...):gsub("particle", "emitter"))

---@type JM.Emitter
local Emitter
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

local setColor = love.graphics.setColor
local draw = love.graphics.draw
local random = math.random
local str_format = string.format
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
local Particle = {}
Particle.__index = Particle

---@param imgs_dir table
---@param _world JM.Physics.World
---@param _gamestate JM.Scene
---@param emitter JM.Emitter
function Particle:init_module(imgs_dir, _world, _gamestate, emitter)
    if imgs_dir then
        local N = #imgs_dir
        for i = 1, N do
            local dir = imgs_dir[i]
            if not IMG[dir] then
                IMG[dir] = love.graphics.newImage(dir)
            end
        end
    end

    world = _world
    gamestate = _gamestate
    Emitter = emitter

    Particle.IMG = IMG
end

local white = Utils:get_rgba(1, 1, 1, 1)

---@param img_dir string|any
function Particle:new(
    img_dir, x, y, w, h,
    qx, qy, qw, qh,
    rot, sx, sy, ox, oy,
    angle, lifetime, gravity, speed_x, speed_y, acc_x, acc_y, mass,
    draw_order, delay, color, id
)
    local img, quad

    if img_dir then
        IMG[img_dir] = IMG[img_dir] or love.graphics.newImage(img_dir)
        img = IMG[img_dir]

        local key = str_format("%d-%d-%d-%d")

        QUADS[img_dir] = QUADS[img_dir] or {}
        QUADS[img_dir][key] = QUADS[img_dir][key]
            or love.graphics.newQuad(qx, qy, qw, qh, img:getDimensions())

        quad = QUADS[img_dir][key]
    end
    --
    w = w or 16
    h = h or 16
    ox = ox or (w * 0.5)
    oy = oy or (h * 0.5)

    local reuse_table = Emitter:pop_particle_reuse_table()

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
        ox = ox,
        oy = oy,
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
        mass = mass or world.default_mass,
        --
        __remove = false,
        --
        draw_order = draw_order and (draw_order + random())
            or random(),
        --
        update = Particle.update,
        draw = Particle.draw_normal,
        --
    }, Particle)

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
        reuse_table.ox = ox
        reuse_table.oy = oy
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
        reuse_table.mass = mass or world.default_mass
        --
        reuse_table.__remove = false
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

        reuse_table.__custom_update__ = false
    end

    return obj
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

function Particle:newBodyAnimated(anima, x, y, w, h, lifetime, angle)
    local obj = self:new(nil, x, y, w, h, nil, nil, nil, nil, nil, nil, nil, nil, nil, angle, lifetime, nil, nil, nil,
        nil, nil, nil)

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

    if self.body then
        self.x = round(self.body.x)
        self.y = round(self.body.y)
    end

    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0.0 then
        self.__remove = true
    end
end

function Particle:draw_anima()
    self.anima:draw(self.x + self.ox, self.y + self.oy)
end

function Particle:draw_normal()
    setColor(self.color)
    draw(self.img, self.quad, self.x, self.y, self.rot, self.sx, self.sy, self.ox, self.oy)
end

return Particle
