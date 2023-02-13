---@type JM.Effect
local Effect = require((...):gsub("Popin", "Effect"))

---@class JM.Effect.Popin: JM.Effect
local Popin = setmetatable({}, Effect)
Popin.__index = Popin

---@param object JM.Template.Affectable|nil
---@param args any
---@return JM.Effect
function Popin:new(object, args)
    local ef = Effect:new(object, args)
    setmetatable(ef, self)

    Popin.__constructor__(ef, args)
    return ef
end

---@param self JM.Effect
---@param args any
function Popin:__constructor__(args)
    self.__id = args and args.__id__ or Effect.TYPE.popin
    self.__type_transform.sx = true
    self.__type_transform.sy = true

    self.__scale.x = 0.3
    self.__speed = args and args.speed or 0.2
    self.__min = 1
    self.__range = 0.2
    self.__state = 1

    if self.__object then
        self.__object:set_effect_transform("sx", args.min or 0)
        self.__object:set_effect_transform("sy", args.min or 0)
    end

    if self.__id == Effect.TYPE.popout then
        if self.__object then
            self.__object:set_visible(true)
            if self.__object then
                self.__object:set_effect_transform("sx", 1)
                self.__object:set_effect_transform("sy", 1)
            end
        end
        self.__scale.x = 1
        self.__min = 0.3
        self.__range = 0.3
    end
end

function Popin:update(dt)
    if self.__state == 1 then
        self.__scale.x = self.__scale.x + (1 + self.__range * 2) / self.__speed * dt

        if self.__scale.x >= ((1 + self.__range)) then
            self.__scale.x = ((1 + self.__range))
            self.__state = 0
        end
    end

    if self.__state == 0 then
        self.__scale.x = self.__scale.x - (1 + self.__range * 2) / self.__speed * dt

        if self.__id == Effect.TYPE.popin then
            if self.__scale.x <= 1 then
                self.__scale.x = 1
                self.__state = -1

                self.__object:set_effect_transform("sx", 1.0 + self.__scale.x)
                self.__object:set_effect_transform("sy", 1.0 + self.__scale.x)

                self.__remove = true
            end
        else
            if self.__scale.x <= self.__min then
                self.__state = -1
                self.__object:set_visible(false)

                self.__object:set_effect_transform("sx", 1.0)
                self.__object:set_effect_transform("sy", 1.0)

                self.__remove = true
                return
            end
        end
    end

    if self.__state >= 0 then
        self.__object:set_effect_transform("sx", self.__scale.x)
        self.__object:set_effect_transform("sy", self.__scale.x)
    end
end

return Popin
