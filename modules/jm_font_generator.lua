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

local table_insert, string_find = table.insert, string.find
local love_draw, love_set_color = love.graphics.draw, love.graphics.setColor
local MATH_HUGE = math.huge

---@param nickname string
---@return string|nil
local function is_valid_nickname(nickname)
    return #nickname > 4 and nickname:match("%-%-[^%-][%w%p]-%-%-") or nil
end

local getGlyphsResult = setmetatable({}, { __mode = 'kv' })

---@param s string
local function get_glyphs(s)
    if not s then return {} end

    local result = getGlyphsResult[s]
    if result then return result end

    local t = {}
    for p, c in utf8.codes(s) do
        table.insert(t, utf8.char(c))
    end

    getGlyphsResult[s] = t

    return t
end

local findNicksResult = setmetatable({}, { __mode = 'v' })

---@param t table
local function find_nicks(t)
    local result = findNicksResult[t]
    if result then return result end

    local next_ = function(init)
        local i = init
        local n = #t
        while (i <= n) do
            if t[i] == '-' and t[i + 1] and t[i + 1] == '-' then
                return (i + 1)
            end
            i = i + 1
        end
        return false
    end

    local i = 1
    local N = #t
    local new_table = {}

    while (i <= N) do
        if t[i] == '-' and t[i + 1] and t[i + 1] == '-' then
            local next = next_(i + 2)
            if next then
                local s = ''
                for k = i, next do
                    s = s .. t[k]
                end

                if is_valid_nickname(s) then
                    table_insert(new_table, s)
                    i = next
                end
            end
        else
            table_insert(new_table, t[i])
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

---@alias JM.AvailableFonts
---|"consolas"
---|"JM caligraphy"

---@class JM.Font.Font
---@field __nicknames table
local Font = {
    buffer_time = 0.0
}

---@overload fun(self: table, args: JM.AvailableFonts)
---@param args {name: JM.AvailableFonts, font_size: number, line_space: number, tab_size: number, character_space: number, color: JM.Color, glyphs:string, glyphs_bold:string, glyphs_italic:string, glyphs_bold_italic:string, regular_data: love.ImageData, bold_data:love.ImageData, italic_data:love.ImageData, regular_quads:any, italic_quads:any, bold_quads:any}
---@return JM.Font.Font new_Font
function Font:new(args)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Font.__constructor__(obj, args)

    return obj
end

---@overload fun(self: table, args: JM.AvailableFonts)
---@param args {name: JM.AvailableFonts, font_size: number, line_space: number, tab_size: number, character_space: number, color: JM.Color, glyphs:string, glyphs_bold:string, glyphs_italic:string, glyphs_bold_italic:string, regular_data: love.ImageData, bold_data:love.ImageData, italic_data:love.ImageData, regular_quads:any, italic_quads:any, bold_quads:any}
function Font:__constructor__(args)
    if type(args) == "string" then
        local temp_table = {}
        temp_table.name = args
        args = temp_table
    end

    self.__imgs = {}

    self.__nicknames = {}

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

    local dir = path:gsub("modules.jm_font_generator", "data/font/")
        .. "%s/%s.png"

    self:load_characters(args.regular_data
    or string.format(dir, args.name, args.name),
        FontFormat.normal, find_nicks(get_glyphs(args.glyphs)),
        args.regular_quads
    )


    if not args.regular_data or args.bold_data then
        self:load_characters(args.bold_data
        or string.format(dir, args.name, args.name .. "_bold"),
            FontFormat.bold, find_nicks(get_glyphs(args.glyphs_bold or args.glyphs)),
            args.bold_quads
        )
    else
        self.__characters[FontFormat.bold] = self.__characters[FontFormat.normal]
        self.__imgs[FontFormat.bold] = self.__imgs[FontFormat.normal]
    end

    if (not args.regular_data or args.italic_data) then
        self:load_characters(args.italic_data
        or string.format(dir, args.name, args.name .. "_italic"),
            FontFormat.italic, find_nicks(get_glyphs(args.glyphs_italic or args.glyphs)),
            args.italic_quads
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

    self.__word_space = self.__ref_height * 0.6

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
        self.__characters[format][nule_glyph.__id] = nule_glyph
    end

    self.__default_color = args.color or { 0.1, 0.1, 0.1, 1 }

    self.__bounds = { left = 0, top = 0, right = love.graphics.getWidth(), bottom = love.graphics.getHeight() }

    self.batches = {
        [FontFormat.normal] = self.__imgs[FontFormat.normal] and
        love.graphics.newSpriteBatch(self.__imgs[FontFormat.normal])
        or nil,
        [FontFormat.bold] = self.__imgs[FontFormat.bold] and
        love.graphics.newSpriteBatch(self.__imgs[FontFormat.bold]) or nil,
        [FontFormat.italic] = self.__imgs[FontFormat.italic] and
        love.graphics.newSpriteBatch(self.__imgs[FontFormat.italic]) or nil
    }
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

-- function Font:__load_caracteres_from_csv(list, name, img, extend, format)
--     if not extend then extend = "" end

--     local lines = Utils:get_lines_in_file("/JM_love2d_package/data/Font/" .. name .. "/" .. name .. extend .. ".txt")

--     for i = 2, #lines do
--         local parse = Utils:parse_csv_line(lines[i])
--         local id = (parse[1])
--         if id == "" then
--             id = ","
--         elseif id == [[_"]] then
--             id = [["]]
--         end
--         local left = tonumber(parse[2])
--         local right = tonumber(parse[3])
--         local top = tonumber(parse[4])
--         local bottom = tonumber(parse[5])
--         local offset_y = tonumber(parse[6])
--         local offset_x = tonumber(parse[7])

--         if not left then
--             break
--         end

--         local character_obj = Glyph:new(img,
--             { id = id, x = left, y = top, w = right - left, h = bottom - top, bottom = offset_y, format = format }
--         )

--         list[character_obj.__id] = character_obj
--     end

--     local nule_char = self:get_nule_character()

--     list[nule_char.__id] = nule_char
-- end

---@param path any
---@param format JM.Font.FormatOptions
---@param glyphs table
function Font:load_characters(path, format, glyphs, quads_pos)
    -- try load the img data
    local success, img_data = pcall(
            function()
                return type(path) == "string" and love.image.newImageData(path)
                    or path
            end
        )

    if not success or not path then return end

    local list = {} -- list of glyphs
    local mask_color = { 1, 1, 0, 1 }
    local mask_color_red = { 1, 0, 0, 1 }

    local function equals(r, g, b, a)
        return r == mask_color[1] and g == mask_color[2] and b == mask_color[3] and a == mask_color[4]
    end

    local function equals_red(r, g, b, a)
        return r == mask_color_red[1] and g == mask_color_red[2] and b == mask_color_red[3] and a == mask_color_red[4]
    end

    local img
    do
        local width, height = img_data:getDimensions()

        local data = love.image.newImageData(width, height)
        data:paste(img_data, 0, 0, 0, 0, width, height)

        local w, h = data:getDimensions()
        for i = 0, w - 1 do
            for j = 0, h - 1 do
                if equals(data:getPixel(i, j)) then
                    data:setPixel(i, j, 0, 0, 0, 0)
                end
            end
        end
        img = love.graphics.newImage(data)
        img:setFilter("linear", "linear")
        data:release()
    end

    local w, h = img_data:getDimensions()
    local cur_id = 1

    local i = 0
    local N_glyphs = #glyphs

    while not quads_pos and (i <= w - 1) do
        if cur_id > N_glyphs then break end

        local j = 0
        while (j <= h - 1) do
            local r, g, b, a = img_data:getPixel(i, j)
            if a == 0 then
                local qx, qy, qw, qh, bottom
                qx, qy = i, j

                for k = i, w - 1 do
                    local r, g, b, a = img_data:getPixel(k, j)
                    if equals(r, g, b, a) then
                        qw = k - qx
                        break
                    end
                end

                for p = j, h - 1 do
                    local r, g, b, a = img_data:getPixel(qx, p)
                    if equals(r, g, b, a) then
                        qh = p - qy
                        break
                    elseif equals_red(img_data:getPixel(qx - 1, p)) then
                        bottom = p
                    end
                end

                if not bottom then
                    for p = qh, h - 1 do
                        if equals_red(img_data:getPixel(qx - 1, p)) then
                            bottom = p
                            break
                        end
                    end
                end

                qh = qh or (h - 1)

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

                list[glyph.__id] = glyph

                if is_valid_nickname(glyph.__id) then
                    table_insert(self.__nicknames, glyph.__id)
                end

                cur_id = cur_id + 1
                i = qx + qw
            end
            j = j + 1
        end
        i = i + 1
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

                list[glyph.__id] = glyph
            end

            cur_id = cur_id + 1
        end
    end

    -- local nule_char = self:get_nule_character()
    -- list[nule_char.__id] = nule_char

    self.__characters[format] = list
    self.__imgs[format] = img
end

local function load_by_tff(name, path, dpi)
    if not name or not path then return end

    ---@type love.Rasterizer
    local render

    local success

    success, render = pcall(function()
            return love.font.newRasterizer(path, dpi or 64)
        end)

    if not success or not path then return end

    local glyphs = "aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVxXyYzZ0123456789."
    glyphs =
    [[aAàÀáÁãÃâÂäÄeEéÉèÈêÊëËiIíÍìÌîÎïÏoOóÓòÒôÔõÕöÖuUúÚùÙûÛüÜbBcCçÇdDfFgGhHjJkKlLmMnNpPqQrRsStTvVwWxXyYzZ0123456789+-=/*%\#§@({[]})|_"'!?,.:;ªº°¹²³£¢¬¨~$<>&^`]]

    local glyph_table = get_glyphs(glyphs)
    local N_glyphs = #glyph_table
    local cur_id = 1

    local cur_x = 4
    local cur_y = 2

    local glyphs_obj = {}
    local glyphs_data = {}
    local total_width = cur_x
    local max_height = -math.huge

    for _, glyph_s in ipairs(glyph_table) do
        local glyph = render:getGlyphData(glyph_s)

        if glyph then
            local w, h = glyph:getDimensions()
            local bbx, bby, bbw, bbh = glyph:getBoundingBox()

            local glyphData = love.image.newImageData(w, h, "rgba8", glyph:getString():gsub("(.)(.)", "%1%1%1%2"))
            local glyphDataWidth, glyphDataHeight = glyphData:getDimensions()

            total_width = total_width + glyphDataWidth + 4
            local height = glyphDataHeight + cur_y + 4
            max_height = (height > max_height and height) or max_height

            glyphs_obj[glyph_s] = glyph
            glyphs_data[glyph] = glyphData
        end
    end
    -- max_height = max_height + 100

    cur_x = 4
    cur_y = 2
    local font_imgdata = love.image.newImageData(total_width, max_height, "rgba8")
    local data_w, data_h = font_imgdata:getDimensions()
    local quad_pos = {}

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

            -- local py = cur_y
            cur_y = data_h - 2 - glyphDataHeight + (bby < 0 and bby or 0)

            for i = -1, glyphDataWidth do
                font_imgdata:setPixel(cur_x + i, cur_y - 1, 0, 0, 0, 0)
                font_imgdata:setPixel(cur_x + i, cur_y + glyphDataHeight, 0, 0, 0, 0)
            end

            for j = -1, glyphDataHeight do
                font_imgdata:setPixel(cur_x - 1, cur_y + j, 0, 0, 0, 0)
                font_imgdata:setPixel(cur_x + glyphDataWidth, cur_y + j, 0, 0, 0, 0)
            end

            font_imgdata:paste(glyphData, cur_x, cur_y, 0, 0, glyphDataWidth, glyphDataHeight)

            local posR_y = math.abs(cur_y + (bby + bbh))
            if posR_y >= 0 and posR_y <= data_h - 1 then
                font_imgdata:setPixel(cur_x - 2, posR_y, 1, 0, 0, 1)
            end

            local posBlue = math.floor(cur_x + bbw - (bbx > 0 and 0 or -bbx))
            if posBlue >= 0 and posBlue <= data_w - 1 then
                font_imgdata:setPixel(posBlue, cur_y - 2, 1, 0, 0, 1)
            end

            quad_pos[glyph_s] = {
                x = cur_x - 1,
                y = cur_y - 1,
                w = glyphDataWidth + 2,
                h = glyphDataHeight + 2,
                bottom = (posR_y >= 0 and posR_y <= data_h - 1 and posR_y)
                or nil,
                right = (posBlue >= 0 and posBlue <= data_w - 1 and posBlue) or nil
            }

            cur_x = cur_x + glyphDataWidth + 4

            -- if _ == 125 then break end
        end
    end

    --font_imgdata:encode("png", name:match(".*[^%.]") .. ".png")

    return font_imgdata, glyphs, quad_pos
end

---@return JM.Font.Glyph
function Font:get_nule_character()
    local char_ = Glyph:new(nil,
            { id = "__nule__", x = nil, y = nil, w = self.__word_space, h = self.__ref_height })

    return char_
end

---@alias JM.Font.Configuration {font_size: number, character_space: number, color: JM.Color, line_space: number, word_space: number, tab_size: number, format: JM.Font.FormatOptions }

local results_get_config = setmetatable({}, { __mode = 'k' })

---@return JM.Font.Configuration
function Font:__get_configuration()
    local index = string.format("%d %d %.2f %.2f %.2f %.2f %d %d",
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
    }

    results_get_config[self] = results_get_config[self] or setmetatable({}, { __mode = 'v' })
    results_get_config[self][index] = config

    return config
end

function Font:push()
    if not self.__config_stack__ then
        self.__config_stack__ = {}
    end

    assert(#self.__config_stack__ >= 0, "\nError: Too many push operations. Are you using more push than pop?")

    local config = self:__get_configuration()
    table.insert(self.__config_stack__, config)
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

    local config = table.remove(self.__config_stack__, #self.__config_stack__)

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
    self.__scale = Utils:desired_size(nil, self.__font_size, nil, self.__ref_height, true).y
end

---@param nickname string
--- @param args {img: love.Image|string, frames: number, frames_list: table,  speed: number, rotation: number, color: JM.Color, scale: table, flip_x: boolean, flip_y: boolean, is_reversed: boolean, stop_at_the_end: boolean, amount_cycle: number, state: JM.AnimaStates, bottom: number, kx: number, ky: number, width: number, height: number, ref_width: number, ref_height: number, duration: number, n: number}
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

    table_insert(self.__nicknames, nickname)

    for _, format in pairs(FontFormat) do
        self.__characters[format][nickname] = new_character
    end

    return animation
end

---@param s string
---@return string|nil nickname
function Font:__is_a_nickname(s, index)
    for _, nickname in ipairs(self.__nicknames) do
        if s:sub(index, index + #nickname - 1) == nickname then
            return nickname
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
    for i = 1, #(self.__nicknames), 1 do
        local character = self:__get_char_equals(self.__nicknames[i])
        local r = character and character:update(dt)
    end
end

---@param c string
---@return JM.Font.Glyph|nil
function Font:__get_char_equals(c)
    if not c then return nil end

    local char_ = self.__characters[self.__format][c]

    if not char_ and is_valid_nickname(c) then
        for _, format in pairs(FontFormat) do
            char_ = self.__characters[format][c]
            if char_ then return char_ end
        end
    end

    return char_
end

local result_sep_text = setmetatable({}, { __mode = 'kv' })

---@param s string
function Font:separate_string(s, list)
    s = s .. " "
    local result = not list and result_sep_text[s]
    if result then return result end

    local sep = "\n "
    local current_init = 1
    local words = list or {}

    while (current_init <= #(s)) do
        local regex = string.format("[^[ ]]*.-[%s]", sep)
        local tag_regex = "< *[%d, =._%w/%-]*>"

        local tag = s:match(tag_regex, current_init)
        local find = not tag and s:match(regex, current_init)
        local nick = false --find and string.match(find, "%-%-%w-%-%-")

        if tag then
            local startp, endp = string_find(s, tag_regex, current_init)
            local sub_s = s:sub(startp, endp)
            local prev_s = s:sub(current_init, startp - 1)

            if prev_s ~= "" and prev_s ~= " " then
                self:separate_string(prev_s, words)
            end

            table_insert(words, sub_s)
            current_init = endp
        elseif nick and nick ~= "----" then
            local startp, endp = string.find(s, "%-%-%w-%-%-", current_init)
            local sub_s = s:sub(startp, endp)
            local prev_word = s:sub(current_init, startp - 1)

            if prev_word and prev_word ~= "" and prev_word ~= " " then
                self:separate_string(prev_word, words)
            end

            if sub_s ~= "" and sub_s ~= " " then
                table_insert(words, sub_s)
            end

            current_init = endp
        elseif find then
            local startp, endp = string_find(s, regex, current_init)
            local sub_s = s:sub(startp, endp - 1)

            if sub_s ~= "" and sub_s ~= " " then
                table_insert(words, sub_s)
            end

            if s:sub(endp, endp) == "\n" then
                table_insert(words, "\n")
            end

            current_init = endp
        else
            break
        end

        current_init = current_init + 1
    end

    local rest = s:sub(current_init, #s)

    if rest ~= "" and not rest:match(" *") then
        table_insert(words, s:sub(current_init, #s))
    end

    result_sep_text[s] = words

    return words
end

---@alias JM.Font.Tags "<bold>"|"</bold>"|"<italic>"|"</italic>"|"<color>"|"</color>"|"<effect>"|"</effect>"|"<pause>"

---@param s string
---@return JM.Font.Tags|false
function Font:__is_a_command_tag(s)
    return (s:match("< *bold *[ %w%-]*>") and "<bold>")
        or (s:match("< */ *bold *[ %w%-]*>") and "</bold>")
        or (s:match("< *italic *[ %w%-]*>") and "<italic>")
        or (s:match("< */ *italic *[ %w%-]*>") and "</italic>")
        or (s:match("< *color[%d, .]*>") and "<color>")
        or (s:match("< */ *color[ %w%-]*>") and "</color>")

        or (s:match("< *effect *=[%w, =%.]* *>") and "<effect>")
        or (s:match("< */ *effect *[ %w%-]*>") and "</effect>")

        or (s:match("< *pause *=[ %d%.]*[, %w%-]*>") and "<pause>")
        or (s:match("< *font%-size *=[ %d%.]*[, %w%-]*>") and "<font-size>")
        or (s:match("< */ *font%-size *[, %w%-]*>") and "</font-size>")

        or (s:match("< *text%-box[ ,=%w%._]*>") and "<text-box>")
        or (s:match("< *sep[ %w,%-]*>") and "<sep>")
        or false
end

---@param text string
function Font:print(text, x, y, w, h, __i__, __color__, __x_origin__, __format__)
    if not text or text == "" then return x, y end

    self:push()

    w = w or nil --love.graphics.getWidth() - 100
    h = h or love.graphics.getHeight()

    local tx = x
    local ty = y

    local current_color = __color__ or self.__default_color
    local original_color = self.__default_color

    local current_format = __format__ or self.__format
    local original_format = self.__format

    local x_origin = __x_origin__ or tx

    local i = __i__ or 1

    local text_size = #(text)

    -- self.batches[FontFormat.normal]:clear()
    -- self.batches[FontFormat.bold]:clear()
    -- self.batches[FontFormat.italic]:clear()

    for _, batch in pairs(self.batches) do
        batch:clear()
    end

    while (i <= text_size) do
        local char_string = text:sub(i, i)
        local is_a_nick = self:__is_a_nickname(text, i)

        if is_a_nick then
            char_string = is_a_nick
            i = i + #char_string - 1
        end

        local tag = text:match("<.->", i)
        if tag then
            local match = self:__is_a_command_tag(tag)

            local startp, endp = text:find("<.->", i)

            local r_tx, r_ty
            if match then
                r_tx, r_ty = self:print(text:sub(i, startp - 1),
                        tx, ty, w, h, 1,
                        current_color, x_origin, current_format
                    )
            end

            if match == "<color>" then
                local parse = Utils:parse_csv_line(text:sub(startp - 1, endp - 1))
                local r = parse[2] or 1
                local g = parse[3] or 0
                local b = parse[4] or 0
                local a = parse[5] or 1

                current_color = Utils:get_rgba(r, g, b, a) --{ r, g, b, 1 }
            elseif match == "</color>" then
                current_color = original_color
            elseif match == "<bold>" then
                current_format = self.format_options.bold
            elseif match == "</bold>" then
                current_format = original_format
            elseif match == "<italic>" then
                current_format = self.format_options.italic
            elseif match == "</italic>" then
                current_format = original_format
            end

            if match then
                i = endp
                if endp == #text then
                    i = i + 1
                end
                tx = r_tx
                ty = r_ty
                char_string = ""
            end
        end

        self:set_format_mode(current_format)

        local char_obj = self:__get_char_equals(char_string)


        if not char_obj then
            char_obj = self:__get_char_equals(text:sub(i, i + 1))
        end

        if char_string == "\n"
            or (char_obj and w)
            and tx + self.__word_space + char_obj:get_width() >= x_origin + w
        then
            ty = ty + self.__ref_height * self.__scale + self.__line_space
            tx = x_origin
        end

        if char_obj then
            char_obj:set_color(current_color)

            char_obj:set_scale(self.__scale)

            if char_obj:is_animated() then
                char_obj:set_color2(1, 1, 1, 1)

                char_obj.__anima:set_size(
                    nil, self.__font_size * 1.4,
                    nil, char_obj.__anima:get_current_frame().h
                )

                char_obj:draw(tx + char_obj.w / 2 * char_obj.sx,
                    ty + char_obj.h / 2 * char_obj.sy
                )
            else
                local quad = char_obj:get_quad()
                local x, y
                -- x, y = char_obj:get_pos_draw_rec(tx, ty + self.__font_size - height, width, height)

                x = tx
                y = ty + self.__font_size - char_obj.h * char_obj.sy

                if quad then
                    self.batches[char_obj.format]:setColor(current_color)
                    self.batches[char_obj.format]:add(quad, x, y, 0, char_obj.sx, char_obj.sy, 0, 0)
                end
            end

            tx = tx + char_obj:get_width() + self.__character_space
        end

        i = i + 1
    end

    love_set_color(1, 1, 1, 1)
    for _, batch in pairs(self.batches) do
        local r = batch:getCount() > 0 and love_draw(batch)
    end

    self:pop()
    return tx, ty
end

local get_char_obj
local len
local print
local line_width
local next_not_command_index
local get_words
--- The functions below are used in the printf method
do
    get_char_obj =
    ---@return JM.Font.Glyph
    function(param)
        return param
    end

    len =
    ---@param args table
    ---@return number width
    function(self, args)
        local width = 0
        for _, obj in ipairs(args) do
            local char_obj = get_char_obj(args[_])
            width = width + char_obj:get_width() + self.__character_space
        end
        return width - self.__character_space
    end

    print =
    ---@param self JM.Font.Font
    ---@param word_list table
    ---@param tx number
    ---@param ty number
    ---@param index_action table
    ---@param current_color {[1]:JM.Color}
    function(self, word_list, tx, ty, index_action, exceed_space, current_color)
        exceed_space = exceed_space or 0

        if ty > self.__bounds.bottom
            or ty + self.__ref_height * self.__scale * 1.5 < self.__bounds.top
        then
            return
        end

        for _, batch in pairs(self.batches) do
            batch:clear()
        end

        for k, word in ipairs(word_list) do
            if index_action then
                for _, action in ipairs(index_action) do
                    if action.i == k then
                        action.action()
                    end
                end
            end

            for i = 1, #(word) do
                ---@type JM.Font.Glyph
                local char_obj = word[i] --get_char_obj(word[i])
                if char_obj then
                    char_obj:set_color2(Utils:unpack_color(current_color[1]))

                    char_obj:set_scale(self.__scale)

                    if char_obj:is_animated() then
                        char_obj:set_color2(1, 1, 1, 1)

                        char_obj.__anima:set_size(
                            nil, self.__font_size * 1.4,
                            nil, char_obj.__anima:get_current_frame().h
                        )

                        char_obj:draw(tx + char_obj.w / 2 * char_obj.sx,
                            ty + char_obj.h / 2 * char_obj.sy
                        )
                    else
                        local quad = char_obj:get_quad()
                        local x, y

                        x = tx
                        y = ty + self.__font_size
                            - (char_obj.h) * char_obj.sy

                        if quad then
                            self.batches[char_obj.format]:setColor(unpack(char_obj.color))
                            self.batches[char_obj.format]:add(quad, x, y, 0, char_obj.sx, char_obj.sy, 0,
                                0)
                        end

                        --char_obj:draw(x, y)
                    end

                    tx = tx + char_obj:get_width()
                        + self.__character_space
                end
            end

            tx = tx + exceed_space
        end

        love_set_color(1, 1, 1, 1)
        for _, batch in pairs(self.batches) do
            local r = batch:getCount() > 0 and love_draw(batch)
        end

        if index_action then
            for _, action in ipairs(index_action) do
                if action.i > #word_list then
                    action.action()
                end
            end
        end
    end


    line_width =
    ---@param self JM.Font.Font
    ---@param line table
    ---@return number
    function(self, line)
        local total = 0
        for _, word in ipairs(line) do
            total = total + len(self, word) + self.__character_space
        end
        return total
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

    local results_get_word = setmetatable({}, { __mode = 'kv' })

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

            table_insert(list, characters)

            i = i + 1
        end

        results_get_word[self] = results_get_word[self] or setmetatable({}, { __mode = 'k' })
        results_get_word[self][separated] = list

        return list
    end
end --- End auxiliary methods for printf


local color_pointer = {}

---@param text string
---@param x number
---@param y number
---@param align "left"|"right"|"center"|"justify"|nil
---@param limit_right number|nil
function Font:printf(text, x, y, align, limit_right)
    if not text or text == "" then return { tx = x, ty = y } end

    self:push()

    local tx = x
    local ty = y
    align = align or "left"
    limit_right = limit_right or 500.0 --love.mouse.getX() - x
    limit_right = limit_right - x

    local current_color = color_pointer
    current_color[1] = self.__default_color

    local original_color = self.__default_color

    local separated = self:separate_string(text)

    local words = get_words(self, separated)

    local total_width = 0
    local line = {}
    local line_actions = {}

    for m = 1, #(words) do
        local command_tag = self:__is_a_command_tag(separated[m])

        if command_tag and command_tag:match("color") then
            local action_i = #line + 1
            local action_func

            if command_tag == "<color>" then
                action_func = function()
                    local parse = Utils:parse_csv_line(separated[m]:sub(2, #separated[m] - 1))
                    local r = parse[2] or 1
                    local g = parse[3] or 0
                    local b = parse[4] or 0
                    local a = parse[5] or 1

                    current_color[1] = Utils:get_rgba(r, g, b, a)
                end
            elseif command_tag == "</color>" then
                action_func = function()
                    current_color[1] = original_color
                end
            end

            table_insert(line_actions, { i = action_i, action = action_func })
        end

        local current_is_break_line = separated[m] == "\n"

        if not command_tag then
            if not current_is_break_line or true then
                table_insert(
                    line,
                    words[m]
                )
            end

            local next_index = next_not_command_index(self, m, separated)

            total_width = total_width + len(self, words[m])
                + self.__space_char:get_width()
                + self.__character_space * 2

            if total_width + (next_index and words[next_index]
                and len(self, words[next_index]) or 0) > limit_right

                or current_is_break_line
            then
                local lw = line_width(self, line)

                local div = #line - 1
                div = div <= 0 and 1 or div
                div = separated[m] == "\n" and lw <= limit_right * 0.8
                    and 100 or div

                local ex_sp = align == "justify"
                    and (limit_right - lw) / div
                    or nil

                local pos_to_draw = (align == "left" and x)
                    or (align == "right" and (x + limit_right) - lw)
                    or (align == "center" and x + limit_right / 2 - lw / 2)
                    or x

                print(self, line, pos_to_draw, ty, line_actions, ex_sp, current_color)

                total_width = 0

                ty = ty + self.__ref_height * self.__scale
                    + self.__line_space

                line = {}
                line_actions = {}
            else
                local next_index = next_not_command_index(self, m, separated)

                local next_is_broken_line = next_index and separated[next_index]
                    and separated[next_index] == "\n"

                if m ~= #words and not next_is_broken_line then
                    table_insert(
                        line,
                        { self.__space_char }
                    )
                end
            end
        end

        if line and m == #words then
            local lw = line_width(self, line)

            local pos_to_draw = (align == "left" and x)
                or (align == "right" and tx + limit_right - lw)
                or (align == "center" and tx + limit_right / 2 - lw / 2)
                or x

            print(self, line, pos_to_draw, ty, line_actions, nil, current_color)
        end
    end

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

---@param self JM.Font.Font
function Font:generate_phrase(text, x, y, right, align)
    align = align or "left"
    right = right or (MATH_HUGE - x)

    self.buffer__ = self.buffer__ or setmetatable({}, { __mode = 'k' })

    if not self.buffer__[text] then
        self.buffer__[text] = setmetatable({}, { __mode = 'v' })
    end

    local index = string.format("%d %d %s", x, y, AlignOptions[align])

    if not self.buffer__[text][index] then
        local f = Phrase:new({ text = text, font = self, x = x, y = y })
        self.buffer__[text][index] = f
    end

    ---@type JM.Font.Phrase
    local fr = self.buffer__[text][index]
    fr:set_bounds(nil, nil, right)

    return fr
end

---@param text any
---@param x any
---@param y any
---@param right any
---@param align any
function Font:printx(text, x, y, right, align)
    local fr = self:generate_phrase(text, x, y, right, align)
    local value = fr:draw(x, y, align)

    return fr
end

function Font:flush()
    self.buffer__ = nil
end

---@class JM.Font.Generator
local Generator = {
    new = function(self, args)
        local f = Font
        return Font.new(Font, args)
    end,
    new_by_ttf = function(self, args)
        args = args or {}
        local imgData, glyphs, quads_pos = load_by_tff(args.name,
                args.path, args.dpi)
        args.regular_data = imgData
        args.regular_quads = quads_pos

        do
            local data, gly, quads = load_by_tff(args.name .. " bold", args.path_bold, args.dpi)

            args.bold_data = data
            args.bold_quads = quads
        end

        do
            local italic_data, glyphs, quads = load_by_tff(
                    args.name .. " italic",
                    args.path_italic, args.dpi)

            args.italic_data = italic_data
            args.italic_quads = quads
        end

        args.glyphs = glyphs
        return Font.new(Font, args)
    end
}

return Generator
