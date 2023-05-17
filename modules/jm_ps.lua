---@type JM.Particle
local Particle = require((...):gsub("jm_ps", "particle.particle"))

---@type JM.Emitter
local Emitter = require((...):gsub("jm_ps", "particle.emitter"))

local IMG = {}

---@class JM.ParticleSystem
local PS = {
    Emitter = Emitter,
    Particle = Particle,
    IMG = IMG,
}

function PS:register_img(path, nick)
    local img
    if type(path) == "string" then
        img = love.graphics.newImage(path)
    else
        --
        img = path
    end
    img:setFilter("linear", "nearest")
    IMG[nick] = img
end

---@param anima JM.Anima
---@param nick string
function PS:register_anima(anima, nick)
    Emitter:register_anima(anima, nick)
end

function PS:init_module(world, gamestate)
    Particle:init_module(world, gamestate)
    Emitter:init_module(world, gamestate)

    Emitter:flush()
end

local AnimaParticles = {}
function PS:register_animated_particle(
    nick, anima_id, w, h, lifetime, draw_order, angle,
    gravity, speed_x, speed_y, acc_x, acc_y, delay, mass
)
    AnimaParticles[nick] = {
        anima_id = anima_id,
        w = w,
        h = h,
        lifetime = lifetime,
        draw_order = draw_order,
        angle = angle,
        gravity = gravity,
        speed_x = speed_x,
        speed_y = speed_y,
        acc_x = acc_x,
        acc_y = acc_y,
        delay = delay,
        mass = mass,
    }
end

function PS:newAnimatedParticle(nick, x, y, draw_order, delay, lifetime)
    local data = AnimaParticles[nick]
    assert(data)

    return Particle:newAnimated(
        Emitter:pop_anima(data.anima_id),
        x, y,
        data.w, data.h,
        lifetime or data.lifetime,
        data.angle,
        data.gravity,
        data.speed_x, data.speed_y,
        data.acc_x, data.acc_y,
        delay or data.delay,
        data.mass,
        draw_order or data.draw_order,
        data.anima_id
    )
end

function PS:newEmitter(x, y, w, h, draw_order, lifetime, custom_action, action_args, reuse_tab)
    local e = Emitter:new(x, y, w, h, draw_order, lifetime, custom_action, action_args, reuse_tab)

    return e
end

return PS
