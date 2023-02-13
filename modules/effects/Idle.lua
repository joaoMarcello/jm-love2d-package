---@type JM.Effect
local Effect = require((...):gsub("Idle", "Effect"))

---@class JM.Effect.Iddle: JM.Effect
local Idle = setmetatable({}, Effect)
Idle.__index = Idle

function Idle:new(object, args)
    local ef = Effect:new(object, args)
    setmetatable(ef, self)

    Idle.__constructor__(ef, args)
    return ef
end

---@param self JM.Effect
---@param args {duration: number, __id__: JM.Effect.id_number}
function Idle:__constructor__(args)
    self.__id = args and args.__id__ or Effect.TYPE.idle
    self.__time_total = args and args.duration or 0
    self.__time = 0
end

function Idle:update(dt)
    self.__time = self.__time + dt

    if self.__time >= self.__time_total then
        self.__remove = true
    end
end

return Idle
