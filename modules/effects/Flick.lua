---@type JM.Effect
local Effect = require((...):gsub("Flick", "Effect"))

-- local shader_code = [[
--     extern number alpha;

--     vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
--         vec4 pixel = Texel(texture, texture_coords );

--         return vec4(1,0,0, pixel.a * alpha);
--         if (alpha == 1){
--             return vec4(pixel.r, pixel.g, pixel.b, pixel.a * alpha);
--         }
--         else{
--             return vec4(1, 1, 1, pixel.a);
--         }
--     }
-- ]]

-- local flick_shader = love.graphics.newShader(shader_code)

---@class JM.Effect.Flick: JM.Effect
local Flick = setmetatable({}, Effect)
Flick.__index = Flick

-- ---@return JM.Effect.Flick
function Flick:new(animation, args)
    local ef = Effect:new(animation, args)
    setmetatable(ef, self)

    Flick.__constructor__(ef, args)
    return ef
end

---@param self JM.Effect
---@param args any
function Flick:__constructor__(args)
    self.__id = Effect.TYPE.flickering
    self.__speed = args and args.speed or 0.1
    self.__time = 0
    -- self.__color = args and args.color or { 0, 0, 1, 1 }

    self.__flick_state = 1
    self.cycle_count = -1
end

function Flick:update(dt)
    self.__time = self.__time + dt


    if self.__flick_state == 1 then
        self.__object:set_visible(true)
    elseif self.__flick_state == -1 then
        self.__object:set_visible(false)
    end

    if self.__time >= self.__speed then
        self.__flick_state = -self.__flick_state
        self.__time = self.__time - self.__speed
        self:__increment_cycle()
    end
end

return Flick
