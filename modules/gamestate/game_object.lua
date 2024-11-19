local Affectable = _G.JM_Affectable

local tab_insert, tab_remove = table.insert, table.remove
local tab_clear = _G.JM_Utils.clear_table

---@type table<integer, GameObject>
local ObjectRecycler = {}

---@class GameObject: JM.Template.Affectable
---@field __effect_manager JM.EffectManager
local GC = setmetatable({}, Affectable)
GC.__index = GC
---@private
GC.ObjectRecycler = ObjectRecycler

---@param gamestate JM.Scene|any
---@param world JM.Physics.World?
---@param group JM.Group?
function GC:init_state(gamestate, world, group)
    GC.gamestate = gamestate
    GC.world = world
    GC.group = group
end

function GC.__push_object(obj)
    tab_clear(obj)
    tab_insert(ObjectRecycler, obj)
end

---@return GameObject?
function GC.__pop_object()
    return tab_remove(ObjectRecycler)
end

function GC:flush()
    tab_clear(ObjectRecycler)
end

function GC:get_gamestate_and_world()
    return GC.gamestate, GC.world, GC.group
end

---@param x number|nil
---@return table|GameObject|any
function GC:new(x, y, w, h, draw_order, update_order, reuse_tab)
    reuse_tab = reuse_tab
        or GC.__pop_object()
    -- or GC.gamestate.pop_object()

    -- if reuse_tab then
    --     for i, _ in pairs(reuse_tab) do
    --         reuse_tab[i] = nil
    --     end
    -- end

    local obj = setmetatable(Affectable:new(nil, reuse_tab), GC)
    GC.__constructor__(obj, x, y, w, h, draw_order, update_order)
    return obj
end

function GC:__constructor__(x, y, w, h, draw_order, update_order)
    self.x = x or 0
    self.y = y or 0
    self.w = w or 16
    self.h = h or 16

    self.ox = self.w * 0.5
    self.oy = self.h * 0.5

    self.is_visible = true
    self.is_enable = true

    self.__remove = false

    self.eff_actives = nil
    self.props = nil
    self.group = nil

    self.draw_order = draw_order or 0
    self.update_order = update_order or 0

    self.draw_order = self.draw_order + math.random()
    self.update_order = self.update_order + math.random()
end

function GC:get_props()
    return self.props
end

--- Check object class type
---@deprecated
---@param class table
---@return boolean
function GC:type_of(class)
    local meta = getmetatable(self)
    while meta do
        if meta == class then
            return true
        end
        meta = getmetatable(meta)
    end
    return false
end

--- Check object class type
---@param class table
---@return boolean
function GC:is_an(class)
    local meta = getmetatable(self)
    while meta do
        if meta == class then
            return true
        end
        meta = getmetatable(meta)
    end
    return false
end

function GC:add_object(obj)
    ---@type JM.Group
    local group = self.group
    -- if group then
    return group:add_object(obj)
    -- end
end

function GC:set_custom_draw(draw)
    self.__specific_draw__ = draw or self.__specific_draw__
end

function GC:set_draw_order(value)
    value = math.floor(value)
    self.draw_order = value + math.random()
end

function GC:set_update_order(value)
    value = math.floor(value)
    self.update_order = value + math.random()
end

function GC:load()

end

function GC:init()

end

function GC:finish()

end

function GC:rect()
    return self.x, self.y, self.w, self.h
end

function GC:remove()
    self.__remove = true
    self.__effect_manager.push_object(self.__effect_manager)
    self.__effect_manager = nil
end

---@param eff_type JM.Effect.id_string
---@param eff_args any
---@return JM.Effect|any
function GC:apply_effect(eff_type, eff_args, force)
    if not self.eff_actives then self.eff_actives = {} end

    local cur_eff = self.eff_actives[eff_type]

    if not force
        and cur_eff
        and not cur_eff.__remove
    then
        return nil
    end

    if cur_eff then
        cur_eff.__remove = true
    end

    self.eff_actives[eff_type] = Affectable.apply_effect(self, eff_type, eff_args)
    return self.eff_actives[eff_type]
end

function GC:remove_effect(eff_type)
    local actives = self.eff_actives
    if not actives then return false end

    ---@type JM.Effect
    local eff = actives[eff_type]
    if eff then
        eff:restaure_object()
        eff.__remove = true
    end
end

function GC:update(dt)
    -- Affectable.update(self, dt)
    self.__effect_manager:update(dt)
end

---@overload fun(self, cam:JM.Camera.Camera?)
---@param custom_draw function
---@param cam JM.Camera.Camera?
function GC:draw(custom_draw, cam)
    if type(custom_draw) == "table" then
        cam = custom_draw
        custom_draw = self.__specific_draw__
    end
    custom_draw = custom_draw or self.__specific_draw__
    if custom_draw then
        return Affectable.draw(self, custom_draw, cam)
    end
end

return GC
