---@type JM.Effect
local Effect = require((...):gsub("stretch_squash", "Effect"))

---@class JM.Effect.StretchSquash : JM.Effect
local Stretch = setmetatable({}, Effect)
Stretch.__index = Stretch

function Stretch:new(obj, args)
    local eff = setmetatable(Effect:new(obj, args), Stretch)
    return Stretch.__constructor__(eff, args)
end

---@param self JM.Effect
function Stretch:__constructor__(args)
    self.__id = Effect.TYPE.stretchSquash

    self.vx = args.vx or 0.0
    self.range_x = args.range_x or 0.2
    self.init_range_x = self.range_x
    self.speed_x = args.speed_x or 0.5
    self.decay_speed_x = args.decay_speed_x or 1
    self.direction_x = args.direction_x or 1
    self.lim_x = args.lim_x

    self.vy = args.vy or 0.0
    self.range_y = args.range_y or 0.2
    self.init_range_y = self.range_y
    self.speed_y = args.speed_y or 0.5
    self.decay_speed_y = args.decay_speed_y or 1
    self.direction_y = args.direction_y or -1
    self.lim_y = args.lim_y

    self.__type_transform.sx = self.range_x ~= 0
    self.__type_transform.sy = self.range_y ~= 0

    return self
end

function Stretch:update(dt)
    local PI_2 = math.pi * 2
    local obj = self.__object

    self.vx = self.vx + (PI_2 / self.speed_x) * dt
    self.vy = self.vy + (PI_2 / self.speed_y) * dt

    do
        local lim_y = self.lim_y
        if lim_y and self.vy > lim_y then
            self.vy = lim_y
        end
    end

    do
        local lim_x = self.lim_x
        if lim_x and self.vx > lim_x then
            self.vx = lim_x
        end
    end

    obj:set_effect_transform("sx",
        1 + self.range_x * math.sin(self.vx) * self.direction_x
    )

    obj:set_effect_transform("sy",
        1 + self.range_y * math.sin(self.vy) * self.direction_y
    )

    self.range_x = self.range_x - (self.init_range_x / self.decay_speed_x) * dt
    self.range_y = self.range_y - (self.init_range_y / self.decay_speed_y) * dt

    if self.range_x < 0 then
        self.range_x = 0
    end

    if self.range_y < 0 then
        self.range_y = 0
    end

    if self.range_x == 0 and self.range_y == 0 then
        self.__remove = true
    end
end

return Stretch
