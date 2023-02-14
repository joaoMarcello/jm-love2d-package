local utf8 = require('utf8')

---@class JM.Font.GlyphIterator
local Iterator = {}
Iterator.__index = Iterator

local iterators = setmetatable({}, { __mode = 'k' })

---@param text string
---@param font JM.Font.Font
---@return JM.Font.GlyphIterator
function Iterator:new(text, font)
    local obj = iterators[font] and iterators[font][text] and iterators[font][text][font.__format]

    if obj then
        obj.__current_index = 1
        return obj
    end


    obj = {}
    setmetatable(obj, self)

    Iterator.__constructor__(obj, text, font)

    iterators[font] = iterators[font] or setmetatable({}, { __mode = 'k' })
    iterators[font][text] = iterators[font][text] or setmetatable({}, { __mode = 'v' })
    iterators[font][text][font.__format] = obj

    return obj
end

---
---@param text string
---@param font JM.Font.Font
function Iterator:__constructor__(text, font)
    self.__current_index = 1
    self.__list_obj = {}

    local i = 1
    while (i <= #text) do
        local current_char, char_obj

        local is_nick = font:__is_a_nickname(text, i)
        if is_nick then
            current_char = is_nick
            i = i + #(is_nick) - 1
        else
            current_char = text:match(".", i)
        end

        char_obj = font:__get_char_equals(current_char)

        if not char_obj then
            char_obj = font:__get_char_equals(text:match("..", i))
            if char_obj then
                current_char = text:sub(i, i + 1)
                i = i + 1
            end
        end

        if not char_obj and current_char ~= "\n" then
            char_obj = font:get_nule_character()
        end

        table.insert(self.__list_obj, char_obj)

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
