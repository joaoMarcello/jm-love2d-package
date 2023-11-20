local Utils = JM.Utils

--==========================================================================
---@type JM.TileMap
local tilemap

---@type JM.TileSet
local tileset

local tile_size = 16
--==========================================================================
---@enum JM.MapPiece.States
local States = {
    free = 1,
    occupied = 2,
}
--==========================================================================
---@class JM.MapPiece
local Piece = {}
Piece.__index = Piece
Piece.States = States

---@param tilemap_ JM.TileMap
function Piece:init_module(tilemap_)
    tilemap = tilemap_
    tileset = tilemap.tile_set
    tile_size = tilemap.tile_size
end

---@return JM.MapPiece
function Piece:new(args)
    local obj = {}
    setmetatable(obj, self)
    Piece.__constructor__(obj, args or {})
    return obj
end

function Piece:__constructor__(args)
    local tiles = args.tiles
    local w = 0
    local h = 0
    for i = 1, #tiles do
        local list = tiles[i]
        local n_list = #list
        w = n_list > w and n_list or w

        for j = 1, n_list do

        end

        h = h + 1
    end

    self.tiles = args.tiles
    self.x = args.x or 0
    self.y = args.y or 0
    -- self.w = w --(tile_size * w)
    -- self.h = h --(tile_size * h)
    self.is_visible = true
    self.state = States.free
end

function Piece:insert()
    if self.state == States.occupied then return end

    local px = self.x
    local py = self.y

    for i = 1, #self.tiles do
        local list = self.tiles[i]

        for j = 1, #list do
            tilemap:insert_tile(px, py, list[j])
            px = px + tile_size
        end

        px = self.x
        py = py + tile_size
    end
end

function Piece:remove()

end

function Piece:update(dt)
    local free = true

    local px = self.x
    local py = self.y

    -- local tilemap = self.tilemap
    -- local tile_size = self.tile_size

    for i = 1, #self.tiles do
        local list = self.tiles[i]

        for j = 1, #list do
            if tilemap.cells_by_pos[tilemap:get_index(px, py)] then
                free = false
                break
            end
            px = px + tile_size
        end

        if not free then
            break
        end

        px = self.x
        py = py + tile_size
    end

    if not free then
        self.state = States.occupied
    else
        self.state = States.free
    end
end

function Piece:draw()
    if not self.is_visible then return end

    local px = self.x
    local py = self.y

    local color = self.state == States.occupied and Utils:get_rgba(1, 0, 0)
    -- local tileset = self.tileset
    -- local tile_size = self.tile_size

    for i = 1, #self.tiles do
        local line = self.tiles[i]

        for j = 1, #line do
            local tile = tileset:get_tile(line[j])
            if tile then
                tile:draw(px, py, color)
            end
            px = px + tile_size
        end

        px = self.x
        py = py + tile_size
    end
end

return Piece
