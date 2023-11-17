---@type JM.EffectManager
local EffectManager = require((...):gsub("font.Word", "jm_effect_manager"))

---@class JM.Font.Word
local Word = {
    eff_wave_range = 2,
    eff_scream_range_x = 1,
    eff_scream_range_y = 2,
}
Word.__index = Word

---@param args {text: string, font: JM.Font.Font, format: JM.Font.FormatOptions}
---@return JM.Font.Word phrase
function Word:new(args)
    local obj = {}
    setmetatable(obj, self)
    -- self.__index = self

    Word.__constructor__(obj, args)

    return obj
end

---@param args {text: string, font: JM.Font.Font, format: JM.Font.FormatOptions}
function Word:__constructor__(args)
    --assert(EffectManager, "\n>Class EffectManager not loaded!")

    self.text = args.text
    self.__font = args.font
    -- self.__args = args

    self.__font_config = self.__font:__get_configuration()

    self.__characters = {}

    -- local format = args.format or self.__font.format_options.normal
    self.font_format = args.format or self.__font.format_options.normal

    self:__load_characters(self.font_format)

    self.__N_characters = #(self.__characters)

    -- self.last_x, self.last_y = math.huge, math.huge

    self.update = Word.update
    self.draw = Word.draw
    self.get_width = Word.get_width
    self.get_height = Word.get_height
end

---@param mode JM.Font.FormatOptions
function Word:__load_characters(mode)
    local last_font_format = self.__font:get_format_mode()

    self.__font:set_format_mode(mode)
    self.__characters = {}

    local iterator = self.__font:get_text_iterator(self.text)

    while (iterator:has_next()) do
        local glyph = iterator:next()

        glyph = glyph:copy()
        glyph:set_color(self.__font.__default_color)

        -- if not glyph.__anima then
        table.insert(self.__characters, glyph)
        -- end

        if glyph:is_animated() then
            glyph:set_color2(1, 1, 1, 1)
            glyph.__anima:set_size(nil, self.__font.__font_size * 1.1, nil, nil)
        end
    end

    self.__font:set_format_mode(last_font_format)
end

---
function Word:copy()
    local args = {
        text = self.text,
        font = self.__font,
        format = self.font_format
    }

    local cpy = Word:new(args)
    return cpy
end

local rad_wave = 0
local fadein_delay = 0

function Word:restaure_effect()
    rad_wave = 0
    fadein_delay = 0
end

---@param startp number|nil
---@param endp number|nil
---@param effect_type string
---@param offset number|nil
function Word:apply_effect(startp, endp, effect_type, offset, eff_args)
    if not startp then startp = 1 end
    if not endp then endp = #self.__characters end
    if not offset then offset = 0 end


    for i = startp, endp, 1 do
        local skip = false
        local eff

        ---@type JM.Font.Glyph
        local glyph = self.__characters[i] --self:__get_char_by_index(i)

        if effect_type == "spooky" then
            eff = EffectManager:generate_effect("float", {
                range = 0.6,
                speed = 0.15,
                rad = math.pi * (i % 4) + offset
            })
        elseif effect_type == "pump" then
            eff = EffectManager:generate_effect("jelly")
        elseif effect_type == "wave" then
            rad_wave = rad_wave - (math.pi * 2 * 0.1)

            if glyph.id == " " then
                skip = true
            else
                eff = EffectManager:generate_effect("float", { range = Word.eff_wave_range, rad = rad_wave, speed = 0.5 })
                -- goto continue
            end
        elseif effect_type == "goddess" then
            glyph:set_color2(nil, nil, nil, 0)
            if eff_args and eff_args.delay then
                eff = EffectManager:generate_effect("fadein", { delay = i * eff_args.delay })
            else
                eff = EffectManager:generate_effect("fadein", { delay = fadein_delay + 0.1 * i })
            end

            if i == endp then
                fadein_delay = fadein_delay + 0.1 * (endp - startp + 1)
            end
        elseif effect_type == "scream" then
            local speed_x = 0.25 --math.random() > 0.5 and 0.3 or 0.4

            eff = EffectManager:generate_effect("earthquake",
                {
                    speed_x = speed_x,
                    speed_y = speed_x,
                    range_x = Word.eff_scream_range_x,
                    range_y = Word.eff_scream_range_y,
                    rad_x = math.random() * math.pi * 2,
                    rad_y = math.random() * math.pi * 2,
                    random = true
                })
        elseif effect_type ~= "pause" then
            eff = EffectManager:generate_effect(effect_type, eff_args)
        end

        if not skip then
            if not eff then break end

            -- if glyph and glyph:is_animated() and false then
            --     eff:apply(glyph.__anima, true)
            -- else
            eff:apply(glyph, true)
            -- end
        end
        -- ::continue::
    end
end

-- function Word:surge_effect(startp, endp, delay)
--     if not startp then startp = 1 end
--     if not endp then endp = #self.__characters end
--     if not delay then delay = 1 end

--     for i = startp, endp, 1 do
--         local eff = EffectManager:generate_effect("fadein", {
--             delay = delay
--         })
--         eff:apply(self.__characters[i])
--         delay = delay + 0.5
--     end
--     return delay
-- end

--- Change the word color
---@param color JM.Color
function Word:set_color(color, startp, endp)
    if not startp then startp = 1 end
    if not endp then endp = self.__N_characters end

    local i = startp
    while (i <= endp) do
        local char_ = self.__characters[i] --self:__get_char_by_index(i)
        if char_ and char_:is_animated() then

        else
            local r = char_ and char_:set_color(color)
        end
        i = i + 1
    end
end

---
function Word:update(dt)
    for i = 1, self.__N_characters, 1 do
        ---@type JM.Font.Glyph
        local char_ = self.__characters[i] --self:__get_char_by_index(i)
        char_:update(dt)
    end
end

---@param index number
---@return JM.Font.Glyph
function Word:__get_char_by_index(index)
    return self.__characters[index]
end

local mt_mode_k = { __mode = 'k' }
Word.WIDTHS = setmetatable({}, mt_mode_k)
---
function Word:get_width()
    local font = self.__font
    -- self.widths = self.widths or {}

    do
        -- local r = self.widths[font.__font_size]
        -- if r then return r end
        local r = Word.WIDTHS[font]
        r = r and r[self.text] or r
        r = r and r[font.__font_size]
        if r then
            return r
        end
    end

    local w = 0
    local N = self.__N_characters --#self.__characters
    local glyphs = self.__characters

    for i = 1, N do
        ---@type JM.Font.Glyph
        local cur_char = glyphs[i] --self:__get_char_by_index(i)

        w = w + (cur_char.w * font.__scale)
            + font.__character_space
    end

    Word.WIDTHS[font] = Word.WIDTHS[font] or setmetatable({}, mt_mode_k)
    Word.WIDTHS[font][self.text] = Word.WIDTHS[font][self.text]
        or {}
    Word.WIDTHS[font][self.text][font.__font_size] = w - font.__character_space

    return Word.WIDTHS[font][self.text][font.__font_size]

    -- self.widths[font.__font_size] = w - font.__character_space
    -- return self.widths[font.__font_size]
end

---
function Word:get_height()
    -- do
    --     -- ---@type JM.Font.Glyph
    --     -- local glyph = self.__characters[1]
    --     -- return
    -- end
    local h = self.__font.__font_size + self.__font.__line_space
    return h
end

---@alias JM.Font.CharacterPosition {x: number, y:number, char: JM.Font.Glyph}

---@param x number
function Word:draw(x, y, __max_char__, __glyph_count__, bottom)
    -- love.graphics.setColor(0.9, 0, 0, 0.15)
    -- love.graphics.rectangle("fill", x, y, self:get_width(), self.__font.__font_size)

    bottom = bottom or (y + self.__font.__font_size)

    local tx = x
    local font = self.__font
    local glyph
    local N = self.__N_characters
    local list_glyphs = self.__characters

    for i = 1, N do
        ---@type JM.Font.Glyph
        glyph = list_glyphs[i]

        glyph:set_color(glyph.color)
        glyph:set_scale(font.__scale)

        if font:is_glyph_xp(glyph) then
            local prop = font.nick_to_glyph_xp[glyph.id]

            glyph:set_color2(1, 1, 1, glyph.color[4])
            local sc = prop.scale or (font.__font_size / glyph.h)
            glyph:set_scale(sc)

            local x = tx
            local y = bottom - glyph.h * sc

            if prop.align == "center" then
                y = bottom - font.__font_size * 0.5 - glyph.h * sc * 0.5
            elseif prop.align == "top" then
                y = bottom - font.__font_size
            end

            if glyph.__anima then
                -- cur_char.__anima:set_color2(1, 1, 1, 0.1)
                glyph.__anima:set_scale(sc, sc)
                -- x = tx + glyph.ox
            end

            glyph:draw(x, y)
            --
        elseif not glyph:is_animated() then
            local px, py
            -- py = bottom - cur_char.h / 2 * cur_char.sy
            -- px = tx + cur_char.w / 2 * cur_char.sx

            py = bottom - glyph.h * glyph.sy
            px = tx
            glyph:draw(px, py)
        else
            glyph.__anima:set_size(
                nil, self.__font.__font_size * 1.4,
                nil, glyph.__anima:get_current_frame().h
            )

            local pos_y = y + glyph.h * 0.5 * glyph.sy

            local pos_x = tx + glyph.w * 0.5 * glyph.sx

            glyph:draw(pos_x, pos_y)
        end

        tx = tx + glyph.w * glyph.sx + font.__character_space

        if __glyph_count__ then
            __glyph_count__[1] = __glyph_count__[1] + 1

            if __max_char__ and __glyph_count__[1] >= __max_char__ then
                return tx, glyph
            end
        end
    end

    -- love.graphics.setColor(1, 1, 1, 1)
    -- for _, batch in pairs(font.batches) do
    --     local r = batch:getCount() > 0 and love.graphics.draw(batch)
    -- end

    -- if self.text ~= " " or true then
    --     love.graphics.setColor(0, 0, 0, 1)
    --     love.graphics.rectangle("line", x - 2, y - 2, self:get_width() + 4, self.__font.__font_size + 4)
    -- end
end

function Word.flush()
    for k, v in pairs(Word.WIDTHS) do
        Word.WIDTHS[k] = nil
    end
end

return Word
