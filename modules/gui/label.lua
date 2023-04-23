local utf8 = require "utf8"
local str_sub = string.sub
local tab_insert, tab_remove = table.insert, table.remove
local lgx = love.graphics
local huge = math.huge

---@type JM.GUI.Component
local Component = require((...):gsub("label", "component"))

local font = _G.JM_Font.current

love.keyboard.setKeyRepeat(true)

---@param s string
local only_alpha_numeric = function(s)
    return string.match(s, "[%a%d_-]") -- letters or numbers
end

---@class JM.GUI.Label : JM.GUI.Component
local Label = setmetatable({
    set_font = function(self, new_font)
        font = new_font
    end
}, Component)
Label.__index = Label

---@return JM.GUI.Label
function Label:new(args)
    args.h = args.h or (font.__font_size + 4)

    local obj = Component:new(args)
    setmetatable(obj, self)
    Label.__constructor__(obj, args)
    return obj
end

function Label:__constructor__(args)
    self.text = ""
    self.max = args.max or math.huge
    self.count = 0
    self.use_filter = args.use_filter
    self.width = 0
    self.lengths = {}
    self.filter = (self.use_filter and only_alpha_numeric) or args.filter
    self.align = args.align or "center"
    self.draw_border = args.border
    self.wait_line = args.line or 2
    self.time = 0.0
    self.speed = 0.5
    self.show_line = true
    self.text_help = args.text_help
end

function Label:textinput(t)
    if not self.on_focus then return end

    if ((self.use_filter and self.filter(t)) or not self.use_filter)
        and self.count < self.max
    then
        self.text = self.text .. t
        self.count = self.count + 1

        local glyph = font:__get_char_equals(t)

        if glyph then
            local len = glyph.w * font.__scale
            tab_insert(self.lengths, len)
            self.width = self.width + len
        end

        self.time = 0.0
        self.show_line = false

        return true
    end
    return false
end

function Label:key_pressed(key)
    if key == "backspace" and self.count > 0 then
        local byteoffset = utf8.offset(self.text, -1)

        if byteoffset then
            local len = tab_remove(self.lengths, #self.lengths)
            self.width = self.width - len
            if self.width < 0 then self.width = 0 end

            self.text = str_sub(self.text, 1, byteoffset - 1)
            self.count = self.count - 1

            self.time = 0.0
            self.show_line = false
        end
    end
end

function Label:update(dt)
    self.time = self.time + dt

    if self.time >= self.speed then
        self.time = self.time - self.speed
        if self.time >= self.speed then self.time = 0.0 end

        if self.show_line then
            self.show_line = false
        else
            self.show_line = true
        end
    end
end

function Label:__custom_draw__()
    if self.draw_border then
        lgx.setColor(1, 0, 0)
        lgx.rectangle("line", self.x, self.y, self.w, self.h)
    end

    local px = self.x

    lgx.push()
    if self.width > self.w then
        local off = self.width - self.w

        if self.align == "center" then
            lgx.translate(-off * 0.5, 0)
            --
        elseif self.align == "left" then
            lgx.translate(-off, 0)
        end
    end

    if self.align == "center" then
        px = self.x + self.w * 0.5 - self.width * 0.5
        font:print(self.text, px, self.y + 2, huge)


        --
    elseif self.align == "right" then
        px = self.x + self.w - self.width
        font:print(self.text, px, self.y + 2, huge)
        --
    else
        font:print(self.text, self.x, self.y + 2, huge)
    end


    if self.text_help and not self.on_focus and self.count <= 0 then
        font:print(self.text_help, self.x, self.y + 1, huge)
        --
    elseif self.show_line and self.on_focus then
        local px2 = px + self.width + 2

        lgx.setColor(font.__default_color)
        lgx.setLineWidth(1)
        lgx.line(px2, self.y + 1, px2, self.y + self.h - 1)
        lgx.setLineWidth(1)
    end

    lgx.pop()

    -- font:print(tostring(self.width), self.x, self.y - 22)
    -- font:print(tostring(self.count), self.x, self.y + self.h + 22)
end

return Label
