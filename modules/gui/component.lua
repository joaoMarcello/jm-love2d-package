local love = _G.love

---@type JM.Utils
local Utils = _G.JM_Utils

---@type JM.Template.Affectable
local Affectable = _G.JM_Affectable

---@enum JM.GUI.TypeComponent
local TYPES_ = {
    generic = 0,
    button = 1,
    icon = 2,
    imageIcon = 3,
    animatedIcon = 4,
    verticalList = 5,
    horizontalList = 6,
    messageBox = 7,
    window = 8,
    textBox = 9,
    dynamicLabel = 10,
    dialogueBox = 11,
    popupMenu = 12,
    checkBox = 13,
    container = 14
}

---@enum JM.GUI.EventOptions
local EVENTS = {
    update = 1,
    draw = 2,
    key_pressed = 3,
    key_released = 4,
    mouse_pressed = 5,
    mouse_released = 6,
    gained_focus = 7,
    lose_focus = 8,
    remove = 9
}

---@enum JM.GUI.Modes
local MODES = {
    keyboard = 1,
    mouse = 2,
    touch = 3,
    mouse_touch = 4,
    overall = 5
}

---@alias JM.GUI.EventNames "update"|"draw"|"key_pressed"|"key_released"|"mouse_pressed"|"mouse_released"|"gained_focus"|"lose_focus"|"remove"

---@alias JM.GUI.Event {action:function, args:any}

local function collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 + w1 > x2
        and x1 < x2 + w2
        and y1 + h1 > y2
        and y1 < y2 + h2
end

---@param gc JM.GUI.Component
---@param type_ JM.GUI.EventOptions
local function dispatch_event(gc, type_)
    ---@type JM.GUI.Event|nil
    local evt = gc.events[type_]
    local r = evt and evt.action(evt.args)
    evt = nil
end

local generic_func = function(self, args) end

---@class JM.GUI.Component: JM.Template.Affectable
local Component = {
    __custom_draw__ = generic_func,
    __pos_draw__ = generic_func,
    __custom_update__ = generic_func
}
setmetatable(Component, Affectable)
Component.__index = Component

---@param args {x:number, y:number, w:number, h:number}|nil
---@return table
function Component:new(args)
    args = args or {}

    local obj = Affectable:new()
    setmetatable(obj, self)

    Component.__constructor__(obj, args)

    return obj
end

function Component:__constructor__(args)
    self.x = args.x or self.x
    self.y = args.y or self.y
    self.w = args.w or self.w
    self.h = args.h or self.h

    self.ox = self.w / 2
    self.oy = self.h / 2

    self.is_visible = true
    self.is_enable = true
    self.on_focus = false
    self.type_obj = TYPES_.generic
    self.TYPE = TYPES_
    self.Utils = Utils
    self.mode = MODES.mouse
    self.MODE = MODES

    self:refresh_corners()
    self.events = {}
    self:init()
end

---@param type_ JM.GUI.EventOptions
function Component:dispatch_event(type_)
    return dispatch_event(self, type_)
end

function Component:init()
    self.is_enable = true
    self.is_visible = true
    self.on_focus = false
    self.remove_ = false

    self.__mouse_pressed = false
end

---@param name JM.GUI.EventNames
---@param action function
---@param args any
-- ---@return JM.GUI.Event|nil
function Component:on_event(name, action, args)
    local evt_type = EVENTS[name]
    if not evt_type then return end

    self.events[evt_type] = {
        action = action,
        args = args
    }

    --return self.events[evt_type]
end

function Component:rect()
    return self.x, self.y, self.w, self.h
end

function Component:check_collision(x, y, w, h)
    return collision(x, y, w, h, self:rect())
end

function Component:key_pressed(key, scancode, isrepeat)
    if not self.on_focus then return end

    ---@type JM.GUI.Event
    local evt = self.events[EVENTS.key_pressed]
    local r = evt and evt.action(key, scancode, isrepeat, evt.args)
end

function Component:key_released(key, scancode)
    if not self.on_focus then return end

    ---@type JM.GUI.Event
    local evt = self.events[EVENTS.key_released]
    local r = evt and evt.action(key, scancode, evt.args)
end

function Component:mouse_pressed(x, y, button, istouch, presses)

    if not self.on_focus then return end

    local check = self:check_collision(x, y, 0, 0)
    if not check then return end

    ---@type JM.GUI.Event|nil
    local evt = self.events[EVENTS.mouse_pressed]
    local r = evt and evt.action(x, y, button, istouch, presses, evt.args)

    self.__mouse_pressed = true
    evt = nil
end

function Component:mouse_released(x, y, button, istouch, presses)
    if not self.on_focus or not self.__mouse_pressed then return end
    self.__mouse_pressed = false

    ---@type JM.GUI.Event|nil
    local evt = self.events[EVENTS.mouse_released]
    local r = evt and evt.action(x, y, button, istouch, presses, evt.args)
    evt = nil
end

---@param self JM.GUI.Component
local function mode_mouse_update(self, dt)
    local x, y
    if self.__holder then
        x, y = self.__holder.Game:get_mouse_position()
    else
        x, y = love.mouse.getPosition()
    end

    if self:check_collision(x, y, 0, 0) then
        if not self.on_focus then
            self:set_focus(true)
        end
    else
        if self.on_focus then
            self:set_focus(false)
            self.__mouse_pressed = false
        end
    end
end

function Component:update(dt)
    dispatch_event(self, EVENTS.update)

    self.__effect_manager:update(dt)

    self:__custom_update__(dt)

    -- if self.mode == MODES.mouse then
    --     mode_mouse_update(self, dt)
    -- end

    return
end

function Component:draw()

    Affectable.draw(self, self.__custom_draw__)

    self:__pos_draw__()
end

do
    function Component:set_position(x, y)
        self.x = Utils:round(x or self.x)
        self.y = Utils:round(y or self.y)
        self:refresh_corners()
    end

    function Component:refresh_corners()
        self.top = self.y
        self.bottom = self.y + self.h
        self.left = self.x
        self.right = self.x + self.w
    end

    function Component:set_dimensions(w, h)
        self.w = w or self.w
        self.h = h or self.h

        self.ox = self.w / 2
        self.oy = self.h / 2

        self:refresh_corners()
    end

    function Component:set_visible(value)
        self.is_visible = value and true or false
    end

    function Component:set_enable(value)
        self.is_enable = value and true or false
    end

    function Component:remove()
        dispatch_event(self, EVENTS.remove)
        self.remove_ = true
    end

    function Component:set_focus(value)
        self.on_focus = value and true or false
        if self.on_focus then
            dispatch_event(self, EVENTS.gained_focus)
        else
            dispatch_event(self, EVENTS.lose_focus)
        end
    end

    --- Sets the container that holds this component.
    ---@param holder JM.GUI.Container
    function Component:set_holder(holder)
        self.__holder = holder
    end

    function Component:get_holder()
        return self.__holder
    end
end

return Component
