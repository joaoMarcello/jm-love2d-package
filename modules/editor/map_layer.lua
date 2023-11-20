local TileMap = JM.TileMap
local GC = JM.GameObject

---@enum JM.MapLayer.Types
local LayerTypes = {
    static = 1,
    only_fall = 2,
    ghost = 3,
}

---@class JM.MapLayer
local Layer = {
    Types = LayerTypes,
}
Layer.__index = Layer

local generic = function() end

local layer_count = 1

---@return JM.MapLayer
function Layer:new(args)
    local o = setmetatable({}, Layer)
    Layer.__constructor__(o, args or {})
    return o
end

function Layer:__constructor__(args)
    self.tilemap = TileMap:new(generic, "/data/img/tilemap-collider.png", args.tile_size or 16)
    self.type = args.type or LayerTypes.static
    self.name = args.name or string.format("layer_%02d", layer_count)
    self.gamestate = GC.gamestate

    layer_count = layer_count + 1
end

function Layer:load()

end

function Layer:finish()

end

return Layer
