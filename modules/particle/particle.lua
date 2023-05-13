local Phys = _G.JM_Package.Physics
local Utils = _G.JM_Utils

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
local Particle = {}
Particle.__index = Particle

local IMG = {}
local QUADS = {}

---@type JM.Physics.World
local world

---@type JM.Scene
local gamestate

function Particle:init_module(imgs_dir, _world, _gamestate)
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
end

---@param img_dir string|any
function Particle:new(
    img_dir, x, y, w, h,
    qx, qy, qw, qh,
    rot, sx, sy, ox, oy,
    angle, lifetime, gravity, speed_x, speed_y, acc_x, acc_y, mass,
    draw_order
)
    local img, quad

    if img_dir then
        IMG[img_dir] = IMG[img_dir] or love.graphics.newImage(img_dir)
        img = IMG[img_dir]

        local key = string.format("%d-%d-%d-%d")

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

    local obj = setmetatable({
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
        --
        angle = angle or 0,
        lifetime = lifetime or 1,
        gravity = gravity or world.gravity,
        speed_x = speed_x or 0.0,
        speed_y = speed_y or 0.0,
        acc_x = acc_x or 0.0,
        acc_y = acc_y or 0.0,
        mass = mass or world.default_mass,
        --
        __remove = false,
        --
        draw_order = draw_order and (draw_order + math.random())
            or math.random(),
        --
        update = Particle.update,
        draw = Particle.draw_normal,
        --
    }, Particle)

    return obj
end

function Particle:newAnimated(
    anima, x, y, w, h,
    lifetime, angle, gravity, speed_x, speed_y, acc_x, acc_y, mass
)
    --
    local obj = self:new(nil, x, y, w or 16, h or 16, nil, nil, nil, nil, nil, nil, nil, nil, nil, angle, lifetime,
        gravity, speed_x,
        speed_y, acc_x, acc_y, mass)

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

function Particle:update(dt)
    if self.__custom_update__ then
        self:__custom_update__(dt)
    end

    if self.anima then
        self.anima:update(dt)
    end

    if self.body then
        self.x = Utils:round(self.body.x)
        self.y = Utils:round(self.body.y)
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
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.img, self.quad, self.x, self.y, self.rot, self.sx, self.sy, self.ox, self.oy)
end

return Particle
