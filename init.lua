local path = (...)
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
        local pix8 = JM.FontGenerator:new {
            name            = "pix8",
            dir             = "jm-love2d-package/data/font/font_pix8-Sheet.png",
            glyphs          = [[AÀÁÃÄÂaàáãäâBbCcÇçDdEÈÉÊËeèéêëFfGgHhIÌÍÎÏiìíîïJjKkLlMmN:enne_up:n:enne:OÒÓÕÔÖoòóõôöPpQqRrSsTtUÙÚÛÜuùúûüVvWwXxYyZz0123456789!?@#$%^&*()<>{}:[]:mult::div::cpy:+-_=¬'"¹²³°ºª\/.:dots:;,:dash:|¢£:blk_bar::arw_fr::arw_bk::arw_up::arw_dw::bt_a::bt_b::bt_x::bt_y::bt_r::bt_l::star::heart::diamond::circle::arw2_fr::arw2_bk::spa_inter::female::male::check::line::db_comma_init::db_comma_end::comma_init::comma_end::arw_head_fr::arw_head_bk:]],
            min_filter      = "linear",
            max_filter      = "nearest",
            character_space = 0,
            word_space      = 5,
            line_space      = 4,
        }
        pix8:set_color(JM.Utils:get_rgba())
        pix8:set_font_size(pix8.__ref_height)
        fonts[font] = pix8
        return pix8
        ---
    elseif font == "pix5" then
        local pix5 = JM.FontGenerator:new {
            name = "pix5",
            dir = "jm-love2d-package/data/font/font_pix5-Sheet.png",
            glyphs = [[aàáãâäbcçdeèéêëfghiìíîïjklmnoòóõôöpqrstuùúûüvwxyz0123456789-_.:dots::+:square::blk_bar::heart:()[]{}:arw_fr::arw_bk::arw_up::arw_dw::dash:|,;!?\/*~^:arw2_fr::arw2_bk:º°¬'":div:%#¢@]],
            min_filter = 'linear',
            max_filter = 'nearest',
            character_space = 0,
            word_space = 4,
            line_space = 1,
        }
        pix5:set_color(JM.Utils:get_rgba())
        pix5:set_font_size(pix5.__ref_height)
        fonts[font] = pix5
        return pix5
        ---
    elseif font == "circuit21" then
        local c21 = JM.FontGenerator:new {
            name = "circuit21",
            dir = "/jm-love2d-package/data/font/circuit21-Sheet.png",
            glyphs = "1234567890-:null:",
            min_filter = "linear",
            max_filter = "nearest",
            word_space = 3,
        }
        c21:set_color(JM.Utils:get_rgba())
        c21:set_font_size(c21.__ref_height)
        fonts[font] = c21
        return c21
        ---
    elseif font == "circuit17" then
        local c17 = JM.FontGenerator:new {
            name = "circuit17",
            dir = "/jm-love2d-package/data/font/circuit17-Sheet.png",
            glyphs = "1234567890-:null:",
            min_filter = "linear",
            max_filter = "nearest",
            word_space = 3,
        }
        c17:set_color(JM.Utils:get_rgba())
        c17:set_font_size(c17.__ref_height)
        fonts[font] = c17
        return c17
        ---
    else
        local f = JM.FontGenerator:new_by_ttf {
            dir = "/jm-love2d-package/data/font/OpenSans-Regular.ttf",
            dir_bold = "/jm-love2d-package/data/font/OpenSans-SemiBold.ttf",
            -- path_italic = "/data/font/Komika Text Italic.ttf",
            dpi = 36,
            name = "open sans",
            font_size = 12,
            character_space = 2,
            tab_size = 4,
            min_filter = "linear",
            max_filter = "nearest",
            max_texturesize = 2048,
            -- save = true,
            threshold = { { "00", "7f" }, { "80", "ff" }, { "100", "17f" }, { "180", "24f" }, { "2b0", "2ff" }, { "300", "36f" }, { "370", "3ff" }, { "400", "4ff" }, { "1d00", "1d7f" }, { "1d80", "1dbf" }, { "1e00", "1eff" }, { "2000", "206f" }, { "2070", "209f" }, { "2100", "214f" }, { "2150", "218f" }, { "2200", "22ff" }, { "2300", "23ff" } },
        }
        fonts[font] = f
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

JM.SplashScreenPath = 'jm-love2d-package.modules.templates.splashScreen'

--===========================================================================
local SceneManager = JM.SceneManager
local Sound = JM.Sound

local fullscreen

--- Loads the first game scene.
---@param s string the directory for the first game scene.
---@param use_splash boolean|nil if should use splash screen
function JM:load_initial_state(s, use_splash)
    fullscreen = love.window.getFullscreen()

    local state

    if use_splash then
        ---@type JM.GameState.Splash
        state = require(JM.SplashScreenPath)
        state:__get_data__():set_next_state_string(s)
    else
        state = require(s)
    end
    SceneManager:change_gamestate(state, { skip_transition = true })
    return SceneManager.scene:resize(love.graphics.getDimensions())
end

function JM:flush()
    JM.FontGenerator.flush()
    collectgarbage()
end

function JM:update(dt)
    SceneManager.scene:update(dt)

    JM:get_font():update(dt)

    Sound:update(dt)
    return self.ParticleSystem:update(dt)
end

function JM:draw()
    return SceneManager.scene:draw()
end

--===========================================================================

function JM:textinput(t)
    return SceneManager.scene:textinput(t)
end

function JM:keypressed(key, scancode, isrepeat)
    local scene = SceneManager.scene
    key = scancode

    if key == "escape" then
        scene:finish()
        scene = nil
        collectgarbage()
        return love.event.quit()
    elseif key == "f11" or (key == 'f' and love.keyboard.isDown("lctrl")) then
        fullscreen = not fullscreen
        love.window.setFullscreen(fullscreen, 'desktop')
        scene:resize(love.graphics.getDimensions())
    end

    return scene:keypressed(key, scancode, isrepeat)
end

function JM:keyreleased(key, scancode)
    key = scancode
    return SceneManager.scene:keyreleased(key, scancode)
end

function JM:mousepressed(x, y, button, istouch, presses)
    return SceneManager.scene:mousepressed(x, y, button, istouch, presses)
end

function JM:mousereleased(x, y, button, istouch, presses)
    return SceneManager.scene:mousereleased(x, y, button, istouch, presses)
end

function JM:mousemoved(x, y, dx, dy, istouch)
    return SceneManager.scene:mousemoved(x, y, dx, dy, istouch)
end

function JM:focus(f)
    local scene = SceneManager.scene

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
    return SceneManager.scene:resize(w, h)
end

--===========================================================================

JM:get_font()

function Play_sfx(name, force)
    return Sound:play_sfx(name, force)
end

function Play_song(name)
    return Sound:play_song(name)
end

return JM
