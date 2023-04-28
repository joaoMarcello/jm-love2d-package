local utf8 = require "utf8"
local str_sub = string.sub
local tab_insert, tab_remove = table.insert, table.remove
local lgx = love.graphics
local huge = math.huge

---@type JM.GUI.Component
local Component = require((...):gsub("label", "component"))

local font = _G.JM_Font.current
local font_config = font:__get_configuration()

-- love.keyboard.setKeyRepeat(true)

---@param s string
local only_alpha_numeric = function(s)
    return string.match(s, "[%a%d_-]") -- letters or numbers
end

---@class JM.GUI.Label : JM.GUI.Component
local Label = setmetatable({
    --
    ---@param new_font JM.Font.Font
    set_font = function(self, new_font)
        font = new_font
        font_config = font:__get_configuration()
    end
    --
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

function Label:clear()
    self.text = ""
    self.count = 0
    self.width = 0

    local N = #self.lengths
    for i = 1, N do
        self.lengths[i] = nil
    end
end

function Label:textinput(t)
    if not self.on_focus then return end

    if ((self.filter and self.filter(t)) or not self.use_filter)
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
        self.show_line = true

        return true
    end
    return false
end

function Label:set_text(text)
    local focus = self.on_focus
    self.on_focus = true

    self:clear()

    for _, code in utf8.codes(text) do
        self:textinput(utf8.char(code))
    end

    self.on_focus = focus
end

function Label:key_pressed(key)
    if not self.on_focus then return end

    if key == "backspace" and self.count > 0 then
        local byteoffset = utf8.offset(self.text, -1)

        if byteoffset then
            local len = tab_remove(self.lengths, #self.lengths)
            self.width = self.width - len
            if self.width < 0 then self.width = 0 end

            self.text = str_sub(self.text, 1, byteoffset - 1)
            self.count = self.count - 1

            self.time = 0.0
            self.show_line = true
        end
        --
    elseif key == "return" then
        self:set_focus(false)
        --
    end
end

function Label:mouse_pressed(x, y, button, istouch, presses)
    if not self.on_focus and self:check_collision(x, y, 0, 0) then
        self:set_focus(true)
        self.time = -0.5
        self.show_line = true
        Component.mouse_pressed(self, x, y, button, istouch, presses)
    end
end

function Label:touch_pressed(id, x, y, dx, dy, pressure)
    if not self.on_focus and self:check_collision(x, y, 0, 0) then
        self:set_focus(true)
        self.time = -0.5
        self.show_line = true
        Component.touch_pressed(self, id, x, y, dx, dy, pressure)
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
        lgx.setColor(0, 0, 0)
        lgx.rectangle("line", self.x, self.y, self.w, self.h)
    end

    local px = self.x

    lgx.push()

    font:push()
    font:set_configuration(font_config)

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

    font:pop()
    lgx.pop()

    -- font:print(tostring(self.width), self.x, self.y - 22)
    -- font:print(tostring(self.count), self.x, self.y + self.h + 22)
end

return Label
