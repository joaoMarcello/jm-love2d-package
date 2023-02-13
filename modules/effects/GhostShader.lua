---@type JM.Effect
local Effect = require((...):gsub("GhostShader", "Effect"))

local m_sin, PI = math.sin, math.pi

---@type love.Shader
local shader

---@class JM.Effect.GhostShader: JM.Effect
local Ghost = setmetatable({}, Effect)
Ghost.__index = Ghost

---@param object JM.Template.Affectable|nil
---@param args any|nil
---@return JM.Effect|JM.Effect.GhostShader
function Ghost:new(object, args)

    if not shader then
        local shader_code = [[
            //extern float alpha;

            vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
                vec4 pix = Texel(texture, texture_coords );

                if (pix.a > 0.0 || true){
                    return pix;//vec4(pix.r, pix.g, pix.b, pix.a);
                }
                else{
                    return pix; //return vec4(0, 0, 0, 0);
                }  
            } 
        ]]

        shader = love.graphics.newShader(shader_code)
    end

    local obj = Effect:new(object, args)
    setmetatable(obj, self)

    Ghost.__constructor__(obj, args)
    return obj
end

---@param self JM.Effect
---@param args any|nil
function Ghost:__constructor__(args)
    self.__id = Effect.TYPE.ghost

    self.__min = args and args.min or 0.0
    self.__max = args and args.max or 1.0
    self.__center = self.__min + (self.__max - self.__min) / 2.0
    self.__range = (self.__max - self.__min) / 2.0
    self.__speed = args and args.speed or 1.5
    self.__alpha = self.__max
    self.__rad = PI
end

function Ghost:update(dt)
    self.__rad = (self.__rad + (PI * 2.0) / self.__speed * dt)
        % (PI * 2.0)

    -- self.__object:set_color2(
    --     nil, nil, nil,
    --     self.__center + m_sin(self.__rad) * self.__range
    -- )
end

function Ghost:draw(obj_draw, ...)
    love.graphics.setShader(shader)

    -- shader:send("alpha", self.__center + m_sin(self.__rad) * self.__range)

    if (...) then
        self.__object:__draw__(obj_draw, unpack { ... })
    else
        self.__object:__draw__(obj_draw)
    end

    love.graphics.setShader()
end

return Ghost
