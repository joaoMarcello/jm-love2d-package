local Textbox = JM.GUI.TextBox

---@class JM.DialogueSystem.Dialogue
local Dialogue = {}
Dialogue.__index = Dialogue

---@param text string
---@param font JM.Font.Font
local create_box = function(text, font, config)
    text = text:gsub("<next>\n", "<next>")
    text = text:gsub("<tab>", "\t")
    -- text = text:gsub("<emphasis>", "<color>")
    -- text = text:gsub("</emphasis>", "</color>")

    return Textbox:new {
        text = text,
        font = font,
        x = config and config.x or (24 + 16),
        y = config and config.y or (16 * 7.25),
        w = config and config.w or (16 * 14),
        align = config and config.align or Textbox.AlignX.left,
        text_align = config and config.text_align or Textbox.AlignY.top,
        update_mode = config and config.update_mode
            or Textbox.UpdateMode.by_glyph,
        speed = config and config.speed or 0.05,
        n_lines = config and config.n_lines or 4,
        time_wait = 0.5,
        allow_cycle = false,
        show_border = true,
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
        code = loadstring(header)()

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
    ---@param font JM.Font.Font
    ---@return JM.DialogueSystem.Dialogue
    function Dialogue:new(dir, font)
        font = font or JM:get_font("pix8")

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

        for i = 1, N do
            local id = ids[i]

            ---@type string
            local line = texts[i]

            if id == speaker and i ~= N then
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
                        create_box(str, font, headers[cur_init]))
                    table.insert(ids_, id)
                end
                str = line
                cur_init = i

                if i == N and line ~= "" then
                    table.insert(boxes, create_box(str, font,
                        headers[cur_init]))
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

function Module:newDialogue(dir, font)
    return Dialogue:new(dir, font)
end

return Module
