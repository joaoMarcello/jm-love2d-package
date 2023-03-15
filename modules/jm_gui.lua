---@type string
local path = ...
path = path:gsub("jm_gui", "")

---@type JM.GUI.Button
local Button = require(path .. "gui.button")

---@type JM.GUI.Container
local Container = require(path .. "gui.container")

---@type JM.GUI.TextBox
local TextBox = require(path .. "gui.textBox")

---@type JM.GUI.Icon
local Icon = require(path .. "gui.icon")

---@type JM.GUI.TouchButton
local TouchButton = require(path .. "gui.touch_button")

---@type JM.GUI.VirtualStick
local VirtualStick = require(path .. "gui.stick")

---@class JM.GUI
local GUI = {}

GUI.Button = Button
GUI.Container = Container
GUI.TextBox = TextBox
GUI.Icon = Icon
GUI.TouchButton = TouchButton
GUI.VirtualStick = VirtualStick

return GUI
