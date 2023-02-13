---@type JM.Effect
local Effect = require((...):gsub("Flash", "Effect"))

local m_sin, PI, love_set_shader = math.sin, math.pi, love.graphics.setShader

local shader_code = [[
    extern vec4 flash_color;

    vec3 rgb2hsv(vec3 c){
        vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
        vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

        float d = q.x - min(q.w, q.y);
        float e = 1.0e-10;
        return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
    }

    vec3 hsv2rgb(vec3 c){
        vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
        vec4 pixel = Texel(texture, texture_coords );
        vec3 hsv_pix = rgb2hsv(vec3(pixel.r, pixel.g, pixel.b));
        vec3 hsv_flash = rgb2hsv(vec3(flash_color.r, flash_color.g, flash_color.b));

        hsv_pix[2] = hsv_pix[2];

        vec3 result = vec3(
            hsv_flash[0],
            hsv_flash[1],
            hsv_flash[2]
        );

        result = hsv2rgb(result);

        return vec4(pixel.r + (flash_color.r * flash_color.a) ,
            pixel.g + (flash_color.g * flash_color.a) ,
            pixel.b + (flash_color.b * flash_color.a)  ,
            flash_color.a * pixel.a);
    }
  ]]

---@type love.Shader
local flash_shader

---
---@class JM.Effect.Flash: JM.Effect
--- Flash is a Effect sub-class.
local Flash = setmetatable({}, Effect)
Flash.__index = Flash

---@param object JM.Template.Affectable|nil
---@param args {speed: number, color: table, min: number, max: number}
---@return JM.Effect effect
function Flash:new(object, args)
    flash_shader = flash_shader or love.graphics.newShader(shader_code)

    local ef = Effect:new(object, args)
    setmetatable(ef, self)

    Flash.__constructor__(ef, args)
    return ef
end

---@overload fun(self: JM.Effect, args: nil)
---@param self JM.Effect
---@param args {speed: number, color: table, min: number, max: number}
function Flash:__constructor__(args)
    self.__id = Effect.TYPE.flash
    self.__alpha = 1
    self.__speed = args and args.speed or 0.3
    self.__color = args and args.color or { 238 / 255, 243 / 255, 46 / 255, 1 }
    local max = args and args.max or 1
    local min = args and args.min or 0.1
    self.__origin = min
    self.__range = (max - min)
    self.__speed = self.__speed + self.__range * self.__speed
end

--- Update flash.
---@param dt number
function Flash:update(dt)
    self.__rad = (self.__rad + PI * 2 / self.__speed * dt)

    if self.__rad >= PI then
        self.__rad = self.__rad % PI
        self:__increment_cycle()
    end

    self.__color[4] = self.__origin + (m_sin(self.__rad) * self.__range)
end

function Flash:draw(obj_draw, ...)
    love_set_shader(flash_shader)
    flash_shader:sendColor("flash_color", self.__color)
    if (...) then
        self.__object:__draw__(obj_draw, unpack { ... })
    else
        self.__object:__draw__(obj_draw)
    end
    love_set_shader()
end

return Flash
