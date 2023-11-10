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

---@type JM.Font.Manager
JM.Font = require(string.gsub(path, "init", "modules.jm_font"))
JM_Font = JM.Font

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


local fonts = {}

---@alias JM.AvailableFonts "pix5"|"pix8"|"circuit17"|"circuit21"

---@param font JM.AvailableFonts
function JM:get_font(font)
    if font == "pix8" then
        local pix8 = fonts[font] or JM.FontGenerator:new {
            name            = "pix8",
            dir             = "jm-love2d-package/data/font/font_pix8-Sheet.png",
            glyphs          = [[AÀÁÃÄÂaàáãäâBbCcÇçDdEÈÉÊËeèéêëFfGgHhIÌÍÎÏiìíîïJjKkLlMmNnOÒÓÕÔÖoòóõôöPpQqRrSsTtUÙÚÛÜuùúûüVvWwXxYyZz0123456789!?@#$%^&*()<>{}:[]:mult::div::cpy:+-_=¬'"¹²³°ºª\/.:dots:;,:dash:|¢£:blk_bar::arw_fr::arw_bk::arw_up::arw_dw::bt_a::bt_b::bt_x::bt_y::star::heart::circle:]],
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
        local pix5 = fonts[font] or JM.FontGenerator:new {
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
        local c21 = fonts[font] or JM.FontGenerator:new {
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
        local c17 = fonts[font] or JM.FontGenerator:new {
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
    end
end

function JM:update(dt)
    JM_Font.current:update(dt)
    self.Sound:update(dt)
    self.ParticleSystem:update(dt)
end

return JM
