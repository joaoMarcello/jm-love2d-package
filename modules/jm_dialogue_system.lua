local Textbox = JM.GUI.TextBox

---@class JM.DialogueSystem.Dialogue
local Dialogue = {}
Dialogue.__index = Dialogue

local default = {
    x = (24 + 16),
    y = (16 * 7.25),
    w = (16 * 14),
    align = Textbox.AlignX.left,
    text_align = Textbox.AlignY.top,
    update_mode = Textbox.UpdateMode.by_glyph,
    speed = 0.05,
    n_lines = 4,
    time_wait = 0.5,
    allow_cycle = false,
    show_border = false,
    -- simulate_speak = false,
}

---@param text string
---@param font JM.Font.Font
local create_box = function(text, font, header, conf)
    text = text:gsub("<next>\n", "<next>")
    text = text:gsub("<tab>", "\t")
    do
        -- using the <play> tag
        -- fix to the command accepted by Textbox class
        local regex = "< *play *= *[%w_%- ]*>"
        local i = 1
        local starp, endp = text:find(regex, i)

        while starp do
            local init, _ = text:find("=", starp)
            local right = text:sub(init + 1, endp - 1)
            local new = string.format("<textbox,action=play_sfx,value=%s>", right)
            text = text:gsub(regex, new, 1)

            i = starp + #new
            starp, endp = text:find(regex, i)
        end
    end
    -- text = text:gsub("<emphasis>", "<color>")
    -- text = text:gsub("</emphasis>", "</color>")

    if not header then
        header = conf
    end

    return Textbox:new {
        text = text,
        font = font,
        x = header.x or conf.x or default.x,
        y = header.y or conf.y or default.y,
        w = header.w or conf.w or default.w,
        align = header.align or conf.align or default.align,
        text_align = header.text_align or conf.text_align
            or default.text_align,
        update_mode = header.update_mode or conf.update_mode
            or default.update_mode,
        speed = header.speed or conf.speed or default.speed,
        n_lines = header.n_lines or conf.n_lines or default.n_lines,
        time_wait = header.time_wait or conf.time_wait or default.time_wait,
        allow_cycle = header.allow_cycle or conf.allow_cycle,
        show_border = header.show_border or conf.show_border,
        simulate_speak = header.simulate_speak,
    }
end

---@param str string
---@param font JM.Font.Font
local function fix_text(str, font)
    local startp, endp = str:find("< *code *>.*< */ *code *>")
    local code
    if startp then
        local s = str:sub(startp, endp)
        s = s:gsub("< *code *>", "")
        s = s:gsub("< */ *code *>", "")
        -- print(s)
        local header = "return " .. s
        code = assert(loadstring(header))()

        str = str:gsub("< *code *>.*< */ *code *>", "")
    end

    local startp, endp = str:find("[%w_%-%(%) ]-:")
    local id

    if startp and startp == 1 then
        local r = font:__is_a_nickname(str, endp)

        if not r then
            id = str:sub(startp, endp)
            str = str:sub(endp + 1)
        end
    end

    return id, str, code
end

do
    ---@param dir string
    ---@return JM.DialogueSystem.Dialogue
    function Dialogue:new(dir, font, conf)
        font = font or JM:get_font("pix8")
        conf = conf or default
        conf = setmetatable(conf, default)

        ---@type love.File|any
        local file = love.filesystem.newFile(dir)
        local boxes = {}
        local ids = {}
        local texts = {}
        local headers = {}

        for line in file:lines() do
            local id, text, header = fix_text(line, font)
            if id then id = id:gsub(":", "") end
            table.insert(texts, text)
            table.insert(ids, id or ids[#ids] or "")
            table.insert(headers, header or false)
            -- print(header)
        end
        table.insert(texts, "")
        table.insert(ids, "")

        local str = ""
        local speaker = ids[1]
        local ids_ = { speaker }
        local N = #texts
        local cur_init = 1
        local cur_header = headers[1]

        for i = 1, N do
            local id = ids[i]

            ---@type string
            local line = texts[i]

            if id == speaker and i ~= N
                and (headers[i] == cur_header or headers[i] == false)
            then
                if str ~= "" then
                    if line == "" then
                        if ids[i + 1] == id and texts[i + 1] ~= "" then
                            str = str .. "<next>"
                        end
                    elseif line ~= "" then
                        str = str .. "\n" .. line
                    end
                elseif line ~= "" then
                    str = str .. line
                end
            else
                do
                    -- print(i)
                    table.insert(boxes,
                        create_box(str, font, headers[cur_init], conf))
                    table.insert(ids_, id)
                end
                str = line
                cur_init = i
                cur_header = headers[i]

                if i == N and line ~= "" then
                    table.insert(boxes, create_box(str, font,
                        headers[cur_init], conf))
                    table.insert(ids_, ids[i])
                end
            end

            speaker = ids[i]
        end

        file:close()
        file:release()
        file = nil

        local w, h = 0, 0
        for i = 1, #boxes do
            ---@type JM.GUI.TextBox
            local box = boxes[i]
            local _, _, bw, bh = box:rect()
            if bw > w then w = bw end
            if bh > h then h = bh end
        end

        ---@class JM.DialogueSystem.Dialogue
        local obj = setmetatable({
            boxes = boxes,
            ids = ids_,
            cur = 1,
            n_boxes = #boxes,
            is_visible = true,
            w = w,
            h = h,
        }, Dialogue)

        boxes = nil
        headers = nil
        ids = nil
        ids_ = nil
        texts = nil

        return obj
    end

    ---@return JM.GUI.TextBox
    function Dialogue:get_cur_box()
        return self.boxes[self.cur]
    end

    ---@return string speaker
    function Dialogue:get_id()
        ---@type string
        local id = self.ids[self.cur]
        local startp, endp = id:find("%( *[%w]* *%)")
        if startp then
            return id:sub(1, startp - 1)
        end
        -- id = id:gsub(":", "")
        return id
    end

    function Dialogue:get_emotion()
        local id = self.ids[self.cur]
        return id:match("%(.*%)") or ""
    end

    function Dialogue:go_to_next()
        self.cur = self.cur + 1
        if self.cur > self.n_boxes then
            self.cur = self.n_boxes
            return false
        end
        self:get_cur_box():restart()
        return true
    end

    function Dialogue:restart()
        self.cur = 1
        self:get_cur_box():restart()
    end

    function Dialogue:finished()
        return self.cur == self.n_boxes and self:get_cur_box():finished()
    end

    function Dialogue:screen_is_finished()
        return self:get_cur_box():screen_is_finished()
    end

    function Dialogue:set_visible(v)
        self.is_visible = v
    end

    function Dialogue:rect()
        local box = self:get_cur_box()
        return box.x, box.y, self.w, self.h
    end

    function Dialogue:update(dt)
        return self:get_cur_box():update(dt)
    end

    function Dialogue:draw(cam)
        if not self.is_visible then return end
        return self:get_cur_box():draw()
    end
end
--==========================================================================

---@class JM.DialogueSystem
local Module = {}

function Module:newDialogue(dir, font, conf)
    return Dialogue:new(dir, font, conf)
end

return Module
