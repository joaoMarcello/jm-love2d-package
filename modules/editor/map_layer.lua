local TileMap = JM.TileMap
local GC = JM.GameObject

---@enum JM.MapLayer.Types
local LayerTypes = {
    static = 1,
    only_fall = 2,
    ghost = 3,
    free = 4,
    object = 5,
}

local TileMaps = {
    "/data/img/tileset-game.png",
    "/data/img/tileset-game2.png",
}

local ColliderTilemaps = {
    "/data/img/tilemap-collider.png",
    "/data/img/tilemap-collider2.png",
}

---@type JM.GameMap
local game_map

local layer_count = 1
local tile_size = 16

---@class JM.MapLayer
local Layer = {
    Types = LayerTypes,
    LayerCount = layer_count,
    TileMapsDir = TileMaps,
    ColliderTileDir = ColliderTilemaps,
}
Layer.__index = Layer

---@param gameMap JM.GameMap|nil
function Layer:init_module(gameMap, tileSize, layerCount)
    game_map = gameMap or game_map
    tile_size = tileSize or tile_size
    layer_count = layerCount or layer_count
end

local generic = function() end


---@return JM.MapLayer
function Layer:new(args)
    local o = setmetatable({}, Layer)
    Layer.__constructor__(o, args or {})
    return o
end

function Layer:__constructor__(args)
    self.type = args.type or LayerTypes.static

    if args.map then
        args.data = loadstring(args.map)
    end

    self.tilemap = TileMap:new(args.data or generic,
        self.type == LayerTypes.only_fall and ColliderTilemaps[2]
        or ColliderTilemaps[1],
        args.tile_size or tile_size
    )

    self.tilemap_number = args.tilemap_number or 1
    self.out_tilemap = TileMap:new(generic, TileMaps[self.tilemap_number], args.tile_size or tile_size)

    self.name = args.name or string.format("layer_%02d", layer_count)
    self.world_number = args.world_number or 1

    self.factor_x = args.factor_x or 1
    self.factor_y = args.factor_y or 1
    self.is_fixed = args.is_fixed or false

    self.show_auto_tilemap = false

    layer_count = layer_count + 1
end

function Layer:load()

end

function Layer:finish()

end

function Layer:move(dx, dy)
    dx = dx or 0
    dy = dy or 0
    dx = math.floor(dx / tile_size) * tile_size
    dy = math.floor(dy / tile_size) * tile_size
    if dx == 0 and dy == 0 then return false end

    local tilemap = self.tilemap
    local cells_by_pos = {}

    for k, v in pairs(tilemap.cells_by_pos) do
        local x, y = tilemap:index_to_x_y(k)
        local id = v
        cells_by_pos[tilemap:get_index(x + dx, y + dy)] = id
    end

    tilemap.cells_by_pos = cells_by_pos
    tilemap.min_x = tilemap.min_x + dx
    tilemap.max_x = tilemap.max_x + dx
    tilemap.min_y = tilemap.min_y + dy
    tilemap.max_y = tilemap.max_y + dy

    tilemap.__bound_left = nil
    tilemap.last_index_left = nil
    return true
end

function Layer:get_min_max_x()
    return self.tilemap.min_x, self.tilemap.max_x
end

function Layer:get_min_max_y()
    return self.tilemap.min_y, self.tilemap.max_y
end

function Layer:tile_top(x, y)
    local tilemap = self.tilemap
    return tilemap.cells_by_pos[tilemap:get_index(x, y - tilemap.tile_size)]
end

function Layer:tile_bottom(x, y)
    local tilemap = self.tilemap
    return tilemap.cells_by_pos[tilemap:get_index(x, y + tilemap.tile_size)]
end

function Layer:tile_left(x, y)
    local tilemap = self.tilemap
    return tilemap.cells_by_pos[tilemap:get_index(x - tilemap.tile_size, y)]
end

function Layer:tile_right(x, y)
    local tilemap = self.tilemap
    return tilemap.cells_by_pos[tilemap:get_index(x + tilemap.tile_size, y)]
end

function Layer:tile_top_left(x, y)
    local tilemap = self.tilemap
    local t = tilemap.tile_size
    return tilemap.cells_by_pos[tilemap:get_index(x - t, y - t)]
end

function Layer:tile_top_right(x, y)
    local tilemap = self.tilemap
    local t = tilemap.tile_size
    return tilemap.cells_by_pos[tilemap:get_index(x + t, y - t)]
end

function Layer:tile_bottom_left(x, y)
    local tilemap = self.tilemap
    local t = tilemap.tile_size
    return tilemap.cells_by_pos[tilemap:get_index(x - t, y + t)]
end

function Layer:tile_bottom_right(x, y)
    local tilemap = self.tilemap
    local t = tilemap.tile_size
    return tilemap.cells_by_pos[tilemap:get_index(x + t, y + t)]
end

function Layer:tilemap_tostring()
    local map = self.tilemap
    local block_id = game_map.pieces["block-1x1"].tiles[1][1]
    local str_format = string.format
    local tile = map.tile_size

    local f = [[local e=function(x,y,id) return Entry(x*tile,y*tile,id or %d) end]]

    f = str_format(f, block_id)

    local j = map.min_y
    -- for j = map.min_y, map.max_y, tile do
    while j <= map.max_y do
        ---
        -- for i = map.min_x, map.max_x, tile do
        local i = map.min_x

        while i <= map.max_x do
            local index = map:get_index(i, j)
            local id = map.cells_by_pos[index]

            if id then
                local line
                local x = i / tile
                local y = j / tile

                if id == block_id then
                    local nx = 1
                    -- counting block tiles
                    for k = i + tile, map.max_x, tile do
                        local index_ = map:get_index(k, j)
                        local id_ = map.cells_by_pos[index_]
                        if id_ and id_ == block_id then
                            nx = nx + 1
                        else
                            break
                        end
                    end

                    if nx > 1 then
                        line =
                            str_format(
                                "for i=0,%d do e(%d+i,%d)end",
                                nx - 1, x, y)

                        i = i + (tile * nx) - tile
                    else
                        line = str_format("e(%d,%d)", x, y)
                    end
                else
                    line = str_format("e(%d,%d,%d)", x, y, id)
                end

                f = str_format("%s\n%s", f, line)
            end

            i = i + tile
        end

        j = j + tile
    end

    return f
end

function Layer:tilemap_tostring_v2()
    local map = self.tilemap
    local block_id = game_map.pieces["block-1x1"].tiles[1][1]
    local str_format = string.format
    local tile = map.tile_size

    local f = [[local e=function(x,y,id) return Entry(x*tile,y*tile,id or %d) end]]

    f = str_format(f, block_id)

    local mapped = {}
    local others = {}

    for j = map.min_y, map.max_y, tile do
        for i = map.min_x, map.max_x, tile do
            ---
            local index = map:get_index(i, j)
            local id = map.cells_by_pos[index]

            if id and not mapped[index] then
                local line --- string
                local x = i / tile
                local y = j / tile


                if id == block_id then
                    local w = tile
                    local h = tile

                    for _i_ = i + tile, map.max_x, tile do
                        local index_ = map:get_index(_i_, j)
                        local _id_ = map.cells_by_pos[index_]

                        if not mapped[index_] and _id_ == block_id then
                            w = w + tile
                        else
                            break
                        end
                    end

                    local min_h = math.huge

                    for _i_ = i, i + w - 1, tile do
                        --
                        local column_h = tile

                        for _j_ = j + tile, map.max_y, tile do
                            --
                            local index_ = map:get_index(_i_, _j_)
                            local _id_ = map.cells_by_pos[index_]

                            if not mapped[index_] and _id_ == block_id then
                                column_h = column_h + tile
                            else
                                break
                            end
                        end

                        if column_h < min_h and column_h ~= 0 then
                            min_h = column_h
                        end
                    end

                    h = min_h

                    for _j_ = j, j + h - 1, tile do
                        for _i_ = i, i + w - 1, tile do
                            local index_ = map:get_index(_i_, _j_)
                            mapped[index_] = true
                        end
                    end

                    local nx = w / tile
                    local ny = h / tile

                    if nx > 1 and ny > 1 then
                        line = str_format("for j=0,%d do for i=0,%d do e(%d+i,%d+j)end end", ny - 1, nx - 1, x, y)
                        ---
                    elseif nx > 1 then
                        line = str_format("for i=0,%d do e(%d+i,%d)end", nx - 1, x, y)
                        ---
                    elseif ny > 1 then
                        line = str_format("for j=0,%d do e(%d,%d+j)end", ny - 1, x, y)
                        ---
                    else
                        line = str_format("e(%d,%d)", x, y)
                    end
                else
                    others[id] = others[id] or {}
                    table.insert(others[id], x)
                    table.insert(others[id], y)

                    -- line = str_format("e(%d,%d,%d)", x, y, id)
                    mapped[index] = true
                end

                if line then
                    f = str_format("%s\n%s", f, line)
                end
            end
        end
    end

    local serialize = function(t, n)
        n = n or #t
        local r = "{"

        for i = 1, n do
            if i == n then
                r = str_format("%s%d", r, t[i])
            else
                r = str_format("%s%d,", r, t[i])
            end
        end

        return str_format("%s}", r)
    end

    local add_func = false

    for id, t in next, others do
        local line
        local n = #t

        if n <= (1 * 2) then -- only one tile from this type of id
            -- line = ""
            for i = 1, n, 2 do
                local x, y = t[i], t[i + 1]
                -- line = line .. str_format("e(%d,%d,%d);", x, y, id)
                line = str_format("e(%d,%d,%d)", x, y, id)
            end
        else
            if not add_func then
                local ff = [[local F=function(t,n,D)for i=1,n,2 do e(t[i],t[i+1],D)end end]]

                f = str_format("%s\n%s", f, ff)
                add_func = true
            end

            line = str_format([[F(%s,%d,%d)]],
                serialize(t, n),
                n,
                id
            )
        end

        f = str_format("%s\n%s", f, line)
    end

    return f
end

function Layer:output_map_tostring()
    local map = self.out_tilemap
    local str_format = string.format
    local tile = map.tile_size

    local f = [[local e=function(x,y,id) return Entry(x*tile_size,y*tile_size,id) end]]

    -- for j = map.min_y, map.max_y, tile do
    local j = map.min_x
    while j <= map.max_y do
        ---
        -- for i = map.min_x, map.max_x, tile do
        local i = map.min_x
        while i <= map.max_x do
            local index = map:get_index(i, j)
            local id = map.cells_by_pos[index]

            if id then
                local x = i / tile
                local y = j / tile

                local line = str_format("e(%d,%d,%d)", x, y, id)
                f = str_format("%s\n%s", f, line)
            end

            i = i + tile
        end

        j = j + tile
    end

    return f
end

---@alias JM.MapLayer.SaveData {map:string, name:string, type:JM.MapLayer.Types, tile_size:number}

---@return JM.MapLayer.SaveData savedata
function Layer:get_save_data()
    return {
        name           = self.name,
        type           = self.type,
        -- tile_size    = self.tilemap.tile_size,
        world_number   = self.world_number,
        factor_x       = self.factor_x,
        factor_y       = self.factor_y,
        tilemap_number = self.tilemap_number,
        map            = self:tilemap_tostring_v2(),
    }
end

function Layer:set_opacity(value)
    value = value or 1
    if self.tilemap then
        self.tilemap.color[4] = value
    end
    self.out_tilemap.color[4] = value
end

---@param camera JM.Camera.Camera
function Layer:draw_no_factor(camera)
    if self.show_auto_tilemap then
        self.out_tilemap:draw(camera)
    else
        self.tilemap:draw(camera)
    end
end

---@param cam JM.Camera.Camera
function Layer:draw(cam)
    local cx, cy = cam.x, cam.y
    local sc = cam.scale

    cam:set_position(cx * self.factor_x, cy * self.factor_y)

    -- cam:attach(nil, GC.gamestate.subpixel)

    if self.show_auto_tilemap then
        self.out_tilemap:draw(cam)
    else
        self.tilemap:draw(cam)
    end

    -- cam:detach()

    cam.x = cx
    cam.y = cy
    cam.scale = sc
end

return Layer
