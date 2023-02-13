local abs, mfloor, mceil, sqrt, min, max = math.abs, math.floor, math.ceil, math.sqrt, math.min, math.max

local table_insert, table_remove, table_sort = table.insert, table.remove, table.sort

---@enum JM.Physics.BodyTypes
local BodyTypes = {
    dynamic = 1,
    static = 2,
    kinematic = 3,
    ghost = 4
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
    leaving_x_axis_body = 14
}

---@alias JM.Physics.Collide JM.Physics.Body|JM.Physics.Slope

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

local function dynamic_filter(obj, item)
    return is_dynamic(item)
end

local function colliders_filter(obj, item)
    return not is_dynamic(item)
end

local default_filter = function(body, item)
    return true
end

---@param kbody JM.Physics.Body
local function kinematic_moves_dynamic_x(kbody, goalx)

    local col = kbody:check2(goalx, nil,
        dynamic_filter,
        nil, kbody.y - 1, nil, kbody.h + 2
    )

    if col.n > 0 then
        for i = 1, col.n do
            local bd

            ---@type JM.Physics.Body
            bd = col.items[i]

            bd:refresh(bd.x + col.diff_x)

            local col_bd

            col_bd = bd:check(nil, nil, colliders_filter)

            if col_bd.n > 0 then
                if col.diff_x < 0 then
                    bd:refresh(col_bd.right + 0.1)
                else
                    bd:refresh(col_bd.left - bd.w - 0.1)
                end

                local col_f = bd:check(nil, nil, colliders_filter)

                -- bd.is_stucked = nn > 0
                -- bd.is_stucked = true
            end

            bd, col_bd = nil, nil
        end
    end

end

---@param kbody JM.Physics.Body
local function kinematic_moves_dynamic_y(kbody, goaly)
    local col = kbody:check2(nil, goaly - 1,
        dynamic_filter,
        nil, kbody.y - 1, nil, kbody.h + 2
    )

    if col.n > 0 then
        for i = 1, col.n do
            local bd

            ---@type JM.Physics.Body
            bd = col.items[i]

            bd:refresh(nil, bd.y + col.diff_y)
            bd.speed_y = 0.0

            local col_bd
            col_bd = bd:check(nil, nil, function(obj, item)
                return item ~= kbody and colliders_filter(obj, item)
            end)

            if col_bd.n > 0 then
                if col.diff_y > 0 then
                    bd:refresh(nil, col_bd.top - bd.h - 0.1)
                end
            end

            col_bd = nil
            bd = nil
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
local Body = {}
do
    ---@return JM.Physics.Body
    function Body:new(x, y, w, h, type_, world, id)
        local obj = {}
        setmetatable(obj, self)
        self.__index = self

        Body.__constructor__(obj, x, y, w, h, type_, world, id)
        return obj
    end

    ---@param world JM.Physics.World
    ---@param type_ JM.Physics.BodyTypes
    function Body:__constructor__(x, y, w, h, type_, world, id)

        self.type = type_
        ---@type string
        self.id = id or ""
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
        self.over_speed_dacc_x = self.dacc_x
        self.over_speed_dacc_y = self.dacc_x

        self.force_x = 0.0
        self.force_y = 0.0

        -- used if body is static or kinematic
        self.resistance_x = 1

        ---@type JM.Physics.Body|JM.Physics.Slope
        self.ground = nil -- used if body is not static

        -- some properties
        self.bouncing_y = nil -- need to be a number between 0 and 1
        self.bouncing_x = nil
        self.__remove = nil
        self.is_stucked = nil

        self.allowed_air_dacc = false
        self.allowed_gravity = true
        self.allowed_speed_y_restriction = true

        self.shape = BodyShapes.rectangle

        -- TODO
        self.hit_boxes = nil
        self.hurt_boxes = nil

        self.events = {}

        self:extra_collisor_filter(default_filter)
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

    ---@alias JM.Physics.EventNames "ground_touch"|"ceil_touch"|"wall_left_touch"|"wall_right_touch"|"axis_x_collision"|"axis_y_collision"|"start_falling"|"speed_y_change_direction"|"speed_x_change_direction"|"leaving_ground"|"leaving_ceil"|"leaving_y_axis_body"|"leaving_wall_left"|"leaving_wall_right"|"leaving_x_axis_body"

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

    function Body:remove_extra_filter()
        self:extra_collisor_filter(default_filter)
    end

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

    function Body:extra_collisor_filter(filter)
        self.extra_filter = filter
    end

    --- Makes the body jump in the air.
    ---@param desired_height number
    ---@param direction -1|1|nil
    function Body:jump(desired_height, direction)
        -- if self.speed_y ~= 0 then return end

        -- do
        --     local r = self:check(nil, self.y + 1, colliders_filter)
        --     if r.n <= 0 then
        --         return
        --     end
        -- end

        direction = direction or -1
        self.y = self.y - 0.05
        self.speed_y = sqrt(2.0 * self:weight() * desired_height) * direction
    end

    function Body:dash(desired_distance, direction)
        direction = direction or self:direction_x()

        self.speed_x = sqrt(2 * abs(self.acc_x) * desired_distance)
            * direction
    end

    function Body:weight()
        return self.world.gravity * (self.mass / self.world.default_mass)
    end

    function Body:refresh(x, y, w, h)
        x = x or self.x
        y = y or self.y
        w = w or self.w
        h = h or self.h

        if x ~= self.x or y ~= self.y or w ~= self.w or h ~= self.h then

            local world
            world = self.world

            local cl1, ct1, cw1, ch1 = world:rect_to_cell(self:rect())
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

            world = nil
            self.x, self.y, self.w, self.h = x, y, w, h
        end
    end

    ---@param body JM.Physics.Body
    ---@param item JM.Physics.Body
    local function collider_condition(body, item, diff_x, diff_y)
        diff_x = diff_x or 0
        diff_y = diff_y or 0

        local cond_y = (diff_y ~= 0
            and (body:right() > item.x and body.x < item:right()))

        local cond_x = (diff_x ~= 0
            and (body:bottom() > item.y and body.y < item:bottom()))

        return (cond_x or cond_y) or (diff_x == 0 and diff_y == 0)
    end

    ---@return JM.Physics.Collisions collisions
    function Body:check(goal_x, goal_y, filter)
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

        local items = self.world:get_items_in_cell_obj(x, y, w, h)

        ---@type JM.Physics.Collisions
        local collisions = {}

        local col_items = {}
        local n_collisions, has_slope = 0, nil
        local most_left, most_right
        local most_up, most_bottom

        for item, _ in pairs(items) do
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

                and self.extra_filter(self, item)
            then
                table_insert(col_items, item)

                if not has_slope then
                    has_slope = item.is_slope and item or nil
                end

                n_collisions = n_collisions + 1

                most_left = most_left or item
                most_left = ((item.x < most_left.x or item.is_slope) and item) or most_left

                most_right = most_right or item
                most_right = ((item.x + item.w)
                    > (most_right.x + most_right.w) and item)
                    or most_left

                most_up = most_up or item
                most_up = ((item.y < most_up.y or item.is_slope) and item) or most_up

                most_bottom = most_bottom or item
                most_bottom = ((item.y + item.h)
                    > (most_bottom.y + most_bottom.h) and item)
                    or most_bottom

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

        local offset = 0.05

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

    ---@param acc_x number|nil
    ---@param acc_y number|nil
    ---@param body JM.Physics.Body|nil
    function Body:apply_force(acc_x, acc_y, body)
        self.force_x = self.force_x + ((acc_x or 0.0) * self.mass)
        self.force_y = self.force_y + ((acc_y or 0.0) * self.mass)

        self.acc_x = acc_x and (self.force_x / self.mass) or self.acc_x
        self.acc_y = acc_y and (self.force_y / self.mass) or self.acc_y
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
                self.speed_y = 0.0
            end

            dispatch_event(self, BodyEvents.axis_y_collision)

            if col.diff_y >= 0 then -- body hit the floor/ground

                if not self.ground then
                    dispatch_event(self, BodyEvents.ground_touch)
                end

                self.ground = col.most_up

                if self.ground.is_slope then
                    self.y = self.ground:get_y(self:rect()) - self.h
                end

            else -- body hit the ceil

                if not self.ceil then
                    dispatch_event(self, BodyEvents.ceil_touch)
                end

                self.speed_y = 0.1

                self.ceil = col.most_bottom
            end
        end
    end

    ---@param col JM.Physics.Collisions
    function Body:resolve_collisions_x(col)

        if col.n > 0 then

            if col.has_slope then

                local n = #(col.items)
                local final_x, final_y
                local slope = col.has_slope

                for i = 1, n do
                    ---@type JM.Physics.Body|JM.Physics.Slope
                    local bd = col.items[i]

                    if bd.is_slope then
                        local temp = bd.is_floor and (-self.h - 0.05) or (0.05)
                        slope = bd
                        final_x = col.goal_x
                        final_y = bd:get_y(col.goal_x, self.y, self.w, self.h) + temp

                    elseif is_kinematic(bd) then
                        if col.diff_x < 0 then
                            final_x = bd:right() + 0.05
                        else
                            final_x = bd:left() - 0.05
                        end
                    end
                end

                self:refresh(final_x, final_y)
                goto end_function
            end


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
        ::end_function::
    end

    function Body:update(dt)
        local obj
        obj = self

        if is_dynamic(obj) or is_kinematic(obj)
            or obj.type == BodyTypes.ghost
        then

            local goalx, goaly

            -- applying the gravity
            if obj.allowed_gravity then
                obj:apply_force(nil, obj:weight())
            end

            -- falling
            if (obj.acc_y ~= 0.0) or (obj.speed_y ~= 0.0) then
                local last_sy = obj.speed_y

                goaly = obj.y + (obj.speed_y * dt)
                    + (obj.acc_y * dt * dt) / 2.0

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

                -- executing the "speed_y_change_direction" event
                if last_sy < 0.0 and obj.speed_y > 0.0
                    or (last_sy > 0.0 and obj.speed_y < 0.0)
                then
                    dispatch_event(obj, BodyEvents.speed_y_change_direction)
                end

                if obj.type == BodyTypes.ghost then
                    obj:refresh(nil, goaly)
                    goto skip_collision_y
                end

                ---@type JM.Physics.Collisions
                local col = obj:check(nil, goaly, colliders_filter)

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

                    if is_kinematic(obj) then
                        kinematic_moves_dynamic_y(obj, goaly)
                    end

                    obj:refresh(nil, goaly)
                end

                if last_sy <= 0.0 and obj.speed_y > 0.0 then
                    dispatch_event(self, BodyEvents.start_falling)
                end
                ::skip_collision_y::
            end
            --=================================================================

            -- moving in x axis
            if (obj.acc_x ~= 0.0) or (obj.speed_x ~= 0.0) then
                local last_sx = obj.speed_x

                goalx = obj.x + (obj.speed_x * dt)
                    + (obj.acc_x * dt * dt) / 2.0

                -- obj.acc_x = obj.ground and obj.acc_x * 0.5 or obj.acc_x
                obj.speed_x = obj.speed_x + obj.acc_x * dt

                -- if reach max speed
                if obj.max_speed_x
                    and abs(obj.speed_x) > obj.max_speed_x
                then
                    obj.speed_x = obj.max_speed_x
                        * obj:direction_x()
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
                    goto skip_collision_x
                end

                --- will store the body collisions with other bodies
                local col

                ---@type JM.Physics.Collisions
                col = obj:check(goalx, nil, colliders_filter)

                if col.n > 0 then -- had collision!

                    obj:resolve_collisions_x(col)

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

                col = nil

                -- simulating the enviroment resistence (friction)
                if obj.speed_x ~= 0.0
                    and (obj.ground or obj.allowed_air_dacc)
                then
                    local dacc = abs(obj.dacc_x)
                    -- dacc = obj.ground and dacc * 0.3 or dacc
                    obj:apply_force(dacc * -obj:direction_x())
                end

                ::skip_collision_x::

            end -- end moving in x axis

            obj.force_x = 0.0
            obj.force_y = 0.0

        end --end if body is dynamic

        obj = nil
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
            love.graphics.setColor(0.1, 0.4, 0.5)
            love.graphics.rectangle("fill", self:rect())
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", self:rect())
        end
    end
end
--=============================================================================

---@class JM.Physics.Slope: JM.Physics.Body
local Slope = {}
setmetatable(Slope, Body)

---@alias JM.Physics.SlopeType "floor"|"ceil"

---@return JM.Physics.Body|JM.Physics.Slope
function Slope:new(x, y, w, h, world, direction, slope_type)
    local obj = Body:new(x, y, w, h, BodyTypes.static, world, "")
    self.__index = self
    setmetatable(obj, self)
    Slope.__constructor__(obj, direction, slope_type)

    return obj
end

function Slope:__constructor__(direction, slope_type)

    self.shape = BodyShapes.slope
    self.is_slope = true

    self.normal_direction = true
    self.is_floor = true
    self.resistance_x = 0.7
end

function Slope:point_left()
    local x, y

    if self.normal_direction then
        y, x = self:bottom_left()
    else
        y, x = self:top_left()
    end
    return x, y
end

function Slope:point_right()
    local x, y

    if self.normal_direction then
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
    if x and w then
        if self.is_floor then
            px = (self.normal_direction and x + w) or x
        else
            px = (self.normal_direction and x) or x + w
        end
    end

    if y and h then
        py = (self.is_floor and (y + h)) or y
        py = -py
    end

    -- do
    --     return x + w / 2.0, py
    -- end
    return px, py
end

function Slope:check_up_down(x, y, w, h)
    local px, py = self:get_coll_point(x, y, w, h)
    return py <= self:A() * px + self:B() and "down" or "up"
end

function Slope:check_collision(x, y, w, h)
    do
        local rec_col = collision_rect(
            self.x, self.y - 5, self.w, self.h + 10,
            x, y, w, h
        )
        if not rec_col then return false end
    end

    local up_or_down = self:check_up_down(x, y, w, h)

    return (self.is_floor and up_or_down == "down")
        or ((not self.is_floor) and up_or_down == "up")
end

function Slope:get_y(x, y, w, h)
    x, y = self:get_coll_point(x, y, w, h)
    y = -y
    local py = -(self:A() * x + self:B())
    py = (py < self.y and self.y) or py
    py = (py > self:bottom() and self:bottom()) or py

    return py
end

function Slope:draw()
    local x1, y1 = self:point_left()
    local x2, y2 = self:point_right()

    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.line(x1, y1, x2, y2)

    love.graphics.setColor(0.3, 1, 0.3, 0.5)

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
end

--=============================================================================

---@class JM.Physics.World
local World = {}
do
    function World:new(args)
        local obj = {}
        setmetatable(obj, self)
        self.__index = self

        World.__constructor__(obj, args)
        return obj
    end

    function World:__constructor__(args)
        self.tile = 32
        self.cellsize = self.tile * 2

        self.meter = self.tile * 3.5
        self.gravity = 9.8 * self.meter
        self.max_speed_y = self.meter * 15.0
        self.max_speed_x = self.max_speed_y
        self.default_mass = 65.0

        self.bodies = {}
        self.bodies_number = 0

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
        self.grid[cy] = self.grid[cy] or setmetatable({}, { __mode = 'v' })
        local row = self.grid[cy]

        row[cx] = row[cx] or { count = 0, x = cx, y = cy, items = setmetatable({}, { __mode = 'k' }) }
        local cell = row[cx]
        self.non_empty_cells[cell] = true

        if not cell.items[obj] then
            cell.items[obj] = true
            cell.count = cell.count + 1
        end
    end

    function World:remove_obj_from_cell(obj, cx, cy)
        local row = self.grid[cy]
        if not row or not row[cx] or not row[cx].items[obj] then return end

        local cell

        ---@type JM.Physics.Cell
        cell = row[cx]
        cell.items[obj] = nil
        cell.count = cell.count - 1

        if cell.count == 0 then
            self.non_empty_cells[cell] = nil
            -- cell.items = nil
            -- self.grid[cy][cx] = nil
        end
        -- row = nil
        -- cell = nil
        return true
    end

    ---@param x number
    ---@param y number
    ---@param w number
    ---@param h number
    function World:get_items_in_cell_obj(x, y, w, h)
        local cl, ct, cw, ch = self:rect_to_cell(x, y, w, h)
        local items = {}

        for cy = ct, (ct + ch - 1) do
            local row = self.grid[cy]

            if row then
                for cx = cl, (cl + cw - 1) do
                    local cell
                    ---@type JM.Physics.Cell
                    cell = row[cx]

                    if cell and cell.count > 0 then
                        for item, _ in pairs(cell.items) do
                            items[item] = true
                        end
                    end

                    cell = nil

                end -- End For Columns
            end
        end -- End for rows

        return items
    end

    ---@param obj JM.Physics.Body
    function World:add(obj)
        table_insert(self.bodies, obj)
        self.bodies_number = self.bodies_number + 1

        local cl, ct, cw, ch = self:rect_to_cell(obj:rect())

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

            local cl, ct, cw, ch = self:rect_to_cell(obj:rect())

            for cy = ct, (ct + ch - 1) do
                for cx = cl, (cl + cw - 1) do
                    self:remove_obj_from_cell(obj, cx, cy)
                end
            end
        end
        r = nil
    end

    function World:update(dt)

        for i = self.bodies_number, 1, -1 do
            local obj

            ---@type JM.Physics.Body
            obj = self.bodies[i]

            if obj.__remove then
                self:remove(obj, i)
                obj = nil
            end

            if obj and obj.is_stucked then
                obj = nil
            end

            if obj and obj.is_enabled then
                obj:update(dt)
            end

            obj = nil
        end
    end

    function World:draw()
        for i = 1, self.bodies_number do
            ---@type JM.Physics.Body|JM.Physics.Slope
            local obj = self.bodies[i]

            local r = obj.draw and obj:draw()
        end
    end

    -- ---@param obj JM.Physics.Body
    -- function World:check(obj)
    --     -- local cl, ct, cw, ch = self:rect_to_cell(obj:rect())
    --     local items = self:get_items_in_cell_obj(obj:rect())

    --     for item, _ in pairs(items) do
    --         if item ~= obj and not item.__remove and obj:check_collision(item) then
    --             return item
    --         end
    --     end
    -- end

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
---@param type_ "dynamic"|"kinematic"|"static"|"ghost"
---@return JM.Physics.Body
function Phys:newBody(world, x, y, w, h, type_)

    local bd_type = BodyTypes[type_] or BodyTypes.static

    local b = Body:new(x, y, w, h, bd_type, world)

    world:add(b)

    return b
end

---@return JM.Physics.Body|JM.Physics.Slope
function Phys:newSlope(world, x, y, w, h, slope_type)
    local slope = Slope:new(x, y, w, h, world, "normal", "floor")
    world:add(slope)
    return slope
end

Phys.collision_rect = collision_rect

return Phys
