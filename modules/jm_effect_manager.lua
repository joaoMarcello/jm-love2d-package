local path = (...):gsub("jm_effect_manager", "")

---@type JM.Effect
local Effect = require(path .. "effects.Effect")

---@type JM.Effect.Flash
local Flash = require(path .. "effects.Flash")

---@type JM.Effect.Flick
local Flick = require(path .. "effects.Flick")

---@type JM.Effect.Pulse
local Pulse = require(path .. "effects.Pulse")

---@type JM.Effect.Float
local Float = require(path .. "effects.Float")

---@type JM.Effect.Swing
local Idle = require(path .. "effects.Idle")

---@type JM.Effect.Rotate
local Rotate = require(path .. "effects.Rotate")

---@type JM.Effect.Swing
local Swing = require(path .. "effects.Swing")

---@type JM.Effect.Popin
local Popin = require(path .. "effects.Popin")

---@type JM.Effect.Fadein
local Fadein = require(path .. "effects.Fadein")

---@type JM.Effect.Ghost
local Ghost = require(path .. "effects.Ghost")

---@type JM.Effect.Disc
local Disc = require(path .. "effects.Disc")

---@type JM.Effect.Disc
local Earthquake = require(path .. "effects.Earthquake")

---@type JM.Effect.GhostShader
local GhostShader = require(path .. "effects.GhostShader")

---@type JM.Effect.StretchSquash
local StretchSquash = require(path .. "effects.stretch_squash")

local Sample = require(path .. "effects.shader")

-- Variable for control the unique id's from EffectManager class
local JM_current_id_for_effect_manager__ = math.random(1000) * math.random()

---@class JM.EffectManager
--- Manages a list of Effect.
local EffectManager = {}
EffectManager.__index = EffectManager

---
--- Public constructor.
---@return JM.EffectManager
function EffectManager:new(affectable_object)
    local obj = {}
    setmetatable(obj, self)

    EffectManager.__constructor__(obj, affectable_object)
    return obj
end

---@param affectable_object JM.Template.Affectable
function EffectManager:__constructor__(affectable_object)
    self.__effects_list = {}
    self.__sort__ = false
    self.object = affectable_object
end

--- Update EffectManager class.
---@param dt number
function EffectManager:update(dt)
    local list = self.__effects_list

    if list then
        for i = #list, 1, -1 do
            ---@type JM.Effect
            local eff = list[i]
            local r1 = eff:__update__(dt)
            local r2 = eff.__is_enabled and not eff.__remove and eff:update(dt)

            if eff.__remove then
                if eff.__final_action then
                    eff.__final_action(eff.__args_final_action)
                end

                -- second test for remove (in cases with the final action restores the effect)
                if eff.__remove then
                    eff:restaure_object()

                    if self.__effects_clear then
                        self.__effects_clear = nil;
                        break
                    end
                    self.__effects_list[i] = nil
                    local r2 = table.remove(self.__effects_list, i)
                end
            end -- END if remove effect
        end     -- END FOR i in effects list

        if self.__sort__ then
            table.sort(self.__effects_list,
                ---@param a JM.Effect
                ---@param b JM.Effect
                ---@return boolean
                function(a, b)
                    return a.__prior > b.__prior;
                end
            )

            self.__sort__ = false
        end -- END IF sort.
    end     -- END effect list is not nil.
end

---
---@param draw function # Draw method from affectable object.
---@param ... unknown # The param for the object draw method
function EffectManager:draw(draw, ...)
    local args = (...) and { ... } or nil

    for i = #(self.__effects_list), 1, -1 do
        ---@type JM.Effect
        local eff = self.__effects_list[i]

        if args then
            eff:draw(draw, unpack(args))
        else
            eff:draw(draw)
        end
    end
end

---
--- Stop all the current running effects.
---@return boolean
function EffectManager:stop_all()
    if self.__effects_list then
        self.__effects_list = {}
        self.__effects_clear = true
        return true
    end
    return false
end

function EffectManager:clear()
    local list = self.__effects_list
    local N = #list
    if N > 0 then
        for i = 1, N do
            ---@type JM.Effect
            local eff = list[i]

            eff:restaure_object()
        end

        for i = 1, N do
            list[i] = nil
        end
        -- self.__effects_list = {}
        return true
    end
    return false
end

--- Stops a especific effect by his unique id.
---@param effect_unique_id number
---@return boolean result
function EffectManager:stop_effect(effect_unique_id)
    for i = 1, #self.__effects_list do
        ---@type JM.Effect
        local eff = self.__effects_list[i]

        if eff:get_unique_id() == effect_unique_id then
            eff.__remove = true
            return true
        end
    end
    return false
end

function EffectManager:pause_all()
    if self.__effects_list then
        for i = 1, #self.__effects_list do
            ---@type JM.Effect
            local eff = self.__effects_list[i]
            eff.__is_enabled = false
        end
    end
end

function EffectManager:resume_all()
    if self.__effects_list then
        for i = 1, #self.__effects_list do
            ---@type JM.Effect
            local eff = self.__effects_list[i]
            eff.__is_enabled = true
        end
    end
end

do
    --- Possible values for effect names.
    ---@alias JM.Effect.id_string string
    ---|"flash" # animation blinks like a star.
    ---|"flickering" # animation surges in the screen.
    ---|"pulse"
    ---|"colorFlick"
    ---|"popin"
    ---|"popout"
    ---|"fadein"
    ---|"fadeout"
    ---|"ghost"
    ---|"spin"
    ---|"clockWise"
    ---|"counterClockWise"
    ---|"swing"
    ---|"pop"
    ---|"growth"
    ---|"disc"
    ---|"idle"
    ---|"echo"
    ---|"float"
    ---|"pointing"
    ---|"darken"
    ---|"brighten"
    ---|"shadow"
    ---|"line"
    ---|"zoomInOut"
    ---|"stretchHorizontal"
    ---|"stretchVertical"
    ---|"circle"
    ---|"eight"
    ---|"bounce"
    ---|"heartBeat"
    ---|"butterfly"
    ---|"jelly"
    ---|"clickHere"
    ---|"ufo"
    ---|"pendulum"
    ---|"earthquake"
    ---|"ghostShader"
    ---|"stretchSquash"
end

local default_args = {}

---Applies effect in a animation.
---@param object JM.Template.Affectable|nil # The object to apply the effect.
---@param type_ JM.Effect.id_string # The type of the effect.
---@param effect_args any # The parameters need for that especific effect.
---@param __only_get__ boolean|nil
---@return JM.Effect eff # The generate effect.
function EffectManager:apply_effect(object, type_, effect_args, __only_get__)
    object = object or self.object

    local eff

    effect_args = effect_args or default_args

    local eff_type = type(type_) == "string" and Effect.TYPE[type_] or type_

    local TYPE = Effect.TYPE

    if eff_type == TYPE.flash then
        eff = Flash:new(object, effect_args)
    elseif eff_type == TYPE.flickering then
        eff = Flick:new(object, effect_args)
    elseif eff_type == TYPE.colorFlick then
        eff = Flick:new(object, effect_args)
        eff.__id = TYPE.colorFlick

        if not effect_args or (effect_args and not effect_args.color) then
            eff.__color = { 1, 0, 0, 1 }
        end
    elseif eff_type == TYPE.pulse then
        eff = Pulse:new(object, effect_args)
    elseif eff_type == TYPE.float then
        eff = Float:new(object, effect_args)
    elseif eff_type == TYPE.pointing then
        effect_args.__id__ = TYPE.pointing
        eff = Float:new(object, effect_args)
    elseif eff_type == TYPE.circle then
        effect_args.__id__ = TYPE.circle
        eff = Float:new(object, effect_args)
    elseif eff_type == TYPE.eight then
        effect_args.__id__ = TYPE.eight
        eff = Float:new(object, effect_args)
    elseif eff_type == TYPE.butterfly then
        effect_args.__id__ = TYPE.butterfly
        eff = Float:new(object, effect_args)
    elseif eff_type == TYPE.idle then
        eff = Idle:new(object, effect_args)
    elseif eff_type == TYPE.heartBeat then
        local pulse = Pulse:new(object, { max_sequence = 2, speed = 0.3, range = 0.1, __id__ = TYPE.heartBeat })
        pulse.__rad = 0

        local idle_eff = Idle:new(object, { duration = 1, __id__ = TYPE.heartBeat })

        pulse:set_final_action(
            function()
                idle_eff:apply(pulse:get_object(), true)
            end
        )

        idle_eff:set_final_action(
            function()
                pulse:apply(idle_eff:get_object(), true)
                pulse.__rad = 0
            end
        )

        eff = pulse
    elseif eff_type == TYPE.clickHere then
        local bb = Swing:new(object, { range = 0.03, speed = 1 / 3, max_sequence = 2 })

        local idle = Idle:new(object, { duration = 1 })

        bb:set_final_action(
            function()
                idle:apply(bb:get_object(), true)
            end)

        idle:set_final_action(
            function()
                bb:apply(idle:get_object(), true)
            end)

        eff = bb
    elseif eff_type == TYPE.jelly then
        effect_args.__id__ = TYPE.jelly
        eff = Pulse:new(object, effect_args)
    elseif eff_type == TYPE.stretchHorizontal then
        effect_args.__id__ = TYPE.stretchHorizontal
        eff = Pulse:new(object, effect_args)
    elseif eff_type == TYPE.stretchVertical then
        effect_args.__id__ = TYPE.stretchVertical
        eff = Pulse:new(object, effect_args)
    elseif eff_type == TYPE.bounce then
        effect_args.__id__ = TYPE.bounce
        eff = Pulse:new(object, effect_args)
    elseif eff_type == TYPE.clockWise then
        eff = Rotate:new(object, effect_args)
    elseif eff_type == TYPE.counterClockWise then
        effect_args.__counter__ = true
        eff = Rotate:new(object, effect_args)
    elseif eff_type == TYPE.swing then
        eff = Swing:new(object, effect_args)
    elseif eff_type == TYPE.popin then
        eff = Popin:new(object, effect_args)
    elseif eff_type == TYPE.popout then
        effect_args.__id__ = TYPE.popout
        eff = Popin:new(object, effect_args)
    elseif eff_type == TYPE.fadein then
        eff = Fadein:new(object, effect_args)
    elseif eff_type == TYPE.fadeout then
        effect_args.__id__ = TYPE.fadeout
        eff = Fadein:new(object, effect_args)
    elseif eff_type == TYPE.ghost then
        eff = Ghost:new(object, effect_args)
    elseif eff_type == TYPE.disc then
        eff = Disc:new(object, effect_args)
    elseif eff_type == TYPE.ufo then
        local circle = self:generate_effect("circle", { range = 25, speed = 4, adjust_range_x = 150 })

        local pulse = Pulse:new(object, { range = 0.5, speed = 4 })

        local idle = Idle:new(object, { duration = 1, __id__ = TYPE.ufo })

        idle:set_final_action(
            function()
                pulse:apply(idle:get_object())
                circle:apply(idle:get_object())
            end)

        eff = idle
    elseif eff_type == TYPE.earthquake then
        eff = Earthquake:new(object, effect_args)
    elseif eff_type == TYPE.ghostShader then
        eff = GhostShader:new(object, effect_args)
    elseif eff_type == TYPE.pendulum then
        -- local pointing = self:apply_effect(object, "pointing", { speed = 4, range = 100 }, true)

        -- local floating = self:apply_effect(object, "float", { speed = 2 }, true)

        -- local idle = Idle:new(object, { duration = 0, __id__ = Effect.TYPE.pendulum })

        -- idle:set_final_action(
        -- ---@param args {idle: JM.Effect, pointing: JM.Effect, floating: JM.Effect}
        --     function(args)
        --         args.pointing:apply(idle.__object)
        --         args.floating:apply(idle.__object)
        --     end,
        --     { idle = idle, pointing = pointing, floating = floating })

        -- eff = idle
    elseif eff_type == "shader" then
        eff = Sample:new(object, effect_args)
    elseif eff_type == TYPE.stretchSquash then
        eff = StretchSquash:new(object, effect_args)
    end

    if eff then
        -- eff:set_unique_id(JM_current_id_for_effect_manager__)
        -- JM_current_id_for_effect_manager__ = JM_current_id_for_effect_manager__ + 1

        if not __only_get__ then
            self:__insert_effect(eff)
        end
    end
    return eff
end

---comment
---@param effect_type JM.Effect.id_string
---@param effect_args any
---@return JM.Effect
function EffectManager:generate_effect(effect_type, effect_args)
    local eff = self:apply_effect(nil, effect_type, effect_args, true)
    eff.__object = nil
    return eff
end

function EffectManager:__is_in_list(effect)
    if not effect then return end

    for i = 1, #self.__effects_list do
        if effect == self.__effects_list[i] then
            return true
        end
    end

    return false
end

--- Insert effect.
---@param effect JM.Effect
function EffectManager:__insert_effect(effect)
    if self:__is_in_list(effect) then return end

    table.insert(self.__effects_list, effect)
    self.__sort__ = true
end

---@param obj JM.Template.Affectable
function EffectManager:transfer(obj)
    if #self.__effects_list <= 0 then return end

    obj:__set_effect_transform(self.object.__effect_transform)

    for i = 1, #(self.__effects_list) do
        ---@type JM.Effect
        local eff = self.__effects_list[i]

        eff:apply(obj)
    end


    self.__effects_list = {}
end

return EffectManager
