local shader_code = [[
uniform Image mask;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 tex_color = Texel(tex, texture_coords);
	vec4 mask_color = Texel(mask, texture_coords);
	tex_color.a = mask_color.a;
	return tex_color;
}
]]

local shader = love.graphics.newShader(shader_code)

local Transition = {}
Transition.__index = Transition

---@param scene JM.Scene
function Transition:new(scene, args)
    local obj = {}
    setmetatable(obj, self)
    Transition.__constructor__(obj, scene, args)
    return obj
end

---@param scene JM.Scene
function Transition:__constructor__(scene, args)
    self.mode_out = args.mode == "out"
    self.scene = scene
    self.color = args.color or { 0, 0, 0, 1 }

    self.time = 0
    self.duration = args.duration or 2
end

function Transition:finished()
    return false
end

function Transition:update(dt)
    self.time = self.time + dt
end

function Transition:draw()
    local last = love.graphics.getShader()
    love.graphics.setShader(shader)
    shader:send("mask", self.mask)
    
    love.graphics.setShader(last)
end

return Transition
