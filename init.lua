local path = (...)
_G.FULLSCREEN_TYPE = _G.FULLSCREEN_TYPE or "desktop"

if not path:match("%.init") then
    path = path .. ".init"
end
_G.JM_Path = string.gsub(path, "init", "")

local JM = {}
JM_Love2D_Package = JM
JM_Package = JM
_G.JM = JM

---@type JM.Utils
JM.Utils = require(string.gsub(path, "init", "modules.jm_utils"))
JM_Utils = JM.Utils

---@type JM.EffectManager
JM.EffectManager = require(string.gsub(
    path, "init", "modules.jm_effect_manager"
))
JM_EffectManager = JM.EffectManager

---@type JM.Template.Affectable
JM.Affectable = require(string.gsub(path, "init", "modules.templates.Affectable"))
JM_Affectable = JM.Affectable

---@type JM.Anima
JM.Anima = require(string.gsub(path, "init", "modules.jm_animation"))
JM_Anima = JM.Anima

---@type JM.Font.Generator
JM.FontGenerator = require(string.gsub(path, "init", "modules.jm_font_generator"))

local fonts = {}

---@alias JM.AvailableFonts "pix5"|"pix8"|"circuit17"|"circuit21"|"default"|nil

---@param font JM.AvailableFonts
function JM:get_font(font)
    font = font or "default"

    do
        local r = fonts[font]
        if r then return r end
    end

    if font == "pix8" then
        local pix8 = self.FontGenerator:new {
            name            = "pix8",
            dir             = "jm-love2d-package/data/font/font_pix8-Sheet.png",
            glyphs          = [[AÀÁÃÄÂaàáãäâBbCcÇçDdEÈÉÊËeèéêëFfGgHhIÌÍÎÏiìíîïJjKkLlMmN:enne_up:n:enne:OÒÓÕÔÖoòóõôöPpQqRrSsTtUÙÚÛÜuùúûüVvWwXxYyZz0123456789!?@#$%^&*()<>{}:[]:mult::div::cpy:+-_=¬'"¹²³°ºª\/.:dots:;,:dash:|¢£:blk_bar::arw_fr::arw_bk::arw_up::arw_dw::bt_a::bt_b::bt_x::bt_y::bt_r::bt_l::star::heart::diamond::circle::arw2_fr::arw2_bk::spa_inter::female::male::check::line::db_comma_init::db_comma_end::comma_init::comma_end::arw_head_fr::arw_head_bk:]],
            min_filter      = "linear",
            max_filter      = "nearest",
            character_space = 0,
            word_space      = 5,
            line_space      = 3,
        }
        pix8:set_color(self.Utils:get_rgba())
        pix8:set_font_size(pix8.__ref_height)
        fonts[font] = pix8
        return pix8
        ---
    elseif font == "pix5" then
        local pix5 = self.FontGenerator:new {
            name = "pix5",
            dir = "jm-love2d-package/data/font/font_pix5-Sheet.png",
            glyphs = "aàáãâäbcçdeèéêëfghiìíîïjklmnoòóõôöpqrstuùúûüvwxyz0123456789-_.:dots::+:square::blk_bar::heart:()[]{}:arw_fr::arw_bk::arw_up::arw_dw::dash:|,;!?\\/*~^:arw2_fr::arw2_bk:º°¬'\":div:%#¢@",
            min_filter = 'linear',
            max_filter = 'nearest',
            character_space = 0,
            word_space = 4,
            line_space = 1,
        }
        pix5:set_color(self.Utils:get_rgba(0, 0, 0))
        pix5:set_font_size(pix5.__ref_height)
        fonts[font] = pix5
        return pix5
        ---
    elseif font == "circuit21" then
        local c21 = self.FontGenerator:new {
            name = "circuit21",
            dir = "/jm-love2d-package/data/font/circuit21-Sheet.png",
            glyphs = "1234567890-:null:",
            min_filter = "linear",
            max_filter = "nearest",
            word_space = 3,
        }
        c21:set_color(self.Utils:get_rgba())
        c21:set_font_size(c21.__ref_height)
        fonts[font] = c21
        return c21
        ---
    elseif font == "circuit17" then
        local c17 = self.FontGenerator:new {
            name = "circuit17",
            dir = "/jm-love2d-package/data/font/circuit17-Sheet.png",
            glyphs = "1234567890-:null:",
            min_filter = "linear",
            max_filter = "nearest",
            word_space = 3,
        }
        c17:set_color(self.Utils:get_rgba())
        c17:set_font_size(c17.__ref_height)
        fonts[font] = c17
        return c17
        ---
    else
        local lfs = love.filesystem
        local zip = "/jm-love2d-package/data/font/open_sans.zip"
        lfs.mount(lfs.newFileData(zip), "content")

        local f = self.FontGenerator:new_by_ttf {
            dir = "content/OpenSans-Regular.ttf",
            dir_bold = "content/OpenSans-SemiBold.ttf",
            ---
            dpi = 48,
            name = "open sans",
            font_size = 12,
            character_space = 2,
            line_space = 18,
            tab_size = 4,
            min_filter = "linear",
            max_filter = "nearest",
            max_texturesize = 2048,
            -- save = true,
            threshold = { { "00", "7f" }, { "80", "ff" }, { "100", "17f" }, { "180", "24f" }, { "2b0", "2ff" }, { "300", "36f" }, { "370", "3ff" }, { "400", "4ff" }, { "1d00", "1d7f" }, { "1d80", "1dbf" }, { "1e00", "1eff" }, { "2000", "206f" }, { "2070", "209f" }, { "2100", "214f" }, { "2150", "218f" }, { "2200", "22ff" }, { "2300", "23ff" } },
        }
        fonts[font] = f
        f:set_font_size(12)
        lfs.unmount(zip)
        -- print(r and "Success unmout" or "Fail unmount")
        return f

        -- local glyphs =
        -- "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĲĳĴĵĶķĸĹĺĻļĽľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏŐőŒœŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŦŧŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽžſ"

        -- local f = JM.FontGenerator:new {
        --     name = "open sans",
        --     dir = "/jm-love2d-package/data/font/open sans.png",
        --     glyphs = glyphs,
        --     dir_bold = "/jm-love2d-package/data/font/open sans bold.png",
        --     glyphs_bold = glyphs,
        --     character_space = 1,
        --     font_size = 12,
        -- }
        -- fonts[font] = f
        -- return f
    end
end

---@param name string
---@param font JM.Font.Font
function JM:set_font(name, font)
    fonts[name] = font
    return font
end

---@type JM.Camera.Camera
JM.Camera = require(string.gsub(path, "init", "modules.jm_camera"))

---@type JM.SceneManager
JM.SceneManager = require(string.gsub(path, "init", "modules.jm_scene_manager"))
JM_SceneManager = JM.SceneManager

---@type JM.Loader
JM.Ldr = require(string.gsub(path, "init", "modules.jm_loader"))
JM_Ldr = JM.Ldr

--==========================================================================

---@type JM.Controller
JM.Controller = require(string.gsub(path, "init", "modules.jm_controller"))

---@type JM.ControllerManager
JM.ControllerManager = require(string.gsub(path, "init", "modules.jm_controller_manager"))
--==========================================================================

---@type JM.Scene
JM.Scene = require(string.gsub(path, "init", "modules.jm_scene"))

---@type JM.Physics
JM.Physics = require(string.gsub(path, "init", "modules.jm_physics"))


---@type JM.Sound
JM.Sound = require(string.gsub(path, "init", "modules.jm_sound"))

---@type JM.TileSet
JM.TileSet = require(string.gsub(path, "init", "modules.tile.tile_set"))

---@type JM.LeaderBoard
JM.Mlrs = require(string.gsub(path, "init", "modules.jm_melrs"))

---@type JM.TileMap
JM.TileMap = require(string.gsub(path, "init", "modules.tile.tile_map"))

---@type GameObject
JM.GameObject = require(string.gsub(path, "init", "modules.gamestate.game_object"))

---@type BodyObject
JM.BodyObject = require(string.gsub(path, "init", "modules.gamestate.body_object"))

---@type JM.GUI
JM.GUI = require(string.gsub(path, "init", "modules.jm_gui"))

---@type JM.ParticleSystem
JM.ParticleSystem = require(string.gsub(path, "init", "modules.jm_ps"))

---@type JM.GameMap
JM.GameMap = require(string.gsub(path, "init", "modules.editor.game_map"))

---@type JM.ShaderManager
JM.Shader = require(string.gsub(path, "init", "modules.jm_shader"))

---@type JM.DialogueSystem
JM.DialogueSystem = require(string.gsub(path, "init", "modules.jm_dialogue_system"))

---@type JM.GUI.VPad
JM.Vpad = JM.Scene:get_vpad() --require(string.gsub(path, "init", "modules.jm_virtual_pad"))

---@type JM.AdmobManager
JM.Admob = require(string.gsub(path, "init", "modules.jm_admob_manager"))

JM.SplashScreenPath = 'jm-love2d-package.modules.templates.splashScreen'

--===========================================================================
local SceneManager = JM.SceneManager
local Sound = JM.Sound

local fullscreen = love.window.getFullscreen()

--- Loads the first game scene.
---@param s string the directory for the first game scene.
---@param use_splash boolean|nil if should use splash screen
function JM:load_initial_state(
    s, use_splash,
    skip_load_default_font,
    use_fullscreen
)
    if use_fullscreen then
        love.window.setFullscreen(true, _G.FULLSCREEN_TYPE or 'desktop')
    end

    if not skip_load_default_font then
        local font = self:get_font()

        if not self.Vpad:get_font() then
            self.Vpad:set_font(font)
        end
    end

    fullscreen = love.window.getFullscreen()

    local state

    if use_splash then
        ---@type JM.GameState.Splash
        state = require(self.SplashScreenPath)
        state:add_transition("fade", "in", { duration = 0.25 }, nil, nil)
        state:__get_data__():set_next_state_string(s)
    else
        state = require(s)
    end

    SceneManager:change_gamestate(state, { skip_transition = true })

    return SceneManager.scene:resize(love.graphics.getDimensions())
end

function JM:to_fullscreen()
    if not fullscreen then
        fullscreen = true
        return love.window.setFullscreen(true, _G.FULLSCREEN_TYPE or 'desktop')
    end
end

function JM:flush()
    self.FontGenerator.flush()
    self.ParticleSystem:flush()
    self.Physics:flush()
    self.Sound:flush()
    collectgarbage()
end

local capture = false
local cap_time = 0.0
local cap_interval = 0.017 * 2
local cap_duration = 0
local cap_frameskip = 1
local capture_id = ""
local identity = love.window.getTitle()

---@type love.Channel|any
local channel_push_img

---@type love.Thread|nil
local thread_save_shot

---@overload fun(self:any, args:{id:string, interval:number, frameskip:number})
---@param interval number|nil
---@param id string|nil
function JM:toggle_capture_mode(id, interval, frameskip, duration)
    if thread_save_shot then
        return
    end

    if type(id) == "table" then
        interval = id.interval
        frameskip = id.frameskip
        duration = id.duration
        id = id.id
    end

    capture = not capture

    if capture then
        cap_time = 0.0
        cap_frameskip = frameskip or 1
        cap_duration = duration or 20
        capture_id = id and tostring(id) or "gif"
        cap_interval = interval or (0.017 * 2) --- 0.0333
        love.filesystem.createDirectory(capture_id)

        channel_push_img = channel_push_img
            or love.thread.getChannel('item')

        ---@type love.Thread
        thread_save_shot = thread_save_shot or love.thread.newThread("/jm-love2d-package/save_shots.lua")

        if not thread_save_shot:isRunning() then
            thread_save_shot:start(capture_id)
        end
        ---
    else
        if channel_push_img then
            channel_push_img:release()
            channel_push_img = nil
        end
    end
    return true
end

function JM:is_in_capture_mode()
    return capture
end

---@return JM.Font.Font|nil
function JM:has_default_font()
    return fonts["default"]
end

---@param font JM.Font.Font
function JM:set_default_font(font, force)
    if self:has_default_font() and not force then return false end
    fonts["default"] = font
    return true
end

---@type JM.GUI.Component|nil
local fullscreen_button = nil

function JM:show_fullscreen_button()
    if fullscreen_button then return end
    local img = love.graphics.newImage("/jm-love2d-package/data/img/fullscreen_icon.png")

    local size = math.floor(
        math.min(love.graphics.getDimensions()) * 0.075 + 0.5)

    fullscreen_button = self.GUI.Component:new {
        x = 0, y = 0, w = size, h = size,
        on_focus = true,
        draw = function(self)
            local lgx = love.graphics
            lgx.setColor(1, 1, 1)
            return lgx.draw(img, self.x, self.y, 0, self.w / img:getWidth(), self.h / img:getHeight())
        end
    }
end

local locker_path = JM_Path .. "modules.locker.init"
function JM:update(dt)
    do
        ---@type JM.Locker
        local locker = package.loaded[locker_path]
        if locker then
            local session = locker.session
            locker:update(dt)
            if not session and locker.session then
                locker.session_inited = true
            end
        end
    end

    self.Admob:update(dt)

    if thread_save_shot then
        local error_msg = thread_save_shot:getError()
        assert(not error_msg, error_msg)
    end

    if capture then
        cap_duration = cap_duration - dt

        if cap_duration <= 0 then
            cap_duration = 0.0

            if channel_push_img:getCount() <= 0 then
                local channel = love.thread.getChannel('finish')
                channel:push(true)
            end

            if thread_save_shot and not thread_save_shot:isRunning() then
                thread_save_shot:release()
                thread_save_shot = nil
                self:toggle_capture_mode()
                collectgarbage()
            end
        else
            cap_time = cap_time + dt

            local interval = cap_interval
                + (cap_interval * cap_frameskip)

            if cap_time >= interval then
                cap_time = cap_time - interval
                if cap_time > interval then
                    cap_time = 0.0
                end

                love.graphics.captureScreenshot(channel_push_img)
            end
        end
    end

    SceneManager.scene:update(dt)

    do
        local font = self:has_default_font()
        if font then font:update(dt) end
    end
    -- if self:has_default_font() then
    --     self:get_font():update(dt)
    -- end

    Sound:update(dt)
    self.ParticleSystem:update(dt)

    local s = ""
    if capture then
        if thread_save_shot and thread_save_shot:isRunning() then
            s = string.format("capturing... %d", channel_push_img:getCount())
        end

        s = string.format("%s - %.2f", s, cap_duration)
    end
    love.window.setTitle(string.format("%s %s", identity, s))

    do
        ---@type JM.Locker
        local locker = package.loaded[locker_path]
        if locker then
            locker.session_inited = false
        end
    end

    do
        if fullscreen_button then
            local w, h = love.graphics:getDimensions()
            local border = math.floor(math.min(w, h) * 0.025 + 0.5)
            fullscreen_button:set_position(border, h - fullscreen_button.h - border)
            fullscreen_button:update(dt)
        end
    end
end

function JM:draw()
    if fullscreen_button and fullscreen_button.on_focus then
        SceneManager.scene:draw()
        return fullscreen_button:draw()
    else
        return SceneManager.scene:draw()
    end
end

--===========================================================================

function JM:textinput(t)
    return SceneManager.scene:textinput(t)
end

function JM:exit_game()
    self.Sound:stop_all()
    self.Shader:finish()
    local scene = SceneManager.scene
    scene:finish()
    scene = nil
    collectgarbage()
    return love.event.quit()
end

JM.esc_to_quit = true

function JM:keypressed(key, scancode, isrepeat)
    local scene = SceneManager.scene
    key = scancode

    if key == "escape" and self.esc_to_quit then
        return self:exit_game()
        ---
    elseif key == "f11"
        -- or (key == 'f' and love.keyboard.isDown("lctrl"))
        or (key == "return") and love.keyboard.isDown('lalt')
    then
        fullscreen = not fullscreen
        love.window.setFullscreen(fullscreen, _G.FULLSCREEN_TYPE or 'desktop')
        return scene:resize(love.graphics.getDimensions())
    end

    return scene:keypressed(key, scancode, isrepeat)
end

function JM:keyreleased(key, scancode)
    key = scancode
    return SceneManager.scene:keyreleased(key, scancode)
end

function JM:mousepressed(x, y, button, istouch, presses)
    if fullscreen_button and istouch and fullscreen_button.on_focus then
        fullscreen_button:set_focus(false)
    end

    if fullscreen_button and fullscreen_button.on_focus
        and fullscreen_button:check_collision(x, y, 0, 0)
    then
        if fullscreen then
            love.window.setFullscreen(false)
            fullscreen = false
        else
            self:to_fullscreen()
        end

        local size = math.floor(
            math.min(love.graphics.getDimensions()) * 0.075 + 0.5)
        fullscreen_button:set_dimensions(size, size)
    else
        return SceneManager.scene:mousepressed(x, y, button, istouch, presses)
    end
end

function JM:mousereleased(x, y, button, istouch, presses)
    return SceneManager.scene:mousereleased(x, y, button, istouch, presses)
end

function JM:mousemoved(x, y, dx, dy, istouch)
    return SceneManager.scene:mousemoved(x, y, dx, dy, istouch)
end

function JM:focus(f)
    local scene = SceneManager.scene

    self.Sound:focus(f)

    if not f then
        scene:pause(math.huge)
    else
        scene:unpause()
        scene:resize(love.graphics.getDimensions())
    end

    return scene:focus(f)
end

function JM:visible(v)
    if v then
        return SceneManager.scene:unpause()
    else
        return SceneManager.scene:pause(math.huge)
    end
end

function JM:wheelmoved(x, y)
    return SceneManager.scene:wheelmoved(x, y)
end

function JM:touchpressed(id, x, y, dx, dy, pressure)
    return SceneManager.scene:touchpressed(id, x, y, dx, dy, pressure)
end

function JM:touchreleased(id, x, y, dx, dy, pressure)
    return SceneManager.scene:touchreleased(id, x, y, dx, dy, pressure)
end

function JM:touchmoved(id, x, y, dx, dy, pressure)
    return SceneManager.scene:touchmoved(id, x, y, dx, dy, pressure)
end

function JM:joystickpressed(joystick, button)
    return SceneManager.scene:joystickpressed(joystick, button)
end

function JM:joystickreleased(joystick, button)
    return SceneManager.scene:joystickreleased(joystick, button)
end

function JM:joystickaxis(joystick, axis, value)
    return SceneManager.scene:joystickaxis(joystick, axis, value)
end

function JM:joystickadded(joystick)
    return SceneManager.scene:joystickadded(joystick)
end

function JM:joystickremoved(joystick)
    return SceneManager.scene:joystickremoved(joystick)
end

function JM:gamepadpressed(joy, button)
    return SceneManager.scene:gamepadpressed(joy, button)
end

function JM:gamepadreleased(joy, button)
    return SceneManager.scene:gamepadreleased(joy, button)
end

function JM:gamepadaxis(joy, axis, value)
    return SceneManager.scene:gamepadaxis(joy, axis, value)
end

function JM:resize(w, h)
    fullscreen = love.window.getFullscreen()
    if fullscreen_button then
        local size = math.floor(
            math.min(w, h) * 0.075 + 0.5)
        fullscreen_button:set_dimensions(size, size)
        fullscreen_button:set_focus(not fullscreen)
    end
    return SceneManager.scene:resize(w, h)
end

--===========================================================================

function Play_sfx(name, force, delay)
    return Sound:play_sfx(name, force, delay)
end

function Play_song(name, reset)
    return Sound:play_song(name, reset)
end

return JM
