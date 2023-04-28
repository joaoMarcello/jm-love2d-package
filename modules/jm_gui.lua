---@type string
local path = ...
path = path:gsub("jm_gui", "")

---@type JM.GUI.Component
local Component = require(path .. "gui.component")

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

---@type JM.GUI.Label
local Label = require(path .. "gui.label")

---@class JM.GUI
local GUI = {
    Component = Component,
    Button = Button,
    Container = Container,
    TextBox = TextBox,
    Icon = Icon,
    TouchButton = TouchButton,
    VirtualStick = VirtualStick,
    Label = Label,
}

return GUI
