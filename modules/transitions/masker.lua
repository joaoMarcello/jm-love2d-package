---@type JM.Transition
local Transition = require((...):gsub("masker", "transition"))

local Utils = _G.JM_Utils

local shader_code = [[
extern vec4 mask_color;

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 screen_coords)
{
	vec4 pix = Texel(tex, tex_coords);

    if(pix.a != 0.0)
    {
        return vec4(0.0, 0.0, 0.0, 0.0);
    }
	return mask_color;
}
]]

local love_setCanvas = love.graphics.setCanvas
local love_getCanvas = love.graphics.getCanvas
local love_getShader = love.graphics.getShader
local love_setShader = love.graphics.setShader
local love_setColor = love.graphics.setColor
local love_draw = love.graphics.draw
local love_clear = love.graphics.clear
local love_push = love.graphics.push
local love_pop = love.graphics.pop

---@type love.Shader
local shader

---@class JM.Transition.Masker : JM.Transition
local Masker = setmetatable({}, Transition)
Masker.__index = Masker

function Masker:new(args, x, y, w, h)
    shader = shader or love.graphics.newShader(shader_code)

    local obj = Transition:new(args, x, y, w, h)
    setmetatable(obj, self)
    Masker.__constructor__(obj, args)
    return obj
end

function Masker:__constructor__(args)
    self.color = args.color or Utils:get_rgba(0, 0, 0, 1)

    self.px = args.px or (self.w / 2)
    self.py = args.py or (self.h / 2)

    ---@type JM.Anima
    self.anima = args.anima

    ---@type function
    self.custom_draw = args.draw or args.custom_draw

    self.radius = math.max(self.w - self.px, self.h - self.py) * 1.25
    self.max_radius = self.radius

    self.duration = args.duration or 1
    self.direction = 1
    self.time = 0.05
    self.mult = 0

    if self.mode_out then
        self.time = self.duration
        self.direction = -1
        self.mult = 1
    end

    self.canvas = love.graphics.newCanvas(self.w, self.h)
    self.canvas:setFilter("linear", "nearest")

    self.subpixel = args.subpixel or 1

    self.enabled = true
end

function Masker:finished()
    if self.mode_out then
        return self.mult <= 0
    else
        return self.mult >= 1
    end
end

function Masker:update(dt)
    if not self.enabled then return end

    if self.anima then self.anima:update(dt) end

    self.time = self.time + dt * self.direction

    self.mult = Utils:clamp(self.time / self.duration, 0, 1)

    self.radius = self.max_radius * self.mult
    self.radius = Utils:clamp(self.radius, 0, self.max_radius)
end

function Masker:draw()
    local last_shader = love_getShader()
    local last_canvas = love_getCanvas()

    love_setCanvas(self.canvas)
    love_clear(0, 0, 0, 0)
    love_setColor(1, 1, 0)
    love_push()
    love.graphics.scale(1 / self.subpixel, 1 / self.subpixel)

    if self.anima then
        local ex = self.mode_out and 3 or 3.5

        self.anima:set_size(self.max_radius * ex
            * (self.mult >= 0.05 and self.mult or 0))
        self.anima:draw(self.px, self.py)
    end

    if self.custom_draw then
        self:custom_draw()
    end

    love_pop()
    love_setCanvas(last_canvas)

    love_setShader(shader)
    shader:sendColor("mask_color", self.color)

    love_setColor(1, 1, 1, 1)
    love_draw(self.canvas, self.x, self.y)

    love_setShader(last_shader)
end

return Masker
