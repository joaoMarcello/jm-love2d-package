---@type JM.Effect
local Effect = require((...):gsub("Earthquake", "Effect"))

local PI, m_cos, m_sin = math.pi, math.cos, math.sin

local function clamp(value, A, B)
    return math.min(math.max(value, A), B)
end

---@class JM.Effect.Earthquake: JM.Effect
local Earthquake = setmetatable({}, Effect)
Earthquake.__index = Earthquake

function Earthquake:new(obj, args)
    local obj = Effect:new(obj, args)
    setmetatable(obj, self)
    Earthquake.__constructor__(obj, args)
    return obj
end

---@param self JM.Effect
function Earthquake:__constructor__(args)
    self.__id = Effect.TYPE.earthquake

    self.is_random = args.random or false

    self.amplitude_x = args.range_x or 10
    self.max_ampli_x = self.amplitude_x
    self.duration_x = args.duration_x
    self.speed_x = args.speed_x or (self.is_random and 0 or 0.4)
    self.rad_x = args.rad_x or PI * 0.3

    self.amplitude_y = args.range_y or 7
    self.max_ampli_y = self.amplitude_y
    self.duration_y = args.duration_y --1
    self.speed_y = args.speed_y or (self.is_random and 0 or 0.4)
    self.rad_y = args.rad_y or PI * 0.4


    self.__type_transform.ox = true
    self.__type_transform.oy = true
end

local function do_the_thing(self, dt, rad, speed, amplitude, max_ampli, duration, transf)
    self[rad] = self[rad] + (PI * 2) / self[speed] * dt

    if self[rad] >= PI * 2 then
        self[rad] = self[rad] % (PI * 2)
        -- self[speed] = clamp(math.random(), 0.25, 0.3)
    end

    if self[duration] then
        self[amplitude] = self[amplitude]
            - (self[max_ampli] / self[duration] * dt)
    end

    self[amplitude] = clamp(self[amplitude], 0, self[max_ampli])

    self.__object:set_effect_transform(transf,
        m_sin(self[rad]) * self[amplitude]
    )
end

local function random_earthquake(self, dt, rad, speed, amplitude, max_ampli, duration, transf)

    self[speed] = self[speed] + dt
    if self[speed] >= 0.05 then
        self[speed] = self[speed] - 0.05
        self[amplitude] = self[max_ampli] * math.random()
    end

    self.__object:set_effect_transform(transf,
        self[amplitude]
    )
end

function Earthquake:update(dt)
    if self.is_random then
        random_earthquake(self, dt, "rad_y", "speed_y", "amplitude_y", "max_ampli_y", "duration_y", "oy")

        random_earthquake(self, dt, "rad_x", "speed_x", "amplitude_x", "max_ampli_x", "duration_x", "ox")
    else
        do_the_thing(self, dt, "rad_x", "speed_x", "amplitude_x", "max_ampli_x", "duration_x", "ox")

        do_the_thing(self, dt, "rad_y", "speed_y", "amplitude_y", "max_ampli_y", "duration_y", "oy")
    end
end

return Earthquake
