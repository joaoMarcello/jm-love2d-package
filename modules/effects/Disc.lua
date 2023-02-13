local Effect = require((...):gsub("Disc", "Effect"))

local m_sin, PI = math.sin, math.pi

---@class JM.Effect.Disc: JM.Effect
local Disc = setmetatable({}, Effect)
Disc.__index = Disc

---@param object JM.Template.Affectable|nil
---@param args any|nil
---@return JM.Effect|JM.Effect.Disc
function Disc:new(object, args)
    local obj = Effect:new(object, args)
    setmetatable(obj, self)

    Disc.__constructor__(obj, args)
    return obj
end

---@param self JM.Effect
---@param args any|nil
function Disc:__constructor__(args)
    self.__id = Effect.TYPE.disc
    self.__type_transform.kx = true
    self.__type_transform.ky = true

    self.__range = 0.8
    self.__speed = 4
    self.__direction = 1
    self.__not_restaure = true
end

function Disc:update(dt)
    self.__rad = self.__rad + (PI * 2) / self.__speed * dt

    if self.__rad >= PI * 2 then
        self:__increment_cycle()
    end

    self.__rad = self.__rad % (PI * 2)

    self.__object:set_effect_transform(
        "kx",
        m_sin(self.__rad) * self.__range
    )

    self.__object:set_effect_transform(
        "ky",
        -m_sin(self.__rad + PI * 1.5) * self.__range
    )
end

return Disc
