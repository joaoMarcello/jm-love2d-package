---@type JM.Font.Phrase
local Phrase = require((...):gsub("gui.textBox", "font.Phrase"))

local Affectable = _G.JM_Affectable

---@enum JM.GUI.TextBox.EventTypes
local Event = {
    finishScreen = 1,
    finishAll = 2,
    changeScreen = 3,
    glyphChange = 4,
    wordChange = 5
}
---@alias JM.GUI.TextBox.EventNames "finishScreen"|"finishAll"|"changeScreen"|"glyphChange"|"wordChange"

local Mode = {
    normal = 1,
    goddess = 2,
    popin = 3,
    rainbow = 4
}

local function mode_goddess(g)
    g:apply_effect("fadein", { speed = 0.2 })
end

local function mode_popin(g)
    g:apply_effect("popin", { speed = 0.2 })
end

local function mode_rainbow(g)
    g:set_color2(math.random(), math.random(), math.random())
end

local ModeAction = {
    normal = function(...) return false end,
    goddess = mode_goddess,
    popin = mode_popin,
    rainbow = mode_rainbow
}
---@alias JM.GUI.TextBox.Modes "normal"|"goddess"|"popin"|"rainbow"|nil


local Align = {
    top = 1,
    bottom = 2,
    center = 3
}

local UpdateMode = {
    by_glyph = 1,
    by_word = 2,
    by_screen = 3
}

---@param self JM.GUI.TextBox
---@param type_ JM.GUI.TextBox.EventTypes
local function dispatch_event(self, type_)
    local evt = self.events and self.events[type_]
    local r = evt and evt.action(evt.args)
end

---@class JM.GUI.TextBox: JM.Template.Affectable
local TextBox = setmetatable({}, Affectable)
TextBox.__index = TextBox

---@return JM.GUI.TextBox
function TextBox:new(text, font, x, y, w)
    local obj = Affectable:new()
    setmetatable(obj, self)

    -- text = "<effect=goddess, delay=0.05>" .. text
    TextBox.__constructor__(obj, { text = text, x = x, y = y, font = font }, w)
    return obj
end

function TextBox:__constructor__(args, w)
    self.sentence = Phrase:new(args)
    self.sentence:set_bounds(nil, nil, args.x + (w or (math.huge - args.x)))

    self.lines = self.sentence:get_lines(self.sentence.x)

    local lines_width = {}
    local max_width = -math.huge
    for _, line in ipairs(self.lines) do
        lines_width[line] = self.sentence:__line_length(line)
        max_width = lines_width[line] > max_width and lines_width[line]
            or max_width
    end

    self.align = "center"
    self.text_align = Align.center
    self.x = self.sentence.x
    self.y = self.sentence.y
    self.w = w or max_width
    self.h = -math.huge
    self.is_visible = true

    self.cur_glyph = 0
    self.time_glyph = 0.0
    self.max_time_glyph = 0.05
    self.extra_time = 0.0

    self.time_pause = 0.0

    self.simulate_speak = false
    self.update_mode = UpdateMode.by_screen

    self.font = self.sentence.__font
    self.font_config = self.font:__get_configuration()

    self.amount_lines = 4
    self.amount_screens = math.ceil(#self.lines / self.amount_lines) --3

    local N = #self.lines

    self.screens = {}
    local j = 1
    while j <= N do
        table.insert(self.screens,
            { unpack(self.lines, j, j + self.amount_lines - 1) })

        -- defining the textBox height
        local h = self.sentence:text_height(self.screens[#self.screens])
        self.h = h > self.h and h or self.h

        local screen = self.screens[#self.screens]

        -- removing empty lines
        local k = 1
        while k <= #screen do
            local line = screen[k]
            local N_line = #line

            if (N_line == 1 and line[1].text == "\n")
                or (N_line <= 0)
            then
                table.remove(screen, k)
                k = k - 1
            end
            k = k + 1
        end --end removing empty lines

        -- removing empty screens
        if #screen <= 0 then
            table.remove(self.screens, #self.screens)
            self.amount_screens = self.amount_screens - 1
        end

        j = j + self.amount_lines
    end

    self.cur_screen = 1
    self:set_mode()

    -- self.screen_width = {}
    -- for _, screen in ipairs(self.screens) do
    --     local max_len = -math.huge

    --     for _, line in ipairs(screen) do
    --         local len = lines_width[line] --self.sentence:__line_length(line)
    --         if len > max_len then
    --             max_len = len
    --         end
    --     end

    --     self.screen_width[screen] = max_len
    --     --self.screen_width[screen] = max_len > self.w and max_len or self.w
    -- end

    self.ox = self.w / 2
    self.oy = self.h / 2
end

-- ---@return number
-- function TextBox:width()
--     local screen = self.screens[self.cur_screen]
--     local width = self.screen_width[screen]
--     return width or self.w
-- end

function TextBox:resetToDefault()
    self.align = "left"
    self.text_align = Align.center
    self.is_visible = true
    self.max_time_glyph = 0.05
    self.update_mode = UpdateMode.by_glyph
end

function TextBox:do_the_thing(index, args)
    if not index then return end
    local field = self[index]
    if type(field) == "function" then
        field(self, args)
    else
        self[index] = args or self[index]
    end
end

---@param mode JM.GUI.TextBox.Modes
function TextBox:set_mode(mode)
    if mode == "goddess" then
        self.max_time_glyph = 0.12
    end
    self.glyph_change_action = ModeAction[mode] or ModeAction["normal"]
end

function TextBox:get_current_glyph()
    return self.sentence:get_glyph(self.cur_glyph, self.screens[self.cur_screen])
end

function TextBox:rect()
    return self.x, self.y, self.w, self.h
end

function TextBox:key_pressed(key)
    if key == "space" then
        local r = self:go_to_next_screen()

        if not r and self:screen_is_finished() then
            self:restart()
        end
    end
end

function TextBox:refresh()
    self.cur_glyph = 0
    self.time_glyph = 0.0
    self.extra_time = 0.0
end

function TextBox:go_to_next_screen()
    if self:screen_is_finished() and self.cur_screen < self.amount_screens then
        self.cur_screen = self.cur_screen + 1
        self.waiting = false
        self:refresh()
        dispatch_event(self, Event.changeScreen)
        return true
    end
    return false
end

function TextBox:restart()
    self.cur_screen = 1
    self.used_tags = nil
    self.waiting = false
    self:refresh()
end

function TextBox:set_finish(value)
    if value then
        if not self.__finish then
            self.__finish = true

            dispatch_event(self, Event.finishScreen)

            if self:finished() then
                dispatch_event(self, Event.finishAll)
            end
        end
    else
        if self.__finish then
            self.__finish = false
        end
    end
end

function TextBox:screen_is_finished()
    if self.update_mode == UpdateMode.by_screen then
        return self.__finish and self.waiting and self.waiting >= 0.9
    end
    return self.__finish
end

function TextBox:finished()
    return self.__finish and self.cur_screen == self.amount_screens
end

---@param name JM.GUI.TextBox.EventNames
---@param action function
---@param args any
function TextBox:on_event(name, action, args)
    local evt_type = Event[name]
    if not evt_type then return end

    self.events = self.events or {}

    self.events[evt_type] = {
        type = evt_type,
        action = action,
        args = args
    }
end

function TextBox:skip_screen()
    self.cur_glyph = nil
end

function TextBox:update(dt)

    self.sentence:update(dt)

    self.__effect_manager:update(dt)

    -- Pausing the textBox
    if self.time_pause > 0 then
        self.time_pause = self.time_pause - dt
        if self.time_pause <= 0 then
            self.time_pause = 0.0
        else
            return false
        end
    end

    -- if love.keyboard.isDown("a") or  then self:skip_screen() end

    if self.update_mode == UpdateMode.by_screen and not self.waiting then
        self.waiting = 0.0
        self:skip_screen()
    end

    if self.waiting then
        self.waiting = self.waiting + dt
    end

    self.time_glyph = self.time_glyph + dt

    if self.time_glyph >= (self.max_time_glyph + self.extra_time) then

        self.time_glyph = self.time_glyph - self.max_time_glyph
            - self.extra_time

        if self.cur_glyph then
            self.cur_glyph = self.cur_glyph + 1
            dispatch_event(self, Event.glyphChange)

            local g, w = self:get_current_glyph()

            if self.update_mode == UpdateMode.by_glyph then
                local temp = g and self.glyph_change_action
                    and self.glyph_change_action(g)

            elseif self.update_mode == UpdateMode.by_word and g and w then
                self.cur_glyph = self.cur_glyph + #(w.__characters) - 1

                if w.text == " " then
                    self.time_glyph = self.max_time_glyph
                else
                    dispatch_event(self, Event.wordChange)
                end
            end

        end -- END if cur_glyph is not nil
    end

    local glyph, word, endword = self:get_current_glyph()

    if glyph then
        if self.simulate_speak then
            local id = glyph.__id

            if id:match("[%.;?]") then
                self.extra_time = 0.8
            elseif id:match("[,!]") then
                self.extra_time = 0.3
            else
                self.extra_time = 0.0
            end
        end
        --===================================================
        if word then
            local tags = self.sentence.word_to_tag[word]

            if tags and endword then
                self.used_tags = self.used_tags or {}
                local N = #tags

                for i = 1, N do
                    local tag = tags[i]
                    local name = tag['tag_name']

                    if not self.used_tags[tag] then
                        self.used_tags[tag] = true

                        if name == "<pause>" then
                            self.time_pause = tag["pause"]
                            return false
                        elseif name == "<text-box>" then
                            self:do_the_thing(tag['action'], tag['value'])
                            self.time_pause = 0.5
                        end
                    end
                end

            end -- End if tags end endword

        end --End if Word

    end -- End if Glyph

    self:set_finish(not glyph and self.cur_glyph ~= 0)
end

local Font = _G.JM_Font

function TextBox:__draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", self:rect())

    local screen = self.screens[self.cur_screen]
    self.sentence:set_bounds(nil, nil,
        self.x + self.w--(self.screen_width[screen] or self.w)
    )

    self.font:push()
    self.font:set_configuration(self.font_config)

    local height = self.sentence:text_height(screen)

    local py = self.y
    if self.text_align == Align.center then
        py = py + self.h / 2 - height / 2
    elseif self.text_align == Align.bottom then
        py = py + self.h - height
    end

    local tx, ty, glyph = self.sentence:draw_lines(
        screen,
        self.x, py,
        self.align, nil,
        self.cur_glyph
    )

    self.font:pop()
    --==========================================================

    -- Font:print(self.__finish and "<color>true" or "<color, 1, 1, 1>false", self.x, self.y - 20)

    -- Font:print(tostring(self.sentence.tags[1]["effect"]), self.x, self.y + self.h + 10)

    -- if self:screen_is_finished() then
    --     Font:print("--a--", self.x + self.w + 5,
    --         self.y + self.h + 10)
    -- end
end

function TextBox:draw()
    Affectable.draw(self, self.__draw)
end

return TextBox
