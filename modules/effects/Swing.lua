---@type JM.Effect
local Effect = require((...):gsub("Swing", "Effect"))

local m_sin, PI = math.sin, math.pi

---@class JM.Effect.Swing: JM.Effect
local Swing = setmetatable({}, Effect)
Swing.__index = Swing

---@param object JM.Template.Affectable|nil
---@param args any
---@return JM.Effect effect
function Swing:new(object, args)
    local ef = Effect:new(object, args)
    setmetatable(ef, self)

    Swing.__constructor__(ef, args)
    return ef
end

---@param self JM.Effect
---@param args any
function Swing:__constructor__(args)
    self.__id = args and args.__id__ or Effect.TYPE.swing
    self.__range = args and args.range or 0.1
    self.__speed = args and args.speed or 4

    self.__direction = 1
    self.__not_restaure = true

    self.__type_transform.rot = true
end

function Swing:update(dt)
    self.__rad = self.__rad + PI * 2.0 / self.__speed * dt * self.__direction

    if self.__rad >= (PI * 2.0) then
        self:__increment_cycle()
        self.__rad = self.__rad % (PI * 2.0)
    end

    self.__object:set_effect_transform("rot", math.sin(self.__rad) * PI * 2.0 * self.__range)

end

return Swing
