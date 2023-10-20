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

---@type JM.GUI
JM.GUI = require(string.gsub(path, "init", "modules.jm_gui"))

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

---@type JM.ParticleSystem
JM.ParticleSystem = require(string.gsub(path, "init", "modules.jm_ps"))

JM.SplashScreenPath = 'jm-love2d-package.modules.templates.splashScreen'

function JM:update(dt)
    JM_Font.current:update(dt)
    self.Sound:update(dt)
    self.ParticleSystem:update(dt)
end

return JM
