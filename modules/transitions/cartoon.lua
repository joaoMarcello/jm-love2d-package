---@type JM.Transition
local Transition = require((...):gsub("cartoon", "transition"))

local Utils = _G.JM_Utils

local shader_code = [[
vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 screen_coords)
{
	vec4 pix = Texel(tex, tex_coords);

    if(pix.r == 1.0 && pix.g == 1.0 && pix.b == 0.0)
    {
        pix.a = 0.0;
    }
	return pix;
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

local shader

---@class JM.Transition.Mask : JM.Transition
local Cartoon = setmetatable({}, Transition)
Cartoon.__index = Cartoon

function Cartoon:new(args, x, y, w, h)
    shader = shader or love.graphics.newShader(shader_code)

    local obj = Transition:new(args, x, y, w, h)
    setmetatable(obj, self)
    Cartoon.__constructor__(obj, args)
    return obj
end

function Cartoon:__constructor__(args)
    self.color = args.color or { 0, 0, 0, 1 }

    self.px = args.px or (self.w / 2)
    self.py = args.py or (self.h / 2)

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
    self.canvas:setFilter("nearest", "nearest")

    self.subpixel = args.subpixel or 4

    self.enabled = true
end

function Cartoon:finished()
    if self.mode_out then
        return self.mult <= 0
    else
        return self.mult >= 1
    end
    return false
end

function Cartoon:update(dt)
    if not self.enabled then return end

    self.time = self.time + dt * self.direction

    self.mult = Utils:clamp(self.time / self.duration, 0, 1)

    self.radius = self.max_radius * self.mult
    self.radius = Utils:clamp(self.radius, 0, self.max_radius)
end

function Cartoon:draw()
    local last_shader = love_getShader()
    local last_canvas = love_getCanvas()

    love_setCanvas(self.canvas)
    love_clear(unpack(self.color))
    love_setColor(1, 1, 0)
    love_push()
    love.graphics.scale(1 / self.subpixel, 1 / self.subpixel)

    love.graphics.circle("fill", self.px, self.py, self.radius)

    love_pop()
    love_setCanvas(last_canvas)

    love_setShader(shader)
    love_setColor(1, 1, 1, 1)
    love_draw(self.canvas, self.x, self.y)

    love_setShader(last_shader)

    -- local font = JM_Font
    -- font:print(self:finished(), 100, 100)
end

return Cartoon
