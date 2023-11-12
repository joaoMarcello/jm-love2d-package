local utf8 = require('utf8')
local tab_insert = table.insert

---@class JM.Font.GlyphIterator
local Iterator = {}
Iterator.__index = Iterator

local metatable_mode_k = { __mode = 'k' }
local metatable_mode_v = { __mode = 'v' }

local iterators = setmetatable({}, metatable_mode_k)

---@param text string
---@param font JM.Font.Font
---@return JM.Font.GlyphIterator
function Iterator:new(text, font)
    local obj = iterators[font] and iterators[font][text] and iterators[font][text][font.__format]

    if obj then
        obj.__current_index = 1
        return obj
    end

    local obj = {}
    setmetatable(obj, self)

    Iterator.__constructor__(obj, text, font)

    iterators[font] = iterators[font] or setmetatable({}, metatable_mode_k)
    iterators[font][text] = iterators[font][text] or setmetatable({}, metatable_mode_v)
    iterators[font][text][font.__format] = obj

    return obj
end

---
---@param text string
---@param font JM.Font.Font
function Iterator:__constructor__(text, font)
    self.__current_index = 1
    self.__list_obj = {}

    local codes = font.CODES[text]
    if not codes then
        codes = {}
        for p, c in utf8.codes(text) do
            codes[p] = utf8.char(c)
        end
        font.CODES[text] = codes
    end

    local i = 1
    -- while (i <= #text) do
    while i <= #codes do
        local current_char, glyph

        local is_nick = font:__is_a_nickname(text, i)
        if is_nick then
            current_char = is_nick
            i = i + #(is_nick) - 1
        else
            -- current_char = text:match(".", i)
            current_char = codes[i] --text:match(".", i)
        end

        glyph = font:__get_char_equals(current_char)

        -- if not glyph then
        --     glyph = font:__get_char_equals(text:match("..", i))
        --     if glyph then
        --         current_char = text:sub(i, i + 1)
        --         i = i + 1
        --     end
        -- end

        if not glyph and current_char ~= "\n" then
            glyph = font:get_nule_character()
        end

        if glyph then
            tab_insert(self.__list_obj, glyph)
        end

        i = i + 1
    end
end

---@return boolean
function Iterator:has_next()
    return self.__list_obj[self.__current_index] and true or false
end

---@return JM.Font.Glyph
function Iterator:next()
    self.__current_index = self.__current_index + 1
    return self.__list_obj[self.__current_index - 1]
end

function Iterator:get_characters_list()
    return self.__list_obj
end

return Iterator
