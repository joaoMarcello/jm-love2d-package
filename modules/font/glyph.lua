local lgx = love.graphics
local lgx_draw = lgx.draw
local lgx_rect = lgx.rectangle
local lgx_setColor = lgx.setColor

---@type JM.Template.Affectable
local Affectable = _G.JM_Affectable

local Quads = setmetatable({}, { __mode = 'k' })

---@class JM.Font.Glyph: JM.Template.Affectable
---@field x number
local Glyph = setmetatable({}, Affectable)
Glyph.__index = Glyph

---@param img love.Image|nil
---@return JM.Font.Glyph
function Glyph:new(img, args)
    -- local obj = Affectable:new(self.__glyph_draw__)
    local obj = Affectable:new()
    setmetatable(obj, self)

    Glyph.__constructor__(obj, img, args)

    return obj
end

function Glyph:__constructor__(img, args)
    self.img = img
    self.id = args.id or ""

    self.x = args.x
    self.y = args.y
    self.w = args.w
    self.h = args.h

    self.qx = self.x
    self.qy = self.y
    self.qw = self.w
    self.qh = self.h

    -- self.bbox_x = args.bbox_x or self.x
    -- self.bbox_w = args.bbox_w or self.w

    self.sy = args.sy or 1
    self.sx = self.sy

    self.format = args.format or 1

    -- self.__args = args

    if self.img then
        self.key = string.format("%d-%d-%d-%d", self.x, self.y, self.w, self.h)

        if not Quads[self.img] then
            Quads[self.img] = {}
        end

        if not Quads[self.img][self.key] then
            Quads[self.img][self.key] = lgx.newQuad(
                self.x, self.y,
                self.w, self.h,
                self.img:getDimensions()
            )
        end
    end

    if self.y and self.h then
        self.bottom = args.bottom or (self.y + self.h)
        self.offset_y = args.bottom and (self.y + self.h - self.bottom) or 0
        self.h = self.h - self.offset_y
    else
        self.bottom = nil
        self.offset_y = nil
    end

    -- if self.x and self.w then
    --     self.right = args.right or (self.x + self.w)
    --     self.offset_x = args.right and (self.x + self.w - self.right) or 0
    --     self.w = self.w - self.offset_x
    -- end

    ---@type JM.Anima
    self.__anima = args.anima

    -- self.color = { 1, 0, 0, 1 }
    self:set_color2(1, 1, 1, 1)

    self.ox = (self.w) * 0.5 --* self.sx
    self.oy = (self.h) * 0.5 --* self.sy

    -- self.bounds = { left = 0, top = 0, right = love.graphics.getWidth(), bottom = love.graphics.getHeight() }

    self.quad = self:get_quad()

    self.update = Glyph.update
    self.draw = Glyph.draw
    self.set_color = Glyph.set_color
    self.set_color2 = Glyph.set_color2
    self.set_scale = Glyph.set_scale
    -- self.__glyph_draw__ = Glyph.__glyph_draw__
end

function Glyph:update(dt)
    if self.__anima then
        self.__anima:update(dt)
    end

    self.__effect_manager:update(dt)
end

function Glyph:get_width()
    return self.w * self.sx
end

function Glyph:get_height()
    return self.h * self.sy
end

local tab_cpy = {}
function Glyph:copy()
    -- local obj = Glyph:new(self.img, self.__args)

    -- if obj.__anima then
    --     obj.__anima = obj.__anima:copy()
    -- end
    -- return obj

    tab_cpy.id = self.id
    tab_cpy.x = self.qx
    tab_cpy.y = self.qy
    tab_cpy.w = self.qw
    tab_cpy.h = self.qh
    tab_cpy.bottom = self.bottom
    tab_cpy.sy = self.sy
    tab_cpy.format = self.format

    local obj = Glyph:new(self.img, tab_cpy)

    if self.__anima then
        obj.__anima = self.__anima:copy()
    end

    return obj
end

---@param value JM.Color
function Glyph:set_color(value)
    self.color = Affectable.set_color(self, value)

    if self.__anima then
        self.__anima:set_color(self.color)
    end
end

function Glyph:set_color2(r, g, b, a)
    Affectable.set_color2(self, r, g, b, a)

    if self.__anima then
        self.__anima:set_color2(r, g, b, a)
    end
end

---@param value number|nil
function Glyph:set_scale(value)
    self.sy = value or self.sy
    self.sx = self.sy

    self.ox = self.w * 0.5 * self.sx
    self.oy = self.h * 0.5 * self.sy

    -- if self:is_animated() then
    --     self.__anima:set_scale({ x = self.sx, y = self.sy })
    -- end
end

function Glyph:is_animated()
    return self.__anima and true or false
end

---@param self JM.Font.Glyph
local function __glyph_draw__(self)
    -- if self.__id == "__nule__" then return end

    if not self.is_visible then return end
    local x, y = self.x + self.ox * self.sx, self.y + self.oy * self.sy

    if self.__anima then
        -- self.__anima:set_color(self.color)
        -- self.__anima:draw(x - self.ox * self.sx, y - self.oy * self.sy)
        self.__anima:draw(x, y)
        --
    elseif not self.img then
        lgx_setColor(0, 0, 0, 0.2)
        lgx_rect("fill", x, y,
            self.w * self.sx,
            self.h * self.sy
        )
    elseif self.id ~= "\t" and self.id ~= " " then
        lgx_setColor(self.color)

        lgx_draw(self.img, self.quad, x, y, 0, self.sx, self.sy, self.ox, self.oy)
    end

    -- if self.w and self.h then
    --     love.graphics.setColor(0, 0, 0, 0.4)
    --     love.graphics.rectangle("line", x - self.ox * self.sx, y - self.oy * self.sy, self.w * self.sx, self.h * self.sy)
    -- end

    -- love.graphics.setColor(0, 0, 0, 0.4)
    -- love.graphics.rectangle("line",
    --     x,
    --     y,
    --     self.w * self.sx,
    --     self.h * self.sy
    -- )
end

-- local floor = math.floor
---@param x number
---@param y number
function Glyph:draw(x, y)
    self.x, self.y = x, y
    -- self.x, self.y = floor(x + 0.5), floor(y + 0.5)
    return Affectable.draw(self, __glyph_draw__)
end

-- function Glyph:draw_rec(x, y, w, h)
--     --local eff_t = self:__get_effect_transform()

--     x = x + w / 2
--     y = y + h
--         - self.h * self.sy  --* (eff_t and eff_t.sy or 1)
--         + self.oy * self.sy -- * (eff_t and eff_t.sy or 1)

--     self:draw(x, y)

--     return x, y
-- end



-- function Glyph:get_pos_draw_rec(x, y, w, h)
--     x = x + w / 2
--     y = y + h - self.h * self.sy + self.oy * self.sy
--     return x, y
-- end

function Glyph:get_quad()
    if self.id ~= "\t" and self.id ~= " " and self.is_visible then
        return Quads[self.img] and Quads[self.img][self.key] or nil
    end
end

return Glyph
