local Phys = _G.JM_Package.Physics
local Affectable = _G.JM_Affectable

---@type GameObject
local GC = require((...):gsub("body_object", "game_object"))

---@class BodyObject: GameObject
local Component = setmetatable({}, GC) --JM_Utils:create_class(Affectable, GC)
Component.__index = Component

---@return table
function Component:new(
    x, y, w, h, draw_order, update_order,
    bd_type, reuse_tab
)
    ---@type BodyObject|table
    local obj = GC:new(x, y, w, h, draw_order, update_order, reuse_tab)

    setmetatable(obj, self)
    -- Affectable.__constructor__(obj)
    Component.__constructor__(obj, bd_type)
    return obj
end

function Component:__constructor__(bd_type)
    self.body = Phys:newBody(self.world, self.x, self.y, self.w, self.h, bd_type or "static")

    self.body:set_holder(self)
end

function Component:init()
    self.is_enable = true
    self.__remove = false
end

function Component:remove()
    self.__remove = true
    self.body.__remove = true
    self.body = nil
    self.__effect_manager.push_object(self.__effect_manager)
    self.__effect_manager = nil
end

-- ---@param eff_type JM.Effect.id_string
-- ---@param eff_args any
-- ---@return JM.Effect|any
-- function Component:apply_effect(eff_type, eff_args, force)
--     if not self.eff_actives then self.eff_actives = {} end

--     local cur_eff = self.eff_actives[eff_type]

--     if not force
--         and cur_eff
--         and not cur_eff.__remove
--     then
--         return nil
--     end

--     if cur_eff then
--         cur_eff.__remove = true
--     end

--     self.eff_actives[eff_type] = Affectable.apply_effect(self, eff_type, eff_args)
--     return self.eff_actives[eff_type]
-- end

function Component:get_cx()
    return self.body.x + self.body.w * 0.5
end

function Component:get_cy()
    return self.body.y + self.body.h * 0.5
end

function Component:update(dt)
    -- Affectable.update(self, dt)
    self.__effect_manager:update(dt)
    self.x, self.y = self.body.x, self.body.y
end

function Component:draw(custom_draw)
    if custom_draw then
        Affectable.draw(self, custom_draw)
    end
    return false
end

return Component
