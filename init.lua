local path = (...)

local JM = {}

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

---@type JM.Scene
JM.Scene = require(string.gsub(path, "init", "modules.jm_scene"))

---@type JM.Physics
JM.Physics = require(string.gsub(path, "init", "modules.jm_physics"))

---@type JM.GUI
JM.GUI = require(string.gsub(path, "init", "modules.jm_gui"))

JM_Love2D_Package = JM
return JM
