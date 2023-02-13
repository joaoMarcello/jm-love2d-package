local Effect = require((...):gsub("shader", "Effect"))

---@class JM.Effect.Sample:JM.Effect
local Sample = setmetatable({}, Effect)
Sample.__index = Sample

local shadercode = [[
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    if(screen_coords.x > 400){
        return vec4(1.0, 0.0, 0.0, 1.0);
    }
    else{
        return vec4(0.0, 0.0, 1.0, 1.0);
    }
}
  ]]

local black_white = [[
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
        vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color
        number average = (pixel.r+pixel.b+pixel.g)/3.0;
        pixel.r = average;
        pixel.g = average;
        pixel.b = average;
        return pixel;
      }
  ]]

local red_shadow = [[
    extern number alpha_value;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
        vec4 pixel = Texel(texture, texture_coords );
        if(pixel.a != 0.0){
            return vec4(1.0, 0.0, 0.0, alpha_value);
        }
        return pixel;
    }
  ]]

local negative = [[
    extern number alpha_value;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
        vec4 pixel = Texel(texture, texture_coords );
        
        return vec4(pixel.r + 1 * alpha_value, 
        pixel.g + 1 * alpha_value * 0.7, 
        pixel.b + 1 * alpha_value * 0.4, 
        pixel.a);
    }
  ]]

local myShader = love.graphics.newShader(negative)

function Sample:new(object, args)
    local obj = Effect:new(object, args)
    setmetatable(obj, self)

    Sample.__constructor__(obj, args)

    return obj
end

---@param self JM.Effect
function Sample:__constructor__(args)
    self.__alpha = 1
    self.__min = 0
    self.__max = 0.5
    self.__origin = self.__min
    self.__range = self.__max - self.__min
end

function Sample:update(dt)
    self.__rad = (self.__rad + math.pi * 2. / self.__speed * dt)

    if self.__rad >= math.pi then
        self.__rad = self.__rad % math.pi
        self:__increment_cycle()
    end

    self.__alpha = self.__origin + (math.sin(self.__rad) * self.__range)
end

function Sample:draw(...)
    love.graphics.setShader(myShader)
    myShader:send("alpha_value", self.__alpha)
    self.__object:__draw__(unpack { ... })
    love.graphics.setShader()
end

return Sample
