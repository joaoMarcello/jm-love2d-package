---@type JM.Effect
local Effect = require((...):gsub("Rotate", "Effect"))

local PI = math.pi

---@class JM.Effect.Rotate: JM.Effect
local Rotate = setmetatable({}, Effect)
Rotate.__index = Rotate

---@param object JM.Template.Affectable|nil
---@param args any|nil
---@return JM.Effect effect
function Rotate:new(object, args)
    local obj = Effect:new(object, args)
    setmetatable(obj, self)

    Rotate.__constructor__(obj, args)
    return obj
end

---@param self JM.Effect
---@param args any|nil
function Rotate:__constructor__(args)
    self.__id = args and args.__id__ or Effect.TYPE.clockWise
    self.__type_transform.rot = true

    self.__speed = args and args.speed or 2
    self.__direction = args and (args.__counter__ and -1) or 1
    self.__prior = 4
end

function Rotate:update(dt)
    self.__rad = self.__rad + (PI * 2) / (self.__speed) * dt * self.__direction

    if self.__rad >= PI * 2 then
        self.__rad = self.__rad % (PI * 2)
        self:__increment_cycle()
    end

    self.__object:set_effect_transform("rot", self.__rad)
end

return Rotate
