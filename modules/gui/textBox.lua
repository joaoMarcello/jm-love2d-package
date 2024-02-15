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

-- local Mode = {
--     normal = 1,
--     goddess = 2,
--     popin = 3,
--     rainbow = 4
-- }

local goddess_args = { speed = 0.2 }
local function mode_goddess(g)
    g:apply_effect("fadein", goddess_args)
end

local popin_args = { speed = 0.2 }
local function mode_popin(g)
    g:apply_effect("popin", popin_args)
end

local function mode_rainbow(g)
    g:set_color2(math.random(), math.random(), math.random())
end

local ModeAction = {
    normal = function(args) return false end,
    goddess = mode_goddess,
    popin = mode_popin,
    rainbow = mode_rainbow
}
---@alias JM.GUI.TextBox.Modes "normal"|"goddess"|"popin"|"rainbow"|nil

---@enum JM.GUI.TextBox.AlignOptionsY
local AlignY = {
    top = 1,
    bottom = 2,
    center = 3
}

---@enum JM.GUI.TextBox.AlignOptionsX
local AlignX = {
    left = "left",
    right = "right",
    center = "center",
    justify = "justify",
}

---@enum JM.GUI.TextBox.UpdateModes
local UpdateMode = {
    by_glyph = 1,
    by_word = 2,
    by_screen = 3
}

local lgx = love.graphics

---@param self JM.GUI.TextBox
---@param type_ JM.GUI.TextBox.EventTypes
local function dispatch_event(self, type_)
    local evt = self.events and self.events[type_]
    local r = evt and evt.action(evt.args)
end

---@class JM.GUI.TextBox: JM.Template.Affectable
local TextBox = setmetatable({}, Affectable)
TextBox.UpdateMode = UpdateMode
TextBox.AlignY = AlignY
TextBox.AlignX = AlignX
TextBox.__index = TextBox

---@alias JM.TextBox.ArgsConstructor {text:string, x:number, y:number, w:number, font:JM.Font.Font, align:JM.GUI.TextBox.AlignOptionsX, text_align:JM.GUI.TextBox.AlignOptionsY, speed:number, simulate_speak:boolean, n_lines:number, mode:JM.GUI.TextBox.Modes, update_mode:JM.GUI.TextBox.UpdateModes, time_wait:number, allow_cycle:boolean, show_border:boolean, remove_empty_lines:boolean}

---
---@overload fun(self: any, args:JM.TextBox.ArgsConstructor)
---@param text string
---@return JM.GUI.TextBox
function TextBox:new(text, font, x, y, w)
    local obj = setmetatable(Affectable:new(), TextBox)

    -- text = "<effect=goddess, delay=0.05>" .. text
    local args

    if type(text) == "table" then
        local t = text
        t.text = t.text or "No text!"
        t.x = t.x or 0
        t.y = t.y or 0

        t.w = t.w or math.huge
        t.font = t.font or JM:get_font()
        t.align = t.align or "left"
        t.speed = t.speed or 0.05
        t.simulate_speak = t.simulate_speak == nil or t.simulate_speak
        t.n_lines = t.n_lines or 4
        t.mode = t.mode or "normal"

        t.text_align = t.text_align
            or AlignY.center

        t.update_mode = (type(t.update_mode) == "string"
                and TextBox.UpdateMode[t.update_mode])
            or (type(t.update_mode) == "number" and math.floor(t.update_mode))
            or UpdateMode.by_glyph
        args = t
    else
        return TextBox:new { text = text, font = font, x = x, y = y, w = w }
    end
    -- TextBox.__constructor__(obj, { text = text, x = x, y = y, font = font }, w)

    TextBox.__constructor__(obj, args)
    args = nil
    return obj
end

---@param args JM.TextBox.ArgsConstructor
function TextBox:__constructor__(args)
    self.args = args

    self.x = args.x --self.sentence.x
    self.y = args.y --self.sentence.y

    args.x = 0
    args.y = 0

    self.sentence = Phrase:new(args)
    -- self.sentence:set_bounds(nil, nil, args.x + (w or (math.huge - args.x)))
    self.sentence.__bounds.right = args.w or math.huge

    self.lines = self.sentence:get_lines()

    local lines_width = {}
    local max_width = -math.huge

    -- local LINE_LENGTH = Phrase.LINE_WIDTH[self.lines]

    for _, line in ipairs(self.lines) do
        -- local w = LINE_LENGTH[line] or 0

        lines_width[line] = self.sentence:__line_length(line)
        max_width = lines_width[line] > max_width and lines_width[line]
            or max_width
    end

    self.align = args.align
    self.text_align = args.text_align
    self.w = args.w or max_width
    self.h = 0 -- -math.huge
    self.is_visible = true

    self.cur_glyph = 0
    self.time_glyph = 0.0
    self.max_time_glyph = args.speed -- 0.05
    self.extra_time = 0.0

    self.time_pause = 0.0

    self.simulate_speak = args.simulate_speak
    self.update_mode = args.update_mode

    self.font = self.sentence.__font
    self.font_config = self.font:__get_configuration()

    self.amount_lines = args.n_lines
    self.amount_screens = math.ceil(#self.lines / self.amount_lines) --3

    self.time_wait_to_next = args.time_wait or 0.9
    self.allow_cycle = args.allow_cycle
    self.show_border = args.show_border

    local N = #self.lines

    -- do
    --     local loc = {}

    --     for i = 1, N do
    --         if self.lines[i][1].text:match("<next>") then
    --             table.insert(loc, i)
    --         end
    --     end

    --     local empty = {}
    --     local NL = #loc
    --     for i = 1, NL do
    --         self.lines[loc[1]] = empty
    --         for k = 1, self.amount_lines - 2 do
    --             table.insert(self.lines, loc[1], empty)
    --         end
    --     end
    -- end

    self.screens = {}
    -- local j = 1
    -- while j <= N do
    --     table.insert(self.screens,
    --         { unpack(self.lines, j, j + self.amount_lines - 1) })

    --     -- defining the textBox height
    --     local h = self.sentence:text_height(self.screens[#self.screens])
    --     self.h = h > self.h and h or self.h

    --     local screen = self.screens[#self.screens]

    --     -- removing empty lines
    --     local k = 1
    --     while k <= #screen do
    --         local line = screen[k]
    --         local N_line = #line

    --         if (N_line == 1 and line[1].text:match("\n")
    --                 and (args.remove_empty_lines or true))
    --             or (N_line <= 0)
    --         then
    --             table.remove(screen, k)
    --             k = k - 1
    --         end
    --         k = k + 1
    --     end --end removing empty lines

    --     -- removing empty screens
    --     if #screen <= 0 then
    --         table.remove(self.screens, #self.screens)
    --         self.amount_screens = self.amount_screens - 1
    --     end

    --     j = j + self.amount_lines
    -- end

    local cur_screen = {}
    local count = 1
    for i = 1, N do
        local line = self.lines[i]
        local n_line = #line
        -- local cond = (n_line == 1 and line[1].text == "\n" and false)
        --     or (n_line <= 0)

        local to_next = n_line >= 1 and line[1].text:match("<next>")

        if not to_next then
            table.insert(cur_screen, line)
        end

        if count < self.amount_lines and i ~= N
            and not to_next
        then
            count = count + 1
        elseif (#cur_screen) ~= 0 then
            table.insert(self.screens, cur_screen)
            cur_screen = {}
            count = 1

            -- defining the textBox height
            local h = self.sentence:text_height(self.screens[#self.screens])
            self.h = h > self.h and h or self.h
        end
    end
    self.amount_screens = #self.screens

    -- local Word = require "jm-love2d-package.modules.font.Word"
    -- table.insert(self.screens[1], { Word:new { text = "\noi", font = self.sentence.__font } })

    self.cur_screen = 1
    self:set_mode()

    self.ox = self.w * 0.5
    self.oy = self.h * 0.5

    self.sentence.__bounds.right = self.x + self.w

    self.update = TextBox.update
    self.draw = TextBox.draw
end

-- ---@return number
-- function TextBox:width()
--     local screen = self.screens[self.cur_screen]
--     local width = self.screen_width[screen]
--     return width or self.w
-- end

--- Resets the textbox configuration to intial state
function TextBox:reset()
    local args = self.args
    self.align = args.align
    self.text_align = args.text_align
    self.is_visible = true
    self.max_time_glyph = args.speed
    self.update_mode = args.update_mode
    self.simulate_speak = args.simulate_speak
    return self:set_mode(args.mode)
end

function TextBox:do_the_thing(index, args)
    if not index then return end
    local field = self[index]
    if type(field) == "function" then
        return field(self, args)
    else                   --if type(field) ~= "nil" then
        self[index] = args -- or self[index]
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

function TextBox:keypressed(key)
    if key == "space" then
        self:skip_screen()
        local r = self:go_to_next_screen()

        if not r and self:screen_is_finished() then
            -- self:restart()
            self.is_visible = false
        end
    end
end

function TextBox:refresh()
    self.cur_glyph = 0
    self.time_glyph = 0.0
    self.extra_time = 0.0
end

function TextBox:go_to_next_screen()
    if self:screen_is_finished()
        and (self.cur_screen < self.amount_screens or self.allow_cycle)
    then
        self.cur_screen = self.cur_screen + 1

        if self.cur_screen > self.amount_screens then
            self.cur_screen = 1
        end

        self.waiting = false
        self:refresh()
        dispatch_event(self, Event.changeScreen)
        return true
    end
    return false
end

function TextBox:go_to_prev_screen()
    if self:screen_is_finished()
        and (self.cur_screen > 1
            or self.allow_cycle)
    then
        self.cur_screen = self.cur_screen - 1

        if self.cur_screen < 1 then self.cur_screen = self.amount_screens end

        self.waiting = false
        self:refresh()
        dispatch_event(self, Event.changeScreen)
        return true
    end
    return false
end

--- Go back to first screen
function TextBox:restart()
    self:reset()
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
        return self.__finish and self.waiting and self.waiting >= self.time_wait_to_next
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
    -- self.cur_glyph = nil
    while not self:screen_is_finished() do
        self:update(self.max_time_glyph)
    end
    self.cur_glyph = nil
end

function TextBox:play_sfx(args)
    if type(args) == "table" then
        return _G.Play_sfx(args.sfx, true)
    else
        return _G.Play_sfx(args, true)
    end
end

-- used to call a function which is in global space
function TextBox:code(args)
    if type(args) == "table" then
        local action = _G[args.action]
        if action then
            if args.unpack then
                return action(unpack(args.args))
            else
                return action(args.args)
            end
        end
    end
end

local enviroment = {}
local scripts = {}
local id = 1

---@param value string
---@return string index
function TextBox.add_script(value)
    local index = string.format("SCRIPT%04d", id)
    value = value:gsub("<next>", " ")
    -- print("--========================")
    -- print(value)
    scripts[index] = assert(loadstring(value))
    id = id + 1
    return index
end

function TextBox.flush()
    for k, v in next, scripts do
        scripts[k] = nil
    end
    id = 1
end

-- used to run scripts using the textbox tag
function TextBox:script(args)
    local script = scripts[args]
    if not script then
        script = assert(loadstring(args))
    end
    -- print(args)

    enviroment["_G"] = _G
    enviroment.box = self
    enviroment.textbox = self
    enviroment.scene = JM.GameObject.gamestate or JM.SceneManager.scene
    enviroment.JM = JM

    local env = setfenv(script, enviroment)
    env()

    enviroment["_G"] = nil
    enviroment.box = nil
    enviroment.textbox = nil
    enviroment.scene = nil
    enviroment.JM = nil
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

        if self.time_glyph > self.max_time_glyph + self.extra_time then
            self.time_glyph = 0
        end

        if self.cur_glyph then
            self.cur_glyph = self.cur_glyph + 1
            dispatch_event(self, Event.glyphChange)

            local g, w = self:get_current_glyph()

            if self.update_mode == UpdateMode.by_glyph then
                local r = g and self.glyph_change_action
                    and self.glyph_change_action(g)
                --
            elseif self.update_mode == UpdateMode.by_word and g and w then
                self.cur_glyph = self.cur_glyph + #(w.__characters) - 1

                if w.text == " " then
                    self.time_glyph = self.max_time_glyph
                else
                    dispatch_event(self, Event.wordChange)
                end
            end
            -- self.prev_word = w
        end -- END if cur_glyph is not nil
    end

    local glyph, word, endword = self:get_current_glyph()

    if glyph then
        if self.simulate_speak then
            local id = glyph.id

            if id:match("[%.;?!]") then
                self.extra_time = 0.8
                --
            elseif id:match("[,]") then
                self.extra_time = 0.2
                --
            else
                self.extra_time = 0.0
            end
        else
            self.extra_time = 0.0
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
                        elseif name == "<textbox>" then
                            -- print(tag['action'], tag['value'])
                            self:do_the_thing(tag['action'], tag['value'])
                            -- self.time_pause = 0.15
                        end
                    end
                end
            end -- End if tags end endword
        end     --End if Word
    end         -- End if Glyph

    self:set_finish(not glyph and self.cur_glyph ~= 0)
end

-- local Font = _G.JM_Font

---@param self JM.GUI.TextBox
local function _draw_(self)
    if not self.is_visible then return end

    if self.show_border then
        lgx.setColor(1, 1, 1, 1)
        lgx.rectangle("line", self:rect())
    end

    local screen = self.screens[self.cur_screen]
    local font = self.font
    local sentence = self.sentence

    font:push()
    font:set_configuration(self.font_config)

    local height = sentence:text_height(screen)

    -- love.graphics.push()
    local py = self.y

    if self.text_align == AlignY.center then
        py = py + self.h * 0.5 - height * 0.5
        --
    elseif self.text_align == AlignY.bottom then
        py = py + self.h - height
        --
    end

    -- love.graphics.translate(math.floor(self.x + 0.5), math.floor(py + 0.5))

    local tx, ty, glyph = sentence:draw_lines(
        screen,
        self.x, py,
        -- 0, 0,

        ---@diagnostic disable-next-line: param-type-mismatch
        self.align, self.w,
        self.cur_glyph
    )
    -- love.graphics.pop()

    return font:pop()
    --==========================================================

    -- Font:print(self.__finish and "<color>true" or "<color, 1, 1, 1>false", self.x, self.y - 20)

    -- Font:print(tostring(self.sentence.tags[1]["effect"]), self.x, self.y + self.h + 10)

    -- if self:screen_is_finished() then
    --     Font:print("--a--", self.x + self.w + 5,
    --         self.y + self.h + 10)
    -- end
end

---@param cam JM.Camera.Camera
function TextBox:draw(cam)
    if cam and not cam:rect_is_on_view(self:rect()) then
        return
    end
    return Affectable.draw(self, _draw_)
end

return TextBox
