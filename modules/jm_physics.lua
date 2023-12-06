local abs, mfloor, mceil, sqrt, min, max, pow = math.abs, math.floor, math.ceil, math.sqrt, math.min, math.max, math.pow

local table_insert, table_remove, table_sort = table.insert, table.remove, table.sort

local pairs, setmetatable = pairs, setmetatable
local next = next

local metatable_mode_v = { __mode = 'v' }
local metatable_mode_k = { __mode = 'k' }

local reuse_tab = setmetatable({}, metatable_mode_k)
local function empty_table()
    for index, _ in next, reuse_tab do
        reuse_tab[index] = nil
    end
    return reuse_tab
end

local reuse_tab2 = setmetatable({}, metatable_mode_v)
local function empty_table_for_coll()
    -- for index, _ in pairs(reuse_tab2) do
    --     reuse_tab2[index] = nil
    -- end
    local N = #reuse_tab2
    for i = N, 1, -1 do
        reuse_tab2[i] = nil
    end
    return reuse_tab2
end

local BodyRecycler = setmetatable({}, metatable_mode_k)

local function push_body(b)
    BodyRecycler[b] = true
end

local function pop_body()
    for bd, _ in next, BodyRecycler do
        BodyRecycler[bd] = nil
        return bd
    end
end

---@enum JM.Physics.BodyTypes
local BodyTypes = {
    dynamic = 1,
    static = 2,
    kinematic = 3,
    ghost = 4,
    only_fall = 5,
}

---@enum JM.Physics.BodyShapes
local BodyShapes = {
    rectangle = 1,
    ground_slope = 2,
    inverted_ground_slope = 3,
    ceil_slope = 4,
    inverted_ceil_slope = 5,
    circle = 8,
    slope = 9
}

---@enum JM.Physics.BodyEventOptions
local BodyEvents = {
    ground_touch = 0,
    ceil_touch = 1,
    wall_left_touch = 2,
    wall_right_touch = 3,
    axis_x_collision = 4,
    axis_y_collision = 5,
    start_falling = 6,
    speed_y_change_direction = 7,
    speed_x_change_direction = 8,
    leaving_ground = 9,
    leaving_ceil = 10,
    leaving_y_axis_body = 11,
    leaving_wall_left = 12,
    leaving_wall_right = 13,
    leaving_x_axis_body = 14,
    on_stucked = 15,
}
---@alias JM.Physics.EventNames "ground_touch"|"ceil_touch"|"wall_left_touch"|"wall_right_touch"|"axis_x_collision"|"axis_y_collision"|"start_falling"|"speed_y_change_direction"|"speed_x_change_direction"|"leaving_ground"|"leaving_ceil"|"leaving_y_axis_body"|"leaving_wall_left"|"leaving_wall_right"|"leaving_x_axis_body"|"on_stucked"

---@alias JM.Physics.Collide JM.Physics.Body|JM.Physics.Slope|any

---@alias JM.Physics.Cell {count:number, x:number, y:number, items:table}

---@alias JM.Physics.Collisions {items: table,n:number, top:number, left:number, right:number, bottom:number, most_left:JM.Physics.Collide, most_right:JM.Physics.Collide, most_up:JM.Physics.Collide, most_bottom:JM.Physics.Collide, diff_x:number, diff_y:number, end_x: number, end_y: number, has_slope:JM.Physics.Collide, goal_x:number, goal_y:number}

local function collision_rect(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 + w1 > x2
        and x1 < x2 + w2
        and y1 + h1 > y2
        and y1 < y2 + h2
end

local function round(value)
    local absolute = abs(value)
    local decimal = absolute - mfloor(absolute)

    if decimal >= 0.5 then
        return value > 0 and mceil(value) or mfloor(value)
    else
        return value > 0 and mfloor(value) or mceil(value)
    end
end

---@param obj JM.Physics.Body
local function is_static(obj)
    return obj.type == BodyTypes.static
end

---@param obj JM.Physics.Body
local function is_dynamic(obj)
    return obj.type == BodyTypes.dynamic
end

---@param obj JM.Physics.Body
local function is_kinematic(obj)
    return obj.type == BodyTypes.kinematic
end

---@param obj JM.Physics.Slope|any
local function is_slope(obj)
    return obj.is_slope
end

---@param item JM.Physics.Body
local function dynamic_filter(obj, item)
    return item.type == BodyTypes.dynamic
end

---@param obj JM.Physics.Body
---@param item JM.Physics.Body|JM.Physics.Slope
local function coll_y_filter(obj, item)
    if item.type == BodyTypes.only_fall and not item.is_slope then
        return (obj.y + obj.h) <= item.y
    else
        if item.is_slope then
            if not item.is_floor then
                local py = item:get_y(obj.x, obj.y, obj.w, obj.h)
                if obj.y + 2 < py then return false end

                return obj.y >= item.y
                    and obj:right() >= item.x - 2 and obj.x <= item:right() - 2
                    and obj.speed_y <= 0
            else
                if not obj.allow_climb_slope then return false end

                local py = item:get_y(obj.x, obj.y, obj.w, obj.h)

                -- if item.type == BodyTypes.only_fall then
                --     if obj.y + obj.h - 2 > py then
                --         -- return false
                --     end
                -- end

                local off = item.world.tile / 4

                return (obj.speed_y >= 0
                    and obj.y - off <= py - obj.h)
                -- or (not item.is_floor and obj.speed_y <= 0)
            end
        end
        ---
        return item.type ~= BodyTypes.dynamic
    end
end

---@param obj JM.Physics.Body
---@param item JM.Physics.Body|JM.Physics.Slope
local function collision_x_filter(obj, item)
    if item.is_slope then
        if not item.is_floor then
            local py = item:get_y(obj.x, obj.y, obj.w, obj.h)
            if obj.y + 2 < py then return false end

            -- return obj:right() >= item.x and obj.x <= item:right()
            return true
        else
            if not obj.allow_climb_slope then return false end

            local py = item:get_y(obj.x, obj.y, obj.w, obj.h)

            -- local cond = item.is_norm and obj.speed_x > 0
            -- cond = not cond and (not item.is_norm and obj.speed_x < 0) or cond

            return obj.y - 2 <= py - obj.h --and cond
        end
    end
    return item.type ~= BodyTypes.dynamic and item.type ~= BodyTypes.only_fall
end

local default_filter = function(body, item)
    return true
end

---@param item JM.Physics.Collide
local collision_filter = function(obj, item)
    local tp = item.type
    return tp == BodyTypes.static or tp == BodyTypes.kinematic
end

---@param self JM.Physics.Body
local function kinematic_moves_dynamic_x(self, goalx, skip_move)
    goalx = goalx or (self.x + ((self.speed_x * love.timer.getDelta())
        + (self.acc_x * (love.timer.getDelta() ^ 2)) * 0.5))

    local list = self.world:get_items_in_cell_obj(self.x - 2, self.y - 1, self.w + 4, self.h + 2,
        self.empty_table())

    local diff = (goalx - self.x)

    if list then
        for item, _ in next, list do
            ---@type JM.Physics.Collide
            item = item

            if item ~= self and not item.__remove
                and (item.type == BodyTypes.dynamic
                    or item.type == BodyTypes.kinematic)
                and not item.is_stucked
                and item.is_enabled
            then
                if collision_rect(goalx, self.y, self.w, self.h, item.x, item.y, item.w, item.h) then
                    local dist1 = abs(item:right() - self.x)
                    local dist2 = abs(item.x - self:right())

                    if dist2 < dist1 then
                        if diff > 0 or item.speed_x < 0 then
                            item:refresh(goalx + self.w + 0.1)
                        end
                    else
                        if diff < 0 or item.speed_x > 0 then
                            item:refresh(goalx - item.w - 0.1)
                        end
                    end

                    local col = item:check(nil, nil, collision_filter, empty_table(), empty_table_for_coll())

                    if col.n > 0 then
                        local s = true
                        for i = 1, col.n do
                            ---@type JM.Physics.Collide
                            local bd = col.items[i]
                            if bd.is_slope then
                                s = false
                            elseif bd.is_slope_adj
                                and ((bd.ground and bd.ground.is_floor)
                                    or math.floor(item:bottom()) == bd.y)
                            then
                                s = false
                            elseif bd == self then
                                s = false
                            end
                        end
                        item:set_stucked(s)
                    end
                end

                if not skip_move and collision_rect(goalx, self.y - 1, self.w, self.h, item.x, item.y, item.w, item.h) then
                    -- item:refresh(nil, self.y - 0.1 - item.h)
                    local col = item:check(item.x + diff, nil, collision_x_filter, empty_table(), empty_table_for_coll())

                    if col.n > 0 then
                        item:resolve_collisions_x(col)
                    else
                        item:refresh(item.x + diff)
                    end
                end
            end
        end
    end
end

---@param kbody JM.Physics.Body
local function kinematic_moves_dynamic_y(kbody, goaly, off)
    local diff = (goaly - kbody.y)

    local list = kbody.world:get_items_in_cell_obj(kbody.x - 1, kbody.y - 2, kbody.w + 2, kbody.h + 4,
        kbody.empty_table())

    if list then
        for item, _ in next, list do
            ---@type JM.Physics.Collide
            item = item

            if item ~= kbody and not item.__remove
                and (item.type == BodyTypes.dynamic
                    or item.type == BodyTypes.kinematic)
                and not item.is_stucked
                and item.is_enabled
                and collision_rect(kbody.x, kbody.y - 1, kbody.w, kbody.h + 2, item.x, item.y - 1, item.w, item.h + 2)
            then
                local dist1 = abs(kbody.y - (item.y + item.h))
                local dist2 = abs((kbody.y + kbody.h) - item.y)

                if dist1 < dist2 then
                    item:refresh(nil, goaly - item.h - 0.1)
                    -- item.speed_y = 100
                else
                    if diff > 0 then
                        item:refresh(nil, goaly + kbody.h + 0.1)
                    end
                end
            end
        end
    end
end

---@param body JM.Physics.Body
---@param type_ JM.Physics.BodyEventOptions
local function dispatch_event(body, type_)
    ---@type JM.Physics.Event
    local evt = body.events[type_]
    local r = evt and evt.action(evt.args)
end

--=============================================================================

---@class JM.Physics.Body
local Body = {
    Types = BodyTypes,
    filter_col_y = coll_y_filter,
    filter_col_x = coll_y_filter,
    filter_default = default_filter,
    empty_table = empty_table,
    empty_table_for_coll = empty_table_for_coll,
    kinematic_moves_dynamic_y = kinematic_moves_dynamic_y,
    kinematic_moves_dynamic_x = kinematic_moves_dynamic_x,
    default_coef_resis_y = 0.08,
    default_coef_resis_x = 0.5,
}
Body.__index = Body
Body.BodyRecycler = BodyRecycler

do
    ---@return JM.Physics.Body
    function Body:new(x, y, w, h, type_, world, id)
        --
        ---@type JM.Physics.Body
        local body_reuse_table = pop_body()
        if body_reuse_table then
            local t = body_reuse_table.events
            if t then
                for key, _ in next, t do
                    t[key] = nil
                end
            end
            ---@type JM.Physics.Collisions
            t = body_reuse_table.colls
            if t then
                t.items = nil
                t.n = 0
            end
        end

        local obj = body_reuse_table or {}
        setmetatable(obj, self)

        Body.__constructor__(obj, x, y, w, h, type_, world, id)
        return obj
    end

    ---@param world JM.Physics.World
    ---@param type_ JM.Physics.BodyTypes
    function Body:__constructor__(x, y, w, h, type_, world, id)
        self.type = type_
        ---@type string
        self.id = id --or ""
        self.world = world

        self.x = x
        self.y = y
        self.w = w
        self.h = h

        self.mass = world.default_mass

        self.speed_x = 0.0
        self.speed_y = 0.0

        self.max_speed_x = nil
        self.max_speed_y = nil

        self.is_enabled = true

        self.acc_x = 0.0
        self.acc_y = 0.0
        self.acc_y = (self.type ~= BodyTypes.dynamic and 0) or self.acc_y

        self.dacc_x = self.world.meter * 3.5
        self.dacc_y = nil
        -- self.over_speed_dacc_x = self.dacc_x
        -- self.over_speed_dacc_y = self.dacc_x

        self.force_x = 0.0
        self.force_y = 0.0

        -- used if body is static or kinematic
        -- self.resistance_x = 1

        ---@type JM.Physics.Body|JM.Physics.Slope
        self.ground = nil -- used if body is not static

        self.ceil = nil
        self.wall_left = nil
        self.wall_right = nil

        self.holder = nil

        -- some properties
        self.bouncing_y = nil -- need to be a number between 0 and 1
        self.bouncing_x = nil
        self.__remove = false
        self.is_stucked = false

        self.allowed_air_dacc = false
        self.allowed_gravity = true
        self.allowed_speed_y_restriction = true
        self.allow_climb_slope = true
        self.stick_to_slope = false

        ---@type JM.Physics.Collide
        self.on_water = nil
        self.density = nil
        self.coef_resis_y = nil
        self.coef_resis_x = nil
        self.area_y = nil
        self.area_x = nil
        self.coef_static = nil
        self.coef_cinetic = nil

        self.is_slope_adj = nil
        self.__is_ice = nil

        self.events = self.events or {}
        self.colls = self.colls or {}
    end

    function Body:turn_into_ice()
        self.coef_static = 0.4
        self.coef_cinetic = 0.08
        self.__is_ice = true
    end

    function Body:set_stucked(value)
        if value and not self.is_stucked then
            self.is_stucked = true
            dispatch_event(self, BodyEvents.on_stucked)
        elseif not value and self.is_stucked then
            self.is_stucked = false
        end
    end

    ---@param holder table|nil
    function Body:set_holder(holder)
        self.holder = holder
    end

    ---@return table|nil
    function Body:get_holder()
        return self.holder
    end

    ---@alias JM.Physics.Event {type:JM.Physics.BodyEventOptions, action:function, args:any}



    ---@param name JM.Physics.EventNames
    ---@param action function
    ---@param args any
    function Body:on_event(name, action, args)
        local evt_type = BodyEvents[name]
        if not evt_type then return end

        self.events = self.events or {}

        self.events[evt_type] = {
            type = evt_type,
            action = action,
            args = args
        }
    end

    ---@param name JM.Physics.EventNames
    function Body:remove_event(name)
        local evt_type = BodyEvents[name]
        if not self.events or not evt_type then return end
        self.events[evt_type] = nil
    end

    -- function Body:remove_extra_filter()
    --     self:extra_collisor_filter(default_filter)
    -- end

    function Body:check_collision(x, y, w, h)
        return collision_rect(self.x, self.y, self.w, self.h,
            x, y, w, h)
    end

    function Body:set_mass(mass)
        self.mass = mass
    end

    function Body:set_position(x, y, resolve_collisions)
        self:refresh(x, y)
    end

    function Body:set_y_pos(y)
        self:set_position(nil, y)
    end

    function Body:set_x_pos(x)
        self:set_position(x)
    end

    function Body:set_dimensions(w, h)
        self:refresh(nil, nil, w, h)
    end

    function Body:rect()
        return self.x, self.y, self.w, self.h
    end

    function Body:direction_x()
        return (self.speed_x < 0.0 and -1) or (self.speed_x > 0.0 and 1) or 0
    end

    function Body:direction_y()
        return (self.speed_y < 0.0 and -1) or (self.speed_y > 0.0 and 1) or 0
    end

    function Body:set_speed(sx, sy)
        sx = sx or self.speed_x
        sy = sy or self.speed_y
        self.speed_x = sx
        self.speed_y = sy
    end

    function Body:set_acc(ax, ay)
        ax = ax or self.acc_x
        ay = ay or self.acc_y
        self.acc_x = ax
        self.acc_y = ay
    end

    -- function Body:extra_collisor_filter(filter)
    --     self.extra_filter = filter
    -- end

    --- Makes the body jump in the air.
    ---@param desired_height number
    ---@param direction -1|1|nil
    function Body:jump(desired_height, direction)
        direction = direction or -1
        self:refresh(nil, self.y + direction)

        local acc = abs(self.world.gravity) - (self:buoyant() / self.mass)
        -- local acc = abs(self.acc_y)
        acc = acc < 0 and 0 or acc
        self.speed_y = sqrt(2.0 * acc * desired_height) * direction
    end

    function Body:dash(desired_distance, direction)
        direction = direction or self:direction_x()

        self.speed_x = sqrt(2 * abs(self.acc_x) * desired_distance)
            * direction
    end

    function Body:weight()
        -- return self.world.gravity * (self.mass / self.world.default_mass)
        return self.world.gravity * self.mass
    end

    function Body:refresh(x, y, w, h)
        x = x or self.x
        y = y or self.y
        w = w or self.w
        h = h or self.h

        if x ~= self.x or y ~= self.y or w ~= self.w or h ~= self.h then
            local world = self.world

            local cl1, ct1, cw1, ch1 = world:rect_to_cell(self.x, self.y, self.w, self.h)
            local cl2, ct2, cw2, ch2 = world:rect_to_cell(x, y, w, h)

            if cl1 ~= cl2 or ct1 ~= ct2 or cw1 ~= cw2 or ch1 ~= ch2 then
                local cr1, cb1 = (cl1 + cw1 - 1), (ct1 + ch1 - 1)
                local cr2, cb2 = (cl2 + cw2 - 1), (ct2 + ch2 - 1)
                local cy_out

                for cy = ct1, cb1 do
                    cy_out = cy < ct2 or cy > cb2

                    for cx = cl1, cr1 do
                        if cy_out or cx < cl2 or cx > cr2 then
                            world:remove_obj_from_cell(self, cx, cy)
                        end
                    end
                end

                for cy = ct2, cb2 do
                    cy_out = cy < ct1 or cy > cb1

                    for cx = cl2, cr2 do
                        if cy_out or cx < cl1 or cx > cr1 then
                            world:add_obj_to_cell(self, cx, cy)
                        end
                    end
                end
            end -- End If

            self.x, self.y, self.w, self.h = x, y, w, h
        end
    end

    -- ---@param body JM.Physics.Body
    -- ---@param item JM.Physics.Body
    -- local function collider_condition(body, item, diff_x, diff_y)
    --     diff_x = diff_x or 0
    --     diff_y = diff_y or 0

    --     local cond_y = (diff_y ~= 0
    --         and (body:right() > item.x and body.x < item:right()))

    --     local cond_x = (diff_x ~= 0
    --         and (body:bottom() > item.y and body.y < item:bottom()))

    --     return (cond_x or cond_y) or (diff_x == 0 and diff_y == 0)
    -- end

    ---@return JM.Physics.Collisions collisions
    function Body:check(goal_x, goal_y, filter, empty_tab, tab_for_items)
        goal_x = goal_x or self.x
        goal_y = goal_y or self.y
        filter = filter or default_filter

        local diff_x = goal_x - self.x
        local diff_y = goal_y - self.y

        local left, top, right, bottom
        top = min(self.y, goal_y)
        bottom = max(self.y + self.h, goal_y + self.h)
        left = min(self.x, goal_x)
        right = max(self.x + self.w, goal_x + self.w)

        local x, y, w, h = left, top, right - left, bottom - top

        local items = self.world:get_items_in_cell_obj(x, y, w, h, empty_tab)

        if not items then
            self.colls.n = 0
            self.colls.has_slope = false
            return self.colls
        end

        ---@type JM.Physics.Collisions
        local collisions = self.colls --{}

        local col_items               --= {}
        local n_collisions, has_slope = 0, nil
        ---@type JM.Physics.Collide, JM.Physics.Collide
        local most_left, most_right
        ---@type JM.Physics.Collide, JM.Physics.Collide
        local most_up, most_bottom

        -- for item, _ in pairs(items) do
        for item, _ in next, items do
            ---@type JM.Physics.Body|JM.Physics.Slope
            local item = item

            if not self.is_enabled then break end

            -- local cond_y = (diff_y ~= 0
            --     and (self:right() > item.x and self.x < item:right()))

            -- local cond_x = (diff_x ~= 0
            --     and (bottom >= item.y and top <= item:bottom()))

            if item ~= self and not item.__remove and not item.is_stucked

                and item.is_enabled

                and item.type ~= BodyTypes.ghost

                -- and (cond_y or cond_x or (diff_x == 0 and diff_y == 0))

                and item:check_collision(x, y, w, h)

                and filter(self, item)

            -- and self.extra_filter(self, item)
            then
                col_items = col_items or tab_for_items or {}

                table_insert(col_items, item)

                if not has_slope then
                    has_slope = item.is_slope and item or nil
                end

                n_collisions = n_collisions + 1

                most_left = most_left or item
                most_left = ((item.x < most_left.x or item.is_slope) and item)
                    or most_left

                most_right = most_right or item
                most_right = ((item.x + item.w)
                        > (most_right.x + most_right.w) and item)
                    or most_left

                most_up = most_up or item

                if true or (most_up.is_slope and item.is_slope)
                    or (not most_up.is_slope and not item.is_slope_adj)
                then
                    most_up = (item.y < most_up.y and item) or most_up
                end

                most_bottom = most_bottom or item

                if true or (most_bottom.is_slope and item.is_slope)
                    or (not most_bottom.is_slope and not item.is_slope_adj)
                then
                    most_bottom = ((item.y + item.h)
                            > (most_bottom.y + most_bottom.h) and item)
                        or most_bottom
                end
            end
        end

        collisions.items = col_items

        collisions.most_left = most_left
        collisions.most_right = most_right
        collisions.most_up = most_up
        collisions.most_bottom = most_bottom

        collisions.top = most_up and most_up.y
        collisions.bottom = most_bottom and (most_bottom.y + most_bottom.h)
        collisions.left = most_left and most_left.x
        collisions.right = most_right and most_right.x + most_right.w

        collisions.diff_x = diff_x
        collisions.diff_y = diff_y

        local offset = abs(diff_y) > 0 and 0.1 or 0.5 --0.1

        collisions.end_x = (diff_x >= 0 and most_left
                and most_left.x - self.w - offset)
            or (diff_x < 0 and most_right and most_right:right() + offset)
            or goal_x

        if most_up and most_up.get_y then
            collisions.end_y = most_up:get_y(self:rect())
            if most_up.is_floor then
                collisions.end_y = collisions.end_y - self.h - offset
            else
                collisions.end_y = collisions.end_y + offset
            end
        else
            collisions.end_y = (diff_y >= 0 and most_up
                    and most_up.y - self.h - offset)
                or (diff_y < 0 and most_bottom and most_bottom:bottom() + offset) or goal_y
        end

        collisions.n = n_collisions

        collisions.has_slope = has_slope
        collisions.goal_x = goal_x
        collisions.goal_y = goal_y

        return collisions
    end

    ---@return JM.Physics.Collisions
    function Body:check2(goal_x, goal_y, filter, x, y, w, h)
        x = x or self.x
        y = y or self.y
        w = w or self.w
        h = h or self.h

        local bd = Body:new(x, y, w, h, self.type, self.world, self.id)

        local filter__ = function(obj, item)
            local r = filter and filter(obj, item)
            r = r and item ~= bd
            return r
        end

        return bd:check(goal_x, goal_y, filter__)
    end

    function Body:right()
        return self.x + self.w
    end

    function Body:bottom()
        return self.y + self.h
    end

    function Body:left()
        return self.x
    end

    function Body:top()
        return self.y
    end

    ---@param fx number|nil
    ---@param fy number|nil
    function Body:apply_force(fx, fy)
        self.force_x = self.force_x + ((fx or 0.0))
        self.force_y = self.force_y + ((fy or 0.0))

        self.acc_x = fx and fx ~= 0 and (self.force_x / self.mass)
            or self.acc_x
        self.acc_y = fy and fy ~= 0 and (self.force_y / self.mass)
            or self.acc_y
    end

    ---@param col JM.Physics.Collisions
    function Body:resolve_collisions_y(col)
        if col.n > 0 then -- collision!
            self:refresh(nil, col.end_y)

            if self.bouncing_y and (not col.most_up.is_slope) then
                self.speed_y = -self.speed_y * self.bouncing_y

                if abs(self.speed_y) <= sqrt(2.0 * self.acc_y * 2.0) then
                    self.speed_y = 0.0
                end
            else
                -- if (col.diff_y >= 0 and col.most_up.type ~= BodyTypes.kinematic)
                --     or col.diff_y < 0
                -- then
                --     self.speed_y = 0.0
                -- end
                self.speed_y = 0.0
            end

            dispatch_event(self, BodyEvents.axis_y_collision)

            if col.diff_y >= 0 then -- body hit the floor/ground
                if not self.ground then
                    dispatch_event(self, BodyEvents.ground_touch)
                end

                self.ground = col.most_up

                if self.ground.is_slope then
                    -- self.y = self.ground:get_y(self:rect()) - self.h
                    if self.ground.is_floor then
                        self:refresh(nil, self.ground:get_y(self:rect()) - self.h)
                    else
                        self:refresh(nil, self.ground:get_y(self:rect()) + 1)
                    end
                end
            else -- body hit the ceil
                if not self.ceil then
                    dispatch_event(self, BodyEvents.ceil_touch)
                end

                -- self.speed_y = 0.1

                self.ceil = col.most_bottom

                if self.ceil.is_slope and self.allowed_gravity then
                    self.speed_y = self.world.meter
                    self.speed_x = 0.0
                    self:refresh(nil, self.ceil:get_y(self:rect()) + 1)
                elseif self.ceil.is_slope then
                    if not self.ceil.is_floor then
                        self:refresh(nil, self.ceil:get_y(self:rect()) + 0.1)
                    end
                end
            end
        end
    end

    -- ---@param bd JM.Physics.Body|any
    -- ---@param slope JM.Physics.Slope|any
    -- local function body_is_adjc_slope(bd, slope)
    --     if not slope then return false end

    --     local slope_r = slope.x + slope.w
    --     local bd_bottom = bd.y + bd.h
    --     local bd_right = bd.x + bd.w

    --     if slope.is_floor then
    --         local cond = bd.y == slope.y
    --         local norm = slope.is_norm

    --         return cond and ((bd.x == slope_r and norm)
    --             or (bd_right == slope.x and not norm))
    --     else
    --         local cond = bd_bottom == (slope.y + slope.h)
    --         local norm = slope.is_norm

    --         return cond and ((bd.x == slope_r and not norm)
    --             or (bd_right == slope.x and norm))
    --     end
    -- end

    ---@param col JM.Physics.Collisions
    function Body:resolve_collisions_x(col)
        if col.n > 0 then
            if col.has_slope then
                -- if col.n > 1 then
                --     table_sort(col.items, is_slope)
                -- end

                local final_x, final_y
                -- local slope = col.has_slope

                for i = 1, col.n do
                    ---@type JM.Physics.Body|JM.Physics.Slope
                    local bd = col.items[i]

                    if bd.is_slope then
                        local temp = bd.is_floor and (-self.h - 0.1) or (0.1)
                        -- slope = bd
                        final_x = final_x or col.goal_x
                        final_y = bd:get_y(col.goal_x, self.y, self.w, self.h) + temp

                        -- if bd.is_floor then
                        --     self.ground = bd
                        -- else
                        --     self.ceil = bd
                        -- end

                        ---
                    else
                        ---
                        if not bd.is_slope_adj then
                            self.speed_x = 0.0

                            if col.diff_x < 0 then
                                final_x = bd:right() + 0.5
                            else
                                final_x = bd:left() - 0.5 - self.w
                            end
                        end
                    end
                end -- END for

                if is_kinematic(self) then
                    kinematic_moves_dynamic_x(self, final_x)
                    -- kinematic_moves_dynamic_y(self, final_y)
                end
                self:refresh(final_x, final_y)
                return
            end

            -- if self.ground and self.ground.is_slope
            --     and not self.ground:check_collision(self.x, self.y, self.w, self.h + 2)
            -- then
            --     self.ground = nil
            -- end

            self:refresh(col.end_x)

            if self.bouncing_x then
                self.speed_x = -self.speed_x * self.bouncing_x
            else
                self.speed_x = 0.0
            end

            dispatch_event(self, BodyEvents.axis_x_collision)

            if col.diff_x < 0 then
                if not self.wall_left then
                    dispatch_event(self, BodyEvents.wall_left_touch)
                end
                self.wall_left = col.most_left
            end

            if col.diff_x > 0 then
                if not self.wall_right then
                    dispatch_event(self, BodyEvents.wall_right_touch)
                end
                self.wall_right = col.most_right
            end

            return true
        end
        -- ::end_function::
    end

    function Body:resistance_y()
        local speed_y = self.speed_y
        if speed_y == 0.0 then return 0.0 end

        if self.type == BodyTypes.dynamic and speed_y <= 0
            and self.allowed_gravity
        then
            return 0.0
        end

        local meter = self.world.meter
        local on_water = self.on_water

        local d = (1.2754) -- air density
        d = on_water and (997) or d

        local c = self.coef_resis_y or 1.3

        -- c = self.on_water and self.type == BodyTypes.dynamic and (c / 10) or c

        local area = self.area_y
            or ((self.w / meter) * ((0.6 * 0.6)))

        if on_water then
            if self.type == BodyTypes.dynamic then
                c = 0.04
                area = (area * 0.2)
            else
                c = c / 40
                -- area = (area * 0.8)
            end
        end

        c = c * area

        return 0.5 * c * d * (speed_y ^ 2) * self:direction_y()
    end

    function Body:buoyant()
        -- calculando empuxo
        local water = self.on_water
        if not water then return 0 end
        local meter = self.world.meter

        local V = self:bottom() - water.y
        V = V > self.h and self.h or V
        V = V < 0 and 0 or V

        if self.type == BodyTypes.dynamic then
            V = (V / meter) * (self.w * 0.8 / meter) * (0.6 * 0.6)
        else
            V = (V / meter) * (self.w / meter) * (0.6 * 0.6)
        end

        local d = 997 -- water.density or self.world.default_density

        return V * self.world.gravity * d
    end

    function Body:resistance_x()
        local speed_x = self.speed_x
        if speed_x == 0 then return 0.0 end

        local meter    = self.world.meter
        local on_water = self.on_water

        local d        = 1.2754 -- air density
        d              = on_water and 997 or d
        -- d              = self.ground and (d * 10) or d

        local c        = self.coef_resis_x or 1.2

        local area     = self.area_x
            or ((0.6 * 0.6) * (self.h / (meter / 3.5)))

        if on_water and self.type == BodyTypes.dynamic then
            c = not self.ground and 0.04 or c --2.3
            area = area * 0.1
        end

        c = self.allowed_air_dacc and not self.ground and (c * 2) or c

        c = c * area

        return 0.5 * c * d * (speed_x ^ 2) * self:direction_x()
    end

    function Body:friction_x()
        if self.speed_x == 0.0 then return 0.0 end

        local ground = self.ground
        if not ground then return 0.0 end

        local FN = abs(self.acc_y * self.mass)

        if abs(self.speed_x) > self.world.meter * 0.5 then --0.25
            -- cinetic
            local cc = ground.coef_cinetic or 0.5          --0.5
            cc = self.on_water and ground and 1.1 or cc

            return FN * cc * (self:direction_x())
        else
            -- static
            local cs = ground.coef_static or 0.6 --0.6
            cs = self.on_water and ground and 1.3 or cs

            return FN * cs * (self:direction_x())
        end
    end

    function Body:static_friction()
        if abs(self.speed_x) > self.world.meter * 0.5 or not self.ground then
            return 0.0
        else
            return self:friction_x()
        end
    end

    function Body:get_ground_angle()
        return (self.ground and self.ground.angle or 0)
    end

    do
        function Body:top_left()
            return self.y, self.x
        end

        function Body:top_right()
            return self.y, self.x + self.w
        end

        function Body:bottom_left()
            return self.y + self.h, self.x
        end

        function Body:bottom_right()
            return self.y + self.h, self.x + self.w
        end

        function Body:draw()
            if self.__remove then return end

            if self.type == BodyTypes.static then
                love.graphics.setColor(0.1, 0.4, 0.5)
            elseif self.type == BodyTypes.only_fall then
                love.graphics.setColor(26 / 255, 201 / 255, 135 / 255)
            else
                love.graphics.setColor(1, 1, 1)
            end
            love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
            -- love.graphics.setColor(1, 1, 1)
            love.graphics.setColor(39 / 255, 31 / 255, 27 / 255)
            love.graphics.rectangle("line", self.x, self.y, self.w, self.h)

            local font = JM:get_font()
            font:push()
            font:set_font_size(6)
            if self.type == BodyTypes.static then
                if self.is_slope_adj then
                    font:print("adj", self.x, self.y)
                end
            end
            return font:pop()
            -- font:print(tostring(self.y), self.x, self.y - 12)
        end
    end

    function Body:update(dt)
        local obj = self

        -- if obj.type == BodyTypes.dynamic or obj.type == BodyTypes.kinematic
        --     or obj.type == BodyTypes.ghost
        -- then
        if obj.type ~= BodyTypes.static
            and obj.type ~= BodyTypes.only_fall
        then
            local goalx, goaly

            -- applying the gravity
            if obj.allowed_gravity then
                obj:apply_force(nil, obj:weight() - self:buoyant() - self:resistance_y())
                --
            else
                obj:apply_force(nil, -self:resistance_y())

                if obj.dacc_y then
                    if obj.speed_y > 0 and obj.acc_y < 0 then
                        obj.acc_y = -abs(obj.dacc_y)
                    elseif obj.speed_y < 0 and obj.acc_y > 0 then
                        obj.acc_y = abs(obj.dacc_y)
                    end
                end
            end

            -- falling
            if (obj.acc_y ~= 0.0) or (obj.speed_y ~= 0.0) then
                local last_sy = obj.speed_y

                goaly = obj.y + (obj.speed_y * dt)
                    + (obj.acc_y * dt * dt) * 0.5

                -- speed up with acceleration
                obj.speed_y = obj.speed_y + obj.acc_y * dt

                -- checking if reach max speed y
                if obj.max_speed_y and abs(obj.speed_y) > obj.max_speed_y then
                    obj.speed_y = obj.max_speed_y * obj:direction_y()
                end

                -- cheking if reach the global max speed
                if obj.world.max_speed_y and obj.allowed_speed_y_restriction
                    and obj.speed_y > obj.world.max_speed_y
                then
                    obj.speed_y = obj.world.max_speed_y
                end

                if self.on_water then
                    if obj.speed_y < 0 then
                        local lim = -self.world.meter * 3
                        if obj.speed_y < lim then
                            obj.speed_y = lim
                        end
                    elseif self.speed_y > 0 then
                        local lim = self.world.meter * 1.5
                        if self.speed_y > lim then
                            self.speed_y = lim
                        end
                    end
                end

                -- executing the "speed_y_change_direction" event
                if last_sy < 0.0 and obj.speed_y > 0.0
                    or (last_sy > 0.0 and obj.speed_y < 0.0)
                then
                    if not obj.allowed_gravity and obj.dacc_y then
                        obj.speed_y = 0.0
                        obj.acc_y = 0.0
                    end
                    dispatch_event(obj, BodyEvents.speed_y_change_direction)
                end

                if obj.type == BodyTypes.ghost then
                    obj:refresh(nil, goaly)
                    -- goto skip_collision_y
                else
                    local ex = 0

                    ex = obj.speed_y > 0 and 1 or 0
                    ex = obj.speed_y < 0 and -1 or ex


                    if self.ground and self.ground.is_slope
                        and self.speed_y >= 0
                        and self.stick_to_slope
                    then
                        ex = ex + self.world.tile * 0.25
                    end

                    if self.ceil and self.ceil.is_slope
                        and self.speed_y <= 0
                        and self.stick_to_slope
                    then
                        ex = ex - self.world.tile * 0.25
                    end

                    ---@type JM.Physics.Collisions
                    local col = obj:check(nil, goaly + ex, coll_y_filter, empty_table(), empty_table_for_coll())

                    if col.n > 0 then -- collision!
                        obj:resolve_collisions_y(col)
                    else
                        if obj.ground then
                            dispatch_event(obj, BodyEvents.leaving_ground)
                        end

                        if obj.ceil then
                            dispatch_event(obj, BodyEvents.leaving_ceil)
                        end

                        if obj.ground or obj.ceil then
                            dispatch_event(obj, BodyEvents.leaving_y_axis_body)
                        end

                        obj.ground = nil
                        obj.ceil = nil

                        if is_kinematic(obj)
                        -- and obj.speed_y ~= 0.0
                        -- and obj.acc_y ~= 0
                        then
                            kinematic_moves_dynamic_y(obj, goaly)
                        end

                        obj:refresh(nil, goaly)
                    end

                    -- simulating the enviroment resistence (friction)
                    if obj.speed_y ~= 0.0
                        and obj.dacc_y
                    then
                        local dacc = abs(obj.dacc_y)
                        obj:apply_force(nil, dacc * -obj:direction_y())
                    end

                    if last_sy <= 0.0 and obj.speed_y > 0.0 then
                        dispatch_event(self, BodyEvents.start_falling)
                    end

                    -- self.delta_h = self.delta_h + (goaly - self.y)
                end
                -- ::skip_collision_y::
            end
            --=================================================================

            do
                local ang = self.ground and self.ground.angle or 0
                local sin = math.sin(ang)
                local on_ice = self.ground and self.ground.__is_ice

                -- if abs(sin) <= 0.45 then
                --     -- sin = 0
                -- end

                local K = 1
                if self.type == BodyTypes.dynamic then
                    if abs(sin) <= 0.45 then
                        if self.speed_x == 0.0 then
                            K = not on_ice and 0 or 1
                        else
                            K = not on_ice and 0.25 or 1
                        end
                    else
                        K = 1
                    end
                end

                -- if self.on_water then
                --     K = 0
                -- end

                local weight_x = (self.acc_y * self.mass) * -sin * K

                do
                    local ground = self.ground
                    local is_norm = ground and ground.is_norm

                    if ground and ground.is_slope
                        and mfloor(self:bottom()) == ground.y
                    then
                        if is_norm then
                            if not ground.next then
                                weight_x = 0
                            end
                        else
                            if not ground.prev then
                                weight_x = 0
                            end
                        end
                    end
                end

                obj:apply_force(-self:resistance_x() - self:friction_x() - weight_x)
            end


            -- moving in x axis
            if (obj.acc_x ~= 0.0) or (obj.speed_x ~= 0.0) then
                local last_sx = obj.speed_x

                -- if obj.speed_x > 0 and obj.acc_x < 0 then
                --     obj.acc_x = -abs(obj.dacc_x)
                -- elseif obj.speed_x < 0 and obj.acc_x > 0 then
                --     obj.acc_x = abs(obj.dacc_x)
                -- end

                -- local mult = 1
                -- do
                --     if obj.ground and obj.ground.is_slope
                --         and self.y + self.h ~= obj.ground.y
                --     then
                --         if obj.ground.is_norm and obj.speed_x > 0
                --             or (not obj.ground.is_norm and obj.speed_x < 0)
                --         then
                --             mult = 1 - abs(math.sin(self.ground.angle))
                --         end
                --     end
                -- end

                -- local mult = 1
                -- do
                --     if obj.ground and obj.ground.is_slope then
                --         if obj.ground.is_norm and obj.speed_x > 0 or (not obj.ground.is_norm and obj.speed_x < 0) then
                --             mult = abs(math.cos(self.ground and self.ground.angle or 0))
                --         end
                --     end
                -- end

                if self.on_water then
                    obj.acc_x = obj.acc_x * 0.5
                end

                goalx = obj.x + ((obj.speed_x * dt)
                    + (obj.acc_x * dt * dt) * 0.5) --* mult


                -- obj.acc_x = obj.ground and obj.acc_x * 0.5 or obj.acc_x
                obj.speed_x = obj.speed_x + obj.acc_x * dt

                obj.speed_x = obj.speed_x

                -- if reach max speed
                if obj.max_speed_x
                    and abs(obj.speed_x) > obj.max_speed_x
                then
                    obj.speed_x = obj.max_speed_x
                        * obj:direction_x()
                end

                do
                    local max_speed_x = self.world.max_speed_x
                    if max_speed_x
                        and abs(self.speed_x) > max_speed_x
                    then
                        self.speed_x = max_speed_x * self:direction_x()
                    end
                end

                -- dacc
                if (obj.acc_x >= 0.0 and last_sx < 0.0 and obj.speed_x >= 0.0)
                    or (obj.acc_x <= 0.0 and last_sx > 0.0 and obj.speed_x <= 0.0)
                then
                    obj.speed_x = 0.0
                    obj.acc_x = 0.0
                    dispatch_event(obj, BodyEvents.speed_x_change_direction)
                end

                if obj.type == BodyTypes.ghost then
                    obj:refresh(goalx)
                    -- goto skip_collision_x
                else
                    local ex = obj.speed_x > 0 and 1 or 0
                    ex = obj.speed_x < 0 and -1 or ex

                    -- if obj.ground and obj.ground.is_slope then
                    --     goalx = goalx - goalx * abs(math.cos(self.ground.angle))
                    -- end

                    --- will store the body collisions with other bodies
                    ---@type JM.Physics.Collisions
                    local col = obj:check(goalx + ex, nil, collision_x_filter, empty_table(), empty_table_for_coll())

                    if col.n > 0 then -- had collision!
                        obj:resolve_collisions_x(col)
                        -- if is_kinematic(obj) then
                        --     kinematic_moves_dynamic_x(obj, obj.x)
                        -- end
                    else -- no collisions
                        if obj.wall_left then
                            dispatch_event(obj, BodyEvents.leaving_wall_left)
                        end

                        if obj.wall_right then
                            dispatch_event(obj, BodyEvents.leaving_wall_right)
                        end

                        if obj.wall_left or obj.wall_right then
                            dispatch_event(obj, BodyEvents.leaving_x_axis_body)
                        end

                        obj.wall_left = nil
                        obj.wall_right = nil

                        if is_kinematic(obj) then
                            kinematic_moves_dynamic_x(obj, goalx)
                        end

                        obj:refresh(goalx)
                    end

                    -- simulating the enviroment resistence (friction)
                    if obj.dacc_x and obj.speed_x ~= 0.0
                        and (obj.ground or obj.allowed_air_dacc)
                    then
                        local dacc = abs(obj.dacc_x)
                        dacc = self.on_water and (dacc * 1.5) or dacc
                        -- dacc = obj.ground and dacc * 0.3 or dacc
                        obj:apply_force(dacc * -obj:direction_x())
                    end
                end
                -- ::skip_collision_x::
            end -- end moving in x axis

            obj.force_x = 0.0
            obj.force_y = 0.0

            if self.on_water then
                if not collision_rect(self.x, self.y, self.w, self.h, self.on_water:rect()) then
                    self.on_water = nil
                end
            end
            if self.holder then
                self.holder.x = obj.x
                self.holder.y = obj.y
            end
        end --end if body is dynamic
        ---
    end
end
--=============================================================================

---@class JM.Physics.Slope: JM.Physics.Body
local Slope = {}
setmetatable(Slope, Body)

---@alias JM.Physics.SlopeType "floor"|"ceil"

---@return JM.Physics.Body|JM.Physics.Slope
function Slope:new(x, y, w, h, world, direction, slope_type, bd_type)
    local obj = Body:new(x, y, w, h, bd_type or BodyTypes.static, world, "")
    self.__index = self
    setmetatable(obj, self)
    Slope.__constructor__(obj, direction, slope_type)

    return obj
end

function Slope:__constructor__(direction, slope_type)
    self.shape = BodyShapes.slope
    self.is_slope = true

    self.is_norm = direction == "normal"
    self.is_floor = slope_type == "floor"

    local left_x, left_y = self:point_left()
    local right_x, right_y = self:point_right()

    local dx = right_x - left_x
    local dy = right_y - left_y

    -- local dist = sqrt(dx ^ 2 + dy ^ 2)

    self.angle = math.atan2(dy, dx)

    self.resistance_x = 0.7

    ---@type JM.Physics.Slope|any
    self.prev = nil
    ---@type JM.Physics.Slope|any
    self.next = nil

    self._A = self:A()
    self._B = self:B()

    self.on_ground = false -- tell if slope is above ground
    self.on_ceil = false
end

function Slope:point_left()
    local x, y

    if self.is_norm then
        y, x = self:bottom_left()
    else
        y, x = self:top_left()
    end
    return x, y
end

function Slope:point_right()
    local x, y

    if self.is_norm then
        y, x = self:top_right()
    else
        y, x = self:bottom_right()
    end
    return x, y
end

function Slope:A()
    local x1, y1 = self:point_left()
    local x2, y2 = self:point_right()
    y1, y2 = -y1, -y2

    return (y1 - y2) / (x1 - x2)
end

function Slope:B()
    local x1, y1 = self:point_left()
    y1 = -y1

    return y1 - self:A() * x1
end

function Slope:get_coll_point(x, y, w, h)
    local px, py
    -- if x and w then
    if self.is_floor then
        px = (self.is_norm and x + w) or x
    else
        px = (self.is_norm and x) or (x + w)
    end
    -- end

    -- if y and h then
    py = (self.is_floor and (y + h)) or y
    py = -py
    -- end

    return px, py
end

-- -@return boolean is_down
function Slope:check_up_down(x, y, w, h)
    local px, py = self:get_coll_point(x, y, w, h)
    -- return py <= self._A * px + self._B and "down" or "up"
    return py <= self._A * px + self._B and true or false
end

function Slope:check_collision(x, y, w, h)
    do
        -- local oy = 0 --self.world.tile * 0.5
        local rec_col = collision_rect(
            self.x, self.y, self.w, self.h,
            x - 1 * 0, y, w + 2 * 0, h --+ oy
        )
        if not rec_col then return false end
    end

    if self.is_floor then
        if self.next and self.is_norm and y + h <= self.y then
            return false
        elseif self.prev and not self.is_norm and y + h <= self.y then
            return false
        end
    else
        if self.next and not self.is_norm and y >= self.y + self.h then
            return false
        end
    end

    local is_down = self:check_up_down(x, y, w, h)

    if self.is_floor then
        return is_down
    else
        return not is_down
    end
    -- return (self.is_floor and is_down)
    --     or ((not self.is_floor) and not is_down)
end

function Slope:get_y(x, y, w, h)
    x, y = self:get_coll_point(x, y, w, h)
    y = -y
    local py = -(self._A * x + self._B)

    local is_floor = self.is_floor
    local is_norm = self.is_norm
    local next = self.next
    local prev = self.prev
    local bottom = self.y + self.h

    if not next then
        if is_floor then
            if is_norm then
                py = py < self.y and self.y or py
                -- else
                -- local bt = self.y + self.h
                -- py = py > bt and bt or py
            end
        else
            if is_norm then

            else
                py = py > bottom and bottom or py
            end
        end
    end

    if not prev then
        if is_floor then
            if not is_norm then
                py = py < self.y and self.y or py
                -- else
                -- local bt = self.y + self.h
                -- py = py > bt and bt or py
            end
        else
            if is_norm then
                py = py > bottom and bottom or py
            end
        end
    else
        if is_floor and not is_norm and not next then
            py = py > bottom and bottom or py
        end
    end

    -- py = not is_floor and (py > self:bottom() and self:bottom()) or py

    if is_floor then
        if self.on_ground and py > bottom then py = bottom - 0.1 end
    else
        if self.on_ceil and py < self.y then py = self.y + 0.1 end
    end

    return py
end

function Slope:draw()
    local x1, y1 = self:point_left()
    local x2, y2 = self:point_right()

    love.graphics.setColor(1, 0, 0, 0.4)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)

    love.graphics.setColor(39 / 255, 31 / 255, 27 / 255)
    love.graphics.setLineWidth(2)
    love.graphics.line(x1, y1, x2, y2)
    love.graphics.setLineWidth(1)

    -- love.graphics.setColor(0.3, 1, 0.3, 0.5)
    if self.type == BodyTypes.static then
        love.graphics.setColor(0.1, 0.4, 0.5)
    elseif self.type == BodyTypes.only_fall then
        love.graphics.setColor(26 / 255, 201 / 255, 135 / 255)
    else
        love.graphics.setColor(1, 1, 1)
    end
    -- love.graphics.setColor(0.1, 0.4, 0.5)

    if self.is_floor then
        love.graphics.polygon("fill", x1, y1, x2, y2,
            self.x + self.w,
            self.y + self.h,
            self.x, self.y + self.h
        )
    else
        love.graphics.polygon("fill", x1, y1, x2, y2,
            self.x + self.w,
            self.y,
            self.x, self.y
        )
    end

    local font = JM:get_font() --JM_Font.current
    font:push()
    font:set_font_size(6)

    local py1 = self.y - 12
    local py2 = self.y - 18

    if not self.is_floor then
        py1 = self.y + self.h
        py2 = self.y + self.h + 6
    end
    font:print("p:" .. tostring(self.prev and true or false), self.x, py1)
    font:print("n:" .. tostring(self.next and true or false), self.x, py2)
    -- font:print(tostring(math.sin(self.angle)), self.x, self.y - 22)

    if self.is_floor then
        if self.on_ground then
            font:set_color(JM.Utils:get_rgba(1, 0, 0, 1))
            font:printf("ground", self.x, self.y + self.h * 0.5 - 6, "center", self.w)
        else
            -- font:print(tostring(self.on_ground), self.x + self.w * 0.5, self.y + self.h * 0.5 - 6)
        end
    else
        if self.on_ceil then
            font:set_color(JM.Utils:get_rgba(1, 0, 0, 1))
            font:print("ceil", self.x + self.w * 0.5, self.y + self.h * 0.5 - 6)
        else
            -- font:print(tostring(self.on_ceil), self.x + self.w * 0.5, self.y + self.h * 0.5 - 6)
        end
    end

    font:set_color(JM.Utils:get_rgba(1, 1, 0, 1))
    if self.is_norm then
        font:printf("norm", self.x, self.y, self.w, "center")
    end

    local dg = math.cos(self.angle)
    local sign = math.abs(dg) / dg
    font:print(string.format("%.2f : %.1f", dg, sign), self.x + self.w - 24, self.y - 12)

    font:pop()
end

--=============================================================================

---@class JM.Physics.World
local World = {}
World.__index = World
do
    function World:new(args)
        local obj = setmetatable({}, self)
        World.__constructor__(obj, args or {})
        return obj
    end

    function World:__constructor__(args)
        self.tile = args.tile or self.tile or 32
        self.cellsize = args.cellsize or self.cellsize or (self.tile * 4)

        self.meter = args.meter or self.meter or (self.tile * 3.5)
        self.gravity = args.gravity or self.gravity or (9.8 * self.meter)
        self.max_speed_y = args.max_speed_y or self.max_speed_y
            or (self.meter * 15) --15
        self.max_speed_x = args.max_speed_x or self.max_speed_x
            or (self.meter * 7)  --self.max_speed_y
        self.default_mass = args.default_mass or self.default_mass or 65.0

        self.default_density = args.default_density or self.default_density or
            (5 / math.pow(self.meter, 2))

        self.bodies = {}
        self.bodies_number = 0
        self.bodies_static = {}

        self.non_empty_cells = {}

        self.grid = {}
    end

    function World:to_cell(x, y)
        return mfloor(x / self.cellsize) + 1, mfloor(y / self.cellsize) + 1
    end

    function World:count_Cells()
        local count = 0
        for _, row in pairs(self.grid) do
            for _, _ in pairs(row) do
                count = count + 1
            end
        end
        return count
    end

    function World:rect_to_cell(x, y, w, h)
        local cleft, ctop = self:to_cell(x, y)
        local cright = mceil((x + w) / self.cellsize)
        local cbottom = mceil((y + h) / self.cellsize)

        return cleft, ctop, cright - cleft + 1, cbottom - ctop + 1
    end

    function World:add_obj_to_cell(obj, cx, cy)
        self.grid[cy] = self.grid[cy] or setmetatable({}, metatable_mode_v)
        local row = self.grid[cy]

        row[cx] = row[cx] or { count = 0, x = cx, y = cy, items = setmetatable({}, metatable_mode_k) }

        local cell = row[cx]
        self.non_empty_cells[cell] = true

        if not cell.items[obj] then
            cell.items[obj] = true
            cell.count = cell.count + 1
            return true
        end
        return false
    end

    function World:remove_obj_from_cell(obj, cx, cy)
        local row = self.grid[cy]
        if not row or not row[cx] or not row[cx].items[obj] then return end

        ---@type JM.Physics.Cell
        local cell = row[cx]
        cell.items[obj] = nil
        cell.count = cell.count - 1

        if cell.count == 0 then
            self.non_empty_cells[cell] = nil
        end
        return true
    end

    ---@param x number
    ---@param y number
    ---@param w number
    ---@param h number
    ---@return table|nil
    function World:get_items_in_cell_obj(x, y, w, h, empty_tab)
        local cl, ct, cw, ch = self:rect_to_cell(x, y, w, h)
        local items

        for cy = ct, (ct + ch - 1) do
            local row = self.grid[cy]

            if row then
                for cx = cl, (cl + cw - 1) do
                    ---@type JM.Physics.Cell
                    local cell = row[cx]

                    if cell and cell.count > 0 then
                        items = items or empty_tab or {}

                        -- for item, _ in pairs(cell.items) do
                        for item, _ in next, cell.items do
                            items[item] = true
                        end
                    end
                end -- End For Columns
            end
        end         -- End for rows

        return items
    end

    ---@param obj JM.Physics.Body
    function World:add(obj)
        if obj.type ~= BodyTypes.static then
            if obj.type == BodyTypes.kinematic then
                table_insert(self.bodies, 1, obj)
            else
                table_insert(self.bodies, obj)
            end

            self.bodies_number = self.bodies_number + 1

            if obj.type == BodyTypes.only_fall then
                table_insert(self.bodies_static, obj)
            end
        else
            table_insert(self.bodies_static, obj)
        end

        local cl, ct, cw, ch = self:rect_to_cell(obj.x, obj.y, obj.w, obj.h)

        for cy = ct, (ct + ch - 1) do
            for cx = cl, (cl + cw - 1) do
                self:add_obj_to_cell(obj, cx, cy)
            end
        end
    end

    ---@param obj JM.Physics.Body
    function World:remove(obj, index)
        local r = table_remove(self.bodies, index)

        if r then
            self.bodies_number = self.bodies_number - 1

            local cl, ct, cw, ch = self:rect_to_cell(obj.x, obj.y, obj.w, obj.h)

            for cy = ct, (ct + ch - 1) do
                for cx = cl, (cl + cw - 1) do
                    self:remove_obj_from_cell(obj, cx, cy)
                end
            end
        end
    end

    ---@param obj JM.Physics.Body|JM.Physics.Slope|any
    function World:remove_by_obj(obj, list_opt)
        local index, list

        list = list_opt or (obj.is_slope and self.bodies_static) or self.bodies

        for i = 1, #list do
            if list[i] == obj then
                index = i
                break
            end
        end

        if index then
            table_remove(list, index)

            if list == self.bodies then
                self.bodies_number = self.bodies_number - 1
            end

            local cl, ct, cw, ch = self:rect_to_cell(obj.x, obj.y, obj.w, obj.h)

            for cy = ct, (ct + ch - 1) do
                for cx = cl, (cl + cw - 1) do
                    self:remove_obj_from_cell(obj, cx, cy)
                end
            end

            return true
        end

        return false
    end

    function World:fix_ground_to_slope()
        local N = #self.bodies_static

        for i = N, 1, -1 do
            ---@type JM.Physics.Collide
            local bd = self.bodies_static[i]

            if bd and not bd.is_slope then
                local items = self:get_items_in_cell_obj(bd.x - 1, bd.y - 2, bd.w + 2, bd.h + 4)

                if items then
                    for item, _ in pairs(items) do
                        ---@type JM.Physics.Collide
                        local item = item

                        if item ~= bd and not item.__remove
                            and item.is_enabled and item.is_slope
                            and collision_rect(bd.x, bd.y - 1, bd.w, bd.h, item:rect())
                        then
                            if bd.x < item.x then
                                local x, y, w, h = bd:rect()
                                bd:refresh(x, y, (item.x - x), h)

                                if w - bd.w > 0 then
                                    self:add(Body:new(x + bd.w, y, w - bd.w, h, BodyTypes.static, self))
                                end
                                --
                            elseif bd.x + bd.w > item.x + item.w then
                                local x, y, w, h = bd:rect()
                                bd:refresh(item.x + item.w, y, bd:right() - item:right(), h)

                                self:add(Body:new(x, y, item.w, h, BodyTypes.static, self))
                            end
                        end
                    end
                end
            end
        end
    end

    function World:fix_slope()
        local N = #self.bodies_static

        for i = N, 1, -1 do
            ---@type JM.Physics.Collide
            local bd = self.bodies_static[i]

            if bd and bd.is_slope then
                local items = self:get_items_in_cell_obj(bd.x - 2, bd.y - 2, bd.w + 4, bd.h + 4)

                if items then
                    -- for item, _ in pairs(items) do
                    for item, _ in next, items do
                        ---@type JM.Physics.Collide
                        local item = item

                        if item ~= bd and not item.__remove
                            and item.is_enabled and not item.is_slope
                            and collision_rect(bd.x - 1, bd.y, bd.w + 2, bd.h + 1, item:rect())
                        then
                            if bd.is_floor and item.y >= bd.y + bd.h then
                                if bd.is_norm then
                                    if item.x < bd.x then
                                        bd.on_ground = true
                                    end
                                else
                                    if item:right() > bd:right() then
                                        bd.on_ground = true
                                    end
                                end
                            end
                        end

                        if item ~= bd and not item.__remove and item.is_enabled and not item.is_slope and collision_rect(bd.x - 1, bd.y - 1, bd.w + 2, bd.h, item:rect()) then
                            if not bd.is_floor and item:bottom() <= bd.y then
                                if bd.is_norm then
                                    bd.on_ceil = item:right() > bd:right() or bd.on_ceil
                                else
                                    bd.on_ceil = item.x < bd.x or bd.on_ceil
                                end
                            end
                        end
                    end
                end

                local col = bd:check(nil, bd.y + 2, function(bd, item)
                    return item ~= bd and not item.__remove
                        and item.is_enabled and not item.is_slope
                        and item.type == BodyTypes.only_fall
                        and bd.is_floor
                end)

                if col.n > 0 and bd.type == BodyTypes.only_fall then
                    for i = 1, #col.items do
                        ---@type JM.Physics.Body
                        local item = col.items[i]

                        local off = bd:bottom() - item.y
                        item:refresh(nil, bd.y + bd.h, nil, item.h - off)
                        -- item:refresh()

                        if item.x < bd.x and bd.is_norm then
                            item:refresh(nil, nil, item.w - (item:right() - bd.x))
                        elseif item.x < bd:right() and not bd.is_norm then
                            item:refresh(bd:right(), nil, item.w - (bd:right() - item.x))
                        end

                        if item.y == bd.y + bd.h
                            and item.x >= bd.x
                            and bd.is_norm
                        then
                            self:remove_by_obj(item, self.bodies_static)
                            item.__remove = true
                        end

                        if item.w <= 0 then
                            self:remove_by_obj(item, self.bodies_static)
                            item.__remove = true
                        end
                    end
                end

                items = self:get_items_in_cell_obj(bd.x - 1, bd.y - 1, bd.w + 2, bd.h + 2)
                if items then
                    for item, _ in next, items do
                        ---@type JM.Physics.Collide
                        local item = item

                        if bd.is_floor and item ~= bd and not item.is_slope and not item.__remove and item.type == BodyTypes.static
                        then
                            if bd.is_norm then
                                if item.y == bd.y and item.x == bd:right() then
                                    item.is_slope_adj = true
                                end
                            else
                                if item.y == bd.y and item:right() == bd.x then
                                    item.is_slope_adj = true
                                end
                            end

                            -- if item.y == bd:bottom() then
                            --     item.is_slope_adj = true
                            -- end
                        end

                        if not bd.is_floor and item ~= bd and not item.is_slope and not item.__remove and item.type == BodyTypes.static
                        then
                            if bd.is_norm then
                                if item:bottom() == bd:bottom() and item:right() == bd.x then
                                    item.is_slope_adj = true
                                end
                            else
                                if item:bottom() == bd:bottom() and item.x == bd:right() then
                                    item.is_slope_adj = true
                                end
                            end

                            -- if item:bottom() == bd.y then
                            --     item.is_slope_adj = true
                            -- end
                        end
                    end
                end
            end
        end
    end

    function World:optimize()
        local N = #self.bodies_static

        for i = N, 1, -1 do
            ---@type JM.Physics.Collide
            local bd = self.bodies_static[i]

            if bd and not bd.is_slope then
                local col = bd:check2(nil, nil, function(_, item)
                    return item ~= bd and not item.is_slope and item.x == bd.x and item.w == bd.w and
                        bd.type == item.type
                end, bd.x, bd.y + 1, bd.w, bd.h)

                if col.n > 0 then
                    self:remove_by_obj(bd, self.bodies_static)
                    bd.__remove = true

                    ---@type JM.Physics.Body
                    local c = col.items[1]
                    c:refresh(nil, c.y - bd.h, nil, c.h + bd.h)
                end

                -- col = bd:check2(nil, nil, function(_, item)
                --     return item ~= bd and not item.is_slope and item.x == bd.x and item.w == bd.w
                -- end, bd.x, bd.y - 1, bd.w, bd.h)

                -- if col.n > 0 then
                --     self:remove_by_obj(bd, self.bodies_static)

                --     ---@type JM.Physics.Body
                --     local c = col.items[1]
                --     c:refresh(nil, c.y, nil, c.h + bd.h)
                -- end


                col = bd:check2(nil, nil, function(_, item)
                    return item ~= bd and not item.is_slope and item.y == bd.y and item.h == bd.h and
                        bd.type == item.type
                end, bd.x - 1, bd.y, bd.w, bd.h)

                if col.n > 0 then
                    self:remove_by_obj(bd, self.bodies_static)
                    bd.__remove = true

                    ---@type JM.Physics.Body
                    local c = col.items[1]
                    c:refresh(nil, nil, c.w + bd.w, nil)
                end


                -- col = bd:check2(nil, nil, function(_, item)
                --     return item ~= bd and not item.is_slope and item.y == bd.y and item.h == bd.h
                -- end, bd.x + 1, bd.y, bd.w, bd.h)

                -- if col.n > 0 then
                --     self:remove_by_obj(bd, self.bodies_static)
                --     bd.__remove = true

                --     ---@type JM.Physics.Body
                --     local c = col.items[1]
                --     c:refresh(c.x - bd.w, nil, c.w + bd.w, nil)
                -- end

                local items = self:get_items_in_cell_obj(bd.x + 1, bd.y + 1, bd.w - 2, bd.h - 2)

                if items and bd.type == BodyTypes.static then
                    -- for item, _ in pairs(items) do
                    for item, _ in next, items do
                        ---@type JM.Physics.Collide
                        local item = item

                        if item ~= bd and not item.__remove
                            and item.is_enabled and item.is_slope
                            and collision_rect(bd.x, bd.y, bd.w, bd.h, item:rect())
                        then
                            --
                            if bd.y >= item.y
                                and bd.y + bd.h <= item.y + item.h
                            then
                                self:remove_by_obj(bd, self.bodies_static)
                                bd.__remove = true
                                --
                            elseif bd.y < item.y
                                and bd.y + bd.h <= item.y + item.h
                            then
                                bd:refresh(nil, bd.y, nil, nil)
                                --
                            elseif bd.y + bd.h > item.y + item.h
                                and bd.y >= item.y
                            then
                                bd:refresh(nil, item.y + item.h, nil, bd.y + bd.h - (item.y + item.h))
                                --
                            end

                            if bd.h <= 0 then
                                self:remove_by_obj(bd, self.bodies_static)
                                bd.__remove = true
                            end

                            break
                        end
                    end
                end

                if not bd.is_slope and bd.type == BodyTypes.only_fall then
                    bd:refresh(nil, nil, nil, self.tile)
                end
                --
            end
        end
    end

    function World:remove_unused()
        local N = #self.bodies_static

        for i = N, 1, -1 do
            ---@type JM.Physics.Collide
            local bd = self.bodies_static[i]

            local items = self:get_items_in_cell_obj(bd.x - 1, bd.y - 1, bd.w + 2, bd.h + 2)

            if items then
                local top, left, right, bottom

                for item, _ in next, items do
                    ---@type JM.Physics.Collide
                    local item = item

                    if item ~= bd and (item.type == BodyTypes.static
                            or item.is_slope)
                    then
                        if item:bottom() == bd.y
                            and item:right() > bd.x and item.x < bd:right()
                        then
                            top = true
                        elseif item.y == bd:bottom()
                            and item:right() > bd.x and item.x < bd:right()
                        then
                            bottom = true
                        end

                        if item:right() == bd.x
                        then

                        end
                    end
                end
            end
        end
    end

    function World:clear()
        return World.__constructor__(self, {})
    end

    ---@param bd JM.Physics.Body
    local update_order = function(bd)
        if bd.__remove then
            return -1000
        end

        local tp = bd.type
        if tp == BodyTypes.static
            or tp == BodyTypes.only_fall
        then
            return 1000
        end

        if tp == BodyTypes.kinematic then
            return 100
        end

        return 0
    end

    ---@param a JM.Physics.Body
    ---@param b JM.Physics.Body
    local sort_update = function(a, b)
        return update_order(a) > update_order(b)
    end

    local dt_lim = 1 / 30
    function World:update(dt)
        dt = dt > dt_lim and dt_lim or dt

        table.sort(self.bodies, sort_update)

        for i = self.bodies_number, 1, -1 do
            ---@type JM.Physics.Body|any
            local obj = self.bodies[i]

            if obj.__remove then
                self:remove(obj, i)
                push_body(obj)
                obj = nil
            elseif obj.type == BodyTypes.static
                or obj.type == BodyTypes.only_fall
            then
                break
            end

            if obj and obj.is_stucked then
                obj = nil
            end

            if obj and obj.is_enabled then
                obj:update(dt)
            end
        end
    end

    ---@param cam JM.Camera.Camera|nil
    function World:draw(draw_static, draw_dynamic, cam)
        if draw_dynamic then
            for i = 1, self.bodies_number do
                ---@type JM.Physics.Body|JM.Physics.Slope
                local obj = self.bodies[i]

                local cond = not cam
                    or (cam and cam:rect_is_on_view(obj:rect()))
                local r = obj.draw and cond and obj:draw()
            end
        end

        if draw_static then
            for i = 1, #self.bodies_static do
                local obj = self.bodies_static[i]
                local cond = not cam
                    or (cam and cam:rect_is_on_view(obj:rect()))
                local r = obj.draw and cond and obj:draw()
            end
        end
    end
end
--=============================================================================

---@class JM.Physics
local Phys = {}
Phys.BodyTypes = BodyTypes

---@return JM.Physics.World
function Phys:newWorld(args)
    return World:new(args)
end

---@param world JM.Physics.World
---@param type_ "dynamic"|"kinematic"|"static"|"ghost"|"only_fall"
---@return JM.Physics.Body
function Phys:newBody(world, x, y, w, h, type_)
    local bd_type = BodyTypes[type_] or BodyTypes.static

    local b = Body:new(x, y, w, h, bd_type, world)

    -- if b.type == BodyTypes.static then
    --     local col = b:check2(nil, nil, function(obj, item)
    --         return item.is_slope
    --     end, x + 1, y + 1, w - 2, h - 2)

    --     -- if col.n > 0 then
    --     --     ---@type JM.Physics.Slope
    --     --     local slope = col.items[1]

    --     --     local tile = world.tile
    --     --     for j = b.y, b.y + b.h - 1, tile do
    --     --         for i = b.x, b.x + b.w - 1, tile do
    --     --             if not collision_rect(i + 1, j + 1, tile - 2, tile - 2, slope:rect()) then
    --     --                 -- Phys:newBody(world, i, j, tile, tile, "static")
    --     --             end
    --     --         end
    --     --     end

    --     --     -- b:refresh(nil, nil, 0)
    --     -- end

    --     local col

    --     ---@diagnostic disable-next-line: cast-local-type
    --     col = b.h > 0 and b.w > 0 and b:check2(nil, nil, function(_, item)
    --         return item.type == BodyTypes.static and item ~= b
    --             and not item.is_slope
    --             and item.h == b.h
    --             and item.y == b.y
    --     end, b.x, b.y, b.w + 1, b.h)

    --     if col and col.n > 0 then
    --         ---@type JM.Physics.Body
    --         local bd = col.items[1]

    --         bd:refresh(bd.x - b.w, bd.y, bd.w + b.w, bd.h)
    --         b:refresh(nil, nil, nil, 0)
    --     end

    --     ---@diagnostic disable-next-line: cast-local-type
    --     col = b.h > 0 and b.w > 0 and b:check2(nil, nil, function(_, item)
    --         return item.type == BodyTypes.static and item ~= b
    --             and not item.is_slope
    --             and item.h == b.h
    --             and item.y == b.y
    --     end, b.x - 1, b.y, b.w, b.h)

    --     if col and col.n > 0 then
    --         ---@type JM.Physics.Body
    --         local bd = col.items[1]

    --         bd:refresh(bd.x, bd.y, bd.w + b.w, bd.h)
    --         b:refresh(nil, nil, nil, 0)
    --     end

    --     ---@diagnostic disable-next-line: cast-local-type
    --     col = b.h > 0 and b.w > 0 and b:check2(nil, nil, function(_, item)
    --         return not item.is_slope and item ~= b
    --             and item.w == b.w
    --             and item.x == b.x
    --     end, b.x, b.y - 1, b.w, b.h)

    --     if col and col.n > 0 then
    --         ---@type JM.Physics.Body
    --         local bd = col.items[1]

    --         bd:refresh(nil, nil, nil, bd.h + b.h)
    --         b:refresh(nil, nil, nil, 0)
    --     end

    --     ---@diagnostic disable-next-line: cast-local-type
    --     col = b.h > 0 and b.w > 0 and b:check2(nil, nil, function(_, item)
    --         return not item.is_slope and item ~= b
    --             and item.w == b.w
    --             and item.x == b.x
    --     end, b.x, b.y + 1, b.w, b.h)

    --     if col and col.n > 0 then
    --         ---@type JM.Physics.Body
    --         local bd = col.items[1]

    --         bd:refresh(nil, bd.y - b.h, nil, bd.h + b.h)
    --         b:refresh(nil, nil, nil, 0)
    --     end
    -- end


    -- if b.h > 0 and b.w > 0 then
    world:add(b)
    -- end

    return b
end

---@param slope JM.Physics.Slope|any
---@param world JM.Physics.World
local function merge_slopes(slope, world)
    local prop = slope.h / slope.w
    local merged = false

    local col = slope:check2(nil, nil, function(obj, item)
        return item.is_slope and item ~= slope and (item.h / item.w) == prop
            and ((slope.is_floor and item.is_floor)
                or (not slope.is_floor and not item.is_floor))
    end, slope.x - 1, slope.y - 1, slope.w, slope.h + 2)

    if col.n > 0 then
        ---@type JM.Physics.Slope
        local item = col.items[1]

        local px, py = item:point_right()
        local sx, sy = slope:point_left()

        local same_dir = (item.is_norm and slope.is_norm)
            or (not item.is_norm and not slope.is_norm)

        if (px == sx and py == sy) and same_dir then
            if item.is_norm then
                item:refresh(nil, item.y - slope.h, item.w + slope.w, item.h + slope.h)
            else
                item:refresh(nil, nil, item.w + slope.w, item.h + slope.h)
            end
            slope = item
            merged = true
        end
    end

    col = slope:check2(nil, nil, function(obj, item)
        return item.is_slope and item ~= slope and (item.h / item.w) == prop
            and ((slope.is_floor and item.is_floor)
                or (not slope.is_floor and not item.is_floor))
    end, slope.x, slope.y - 1, slope.w + 1, slope.h + 2)

    if col.n > 0 then
        ---@type JM.Physics.Slope
        local item = col.items[1]

        local px, py = item:point_left()
        local sx, sy = slope:point_right()

        local same_dir = (item.is_norm and slope.is_norm)
            or (not item.is_norm and not slope.is_norm)

        if (px == sx and py == sy) and same_dir then
            if merged then
                world:remove_by_obj(item)

                if slope.is_norm then
                    slope:refresh(nil, item.y, slope.w + item.w, slope.h + item.h)
                else
                    slope:refresh(slope.x, slope.y, slope.w + item.w, slope.h + item.h)
                end
            else
                if item.is_norm then
                    item:refresh(item.x - slope.w, item.y, item.w + slope.w, item.h + slope.h)
                else
                    item:refresh(slope.x, slope.y, item.w + slope.w, item.h + slope.h)
                end

                return item
            end
        end
    end

    return slope
end

---@param world JM.Physics.World
---@param bd_type "dynamic"|"kinematic"|"static"|"ghost"|"only_fall"|nil
---@return JM.Physics.Body|JM.Physics.Slope
function Phys:newSlope(world, x, y, w, h, slope_type, direction, bd_type)
    ---@diagnostic disable-next-line: cast-local-type
    bd_type = BodyTypes[bd_type] or BodyTypes.static

    local slope = Slope:new(x, y, w, h, world, direction, slope_type, bd_type)

    local result = merge_slopes(slope, world)
    local merged = result ~= slope

    if not merged then
        world:add(slope)
    else
        slope = result
    end

    local col = slope:check2(nil, nil, function(obj, item)
        return item.is_slope and item ~= slope
            and ((slope.is_floor and item.is_floor)
                or (not slope.is_floor and not item.is_floor))
    end, slope.x - 1, slope.y - 1, slope.w, slope.h + 2)

    if col.n > 0 then
        ---@type JM.Physics.Slope|any
        local prev = col.items[1]

        local px, py = prev:point_right()
        local sx, sy = slope:point_left()

        local same_dir = (prev.is_norm and slope.is_norm)
            or (not prev.is_norm and not slope.is_norm)

        if (px == sx and py == sy) and same_dir then
            slope.prev = col.items[1]
            prev.next = slope
        end
    else
        col = slope:check2(nil, nil, function(obj, item)
            return item.is_slope and item ~= slope
                and ((slope.is_floor and item.is_floor)
                    or (not slope.is_floor and not item.is_floor))
        end, slope.x, slope.y - 1, slope.w + 1, slope.h + 2)

        if col.n > 0 then
            ---@type JM.Physics.Slope|any
            local next = col.items[1]

            local px, py = next:point_left()
            local sx, sy = slope:point_right()

            local same_dir = (next.is_norm and slope.is_norm)
                or (not next.is_norm and not slope.is_norm)

            if (px == sx and py == sy) and same_dir then
                slope.next = col.items[1]
                next.prev = slope
            end
        end
    end

    col = slope:check2(nil, nil,
        ---@param item JM.Physics.Body | JM.Physics.Slope
        function(obj, item)
            return (item.type == BodyTypes.static) and item ~= slope and not item.is_slope
        end, slope.x + 1, slope.y + 1, slope.w - 2, slope.h - 2
    )

    if col.n > 0 then
        for i = 1, col.n do
            ---@type JM.Physics.Body
            local bd = col.items[i]

            local tile = world.tile
            world:remove_by_obj(bd, world.bodies_static)
            bd.__remove = true

            for p = bd.y, bd.y + bd.h - 1, tile do
                for k = bd.x, bd.x + bd.w - 1, tile do
                    if not collision_rect(
                            k + 1, p + 1, tile - 2, tile - 2,
                            slope.x, slope.y, slope.w, slope.h
                        )
                    then
                        Phys:newBody(world, k, p, tile, tile, "static")
                    end
                end
            end

            if bd.h <= 0 or bd.w <= 0 then
                -- world:remove_by_obj(bd, world.bodies_static)
            end
        end
    end

    return slope
end

Phys.collision_rect = collision_rect

return Phys
