local utf8 = require('utf8')

---@type string
local path = ...

---@type JM.Anima
local Anima = _G.JM_Anima

---@type JM.Utils
local Utils = _G.JM_Utils

---@type JM.Font.Glyph
local Glyph = require((...):gsub("jm_font_generator", "font.glyph"))

---@type JM.Font.GlyphIterator
local Iterator = require((...):gsub("jm_font_generator", "font.font_iterator"))

---@type JM.Font.Phrase
local Phrase = require((...):gsub("jm_font_generator", "font.Phrase"))

--====================================================================

local tab_insert, tab_remove, str_find, str_format = table.insert, table.remove, string.find, string.format
local lgx = love.graphics
local love_draw, love_set_color = lgx.draw, lgx.setColor
local ipairs, pairs, unpack, assert = ipairs, pairs, unpack, assert

local MATH_HUGE = math.huge

local metatable_mode_k = { __mode = 'k' }
local metatable_mode_v = { __mode = 'v' }
local metatable_mode_kv = { __mode = 'kv' }

---@param nickname string
---@return string|nil
local function is_valid_nickname(nickname)
    local N = #nickname
    -- local r = N > 4 and nickname:match("%-%-[^%-][%w%p]-%-%-") or nil
    local r = N > 2 and nickname:match("%:[^ %p][%w%-%_]-%:")
    return r
end

local getGlyphsResult = setmetatable({}, metatable_mode_kv)

--- Receive a string and returns a table wich each index is a glyph
---@param s string
---@return table t
local function get_glyphs(s)
    if not s then return {} end

    local result = getGlyphsResult[s]
    if result then return result end

    local t = {}
    for p, c in utf8.codes(s) do
        tab_insert(t, utf8.char(c))
    end

    getGlyphsResult[s] = t

    return t
end

local findNicksResult = setmetatable({}, metatable_mode_v)

-- ---@param t table
-- local function find_nicks(t)
--     local result = findNicksResult[t]
--     if result then return result end

--     local next_ = function(init)
--         local i = init
--         local n = #t
--         while (i <= n) do
--             if t[i] == '-' and t[i + 1] and t[i + 1] == '-' then
--                 return (i + 1)
--             end
--             i = i + 1
--         end
--         return false
--     end

--     local i = 1
--     local N = #t
--     local new_table = {}

--     while (i <= N) do
--         if t[i] == '-' and t[i + 1] and t[i + 1] == '-' then
--             local next = next_(i + 2)
--             if next then
--                 local s = ''
--                 for k = i, next do
--                     s = s .. t[k]
--                 end

--                 if is_valid_nickname(s) then
--                     tab_insert(new_table, s)
--                     i = next
--                 end
--             end
--         else
--             tab_insert(new_table, t[i])
--         end

--         i = i + 1
--     end

--     findNicksResult[t] = new_table
--     return new_table
-- end

local function find_nicks2(t)
    local result = findNicksResult[t]
    if result then return result end

    local next_ = function(init, N)
        local i = init
        local len = 0
        while i <= N do
            if t[i] == ":" and len <= 20 then
                return i
            elseif len > 20 then
                return false
            else
                len = len + 1
            end
            i = i + 1
        end
        return false
    end

    local i = 1
    local N = #t
    local new_table = {}

    while i <= N do
        if t[i] == ":" then
            local next = next_(i + 1, N)
            if next then
                local s = ''
                for k = i, next do
                    s = s .. t[k]
                end

                if is_valid_nickname(s) then
                    tab_insert(new_table, s)
                    i = next
                else
                    tab_insert(new_table, t[i])
                end
                ---
            else
                tab_insert(new_table, t[i])
            end
        else
            tab_insert(new_table, t[i])
        end
        i = i + 1
    end

    findNicksResult[t] = new_table
    return new_table
end

---@enum JM.Font.FormatOptions
local FontFormat = {
    normal = 0,
    bold = 1,
    italic = 2,
    bold_italic = 3
}

-- -@alias JM.AvailableFonts
-- -|"consolas"
-- -|"JM caligraphy"

---@class JM.Font.Font
---@field __nicknames table
local Font = {
    buffer_time = 0.0,
    Phrase = Phrase,
}

---@alias JM.FontGenerator.Args {name: string, font_size: number, line_space: number, tab_size: number, character_space: number, color: JM.Color, glyphs:string, glyphs_bold:string, glyphs_italic:string, glyphs_bold_italic:string, regular_data: love.ImageData, bold_data:love.ImageData, italic_data:love.ImageData, regular_quads:any, italic_quads:any, bold_quads:any, min_filter:string, max_filter:string, dir:string, dir_bold:string, dir_italic:string, word_space:number, skip_remove_mask_step:boolean}

-- -@overload fun(self: table, args: JM.AvailableFonts)

---@param args JM.FontGenerator.Args
---@return JM.Font.Font new_Font
function Font:new(args)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Font.__constructor__(obj, args)

    return obj
end

-- -@overload fun(self: table, args: JM.AvailableFonts)

---@param args JM.FontGenerator.Args
function Font:__constructor__(args)
    if type(args) == "string" then
        local temp_table = {}
        temp_table.name = args
        args = temp_table
    end

    self.__imgs = {}

    self.__nicknames = {}
    self.id_to_nick = {}
    self.n_nicks = 0

    self.__font_size = args.font_size or 20

    self.__character_space = args.character_space or 0
    self.__line_space = args.line_space or 10

    self.name = args.name

    self.__characters = {
        [FontFormat.normal] = {},
        [FontFormat.bold] = {},
        [FontFormat.italic] = {},
        [FontFormat.bold_italic] = {}
    }

    -- local dir = path:gsub("modules.jm_font_generator", "/data/font/")
    --     .. "%s/%s.png"

    self:load_glyphs(args.regular_data
        or args.dir,
        -- or str_format(dir, args.name, args.name),
        FontFormat.normal,
        find_nicks2(get_glyphs(args.glyphs)),
        args.regular_quads,
        args.min_filter,
        args.max_filter,
        args.skip_remove_mask_step
    )


    -- if not args.regular_data or args.bold_data then
    if args.bold_data or args.dir_bold then
        self:load_glyphs(args.bold_data
            or args.dir_bold,
            -- or str_format(dir, args.name, args.name .. "_bold"),
            FontFormat.bold,
            find_nicks2(get_glyphs(args.glyphs_bold or args.glyphs)),
            args.bold_quads,
            args.min_filter,
            args.max_filter,
            args.skip_remove_mask_step
        )
    else
        self.__characters[FontFormat.bold] = self.__characters[FontFormat.normal]
        self.__imgs[FontFormat.bold] = self.__imgs[FontFormat.normal]
    end

    -- if (not args.regular_data or args.italic_data) then
    if (args.italic_data or args.dir_italic) then
        self:load_glyphs(args.italic_data
            or args.dir_italic,
            -- or str_format(dir, args.name, args.name .. "_italic"),
            FontFormat.italic,
            find_nicks2(get_glyphs(args.glyphs_italic or args.glyphs)),
            args.italic_quads,
            args.min_filter,
            args.max_filter,
            args.skip_remove_mask_step
        )
    else
        self.__characters[FontFormat.italic] = self.__characters[FontFormat.normal]
        self.__imgs[FontFormat.italic] = self.__imgs[FontFormat.normal]
    end

    self.__format = FontFormat.normal

    self.format_options = FontFormat

    self.__ref_height = (self:__get_char_equals("A")
            and self:__get_char_equals("A").h)
        or (self:__get_char_equals("0") and self:__get_char_equals("0").h)
        or self.__font_size

    self.__word_space = args.word_space or (self.__ref_height * 0.6)

    self.__tab_size = args.tab_size or 4

    self:set_font_size(self.__font_size)

    self.__tab_char = Glyph:new(self.__imgs[FontFormat.normal], {
        id = "\t",
        x = 0,
        y = 0,
        w = self.__word_space * self.__tab_size,
        h = self.__ref_height
    })

    self.__space_char = Glyph:new(self.__imgs[FontFormat.normal], {
        id = " ",
        x = 0,
        y = 0,
        w = self.__word_space,
        h = self.__ref_height
    })

    local nule_glyph = self:get_nule_character()

    for _, format in pairs(FontFormat) do
        self.__characters[format][" "] = self.__space_char
        self.__characters[format]["\t"] = self.__tab_char
        self.__characters[format][nule_glyph.id] = nule_glyph
    end

    self.__default_color = args.color or { 0.1, 0.1, 0.1, 1 }

    self.__bounds = { left = 0, top = 0, right = lgx.getWidth(), bottom = lgx.getHeight() }

    self.batches = {
        [FontFormat.normal] = self.__imgs[FontFormat.normal] and
            lgx.newSpriteBatch(self.__imgs[FontFormat.normal])
            or nil,
        --
        [FontFormat.bold] = self.__imgs[FontFormat.bold] and
            lgx.newSpriteBatch(self.__imgs[FontFormat.bold]) or nil,
        --
        [FontFormat.italic] = self.__imgs[FontFormat.italic] and
            lgx.newSpriteBatch(self.__imgs[FontFormat.italic]) or nil
    }

    self.__batches = {
        [1] = self.batches[FontFormat.normal],
        [2] = self.batches[FontFormat.bold],
        [3] = self.batches[FontFormat.italic],
    }
    self.__n_batches = #self.__batches

    if not args.font_size then
        self:set_font_size(self.__ref_height)
    end
end

---@return JM.Font.GlyphIterator
function Font:get_text_iterator(text)
    return Iterator:new(text, self)
end

---
---@param value JM.Font.FormatOptions
function Font:set_format_mode(value)
    self.__format = value
end

function Font:get_format_mode()
    return self.__format
end

local function symbols_unicode()
    return {
        [":cpy:"] = utf8.char(169),     --"\u{a9}",
        [":enne_up:"] = utf8.char(209), --"\u{d1}",
        [":enne:"] = utf8.char(241),    --"\u{f1}",
        [":mult:"] = utf8.char(10005),  --"\u{2715}",
    }
end

---@param dir any
---@param format JM.Font.FormatOptions
---@param glyphs table
function Font:load_glyphs(dir, format, glyphs, quads_pos, min_filter, max_filter, skip_remove_mask_step)
    -- try load the img data
    local success, img_data = pcall(
        function()
            return type(dir) == "string" and love.image.newImageData(dir)
                or dir
        end
    )

    if not success or not dir then return end

    local list = {} -- list of glyphs
    local mask_color = { 1, 1, 0, 1 }
    local mask_color_red = { 1, 0, 0, 1 }

    local function is_yellow(r, g, b, a)
        return r == mask_color[1] and g == mask_color[2] and b == mask_color[3] and a == mask_color[4]
    end

    local function is_red(r, g, b, a)
        return r == mask_color_red[1] and g == mask_color_red[2] and b == mask_color_red[3] and a == mask_color_red[4]
    end

    ---@type love.Image
    local img
    if not skip_remove_mask_step then
        local width, height = img_data:getDimensions()

        local data = love.image.newImageData(width, height)
        data:paste(img_data, 0, 0, 0, 0, width, height)

        local w, h = data:getDimensions()
        for i = 0, w - 1 do
            for j = 0, h - 1 do
                if is_yellow(data:getPixel(i, j)) then
                    data:setPixel(i, j, 0, 0, 0, 0)
                end
            end
        end
        img = lgx.newImage(data)
        img:setFilter(min_filter or "linear", max_filter or "nearest")
        data:release()
        ---
    else
        img = lgx.newImage(img_data)
    end

    local w, h = img_data:getDimensions()
    local cur_id = 1

    local N_glyphs = #glyphs
    local founds = {}
    local n_founds = 0

    local collision = function(qx, qy)
        for i = 1, n_founds do
            local quad = founds[i]
            local fx, fy, fw, fh = quad[1], quad[2], quad[3], quad[4]
            local r = qx >= fx and qx <= fx + fw
                and qy >= fy and qy <= fy + fh
            if r then return fx, fy, fw, fh end
        end
    end

    local y = 0
    while not quads_pos and (y <= h - 1) do
        if cur_id > N_glyphs then break end

        local x = 0

        while (x <= w - 1) do
            local r, g, b, a = img_data:getPixel(x, y)

            if (a == 0
                    or (not is_yellow(r, g, b, a) and not is_red(r, g, b, a)))
            -- and not collision(x, y)
            then
                local cx, cy, cw, ch = collision(x, y)

                if not cx then
                    local qx, qy, qw, qh, bottom

                    qx, qy = x, y

                    for k = x, w - 1 do
                        if is_yellow(img_data:getPixel(k, y)) then
                            qw = k - qx
                            break
                        end
                    end

                    for p = y, h - 1 do
                        if is_yellow(img_data:getPixel(qx, p)) then
                            qh = p - qy
                            break
                        elseif is_red(img_data:getPixel(qx - 1, p)) then
                            bottom = p
                        end
                    end

                    if not bottom and qh then
                        for p = qy, qy + qh + 5 do
                            if p > h - 1 then break end
                            if is_red(img_data:getPixel(qx - 1, p)) then
                                bottom = p
                                break
                            end
                        end
                    end

                    qh = qh or (h - 1)

                    if qh and qw then
                        tab_insert(founds, { qx, qy, qw, qh })
                        n_founds = n_founds + 1

                        local glyph = Glyph:new(img,
                            {
                                id = glyphs[cur_id],
                                x = qx,
                                y = qy,
                                w = qw,
                                h = qh,
                                bottom = bottom or (qy + qh),
                                format = format
                            })

                        list[glyph.id] = glyph

                        if is_valid_nickname(glyph.id) then
                            self:push_nick_glyph(glyph.id)
                        end

                        cur_id = cur_id + 1
                        x = qx + qw - 1
                    end
                    ---
                else
                    -- COLLISION!
                    x = x + cw - 1
                end
            end
            x = x + 1
        end
        y = y + 1
    end

    if quads_pos then
        while (cur_id <= N_glyphs) do
            local id = glyphs[cur_id]
            local quad = quads_pos[id]

            if id and quad then
                local qx, qy, qw, qh, bottom, right = quad.x, quad.y, quad.w, quad.h, quad.bottom, quad.right

                local glyph = Glyph:new(img,
                    {
                        id = glyphs[cur_id],
                        x = qx,
                        y = qy,
                        w = qw,
                        h = qh,
                        bottom = bottom or (qy + qh),
                        right = right or nil,
                        format = format
                    })

                list[glyph.id] = glyph
            end

            cur_id = cur_id + 1
        end
    end

    local symbols = symbols_unicode()
    for k, v in pairs(symbols) do
        list[v] = list[v] or list[k]
    end


    self.__characters[format] = list
    self.__imgs[format] = img
end

---@param hinting "normal"|"light"|"mono"|"none"|any
local function load_by_tff(name, path, fontsize, save, threshold, glyphs_str, max_texturesize, hinting, dpiscale)
    if not name or not path then return end

    ---@type love.Rasterizer
    local render

    local success

    success, render = pcall(function()
        -- return love.font.newRasterizer(path, dpi or 64)
        return love.font.newRasterizer(path, fontsize or 64, hinting or "normal", dpiscale or 1)
    end)

    if not success or not path then return end


    if glyphs_str and glyphs_str == "" then glyphs_str = nil end

    local glyph_table = {}
    local glyphs = ""

    --[[
        Useful site to checks the desired threshold
             https://symbl.cc/en/unicode-table/
    ]]
    local threshold = threshold or { { 33, 126 }, { 128, 255 }, { 256, 383 } }

    local type, tonumber = type, tonumber
    local utf8_char = utf8.char

    for k = 1, #threshold do
        local lim = threshold[k]
        local left = lim[1]
        local right = lim[2]

        if type(left) == "string" then
            left = left:gsub("#", "")
            left = tonumber("0x" .. left)
        end
        if type(right) == "string" then
            right = right:gsub("#", "")
            right = tonumber("0x" .. right)
        end

        assert(left <= right)

        for i = left, right do
            local glyph_s = utf8_char(i)
            local glyph = render:getGlyphData(glyph_s)

            if glyph then
                local w, h = glyph:getDimensions()
                if w > 0 and h > 0 then
                    tab_insert(glyph_table, glyph_s)

                    if not glyphs_str then
                        glyphs = glyphs .. glyph_s
                    end
                end
            end
        end
    end

    glyphs = glyphs_str or glyphs

    local cur_x = 4
    local cur_y = 2

    local glyphs_obj = {}
    local glyphs_data = {}
    local total_width = cur_x
    local max_height = -math.huge

    local newImageData = love.image.newImageData

    -- for _, glyph_s in ipairs(glyph_table) do
    for i = 1, #glyph_table do
        local glyph_s = glyph_table[i]
        local glyph = render:getGlyphData(glyph_s)

        if glyph then
            local w, h = glyph:getDimensions()
            -- local bbx, bby, bbw, bbh = glyph:getBoundingBox()

            if type(w) == "number" and type(h) == "number"
                and w > 0 and h > 0
            then
                local glyphData = newImageData(w, h, "rgba8", glyph:getString():gsub("(.)(.)", "%1%1%1%2"))

                local glyphDataWidth, glyphDataHeight = glyphData:getDimensions()

                total_width = total_width + glyphDataWidth + 4
                local height = glyphDataHeight + cur_y + 4
                max_height = (height > max_height and height) or max_height

                glyphs_obj[glyph_s] = glyph
                glyphs_data[glyph] = glyphData
            end
        end
    end
    -- max_height = max_height + 100

    cur_x = 2
    cur_y = 2
    local py = 3

    local limits = love.graphics.getSystemLimits()
    local max_value = max_texturesize or total_width

    if total_width < max_texturesize then
        max_value = total_width + 4
    end

    if max_value > limits.texturesize then
        max_value = limits.texturesize
    end

    local n_lines = math.ceil(total_width / max_value)
    n_lines = n_lines == 0 and 1 or n_lines

    local font_imgdata = newImageData(
        max_value,
        (max_height) * n_lines + 5, "rgba8"
    )

    local data_w, data_h = font_imgdata:getDimensions()
    local quad_pos = {}

    -- turning the output img completely yellow
    for i = 0, data_w - 1 do
        for j = 0, data_h - 1 do
            font_imgdata:setPixel(i, j, 1, 1, 0, 1)
        end
    end

    for _, glyph_s in ipairs(glyph_table) do
        ---@type love.GlyphData
        local glyph = glyphs_obj[glyph_s]

        if glyph then
            local bbx, bby, bbw, bbh = glyph:getBoundingBox()

            ---@type love.ImageData
            local glyphData = glyphs_data[glyph]

            local glyphDataWidth, glyphDataHeight = glyphData:getDimensions()

            if cur_x + glyphDataWidth >= max_value then
                cur_x = 2
                py = py + max_height - 3
            end

            cur_y = py

            -- turning transparent the glyph quad in the output img (width)
            for i = 0, glyphDataWidth - 1 do
                if cur_y - 1 <= data_h - 1 and cur_x + i <= data_w - 1 then
                    font_imgdata:setPixel(cur_x + i, cur_y, 0, 0, 0, 0)
                end
            end

            for y = cur_y, cur_y + bby + bbh - 1 do
                for x = cur_x, cur_x + bbw - 1 do
                    if x <= data_w - 1 and y <= data_h - 1 then
                        font_imgdata:setPixel(x, y, 0, 0, 0, 0)
                    end
                end
            end


            font_imgdata:paste(glyphData, cur_x, cur_y, 0, 0, glyphDataWidth, glyphDataHeight)


            local posR_y = math.abs(cur_y + (bby + bbh))
            if posR_y >= 0 and posR_y <= data_h - 1 then
                font_imgdata:setPixel(cur_x - 1, posR_y, 1, 0, 0, 1)
            end

            -- local posBlue = math.floor(cur_x + bbw - (bbx > 0 and 0 or -bbx))
            local posBlue = cur_x + bbw
            if posBlue >= 0 and posBlue <= data_w - 1 and cur_y - 1 < data_h - 1 then
                font_imgdata:setPixel(posBlue, cur_y - 1, 1, 0, 0, 1)
            end

            local pos_bx = cur_x + bbx - 1
            if pos_bx > 0 and cur_y - 1 >= 0 then
                font_imgdata:setPixel(pos_bx, cur_y - 1, 1, 0, 0, 1)
            end

            quad_pos[glyph_s] = {
                x = cur_x,
                y = cur_y,
                w = glyphDataWidth,  -- + 1,
                h = glyphDataHeight, --+ 2,
                bottom = (posR_y >= 0 and posR_y <= data_h - 1 and posR_y)
                    or nil,
                right = (posBlue >= 0 and posBlue <= data_w - 1 and posBlue) or nil
            }

            cur_x = cur_x + glyphDataWidth + 4
        end
    end

    if save then
        font_imgdata:encode("png", name:match(".*[^%.]") .. ".png")
        love.filesystem.write("glyphs_" .. name .. ".txt", glyphs)
        JM.Ldr.save(quad_pos, "quad_" .. name .. ".dat")
        JM.Ldr.save({ glyphs = glyphs, quad_pos = quad_pos }, "data_" .. name .. ".dat")
    end

    return font_imgdata, glyphs, quad_pos
end

---@return JM.Font.Glyph
function Font:get_nule_character()
    local char_ = Glyph:new(nil,
        { id = "__nule__", x = nil, y = nil, w = self.__word_space, h = self.__ref_height })

    return char_
end

---@alias JM.Font.Configuration {font_size: number, character_space: number, color: JM.Color, line_space: number, word_space: number, tab_size: number, format: JM.Font.FormatOptions, scale:number }

local results_get_config = setmetatable({}, metatable_mode_k)

---@return JM.Font.Configuration
function Font:__get_configuration()
    local index = str_format("%d %d %.1f %.1f %.1f %.1f %d %d",
        self.__font_size,
        self.__character_space,
        (self.__default_color[1]),
        (self.__default_color[2]),
        (self.__default_color[3]),
        (self.__default_color[4]),
        self.__line_space,
        self.__format)

    local result = results_get_config[self] and results_get_config[self][index]
    if result then return result end

    local config = {
        font_size = self.__font_size,
        character_space = self.__character_space,
        color = self.__default_color,
        line_space = self.__line_space,
        word_space = self.__word_space,
        tab_size = self.__tab_size,
        format = self.__format,
        scale = self.__scale
    }

    results_get_config[self] = results_get_config[self] or setmetatable({}, metatable_mode_v)
    results_get_config[self][index] = config

    return config
end

function Font:push()
    if not self.__config_stack__ then
        self.__config_stack__ = {}
    end

    assert(#self.__config_stack__ >= 0, "\nError: Too many push operations. Are you using more push than pop?")

    local config = self:__get_configuration()
    tab_insert(self.__config_stack__, config)
end

---@param config JM.Font.Configuration
function Font:set_configuration(config)
    self:set_font_size(config.font_size)
    self.__character_space = config.character_space
    self.__default_color = config.color
    self.__line_space = config.line_space
    self.__word_space = config.word_space
    self.__tab_size = config.tab_size
    self.__format = config.format
end

function Font:pop()
    assert(self.__config_stack__ and #self.__config_stack__ > 0,
        "\nError: You're using a pop operation without using a push before.")

    local config = tab_remove(self.__config_stack__, #self.__config_stack__)

    self:set_configuration(config)
end

function Font:set_character_space(value)
    self.__character_space = value
end

---@param color JM.Color
function Font:set_color(color)
    self.__default_color = color
end

function Font:set_line_space(value)
    self.__line_space = value
end

function Font:set_tab_size(value)
    self.__tab_size = value
    self.__tab_char.w = self.__word_space * self.__tab_size
end

function Font:set_word_space(value)
    self.__word_space = value
end

---@param value number
function Font:set_font_size(value)
    self.__font_size = value
    -- self.__scale = Utils:desired_size2(nil, self.__font_size, nil, self.__ref_height, true).y
    local _, y = Utils:desired_size2(nil, self.__font_size, nil, self.__ref_height, true)
    self.__scale = y
end

function Font:push_nick_glyph(nick)
    tab_insert(self.__nicknames, nick)
    self.id_to_nick[nick] = true
    self.n_nicks = #self.__nicknames
end

---@param nickname string
-- --- @param args {img: love.Image|string, frames: number, frames_list: table,  speed: number, rotation: number, color: JM.Color, scale: table, flip_x: boolean, flip_y: boolean, is_reversed: boolean, stop_at_the_end: boolean, amount_cycle: number, state: JM.AnimaStates, bottom: number, kx: number, ky: number, width: number, height: number, ref_width: number, ref_height: number, duration: number, n: number}
function Font:add_nickname_animated(nickname, args)
    assert(is_valid_nickname(nickname),
        "\nError: Invalid nickname. The nickname should start and ending with '--'. \nExamples: --icon--, --emoji--.")

    local animation = Anima:new(args)

    local new_character = Glyph:new(nil, {
        id = nickname,
        anima = animation,
        w = self.__ref_height * 1.5,
        h = self.__ref_height
    })

    -- tab_insert(self.__nicknames, nickname)
    self:push_nick_glyph(nickname)

    for _, format in pairs(FontFormat) do
        self.__characters[format][nickname] = new_character
    end

    return animation
end

---@param img love.Image | any
---@param align "center"|"bottom"|"top"
function Font:add_glyph_xp(nick, img, qx, qy, qw, qh, align, scale)
    nick = assert(is_valid_nickname(nick))

    self.nick_to_glyph_xp = self.nick_to_glyph_xp or {}
    self.glyphs_xp = self.glyphs_xp or {}

    local glyph = Glyph:new(img, {
        id = nick,
        x = qx,
        y = qy,
        w = qw,
        h = qh,
    })

    self.nick_to_glyph_xp[nick] = {
        glyph = glyph,
        align = align,
        scale = scale
    }
    tab_insert(self.glyphs_xp, nick)

    for _, format in pairs(FontFormat) do
        self.__characters[format][nick] = glyph
    end

    return glyph
end

function Font:add_animated_glyph_xp(nick, width, height, align, scale, anima)
    if scale then
        width = width * scale
        height = height * scale
    end
    local glyph = self:add_glyph_xp(nick, nil, nil, nil, width, height, align or "center", scale)
    glyph.__anima = anima
    return glyph
end

---@param glyph JM.Font.Glyph
function Font:is_glyph_xp(glyph)
    return self.nick_to_glyph_xp and self.nick_to_glyph_xp[glyph.id]
end

---@param s string
---@return string|nil nickname
---@return number|nil len
function Font:__is_a_nickname(s, index)
    if s:sub(index, index) ~= ":" then return nil end

    local nicknames = self.__nicknames
    local N = self.n_nicks --#self.__nicknames
    local i = 1
    -- for _, nickname in ipairs(self.__nicknames) do
    while i <= N do
        local nick = nicknames[i]
        local len = #nick
        if s:sub(index, index + len - 1) == nick then
            return nick, len
        end
        i = i + 1
    end

    local glyphs_xp = self.glyphs_xp
    if glyphs_xp then
        for i = 1, #glyphs_xp do
            local id = glyphs_xp[i]
            local len = #id
            if s:sub(index, index + len - 1) == id then
                return id, len
            end
        end
    end

    return nil
end

---
function Font:string_is_nickname(s)
    return self:__is_a_nickname(s, 1)
end

---
function Font:update(dt)
    -- for i = 1, #(self.__nicknames) do
    for i = 1, self.n_nicks do
        local glyph = self:__get_char_equals(self.__nicknames[i])
        if glyph then glyph:update(dt) end
    end

    local xp = self.glyphs_xp
    if xp then
        for i = 1, #xp do
            ---@type JM.Font.Glyph
            local glyph = self.__characters[FontFormat.normal][xp[i]]

            if glyph.__anima then
                glyph:update(dt)
            end
        end
    end
end

---@param c string
---@return JM.Font.Glyph|nil
function Font:__get_char_equals(c)
    if not c then return nil end

    local glyph = self.__characters[self.__format][c]

    if glyph then return glyph end

    if is_valid_nickname(c) then
        -- for _, format in pairs(FontFormat) do
        --     glyph = self.__characters[format][c]
        --     if glyph then return glyph end
        -- end
        glyph = self.__characters[FontFormat.normal][c]
        if glyph then return glyph end
        glyph = self.__characters[FontFormat.bold][c]
        if glyph then return glyph end
        glyph = self.__characters[FontFormat.italic][c]
        if glyph then return glyph end
    end

    return glyph
end

local result_sep_text = setmetatable({}, metatable_mode_kv)

---@param s string
function Font:separate_string(s, list)
    s = s .. " "
    local result = not list and result_sep_text[s]
    if result then return result end
    local init_s = not list and s or nil

    if not list then
        s = s:gsub("`#`", "</color>")
        s = s:gsub("`#%-`", "</color no-space>")
        s = s:gsub("<br>", "\n<void>")
        s = s:gsub("<tab>", "\t")

        for m in string.gmatch(s, "`#[abcdef%d]*`") do
            s = s:gsub(m, string.format("<color-hex=%s>", m:sub(2, #m - 1)), 1)
        end
    end

    if not list then
        for m in string.gmatch(s, "%*%*.-%*%*") do
            local new = string.gsub(m, "%*%*", "")
            s = string.gsub(s, "%*%*.-%*%*", string.format("<bold>%s</bold>", new), 1)
        end
    end

    if not list then
        for m in string.gmatch(s, "%*.-%*") do
            local new = string.sub(m, 2, #m - 1)
            s = string.gsub(s, "%*.-%*", string.format("<italic>%s</italic>", new))
        end
    end

    local sep = "\n "
    ---@type any
    local current_init = 1
    local words = list or {}

    local N = #s
    local tag_regex = "< *[%d, =._%w/%-%#%{%}\'\";():\\]*>"

    while (current_init <= N) do
        -- while (current_init <= utf8.len(s)) do
        -- local regex = str_format("[^[ ]]*.-[%s]", sep)
        local regex = str_format(".-[%s]", sep)

        local tag = s:match(tag_regex, current_init)
        local find = not tag and s:match(regex, current_init)
        local nick = false --find and string.match(find, "%-%-%w-%-%-")

        if tag then
            local startp, endp = str_find(s, tag_regex, current_init)

            local sub_s = startp and s:sub(startp, endp)
            local prev_s = s:sub(current_init, startp - 1)

            if prev_s ~= "" and prev_s ~= " " then
                self:separate_string(prev_s, words)
            end

            tab_insert(words, sub_s)
            current_init = endp
            ---
            -- elseif nick and nick ~= "----" then
            -- local startp, endp = string.find(s, "%-%-%w-%-%-", current_init)
            -- local sub_s = startp and s:sub(startp, endp)
            -- local prev_word = s:sub(current_init, startp - 1)

            -- if prev_word and prev_word ~= "" and prev_word ~= " " then
            --     self:separate_string(prev_word, words)
            -- end

            -- if sub_s ~= "" and sub_s ~= " " then
            --     tab_insert(words, sub_s)
            -- end

            -- current_init = endp
        elseif find then
            local startp, endp = str_find(s, regex, current_init)
            -- local len
            local sub_s = startp and s:sub(startp, endp - 1)

            if sub_s ~= "" and sub_s ~= " "
            then
                tab_insert(words, sub_s)
            end

            if endp and s:sub(endp, endp) == "\n" then
                tab_insert(words, "\n")
            end

            current_init = endp
        else
            break
        end

        current_init = current_init + 1
    end

    local rest = s:sub(current_init, #s)

    if rest ~= "" and not rest:match(" *") then
        tab_insert(words, s:sub(current_init, #s))
    end

    -- result_sep_text[s] = words
    if init_s then
        result_sep_text[init_s] = words
    end

    return words
end

---@alias JM.Font.Tags "<bold>"|"</bold>"|"<italic>"|"</italic>"|"<color>"|"</color>"|"<effect>"|"</effect>"|"<pause>"|"<font>"|"<sep>"|"<color-hex>"

---@param s string
---@return JM.Font.Tags|false
function Font:__is_a_command_tag(s)
    if s:sub(1, 1) ~= "<" then return false end

    return (s:match("< *bold *[ %w%-]*>") and "<bold>")
        or (s:match("< */ *bold *[ %w%-]*>") and "</bold>")
        or (s:match("< *italic *[ %w%-]*>") and "<italic>")
        or (s:match("< */ *italic *[ %w%-]*>") and "</italic>")

        or (s:match("< *color%-hex *=- *[%#%dabcdef]* *>") and "<color-hex>")

        or (s:match("< *color[%d, .]*>") and "<color>")


        or (s:match("< */ *color[ %w%-]*>") and "</color>")

        or (s:match("< *effect *=[%w, =%.]* *>") and "<effect>")
        or (s:match("< */ *effect *[ %w%-]*>") and "</effect>")

        or (s:match("< *font *= *[%w%d,%. _%-%=%#]*>") and "<font>")
        or (s:match("< *pause *=[ %d%.]*[, %w%-]*>") and "<pause>")

        -- or (s:match("< *font%-size *=[ %d%.]*[, %w%-]*>") and "<font-size>")
        -- or (s:match("< */ *font%-size *[, %w%-]*>") and "</font-size>")

        -- or (s:match("< *textbox[ ,=%w%._%-%{%}\'\";]*>") and "<textbox>")
        or (s:match("< *textbox[%w%p%a%d _\'\"%.]*>") and "<textbox>")
        or (s:match("< *sep[ %w,%-]*>") and "<sep>")
        or false
end

local tag_args_result = setmetatable({}, metatable_mode_kv)
local tag_args_default_table = {}

---@param s string
function Font:get_tag_args(s)
    if not s or s == "" then return tag_args_default_table end
    -- s = s:sub(2, #s - 1)
    s = s:gsub("<", "")
    s = s:gsub(">", "")
    if not s or s == "" then return tag_args_default_table end

    do
        local r = tag_args_result[s]
        if r then return r end
    end

    local N = #s
    ---@type any
    local i = 1
    local result = {}

    while (i <= N) do
        local startp, endp = s:find("[=,>]", i)

        if startp then
            local left = s:sub(i, endp - 1):match("[^ ].*[^ ]")
            local s2, e2 = s:find(",", i)

            i = endp
            local right

            if s2 then
                right = s:sub(endp + 1, e2 - 1)
                i = e2
            else
                right = s:sub(endp + 1)
            end

            if right then
                if right == "" then
                    right = false -- true
                elseif tonumber(right) then
                    right = tonumber(right)
                elseif right:match("{.*}") then
                    i = i + #right
                    right = assert(loadstring("return " .. right))()
                    ---
                elseif right:match("true") then
                    right = true
                elseif right:match("false") then
                    right = false
                else
                    right = right:match("[^ ].*[^ ]")
                end
            end

            if left then
                result[left] = right
            end
        else
            local index = s:sub(i, #s):match("[^ ].*[^ ]")
            if index then
                result[s:sub(i, #s):match("[^ ].*[^ ]")] = true
            end
            break
        end

        i = i + 1
    end

    tag_args_result[s] = result
    return result
end

local codes_result = setmetatable({}, metatable_mode_kv)
Font.CODES = codes_result

---@param text string
function Font:print(text, x, y, w, h, __i__, __color__, __x_origin__, __format__, __fontsize__)
    if not text or text == "" then return x, y end

    self:push()

    w = w or nil --love.graphics.getWidth() - 100
    h = h or lgx.getHeight()

    local tx = x
    local ty = y

    local cur_color = __color__ or self.__default_color
    local original_color = self.__default_color

    local cur_format = __format__ or self.__format
    local original_format = self.__format

    local cur_fontsize = __fontsize__ or self.__font_size
    local original_fontsize = self.__font_size

    local x_origin = __x_origin__ or tx

    local i = __i__ or 1

    for i = 1, self.__n_batches do
        self.__batches[i]:clear()
    end

    local codes = codes_result[text]

    if not codes then
        codes = {}
        for p, c in utf8.codes(text) do
            tab_insert(codes, utf8.char(c))
        end
        codes_result[text] = codes
    end

    while i <= #codes do
        ---
        local glyph_id = codes[i]
        local pos = utf8.offset(text, i)

        local is_a_nick, len = self:__is_a_nickname(text, pos)

        if is_a_nick then
            glyph_id = is_a_nick
            i = i + len - 1
        end

        if glyph_id == "<" then
            local startp, endp = text:find(".->", pos + 1)

            if startp then
                local tag = text:sub(pos, endp)
                local match = not tag:match("<", 2)
                    and self:__is_a_command_tag(tag)

                if match then
                    if match == "<color>" then
                        local parse = Utils:parse_csv_line(text:sub(startp - 1, endp - 1))
                        local r = parse[2] or 1
                        local g = parse[3] or 0
                        local b = parse[4] or 0
                        local a = parse[5] or 1

                        cur_color = Utils:get_rgba(r, g, b, a)
                        --
                    elseif match == "<color-hex>" then
                        local r, g, b, a

                        local tag_values = self:get_tag_args(tag)
                        local hex = tag_values['color-hex']
                        r, g, b, a = Utils:hex_to_rgba_float(type(hex) == "string" and hex or "ff0000")

                        cur_color = Utils:get_rgba(r, g, b, a)
                        ---
                    elseif match == "<font>" then
                        local tag_values = match and self:get_tag_args(tag)
                        local action = tag_values["font"]

                        if action == "color-hex" then
                            local r, g, b, a =
                                Utils:hex_to_rgba_float(tag_values["value"])
                            cur_color = Utils:get_rgba(r, g, b, a)
                            ---
                        elseif action == "font-size" then
                            self:set_font_size(tag_values["value"] or original_fontsize)
                        end
                        ---
                    elseif match == "</color>" then
                        cur_color = original_color
                    elseif match == "<bold>" then
                        cur_format = self.format_options.bold
                    elseif match == "</bold>" then
                        cur_format = original_format
                    elseif match == "<italic>" then
                        cur_format = self.format_options.italic
                    elseif match == "</italic>" then
                        cur_format = original_format
                    end

                    glyph_id = nil
                    local off = utf8.offset(text, i) - i
                    i = endp - off
                end
            end
        end

        self:set_format_mode(cur_format)

        local glyph = glyph_id and self:__get_char_equals(glyph_id)

        if glyph_id == "\n"
            or ((glyph and w)
                and tx + self.__word_space + (glyph.w * self.__scale) >= x_origin + w)
        then
            ty = ty + (self.__ref_height + self.__line_space) * self.__scale
            tx = x_origin
        end

        if glyph then
            glyph:set_color(cur_color)

            glyph:set_scale(self.__scale)

            if self:is_glyph_xp(glyph) then
                --
                local prop = self.nick_to_glyph_xp[glyph.id]

                glyph:set_color2(1, 1, 1, glyph.color[4])
                local sc = prop.scale or (self.__font_size / glyph.h)
                glyph:set_scale(sc)

                local x = tx
                local y = ty + self.__font_size - glyph.h * sc

                if prop.align == "center" then
                    y = ty + self.__font_size * 0.5 - glyph.h * sc * 0.5
                elseif prop.align == "top" then
                    y = ty
                end

                if glyph.__anima then
                    glyph.__anima:set_scale(sc, sc)
                    -- x = tx + glyph.ox
                end

                glyph:draw(x, y)
                --
            elseif glyph:is_animated() then
                glyph:set_color2(1, 1, 1, 1)

                glyph.__anima:set_size(
                    nil, self.__font_size * 1.4,
                    nil, glyph.__anima:get_current_frame().h
                )

                glyph:draw(tx + glyph.w * 0.5 * glyph.sx,
                    ty + glyph.h * 0.5 * glyph.sy
                )
            else
                local quad = glyph.quad
                local x, y
                -- x, y = char_obj:get_pos_draw_rec(tx, ty + self.__font_size - height, width, height)

                x = tx
                -- y = ty + self.__font_size - glyph.h * glyph.sy
                y = ty + cur_fontsize - glyph.h * self.__scale

                if quad then
                    self.batches[glyph.format]:setColor(cur_color)
                    self.batches[glyph.format]:add(quad, x, y, 0, glyph.sx, glyph.sy, 0, 0)
                end
            end

            tx = tx
                + (glyph.w + self.__character_space) * glyph.sx
            -- + self.__character_space
        end

        i = i + 1
    end

    love_set_color(1, 1, 1, 1)

    for i = 1, self.__n_batches do
        local batch = self.__batches[i]
        if batch:getCount() > 0 then
            batch:flush()
            love_draw(batch)
        end
    end

    self:pop()
    -- _G[text] = nil

    return tx, ty
end

-- local get_char_obj
local len
local print
local line_width
local next_not_command_index
local get_words

local color_pointer = {}
local fontsize_pointer = {}

--- The functions below are used in the printf method
do
    -- get_char_obj =
    -- ---@return JM.Font.Glyph
    --     function(param)
    --         return param
    --     end

    -- local len_result = setmetatable({}, metatable_mode_k)

    len =
    ---@param self JM.Font.Font
    ---@param args table
    ---@return number width
        function(self, args)
            if not args then return 0 end

            local width = 0
            local N = #args

            for i = 1, N do
                ---@type JM.Font.Glyph
                local char_obj = args[i]

                width = width
                    + (char_obj.w + self.__character_space) * self.__scale
                -- + self.__character_space
            end


            return width - (self.__character_space * self.__scale)
        end

    print =
    ---@param self JM.Font.Font
    ---@param word_list table
    ---@param tx number
    ---@param ty number
    ---@param index_action table|nil
    ---@param current_color {[1]:JM.Color}
    ---@param fontsize {[1]:number}
        function(self, word_list, tx, ty, index_action, exceed_space, current_color, N_word, fontsize)
            exceed_space = exceed_space or 0

            if ty > self.__bounds.bottom
                or ty + self.__ref_height * self.__scale * 1.5 < self.__bounds.top
            then
                return
            end

            N_word = N_word or #word_list

            -- self:set_font_size(fontsize[1])

            -- for _, batch in pairs(self.batches) do
            --     batch:clear()
            -- end
            -- local i = 1
            local batches = self.__batches
            local n_batches = self.__n_batches

            for i = 1, n_batches do
                batches[i]:clear()
            end

            -- for k, word in ipairs(word_list) do
            for k = 1, N_word do
                local word = word_list[k]

                if index_action then
                    for _, action in ipairs(index_action) do
                        if action.i == k then
                            if action.args then
                                action.action(unpack(action.args))
                            else
                                action.action()
                            end
                        end
                    end
                end

                local N_glyphs = #(word)

                for i = 1, N_glyphs do
                    ---@type JM.Font.Glyph
                    local glyph = word[i] --get_char_obj(word[i])

                    if glyph then
                        glyph:set_color2(unpack(current_color[1]))
                        glyph:set_scale(self.__scale)

                        if self:is_glyph_xp(glyph) then
                            --
                            local prop = self.nick_to_glyph_xp[glyph.id]

                            glyph:set_color2(1, 1, 1, glyph.color[4])
                            local sc = prop.scale or (self.__font_size / glyph.h)
                            glyph:set_scale(sc)

                            local x = tx
                            local y = ty + fontsize[1] - glyph.h * sc

                            if prop.align == "center" then
                                y = ty + fontsize[1] * 0.5 - glyph.h * sc * 0.5
                            elseif prop.align == "top" then
                                y = ty
                            end

                            if glyph.__anima then
                                glyph.__anima:set_scale(sc, sc)
                                -- x = tx + glyph.ox
                            end

                            glyph:draw(x, y)
                            --
                        elseif glyph:is_animated() then
                            glyph:set_color2(1, 1, 1, 1)

                            glyph.__anima:set_size(
                                nil, self.__font_size * 1.4,
                                nil, glyph.__anima:get_current_frame().h
                            )

                            glyph:draw(tx + glyph.w * 0.5 * glyph.sx,
                                ty + glyph.h * 0.5 * glyph.sy
                            )
                            --
                        else
                            local quad = glyph.quad
                            local x, y

                            x = tx
                            y = ty + fontsize[1]
                                - (glyph.h) * glyph.sy

                            if quad then
                                self.batches[glyph.format]:setColor(unpack(glyph.color))

                                self.batches[glyph.format]:add(quad, x, y, 0, glyph.sx, glyph.sy, 0,
                                    0)
                            end

                            --char_obj:draw(x, y)
                        end

                        tx = tx
                            + (glyph.w + self.__character_space) * glyph.sx
                        -- + self.__character_space
                    end
                end

                tx = tx + exceed_space
            end

            love_set_color(1, 1, 1, 1)

            for i = 1, n_batches do
                local bt = batches[i]
                if bt:getCount() > 0 then
                    bt:flush()
                    love_draw(bt)
                end
            end

            if index_action then
                for _, action in ipairs(index_action) do
                    if action.i > N_word then
                        if action.args then
                            action.action(unpack(action.args))
                        else
                            action.action()
                        end
                    end
                end
            end
        end


    line_width =
    ---@param self JM.Font.Font
    ---@param line table
    ---@return number
        function(self, line, N)
            local total = 0
            N = N or #line

            local word
            for i = 1, N do
                word = line[i]
                total = total + len(self, word)
                    + (self.__character_space * self.__scale)
            end
            return total - (self.__character_space * self.__scale)
        end

    next_not_command_index =
    ---@param self JM.Font.Font
    ---@param index number
    ---@param separated table
    ---@return number|nil
        function(self, index, separated)
            local current_index = index + 1

            while (separated[current_index]
                    and self:__is_a_command_tag(separated[current_index])) do
                current_index = current_index + 1
            end

            if not separated[current_index] then return nil end
            return current_index
        end

    local results_get_word = setmetatable({}, metatable_mode_kv)

    ---@param self JM.Font.Font
    ---@param separated any
    ---@param list any
    ---@return unknown
    function get_words(self, separated, list)
        local result = results_get_word[self]
            and results_get_word[self][separated]
        if result then return result end

        list = list or {}

        local current_format = self.__format
        local original_format = self.__format
        local cur_fontsize = self.__font_size
        local original_fontsize = self.__font_size

        local i = 1

        while (i <= #(separated)) do
            local cur_word = separated[i] or ""

            local match = self:__is_a_command_tag(cur_word)

            if match == "<bold>" then
                current_format = self.format_options.bold
            elseif match == "</bold>" then
                current_format = original_format
            elseif match == "<italic>" then
                current_format = self.format_options.italic
            elseif match == "</italic>" then
                current_format = original_format
            end

            self:set_format_mode(current_format)

            local characters = self:get_text_iterator(cur_word)
            characters = characters:get_characters_list()

            if cur_word ~= "<void>" then
                tab_insert(list, characters)
            end

            -- _G[cur_word] = nil

            i = i + 1
        end

        results_get_word[self] = results_get_word[self]
            or setmetatable({}, metatable_mode_k)
        results_get_word[self][separated] = list

        return list
    end
end --- End auxiliary methods for printf

local action_set_color = function(m, separated)
    local parse = Utils:parse_csv_line(separated[m]:sub(2, #separated[m] - 1))
    local r = parse[2] or 1
    local g = parse[3] or 0
    local b = parse[4] or 0
    local a = parse[5] or 1

    color_pointer[1] = Utils:get_rgba(r, g, b, a)
end

local action_set_color_hex = function(s)
    local r, g, b, a = Utils:hex_to_rgba_float(s)

    color_pointer[1] = Utils:get_rgba(r, g, b, a)
end

local action_restaure_color = function(original_color)
    color_pointer[1] = original_color
end

local printf_lines = setmetatable({}, metatable_mode_k)

---@param text string
---@param x number
---@param y number
---@param align "left"|"right"|"center"|"justify"|any
---@param limit_right number|any
function Font:printf(text, x, y, align, limit_right, skip_round)
    --
    if type(align) == "number" then
        ---@diagnostic disable-next-line: cast-local-type
        align, limit_right = limit_right, align
    end

    if not text or text == "" then
        return false --{ tx = x, ty = y }
    end

    self:push()

    local tx = x
    x = 0

    -- local ty = y
    align = align or "left"
    limit_right = limit_right or lgx.getWidth() --love.mouse.getX() - x
    -- limit_right = limit_right - tx

    local current_color = color_pointer
    current_color[1] = self.__default_color

    local cur_fontsize = fontsize_pointer
    cur_fontsize[1] = self.__font_size

    local original_color = self.__default_color

    local separated = self:separate_string(text)

    local words = get_words(self, separated)

    self.__printf_space_glyph = self.__printf_space_glyph
        or { self.__space_char }


    local all_lines

    local result = printf_lines[self] and printf_lines[self][text]
    result = result and result[limit_right]

    if result then
        all_lines = result
    else
        all_lines = { lines = {}, actions = nil, width = {} }

        local total_width = 0
        local line = {}
        local line_actions

        local space_glyph = self.__printf_space_glyph

        local N = #(words)


        for m = 1, N do
            local command_tag = self:__is_a_command_tag(separated[m])

            if command_tag then
                local action_i = #line + 1
                local action_func, action_args

                if command_tag == "<color>" then
                    action_func = action_set_color
                    action_args = { m, separated }
                    --
                elseif command_tag == "<color-hex>" then
                    local tag_values = self:get_tag_args(separated[m])
                    local hex = tag_values["color-hex"]

                    action_func = action_set_color_hex
                    action_args = { type(hex) == "string" and hex or "ff0000" }
                    ---
                elseif command_tag == "</color>" then
                    action_func = action_restaure_color
                    action_args = { original_color }
                    --
                elseif command_tag == "<font>" then
                    local tag_values = self:get_tag_args(separated[m])
                    local action = tag_values["font"]

                    -- if tag_values["no-space"] then
                    --     -- total_width = total_width - self.__word_space * self.__scale
                    -- end

                    if action == "color-hex" then
                        action_func = action_set_color_hex
                        action_args = { tag_values["value"] }
                        ---
                    elseif action == "font-size" then
                        action_func = self.set_font_size
                        local size = tag_values["value"] or cur_fontsize[1]
                        action_args = { self, size }
                        self:set_font_size(size)
                        -- total_width = total_width - len(self, prev_word)
                    end
                    ---
                end

                if action_func then
                    line_actions = line_actions or {}

                    tab_insert(line_actions, {
                        i = action_i,
                        action = action_func,
                        args = action_args
                    })
                end
            end

            local current_is_break_line = separated[m] == "\n"

            if not command_tag then
                -- if not current_is_break_line or true then
                tab_insert(line, words[m])
                -- end

                local next_index = next_not_command_index(self, m, separated)

                total_width = total_width + len(self, words[m])
                    + (self.__space_char.w + self.__character_space) * self.__scale

                if total_width + (next_index and words[next_index]
                        and len(self, words[next_index]) or 0) > limit_right
                    or current_is_break_line
                then
                    -- tab_insert(all_lines.width, total_width
                    --     - (self.__word_space + self.__character_space) * self.__scale
                    -- )

                    total_width = 0

                    tab_insert(all_lines.lines, line)

                    if line_actions then
                        all_lines.actions = all_lines.actions or {}
                        all_lines.actions[#(all_lines.lines)] = line_actions
                    end

                    line = {}
                    line_actions = nil
                    --
                else
                    local next_index = next_not_command_index(self, m, separated)

                    local next_is_broken_line = next_index
                        and separated[next_index]
                        and separated[next_index] == "\n"

                    if m ~= N and not next_is_broken_line then
                        local next = separated[m + 1]
                        local skip_add_space = next
                            and self:__is_a_command_tag(next)
                            and next:match("no%-space")

                        if not skip_add_space then
                            tab_insert(
                                line,
                                space_glyph
                            )
                        end
                    elseif m ~= N then
                        total_width = total_width - (self.__word_space + self.__character_space) * self.__scale
                    end
                end
            end

            if line and m == N then
                tab_insert(all_lines.lines, line)

                -- tab_insert(all_lines.width, total_width
                --     - (self.__word_space + self.__character_space)
                --     * self.__scale
                -- )


                if line_actions then
                    all_lines.actions = all_lines.actions or {}
                    all_lines.actions[#(all_lines.lines)] = line_actions
                end
            end
        end

        all_lines.N_lines = #all_lines.lines

        for i = 1, all_lines.N_lines do
            local line = all_lines.lines[i]
            all_lines.width[i] = line_width(self, line, #line)
        end

        printf_lines[self] = printf_lines[self]
            or setmetatable({}, metatable_mode_k)

        printf_lines[self][text] = printf_lines[self][text]
            or setmetatable({}, metatable_mode_v)

        printf_lines[self][text][limit_right] = all_lines
    end

    local ty = 0                --y
    local N = all_lines.N_lines --#(all_lines.lines)
    local floor = math.floor
    -- x = 0
    lgx.push()
    if not skip_round then
        tx = floor(tx + 0.5)
        y = floor(y + 0.5)
    end
    lgx.translate(tx, y)

    self:set_font_size(cur_fontsize[1])
    local init_scale = self.__scale

    for i = 1, N do
        local line = all_lines.lines[i]
        local actions = all_lines.actions and all_lines.actions[i]
        local N_line = #line
        -- local lw = line_width(self, line, N_line)
        local lw = all_lines.width[i]

        local div = N_line - 1
        div = div <= 0 and 1 or div

        local ex_sp = align == "justify"
            and (limit_right - lw) / div
            or nil

        if i == N then ex_sp = nil end

        local pos_to_draw = (align == "left" and x)
            or (align == "right" and (x + limit_right) - lw)
            or (align == "center" and x + limit_right * 0.5 - lw * 0.5)
            or x

        pos_to_draw = floor(pos_to_draw + .5)

        print(self, line, pos_to_draw, ty, actions, ex_sp, current_color, N_line, cur_fontsize)

        ty = ty + (self.__ref_height + self.__line_space) * init_scale
    end

    lgx.pop()

    self:pop()

    -- love.graphics.setColor(0, 0, 0, 0.3)
    -- love.graphics.line(x, 0, x, love.graphics.getHeight())
    -- love.graphics.line(x + limit_right, 0, x + limit_right, love.graphics.getHeight())
end

local AlignOptions = {
    left = 1,
    right = 2,
    center = 3,
    justify = 4
}

local phrase_construct_table = {}

---@param self JM.Font.Font
function Font:generate_phrase(text, x, y, right, align)
    align = align or "left"
    x = x or 0
    y = y or 0
    right = right or (MATH_HUGE - x)

    self.buffer__ = self.buffer__ or setmetatable({}, metatable_mode_k)

    if not self.buffer__[text] then
        self.buffer__[text] = setmetatable({}, metatable_mode_v)
    end

    local index = str_format("%d %d %s", x, y, AlignOptions[align])

    if not self.buffer__[text][index] then
        phrase_construct_table.text = text
        phrase_construct_table.font = self
        phrase_construct_table.x = x
        phrase_construct_table.y = y
        -- local f = Phrase:new({ text = text, font = self, x = x, y = y })
        local f = Phrase:new(phrase_construct_table)
        self.buffer__[text][index] = f
    end

    ---@type JM.Font.Phrase
    local fr = self.buffer__[text][index]
    fr:set_bounds(nil, nil, right)

    local lines = fr:get_lines()
    return fr, fr:width(lines), fr:text_height(lines)
end

function Font:get_text_dimensions(text, x, y, w, align)
    x = x or 0
    y = y or 0
    w = w or 100000000
    align = align or "left"
    local _, width, height = self:generate_phrase(text, x, y, w, align)
    return width, height
end

---@param text any
---@param x any
---@param y any
---@param right any
---@param align any
function Font:printx(text, x, y, right, align)
    if type(right) == "string" then
        right, align = align, right
    end

    local fr = self:generate_phrase(text, x, y, right, align)
    local value = fr:draw(x, y, align)

    return fr
end

function Font.flush()
    -- self.buffer__ = nil

    for k, v in pairs(printf_lines) do
        printf_lines[k] = nil
    end

    for k, v in pairs(codes_result) do
        codes_result[k] = nil
    end

    for k, v in pairs(tag_args_result) do
        tag_args_result[k] = nil
    end

    for k, v in pairs(result_sep_text) do
        result_sep_text[k] = nil
    end

    Iterator.flush()
    return Phrase.flush()
end

---@class JM.Font.Generator
local Generator = {
    ---@param args JM.FontGenerator.Args
    new = function(self, args)
        -- local f = Font
        return Font.new(Font, args)
    end,
    --
    --
    new_by_ttf = function(self, args)
        args = args or {}
        local imgData, glyphs, quads_pos = load_by_tff(
            args.name,
            args.dir or args.path, args.dpi, args.save, args.threshold, nil,
            args.max_texturesize, args.hinting, args.dpiscale
        )
        args.regular_data = imgData
        args.regular_quads = quads_pos

        do
            local data, _, quads = load_by_tff(
                args.name .. " bold",
                args.dir_bold or args.path_bold,
                args.dpi, args.save, args.threshold,
                glyphs, args.max_texturesize,
                args.hinting, args.dpiscale
            )

            args.bold_data = data
            args.bold_quads = quads
        end

        do
            local italic_data, _, quads = load_by_tff(
                args.name .. " italic",
                args.dir_italic or args.path_italic,
                args.dpi, args.save, args.threshold,
                glyphs, args.max_texturesize,
                args.hinting, args.dpiscale
            )

            args.italic_data = italic_data
            args.italic_quads = quads
        end

        args.glyphs = glyphs

        do
            local font = Font.new(Font, args)
            local font_size = args.font_size
            if font_size then font:set_font_size(font_size) end
            return font
        end
    end,
    --
    --
    flush = function()
        return Font.flush()
    end
}

Generator.load_by_img = Generator.new
Generator.load_by_fontfile = Generator.new_by_ttf
Generator.get_glyphs = get_glyphs

return Generator
