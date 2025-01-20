local Utils = JM.Utils

local MSG_using_effect_with_no_associated_affectable =
"\nError: Trying to use a 'Effect' object without associate him to a 'Affectable' object.\n\nTip: Try use the ':apply' method from the 'Effect' object."

--- Check if object implements all the needed Affectable methods and fields.
---@param object table
local function checks_implementation(object)
    if not object then return end

    assert(object.__effect_manager, "\nError: The class do not have the required '__effect_manager' field.")

    assert(object.set_color, "\nError: The class do not implements the required 'set_color' method.")

    assert(object.set_visible,
        "\nError: The class do not implements the required 'set_visible' method.")

    assert(object.__draw__,
        "\nError: The class do not implements the required '__draw__' method.")

    assert(object.__get_effect_transform,
        "\nError: The class do not implements the required '__get_effect_transform' method.")

    -- assert(object.__set_effect_transform,
    --     "\nError: The class do not implements the required '__set_effect_transform' method.")
end

---
--- The animation effects.
---
---@enum JM.Effect.id_number
local TYPE_ = {
    generic = 0,           --***
    flash = 1,             --***
    flickering = 2,        --***
    pulse = 3,             --***
    colorFlick = 4,        --***
    popin = 5,             --***
    popout = 6,            --***
    fadein = 7,            --***
    fadeout = 8,           --***
    ghost = 9,             --***
    spin = 10,
    clockWise = 11,        --***
    counterClockWise = 12, --***
    swing = 13,            --***
    pop = 14,
    growth = 15,
    disc = 16,     --***
    idle = 17,     --***
    echo = 18,
    float = 19,    --***
    pointing = 20, --***
    darken = 21,
    brighten = 22,
    shadow = 23,
    line = 24,
    zoomInOut = 25,
    stretchHorizontal = 26, --***
    stretchVertical = 27,   --***
    circle = 28,            --***
    eight = 29,             --***
    bounce = 30,            --***
    heartBeat = 31,         --***
    butterfly = 32,         --***
    jelly = 33,             --***
    shake = 34,
    clickHere = 35,         --***
    jump = 36,
    ufo = 37,               --***
    pendulum = 38,
    earthquake = 39,        --***
    ghostShader = 40,       --***
    stretchSquash = 41,
}

---
---@class JM.Effect
---@field __id JM.Effect.id_number
---@field __UNIQUE_ID number
---@field __init function
local Effect = {}
Effect.__index = Effect
Effect.TYPE = TYPE_

---
--- Class effect constructor.
---@overload fun(self: table|nil, object: nil, args: nil):JM.Effect
---@param object JM.Template.Affectable
---@param args any
---@return JM.Effect effect
function Effect:new(object, args)
    -- ---@type JM.Effect
    local effect = setmetatable({}, Effect)
    return Effect.__constructor__(effect, object, args)
end

---
--- Class effect constructor.
---
---@param self JM.Effect
---@param object JM.Template.Affectable
function Effect:__constructor__(object, args)
    self.__id = Effect.TYPE.generic
    self.__color = Utils:get_rgba(1, 1, 1, 1)
    self.__scale = { x = 1, y = 1 }
    self.__is_enabled = true
    self.__prior = 1
    self.__rad = args.rad or 0
    self.cycle_count = 0
    self.__args = args
    self.__remove = false
    self.__update_time = 0
    self.__duration = args and args.duration or nil
    self.__speed = 0.5
    self.__max_sequence = args and args.max_sequence or 100
    self.__ends_by_cycle = args and args.max_sequence or false
    self.__time_delay = args and args.delay or 0

    self.__type_transform = {}

    self.__remove = false

    self.ox = nil
    self.oy = nil

    self.__obj_initial_color = Utils:get_rgba(1, 1, 1, 1)
    self:set_object(object)
    return self
end

--
--- Set the effect final action.
---@param action function
---@param args any
function Effect:set_final_action(action, args)
    self.__final_action = action
    self.__args_final_action = args
end

-- --- Set effect in loop mode.
-- ---@param value boolean
-- function Effect:loop_mode(value)
--     if value then
--         self:set_final_action(
--         ---comment
--         ---@param args JM.Affectable
--             function(args)
--                 local eff = args:apply(self.__args)
--                 eff:loop_mode(true)
--             end,

--             self.__object
--         )
--     else -- value parameter is nil or false
--         self.__final_action = nil
--         self.__args_final_action = nil
--     end
-- end

function Effect:init()
    self.__remove = false
    self.__is_enabled = true
    self.__rad = 0
    self.cycle_count = 0
    self.__update_time = 0
    self.__not_restaure = false
    self:__constructor__(self.__args)
end

function Effect:copy()
    local obj = Effect:new(nil, self.__args)
    return obj
end

---
---@param object JM.Template.Affectable
function Effect:set_object(object)
    checks_implementation(object)

    self.__object = object

    if self.__object then
        self.__obj_initial_color = self.__object:get_color()
    end
end

function Effect:get_object()
    return self.__object
end

function Effect:__increment_cycle()
    self.cycle_count = self.cycle_count + 1
end

function Effect:completed_cycle()
    return self.__max_sequence
        and self.__ends_by_cycle
        and (self.cycle_count >= self.__max_sequence)
end

function Effect:update(dt)
    return false
end

function Effect:__update__(dt)
    assert(self.__object, "Error: Effect object is not associated with a Affectable object.")

    if self.__time_delay > 0 then
        self.__is_enabled = false

        self.__time_delay = self.__time_delay - dt

        if self.__time_delay <= 0 then
            self.__is_enabled = true
        else
            return
        end
    end

    self.__update_time = self.__update_time + dt

    if self.__duration and self.__update_time >= self.__duration then
        self.__remove = true
    end

    if self.__max_sequence
        and self.__ends_by_cycle
        and (self.cycle_count >= self.__max_sequence) then
        self.__remove = true
    end

    if self.__remove then
        if self.__final_action then
            self.__final_action(self.__args_final_action)
        end
        self:restaure_object()
    end
end

function Effect:restaure_object()
    local obj = self.__object
    assert(obj, MSG_using_effect_with_no_associated_affectable)

    local id = self.__id
    local Type = Effect.TYPE

    if id == Type.flash
        or id == Type.fadein
        or id == Type.fadeout
        or id == Type.ghost
        or id == Type.flickering
    then
        obj:set_color(self.__obj_initial_color)
    end

    if id == Type.flickering
    -- or id == Type.popout
    then
        obj:set_visible(true)
    end

    local type_transform = self.__type_transform
    obj:set_effect_transform("rot", type_transform.rot and 0)
    obj:set_effect_transform("sx", type_transform.sx and 1)
    obj:set_effect_transform("sy", type_transform.sy and 1)
    obj:set_effect_transform("ox", type_transform.ox and 0)
    obj:set_effect_transform("oy", type_transform.oy and 0)
    obj:set_effect_transform("kx", type_transform.kx and 0)
    obj:set_effect_transform("ky", type_transform.ky and 0)
end

function Effect:draw(...)
    return
end

--- Forca efeito em um objeto que nao era dele.
---@param object JM.Template.Affectable|nil
function Effect:apply(object, reset)
    if not object then return end

    do
        local manager = object.__effect_manager
        manager:use_effect()
    end

    if object and object ~= self.__object then
        if self.__object then self:restaure_object() end

        self.__obj_initial_color = object:get_color()
    end

    self:set_object(object)
    self:restart(reset)
end

---comment
---@param value number
function Effect:set_unique_id(value)
    if not self.__UNIQUE_ID then
        self.__UNIQUE_ID = value
    end
end

--- The unique identifiers.
---@return number
function Effect:get_unique_id()
    return self.__UNIQUE_ID
end

--- Restaure the effect in animation.
---@param reset_config boolean|nil # if reset the effect to his initial configuration.
function Effect:restart(reset_config)
    if reset_config then
        self:init()
    end

    assert(self.__object, MSG_using_effect_with_no_associated_affectable)
    self.__object.__effect_manager:__insert_effect(self)
end

return Effect
