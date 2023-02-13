--[[ Lua module for animation in LÖVE 2D.

    Copyright (c) 2022, Joao Moreira.
]]

---@type string
local path = (...)

---@type JM.Template.Affectable
local Affectable = require(path:gsub("jm_animation", "templates.Affectable"))

-- Some local variables to store global modules.
local love_graphics = love.graphics
local love_graphics_draw = love_graphics.draw
local love_graphics_set_color = love_graphics.setColor

---@enum JM.Anima.EventTypes
local Event = {
    frame_change = 0,
    pause = 1,
    update = 2,
}
---@alias JM.Anima.EventNames "frame_change"|"pause"|"update"


---@enum JM.Anima.States
local ANIMA_STATES = {
    looping = 1,
    back_and_forth = 2,
    random = 3,
    repeating_last_n_frames = 4
}


---@param width any
---@param height any
---@param ref_width any
---@param ref_height any
---@param keep_proportions any
---@return number
---@return number
local function desired_size(width, height, ref_width, ref_height, keep_proportions)
    local dw, dh

    dw = width and width / ref_width or nil
    dh = height and height / ref_height or nil

    if keep_proportions then
        if not dw then
            dw = dh
        elseif not dh then
            dh = dw
        end
    end

    return dw, dh
end

---@param animation JM.Anima
---@param type_ JM.Anima.EventTypes
local function dispatch_event(animation, type_)
    local evt = animation.events and animation.events[type_]
    local r = evt and evt.action(evt.args)
end

--===========================================================================

---@class JM.Anima.Frame
--- Internal class Frame.
local Frame = {}
do
    ---@param args {left: number, right:number, top:number, bottom:number, speed:number, ox:number, oy:number}
    function Frame:new(args)
        local obj = {}

        setmetatable(obj, self)
        self.__index = self

        Frame.__constructor__(obj, args)

        return obj
    end

    --- Constructor.
    function Frame:__constructor__(args)
        local left = args.left or args[1]
        local top = args.top or args[3]
        local right = args.right or args[2]
        local bottom = args.bottom or args[4]

        self.x = left
        self.y = top
        self.w = right - left
        self.h = bottom - top
        self.ox = args.ox or (self.w / 2)
        self.oy = args.oy or (self.h / 2)

        self.speed = args.speed or nil

        self.bottom = self.y + self.h
    end

    function Frame:get_offset()
        return self.ox, self.oy
    end

    function Frame:set_offset(ox, oy)
        self.ox = ox or self.ox
        self.oy = oy or self.oy
    end

    --- Sets the Quad Viewport.
    ---@param img love.Image
    ---@param quad love.Quad
    function Frame:setViewport(img, quad)
        quad:setViewport(
            self.x, self.y,
            self.w, self.h,
            img:getWidth(), img:getHeight()
        )
    end

end
--===========================================================================

---@param anima JM.Anima
local function is_in_normal_direction(anima)
    return anima.direction > 0
end

---@param anima JM.Anima
local function is_in_looping_state(anima)
    return anima.current_state == ANIMA_STATES.looping
end

---@param anima JM.Anima
local function is_in_repeating_last_n_state(anima)
    return anima.current_state == ANIMA_STATES.repeating_last_n_frames
end

---@param anima JM.Anima
local function is_in_random_state(anima)
    return anima.current_state == ANIMA_STATES.random
end

--===========================================================================

-- Class to animate.
--- @class JM.Anima: JM.Template.Affectable
--- @field __configuration {scale: JM.Point, color: JM.Color, direction: -1|1, rotation: number, speed: number, flip: table, kx: number, ky: number, current_frame: number}
local Anima = {}
setmetatable(Anima, Affectable)
Anima.__index = Anima

---
--- Animation class constructor.
---
--- @param args {img: love.Image|string, frames: number, frames_list: table,  speed: number, rotation: number, color: JM.Color, scale: table, flip_x: boolean, flip_y: boolean, is_reversed: boolean, stop_at_the_end: boolean, amount_cycle: number, state: JM.AnimaStates, bottom: number, kx: number, ky: number, width: number, height: number, ref_width: number, ref_height: number, duration: number, n: number}  # A table containing the following fields:
-- * img (Required): The source image for animation (could be a Love.Image or a string containing the file path).
-- * frames: The amount of frames in the animation.
-- * speed: Time in seconds to update frame.
--- @return JM.Anima animation # A instance of Anima class.
function Anima:new(args)
    assert(args, "\nError: Trying to instance a Animation without inform any parameter.")

    local animation = Affectable:new()
    setmetatable(animation, self)
    Anima.__constructor__(animation, args)

    return animation
end

---
--- Internal method for constructor.
---
--- @param args {img: love.Image|string, frames: number, frames_list: table,  speed: number, rotation: number, color: JM.Color, scale: table, flip_x: boolean, flip_y: boolean, is_reversed: boolean, stop_at_the_end: boolean, amount_cycle: number, state: JM.AnimaStates, bottom: number, kx: number, ky: number, width: number, height: number, ref_width: number, ref_height: number, duration: number, n: number}  # A table containing the follow fields:
---
function Anima:__constructor__(args)
    self.args = args

    self:set_img(args.img)

    self.__amount_frames = (args.frames_list and #args.frames_list) or (args.frames) or 1

    self.time_frame = 0
    self.time_update = 0
    self.time_paused = 0
    self.cycle_count = 0
    self.is_visible = true
    self.__is_enabled = true
    self.initial_direction = nil

    self:set_reverse_mode(args.is_reversed)

    self:set_color(args.color or { 1, 1, 1, 1 })

    self.rotation = args.rotation or 0
    self.speed = args.speed or 0.3
    self.__stop_at_the_end = args.stop_at_the_end or false
    self.max_cycle = args.amount_cycle or nil
    if args.duration then self:set_duration(args.duration) end

    self.current_frame = (self.direction < 0 and self.__amount_frames) or 1

    self:set_state(args.state)

    self.__N__ = args.n or 0

    self.flip_x = 1
    self.flip_y = 1

    self.scale_x = 1
    self.scale_y = 1
    self:set_scale(args.scale and args.scale.x, args.scale and args.scale.y)

    self.frames_list = {}

    if not args.frames_list then
        args.frames_list = {}
        local w = self.img:getWidth() / self.__amount_frames
        for i = 1, self.__amount_frames do
            table.insert(args.frames_list, {
                (i - 1) * w,
                (i - 1) * w + w,
                0,
                args.bottom or self.img:getHeight()
            })
        end
    end


    -- Generating the Frame objects and inserting them into the frames_list
    for i = 1, #args.frames_list do
        self.frames_list[i] = Frame:new(args.frames_list[i])
    end -- END FOR for generate frames objects


    if args.width or args.height then
        self:set_size(args.width, args.height, args.ref_width, args.ref_height)
    end

    self.quad = love.graphics.newQuad(0, 0,
        args.frames_list[1][1],
        args.frames_list[1][2],
        self.img:getDimensions()
    )
end

function Anima:copy()
    self.args.img = self.img
    local anim = Anima:new(self.args)
    anim:set_color(self:get_color())
    anim:set_scale(self:get_scale())
    return anim
end

---@param n integer
---@param config {left:number, right:number, top:number, bottom:number, speed:number, ox:number, oy:number}
function Anima:config_frame(n, config)

    ---@type JM.Anima.Frame|nil
    local frame = self.frames_list[n]

    if not frame or not config then return end

    config.left = config.left or frame.x
    config.right = config.right or (frame.x + frame.w)
    config.top = config.top or frame.y
    config.bottom = config.bottom or frame.bottom
    config.speed = config.speed or frame.speed
    config.ox = config.ox or frame.ox
    config.oy = config.oy or frame.oy

    self.frames_list[n] = Frame:new(config)
    frame = nil
end

---@param name JM.Anima.EventNames
---@param action function
---@param args any
function Anima:on_event(name, action, args)
    local evt_type = Event[name]
    if not evt_type then return end

    self.events = self.events or {}

    self.events[evt_type] = {
        type = evt_type,
        action = action,
        args = args
    }
end

---@param name JM.Anima.EventNames
function Anima:remove_event(name)
    local evt_type = Event[name]
    if not self.events or not evt_type then return end
    self.events[evt_type] = nil
end

--- Sets the size in pixels to draw the frame.
---@param width number|nil
---@param height number|nil
---@param ref_width number|nil
---@param ref_height number|nil
function Anima:set_size(width, height, ref_width, ref_height)
    if width or height then
        local current_frame = self:get_current_frame()

        local dw, dh = desired_size(
            width, height,
            ref_width or current_frame.w,
            ref_height or current_frame.h,
            true
        )

        if dw then
            self:set_scale(dw, dh)
        end
    end
end

---@param value number
function Anima:set_speed(value)
    assert(value >= 0, "\nError: Value passed to 'set_speed' method is smaller than zero.")

    self.speed = value
end

---@param duration number
function Anima:set_duration(duration)
    assert(duration > 0, "\nError: Value passed to 'set_duration' method is smaller than zero.")

    self.speed = duration / self.__amount_frames
end

---@param value boolean
function Anima:set_reverse_mode(value)
    self.direction = value and -1 or 1
end

---@param value boolean
---@param stop_action function
function Anima:stop_at_the_end(value, stop_action)
    self.__stop_at_the_end = value and true or false

    if self.__stop_at_the_end and stop_action then
        self:on_event("pause", stop_action)
    end
end

---
--- Set the source image for animation.
--
---@overload fun(self: table, image: love.Image)
---@param file_name string # The file path for source image.
function Anima:set_img(file_name)
    if type(file_name) == "string" then
        self.img = love.graphics.newImage(file_name)
    else
        self.img = file_name
    end
    self.img:setFilter("linear", "nearest")
    return self.img
end

---
function Anima:set_flip_x(flip)
    self.flip_x = flip and -1 or 1
end

---
function Anima:set_flip_y(flip)
    self.flip_y = flip and -1 or 1
end

function Anima:toggle_flip_x()
    self.flip_x = self.flip_x * (-1)
end

function Anima:toggle_flip_y()
    self.flip_y = self.flip_y * (-1)
end

---@param x number|nil
---@param y number|nil
function Anima:set_scale(x, y)
    if not x and not y then return end

    self.scale_x = x or self.scale_x
    self.scale_y = y or self.scale_y
end

---@return number scale_x
---@return number scale_y
function Anima:get_scale()
    return self.scale_x, self.scale_y
end

--- Sets Animation rotation in radians.
---@param value number
function Anima:set_rotation(value)
    self.rotation = value
end

--- Gets Animation current rotation in radians.
---@return number
function Anima:get_rotation()
    return self.rotation
end

--- Gets the animation color field.
---@return table
function Anima:get_color()
    return self.color
end

---@param value JM.Color
function Anima:set_color(value)
    self.color = Affectable.set_color(self, value)
end

function Anima:set_color2(r, g, b, a)
    Affectable.set_color2(self, r, g, b, a)
end

function Anima:get_offset()
    local cf = self:get_current_frame()
    return cf:get_offset()
end

function Anima:set_kx(value)
    self.__kx = value
end

function Anima:set_ky(value)
    self.__ky = value
end

---
--- Different animation states.
---
---@alias JM.AnimaStates
---|"looping" # (default) when animation reaches the last frame, the current frame is set to beginning.
---|"random" # animation shows his frames in a aleatory order.
---|"back and forth" # when animation reaches the last frame, the direction of animation changes.
---|"repeat last n" # When animation reaches the last frame, it backs to the last N frames

--
--- Set state.
---@param state JM.AnimaStates Possible values are "repeating", "random" or "come and back". If none of these is informed, the state is setted as "repeating".
function Anima:set_state(state)
    if state then
        state = string.lower(state)
    end

    if state == "random" then
        self.current_state = ANIMA_STATES.random

    elseif state == "back and forth"
        or state == "back_and_forth" then

        self.current_state = ANIMA_STATES.back_and_forth
    elseif state == "repeat last n" then
        self.current_state = ANIMA_STATES.repeating_last_n_frames
    else
        self.current_state = ANIMA_STATES.looping
    end
end

function Anima:set_max_cycle(value)
    self.max_cycle = value
end

function Anima:set_visible(value)
    self.is_visible = value and true or false
end

---
--- Resets Animation's fields to his default values.
---
function Anima:reset()
    self.time_update = 0
    self.time_frame = 0
    self.time_paused = 0
    self.current_frame = (self.direction > 0 and 1) or self.__amount_frames
    self.cycle_count = 0
    self.initial_direction = nil
    self.__is_paused = nil
    self.is_visible = true
    self.__is_enabled = true
end

-- ---@param arg {x: number, y: number, rot: number, sx: number, sy: number, ox: number, oy: number, kx: number, ky: number}
-- function Anima:__set_effect_transform(arg)

--     Affectable.__set_effect_transform(self, arg)

-- end

-- function Anima:__get_effect_transform()
--     return Affectable.__get_effect_transform(self)
-- end

---
-- Execute the animation logic.
---@param self JM.Anima
---@param dt number # The delta time.
function Anima:update(dt)
    if not self.__is_enabled then return end

    self.time_update = (self.time_update + dt)

    if not self.initial_direction then
        self.initial_direction = self.direction
        dispatch_event(self, Event.frame_change)
    end

    -- updating the Effects
    if self.__effect_manager then self.__effect_manager:update(dt) end

    -- Executing the custom update action
    dispatch_event(self, Event.update)

    if self.__is_paused
    -- or (self.max_cycle and self.cycle_count >= self.max_cycle)
    then

        self.time_paused = (self.time_paused + dt) % 5000000
        return
    end

    local last_frame = self.current_frame
    local speed = self:get_current_frame().speed or self.speed

    self.time_frame = self.time_frame + dt

    if self.time_frame >= speed then

        self.time_frame = self.time_frame - speed

        -- dispatch_event(self, Event.frame_change)

        if is_in_random_state(self) then
            local last_frame = self.current_frame
            local number = love.math.random(0, self.__amount_frames - 1)

            self.current_frame = 1 + (number % self.__amount_frames)

            self.cycle_count = (self.cycle_count + 1) % 6000000

            if last_frame == self.current_frame then
                self.current_frame = 1 + (self.current_frame
                    % self.__amount_frames)
            end

            return
        end -- END if animation is in random state

        self.current_frame = self.current_frame + (1 * self.direction)

        if is_in_normal_direction(self) then

            if self.current_frame > self.__amount_frames then

                if is_in_looping_state(self) then
                    self.current_frame = 1
                    self.cycle_count = (self.cycle_count + 1) % 600000

                    -- if self.__stop_at_the_end then
                    --     self.current_frame = self.__amount_frames
                    --     self:pause()
                    -- end

                elseif is_in_repeating_last_n_state(self) then
                    self.current_frame = self.current_frame - self.__N__
                    self.cycle_count = (self.cycle_count + 1)

                else -- ELSE: animation is in "back and forth" state

                    self.current_frame = self.__amount_frames
                    self.time_frame = self.time_frame + speed
                    self.direction = -self.direction

                    if self.direction == self.initial_direction then
                        self.cycle_count = (self.cycle_count + 1) % 600000
                    end

                    -- if self.__stop_at_the_end
                    --     and self.direction == self.initial_direction
                    -- then

                    --     self:pause()
                    -- end
                end -- END ELSE animation in "back and forth" state

            end -- END ELSE if animation is repeating

        else -- ELSE direction is negative

            if self.current_frame < 1 then

                if is_in_looping_state(self) then
                    self.current_frame = self.__amount_frames
                    self.cycle_count = (self.cycle_count + 1) % 600000

                    -- if self.__stop_at_the_end then
                    --     self.current_frame = 1
                    --     self:pause()
                    -- end

                elseif is_in_repeating_last_n_state(self) then
                    self.current_frame = self.__N__
                    self.cycle_count = (self.cycle_count + 1)

                else -- ELSE animation is not repeating
                    self.current_frame = 1
                    self.time_frame = self.time_frame + speed
                    self.direction = self.direction * (-1)

                    if self.direction == self.initial_direction then
                        self.cycle_count = (self.cycle_count + 1) % 600000
                    end

                    -- if self.__stop_at_the_end
                    --     and self.direction == self.initial_direction then

                    --     self:pause()
                    -- end

                end -- END ELSE animation is not repeating
            end
        end -- END if in normal direction (positive direction)

    end -- END IF time update bigger than speed

    if last_frame ~= self.current_frame then
        dispatch_event(self, Event.frame_change)
    end

    if (self.max_cycle and self.cycle_count >= self.max_cycle) then
        self:pause()
    end

    if self.__stop_at_the_end and self.cycle_count >= 1
        and not is_in_repeating_last_n_state(self)
    then
        self.cycle_count = 0
        self.current_frame = last_frame
        self:pause()
    end

end -- END update function

---
--- Draw the animation. Apply effects if exists.
---
---@param x number # The top-left position to draw (x-axis).
---@param y number # The top-left position to draw (y-axis).
function Anima:draw(x, y)
    self.x, self.y = x, y

    Affectable.draw(self, self.__draw_with_no_effects__)
end

---@return JM.Anima.Frame
function Anima:get_current_frame()
    return self.frames_list[self.current_frame]
end

---
--- Draw the animation using a rectangle.
---@param x number # Rectangle top-left position (x-axis).
---@param y number # Rectangle top-left position (y-axis).
---@param w number # Rectangle width in pixels.
---@param h number # Rectangle height in pixels.
function Anima:draw_rec(x, y, w, h)
    local current_frame, effect_transform
    current_frame = self:get_current_frame()

    effect_transform = self:__get_effect_transform()

    x = x + w / 2.0
    y = y + h
        - current_frame.h * self.scale_y * (effect_transform and effect_transform.sy or 1)
        + current_frame.oy * self.scale_y * (effect_transform and effect_transform.sy or 1)

    if self:is_flipped_in_y() then
        y = y - h + (current_frame.h * self.scale_y * (effect_transform and effect_transform.sy or 1))
    end

    self:draw(x, y)
end

---
--- Draws the animation without apply any effect.
--
function Anima:__draw_with_no_effects__()

    local current_frame
    current_frame = self:get_current_frame()

    current_frame:setViewport(self.img, self.quad)

    love_graphics_set_color(self.color)

    if self.is_visible then
        love_graphics_draw(self.img, self.quad,
            self.x, self.y,
            self.rotation, self.scale_x * self.flip_x,
            self.scale_y * self.flip_y,
            current_frame.ox, current_frame.oy,
            self.__kx,
            self.__ky
        )
    end
    current_frame = nil
end

---Tells if animation is flipped in y-axis.
---@return boolean
function Anima:is_flipped_in_y()
    return self.flip_y < 0
end

---Tells if animation is flipped in x-axis.
---@return boolean
function Anima:is_flipped_in_x()
    return self.flip_x < 0
end

function Anima:toggle_direction()
    self.direction = self.direction * -1
end

function Anima:pause()
    if not self.__is_paused then
        self.__is_paused = true
        dispatch_event(self, Event.pause)
        return true
    end
    return false
end

---@param restart boolean|nil
---@return boolean
function Anima:unpause(restart)
    if self.__is_paused then
        self.__is_paused = false
        local r = restart and self:reset()
        return true
    end
    return false
end

function Anima:is_paused()
    return self.__is_paused
end

function Anima:stop()
    if self.__is_enabled then
        self.__is_enabled = false
        return true
    end
    return false
end

function Anima:resume()
    if not self.__is_enabled then
        self.__is_enabled = true
        return true
    end
    return false
end

function Anima:is_enabled()
    return self.__is_enabled
end

--- Amount of time that animation is running (in seconds).
---@return number
function Anima:time_updating()
    return self.time_update
end

function Anima:reset_time_updating()
    self.time_update = 0
end

---@param current JM.Anima
---@param new_anima JM.Anima
function Anima.change_animation(current, new_anima)
    if new_anima == current then
        return current
    end
    new_anima:reset()
    new_anima:set_flip_x(current:is_flipped_in_x())
    current:transfer_effects(new_anima)
    return new_anima
end

return Anima
