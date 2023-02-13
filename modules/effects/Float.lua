---@type JM.Effect
local Effect = require((...):gsub("Float", "Effect"))

---@class JM.Effect.Float: JM.Effect
local Float__ = setmetatable({}, Effect)
Float__.__index = Float__

---@param object JM.Template.Affectable|nil
---@param args any|nil
---@return JM.Effect|JM.Effect.Float
function Float__:new(object, args)

    local obj = Effect:new(object, args)
    setmetatable(obj, self)

    Float__.__constructor__(obj, args)
    return obj
end

---@param self JM.Effect
---@param args any|nil
function Float__:__constructor__(args)
    self.__id = args and args.__id__ or Effect.TYPE.float

    self.__speed = args and args.speed or 1

    self.__range = args and args.range or 20

    self.__floatX = self.__id == Effect.TYPE.pointing
        or self.__id == Effect.TYPE.circle or self.__id == Effect.TYPE.eight
        or self.__id == Effect.TYPE.butterfly

    self.__floatY = self.__id == Effect.TYPE.float
        or self.__id == Effect.TYPE.circle or self.__id == Effect.TYPE.eight
        or self.__id == Effect.TYPE.butterfly

    self.__adjust = args and args.adjust or math.pi / 2
    self.__rad = args and args.rad or 0

    if self.__id ~= Effect.TYPE.circle then
        self.__adjust = self.__id == Effect.TYPE.eight and 2 or 1
    end
    self.__adjustY = self.__id == Effect.TYPE.butterfly and 2 or 1

    self.__type_transform.ox = self.__floatX
    self.__type_transform.oy = self.__floatY

    self.__adjust_range_x = args and args.adjust_range_x or 0

    self.__threshold = args and args.threshold or math.pi * 2
    self.__direction = 1

end

function Float__:update(dt)
    self.__rad = self.__rad + ((self.__threshold) / self.__speed) * dt

    if self.__rad >= self.__threshold then
        self:__increment_cycle()
    end

    self.__rad = self.__rad % (self.__threshold)

    if self.__id == Effect.TYPE.circle then
        self:__circle_update(dt)
    else
        self:__not_circle_update(dt)
    end
end

function Float__:__circle_update(dt)
    local tx = self.__floatX and (math.sin(self.__rad + self.__adjust)
        * (self.__range + self.__adjust_range_x)) or 0

    local ty = self.__floatY and (math.sin(self.__rad * self.__adjustY)
        * self.__range) or 0

    self.__object:set_effect_transform("ox", tx)

    self.__object:set_effect_transform("oy", ty)
end

function Float__:__not_circle_update(dt)
    local tx = self.__floatX and (math.sin(self.__rad * self.__adjust) * self.__range) or 0

    local ty = self.__floatY and (math.sin(self.__rad * self.__adjustY) * self.__range) * self.__direction or 0

    if tx ~= 0 and ty ~= 0 then
        self.__object:set_effect_transform("ox", tx)
        self.__object:set_effect_transform("oy", ty)

    elseif tx ~= 0 then
        self.__object:set_effect_transform("ox", tx)

    else
        self.__object:set_effect_transform("oy", ty)

    end

end

return Float__
