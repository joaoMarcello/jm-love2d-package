---@type JM.Effect
local Effect = require((...):gsub("Ghost", "Effect"))

local m_sin, PI = math.sin, math.pi

---@class JM.Effect.Ghost: JM.Effect
local Ghost = setmetatable({}, Effect)
Ghost.__index = Ghost

---@param object JM.Template.Affectable|nil
---@param args any|nil
---@return JM.Effect|JM.Effect.Ghost
function Ghost:new(object, args)
    local obj = Effect:new(object, args)
    setmetatable(obj, self)

    Ghost.__constructor__(obj, args)
    return obj
end

---@param self JM.Effect
---@param args any|nil
function Ghost:__constructor__(args)
    self.__id = Effect.TYPE.ghost

    self.__min = args and args.min or 0
    self.__max = args and args.max or 1
    self.__center = self.__min + (self.__max - self.__min) / 2
    self.__range = (self.__max - self.__min) / 2
    self.__speed = args and args.speed or 1.5
    self.__alpha = self.__max
    self.__rad = PI
end

function Ghost:update(dt)
    self.__object:set_color2(
        nil, nil, nil,
        self.__center + m_sin(self.__rad) * self.__range
    )

    self.__rad = (self.__rad + (PI * 2) / self.__speed * dt)

    if self.__rad >= (PI * 2) then
        self.__rad = self.__rad % (PI * 2)
        self:__increment_cycle()
    end
end

return Ghost
