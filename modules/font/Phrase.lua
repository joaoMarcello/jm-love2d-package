local table_insert = table.insert

---@type JM.Font.Word
local Word = require((...):gsub("Phrase", "Word"))

---@type JM.Utils
local Utils = _G.JM_Utils

---@class JM.Font.Phrase
local Phrase = {}

---@param args {text: string, font: JM.Font.Font, x:any, y:any}
---@return JM.Font.Phrase phrase
function Phrase:new(args)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Phrase.__constructor__(obj, args)

    return obj
end

---@param args {text: string, font: JM.Font.Font, x:any, y:any}
function Phrase:__constructor__(args)
    assert(Utils, "\n> Module Utils not initialized!")

    self.text = args.text
    self.__font = args.font

    self.x = args.x or 0
    self.y = args.y or 0

    self.__font_config = self.__font:__get_configuration()

    self.__font:push()

    self.__separated_string = self.__font:separate_string(self.text)
    self.__words = {}

    self.__bounds = { top = 0, left = 0, bottom = love.graphics.getHeight(), right = love.graphics.getWidth() - 100 }

    local prev_word
    self.tags = {}
    self.word_to_tag = {}

    for i = 1, #self.__separated_string do
        local w = Word:new({
                text = self.__separated_string[i],
                font = self.__font,
                format = self.__font:get_format_mode()
            })

        local tag_values = self:__verify_commands(w.text)

        if w.text ~= "" then
            if not self.__font:__is_a_nickname(w.text, 1) then
                w:set_color(self.__font.__default_color)
            end

            local is_command_tag = self.__font:__is_a_command_tag(w.text)

            table_insert(self.__words, w)

            if tag_values then
                tag_values["prev"] = prev_word
                table_insert(self.tags, tag_values)

                local index = prev_word or "first"
                self.word_to_tag[index] = self.word_to_tag[index] or {}
                table_insert(self.word_to_tag[index], tag_values)
            end

            prev_word = (not is_command_tag and w) or prev_word
        end
    end

    Word:restaure_effect()

    self.__font:pop()
end

---@param s string
local function get_tag_args(s)
    if not s or s == "" then return {} end
    s = s:sub(2, #s - 1)
    if not s or s == "" then return {} end

    local N = #s
    local i = 1
    local result = {}

    while (i <= N) do
        local startp, endp = s:find("[=,]", i)

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
                    right = true
                elseif tonumber(right) then
                    right = tonumber(right)
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

    return result
end

---@param text string
function Phrase:__verify_commands(text)
    local result = self.__font:__is_a_command_tag(text)

    if result then
        local tag_values = get_tag_args(text)
        tag_values["tag_name"] = result

        if result == "<bold>" then
            self.__font:set_format_mode(self.__font.format_options.bold)
            --
        elseif result == "</bold>" then
            self.__font:set_format_mode(self.__font_config.format)
            --
        elseif result == "<color>" then
            local tag = text:match("< *color[ ,%d.]*>")
            local parse = Utils:parse_csv_line(tag:sub(2, #tag - 1))
            local r = tonumber(parse[2]) or 1
            local g = tonumber(parse[3]) or 0
            local b = tonumber(parse[4]) or 0
            local a = tonumber(parse[5]) or 1

            self.__font:set_color({ r, g, b, a })
        elseif result:match("< */ *color *>") then
            self.__font:set_color(self.__font_config.color)
        elseif result:match("< *italic *>") then
            self.__font:set_format_mode(self.__font.format_options.italic)
        elseif result:match("< */ *italic *>") then
            self.__font:set_format_mode(self.__font_config.format)
        end

        return tag_values
    end
end

function Phrase:set_bounds(top, left, right, bottom)
    self.__bounds.top = top or self.__bounds.top
    self.__bounds.left = left or self.__bounds.left
    self.__bounds.right = right or self.__bounds.right
    self.__bounds.bottom = bottom or self.__bounds.bottom
end

---@return JM.Font.Word
function Phrase:get_word_by_index(index)
    return self.__words[index]
end

local results_get_lines = setmetatable({}, { __mode = 'k' })

---@return table
function Phrase:get_lines(x)
    local key = string.format("%d %d", x, self.__font.__font_size)
    local result = results_get_lines[self] and results_get_lines[self][key]
    if result then return result end

    local lines = {}
    local tx = x
    local cur_line = 1
    local word_char = Word:new({ text = " ", font = self.__font })

    local effect = nil
    local eff_args = nil
    local prev_word

    for i = 1, #self.__words do
        ---@type JM.Font.Word
        local current_word = self.__words[i]

        ---@type JM.Font.Word|nil
        local next_word = self.__words[i + 1]

        -- ---@type JM.Font.Word
        -- local prev_word = self.__words[i - 1]

        local cur_is_tag = self.__font:__is_a_command_tag(current_word.text)

        local r = current_word:get_width()
            + word_char:get_width()

        if cur_is_tag then
            if current_word.text:match("no%-space") then
                -- eliminating tha last added glyph object if his id equals "space"

                local last_added = lines[cur_line] and lines[cur_line][#lines[cur_line]]

                if last_added and last_added.text == " " then
                    table.remove(lines[cur_line], #lines[cur_line])
                end
            end

            goto skip_word
        end

        do
            local tags = self.word_to_tag[prev_word]
                or self.word_to_tag["first"]

            if tags then
                for i = 1, #tags do
                    local tag = tags[i]
                    local tag_name = tag["tag_name"]

                    if tag_name == "<effect>" then
                        effect = effect or {}
                        table_insert(effect, tag['effect'])

                        eff_args = eff_args or {}
                        table_insert(eff_args, tag)
                    elseif tag_name == "</effect>" then
                        effect = nil
                        eff_args = nil
                    end
                end
            end
        end

        prev_word = current_word

        if effect and eff_args then
            for i = 1, #effect do
                local eff = effect[i]
                local args = eff_args[i]
                current_word:apply_effect(nil, nil, eff, nil, args)
            end
        end


        if tx + r > self.__bounds.right
            or current_word.text:match("\n ?") then
            tx = x

            -- Try remove the last added space word
            ---@type JM.Font.Word
            local last_added = lines[cur_line] and lines[cur_line][#(lines[cur_line])]

            if last_added and last_added.text == " " then
                table.remove(lines[cur_line], #lines[cur_line])
            end
            --=========================================================

            if not lines[cur_line] then lines[cur_line] = {} end
            cur_line = cur_line + 1
            if not lines[cur_line] then lines[cur_line] = {} end
        end

        if not lines[cur_line] then lines[cur_line] = {} end

        if current_word.text ~= "\n" then
            table_insert(lines[cur_line], current_word)
        else
            if lines[cur_line - 1] then
                table_insert(lines[cur_line - 1], current_word)
            end
        end

        if i ~= #(self.__words)
            and current_word.text ~= "\t"
            and current_word.text ~= "\n"
            and next_word and next_word.text ~= "\t"
        then
            table_insert(lines[cur_line], word_char)
        end

        tx = tx + r

        ::skip_word::
    end

    table_insert(
        lines[cur_line],
        Word:new({ text = "\n", font = self.__font })
    )

    results_get_lines[self] = results_get_lines[self]
        or setmetatable({}, { __mode = 'v' })
    results_get_lines[self][key] = lines

    return lines
end -- END function get_lines()

function Phrase:text_height(lines)
    if not lines then return end
    lines = lines or self:get_lines(self.x)

    ---@type JM.Font.Word
    local word = lines[1][1] or lines[1][2]

    if word then
        local h = word:get_height() * (#lines)
        return h --- self.__font.__line_space
    end
    return 0
end

function Phrase:__line_length(line)
    local total_len = 0

    for i = 1, #line do
        ---@type JM.Font.Word
        local word = line[i]
        total_len = total_len + word:get_width()
    end

    return total_len
end

function Phrase:width(lines)
    lines = lines or self:get_lines(self.x)
    local max = -math.huge
    local N = #lines

    for i = 1, N do
        local len = self:__line_length(lines[i])
        max = len > max and len or max
    end

    return max
end

function Phrase:update(dt)
    for i = 1, #self.__words, 1 do
        ---@type JM.Font.Word
        local w = self.__words[i]
        w:update(dt)
    end
end

---@param n number|nil
---@param lines table|nil
---@return JM.Font.Glyph|nil
---@return JM.Font.Word|nil
---@return boolean|nil
function Phrase:get_glyph(n, lines)
    if not n then return end
    lines = lines or self:get_lines(self.x)
    local count = 0

    local is_command_tag = self.__font.__is_a_command_tag

    for i = 1, #lines do
        for j = 1, #lines[i] do
            ---@type JM.Font.Word
            local word = lines[i][j]

            if is_command_tag(self.__font, word.text) then
                goto next_word
            end

            local N = #(word.__characters)
            count = count + N

            if count >= n then
                local exceed = count - n

                ---@type JM.Font.Glyph
                local glyph = word.__characters[N - exceed]

                return glyph, word, count == n
            end

            ::next_word::
        end
    end
end

local apply_commands = function(self, cur_word, init_font_size)
    local tags = self.word_to_tag[cur_word]
    if tags then
        for i = 1, #tags do
            local tag = tags[i]
            local name = tag["tag_name"]

            if name == "<font-size>" then
                self.__font:set_font_size(tag["font-size"])
            elseif name == "</font-size>" then
                self.__font:set_font_size(init_font_size)
            end
        end
        return true
    end
    return false
end

local pointer_char_count = { [1] = 0 }
---
---@param lines table
---@param x number
---@param y number
---@param align "left"|"right"|"center"|"justify"|nil
---@param threshold number|nil
---@return number|nil tx
---@return number|nil ty
---@return JM.Font.Glyph|nil glyph
function Phrase:draw_lines(lines, x, y, align, threshold, __max_char__)
    if not align then align = "left" end
    if not threshold then threshold = #lines end

    if __max_char__ and __max_char__ <= 0 then return end

    local tx, ty = x, y
    local space = 0
    local character_count = pointer_char_count --{ [1] = 0 }
    character_count[1] = 0

    local result_tx, result_char

    self.__font:push()

    local init_font_size = self.__font.__font_size

    for i = 1, #lines do
        if align == "right" then
            tx = self.__bounds.right - self:__line_length(lines[i])
        elseif align == "center" then
            tx = x + (self.__bounds.right - x) / 2 - self:__line_length(lines[i]) / 2
        elseif align == "justify" then
            local total = self:__line_length(lines[i])

            local len_line = #lines[i]
            local q = len_line - 1

            if lines[i][len_line] and lines[i][len_line].__text == "\n" then
                q = q * 2 + 7
                q = 100
            end

            if i == #lines or (i == 1 and #lines == 1) then
                --q = q + 10
                tx = x
                space = 0
                goto skip_justify
            end

            if q == 0 then q = 1 end
            space = (self.__bounds.right - x - total) / (q)

            tx = tx
            ::skip_justify::
        end

        for j = 1, #lines[i] do
            -- local current_word = self:__get_word_in_list(lines[i], j)

            ---@type JM.Font.Word
            local current_word = lines[i][j]

            local first = apply_commands(self, (i == 1 and j == 1 and "first")
                or nil, init_font_size)

            local r = current_word:get_width() + space

            result_tx, result_char = current_word:draw(tx, ty, __max_char__, character_count, ty + init_font_size)

            tx = tx + r

            apply_commands(self, not first and current_word, init_font_size)

            if result_tx then
                self.__font:pop()
                return result_tx, ty, result_char
            end
            ::continue::
        end

        tx = x
        ty = ty + (init_font_size + self.__font.__line_space)

        if i >= threshold then
            break
        end
    end

    self.__font:pop()

    return nil, ty, nil
end

-- function Phrase:refresh()
--     self.__last_lines__ = nil
-- end

function Phrase:__debbug()
    local s = self.text
    local w = self.__font:separate_string(s)

    -- w = self.__separated_string
    for i = 1, #w do
        --self.__font:print(tostring(w[i]), 32 * 10, 12 * i)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(tostring(w[i]), 32 * 10, 12 * i)
    end
end

---@param x number
---@param y number
---@param align "left"|"right"|"center"|"justify"|nil
---@param __max_char__ number|nil
---@param dt number|nil
function Phrase:draw(x, y, align, __max_char__, dt)
    if __max_char__ and __max_char__ == 0 then return end
    -- self:__debbug()

    self.x = x
    self.y = y

    self:update(dt or love.timer.getDelta())

    return self:draw_lines(
            self:get_lines(x),
            x, y, align,
            nil, __max_char__
        )

    -- love.graphics.setColor(0.4, 0.4, 0.4, 1)
    -- love.graphics.line(self.__bounds.right, 0, self.__bounds.right, 600)

    ------------------------------------------------------------------------
end

return Phrase
