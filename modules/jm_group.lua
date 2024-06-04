local tab_sort = table.sort
local tab_insert, tab_remove = table.insert, table.remove

local sort_update = function(a, b) return a.update_order > b.update_order end
local sort_draw = function(a, b) return a.draw_order < b.draw_order end

local sort_draw_by_y = function(a, b)
    return a.y < b.y
end

local GameObject = _G.JM.GameObject
local PS = _G.JM.ParticleSystem
--============================================================================

---@class JM.Group
local Group = {}
Group.__index = Group

---@param gamestate JM.Scene
---@param world JM.Physics.World?
---@return JM.Group
function Group:new(gamestate, world)
    ---@class JM.Group
    local obj = {
        list = {},
        N = 0,
        gamestate = gamestate,
        world = world,
    }

    obj.draw = Group.draw
    obj.update = Group.update

    GameObject:init_state(gamestate, world, obj)
    PS:init_module(world, gamestate)

    setmetatable(obj, Group)
    return obj
end

function Group:clear()
    _G.JM_Utils.clear_table(self.list)
    self.N = 0
end

---@param obj GameObject|BodyObject
---@return any
function Group:add_object(obj)
    tab_insert(self.list, obj)
    self.N = self.N + 1
    return obj
end

---@return (GameObject|BodyObject)?
function Group:remove_object(index)
    local list = self.list

    ---@type GameObject | BodyObject
    local obj = list[index]

    if obj then
        do
            local bd = obj.body
            if bd then bd.__remove = true end
        end

        self.N = self.N - 1
        return tab_remove(list, index)
    end
end

function Group:update(dt)
    local list = self.list
    tab_sort(list, sort_update)

    local state, world, group = GameObject:get_gamestate_and_world()
    do
        local my_gamestate, my_world = self.gamestate, self.world
        GameObject:init_state(my_gamestate, my_world, self)
        PS:init_module(my_world, my_gamestate)
    end

    for i = self.N, 1, -1 do
        ---@type GameObject
        local gc = list[i]

        if gc.__remove then
            self:remove_object(i)
            GameObject.__push_object(gc)
            ---
        else
            do
                local update = gc.update
                if update and gc.is_enable then
                    update(gc, dt)
                end
            end

            if gc.__remove then
                gc.update_order = -100000
            end
            --
        end
        ---
    end

    GameObject:init_state(state, world, group)
    PS:init_module(world, state)
    ---
end

---@param camera JM.Camera.Camera?
---@param sort_by_y boolean?
---@param custom_sort function?
function Group:draw(camera, sort_by_y, custom_sort)
    local list = self.list
    tab_sort(list, custom_sort or (sort_by_y and sort_draw_by_y or sort_draw))

    for i = 1, self.N do
        ---@type GameObject
        local gc = list[i]

        do
            local draw = gc.draw
            if draw and not gc.__remove then
                draw(gc, camera)
            end
        end
        ---
    end

    ---
end

return Group
