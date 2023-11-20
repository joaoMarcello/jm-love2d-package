local path = ...
local JM = _G.JM
local Loader = JM.Ldr

---@type JM.GameMap
local GameMap = require(string.gsub(path, "editor.editor", "editor.game_map"))

do
    _G.SUBPIXEL = _G.SUBPIXEL or 3
    _G.CANVAS_FILTER = _G.CANVAS_FILTER or 'linear'
    _G.TILE = _G.TILE or 16
end

---@class JM.Editor : JM.Scene
local State = JM.Scene:new {
    x = nil,
    y = nil,
    w = nil,
    h = nil,
    -- canvas_w = 1024,
    -- canvas_h = 768,
    tile = 64,
    subpixel = 1,
    canvas_filter = _G.CANVAS_FILTER or 'linear',
    bound_top = 0,
    bound_left = 0,
    bound_right = 1366,
    bound_bottom = 1366,
    cam_scale = 1,
}
--============================================================================
---@class JM.Editor.Data
local data = {}

function data:save()
    ---@type any
    local d = self.map:get_save_data()

    Loader.save(d, "gamemap.dat")

    d = Loader.ser.pack(d)
    love.filesystem.write("gamemap.txt", d)
    -- Loader:savexp(d, "gamemap.dat")
end

function data:load()
    local dir = 'gamemap.dat'
    ---@type any
    local d = Loader.load(dir)

    self.map:init(d)
    -- data.map.camera:set_viewport(State.screen_w * 0.1, State.screen_h * 0.1, State.screen_w * 0.8, State.screen_h * 0.8)
end

--============================================================================

function State:__get_data__()
    return data
end

local function load()
    GameMap:load()
end

local function finish()
    GameMap:finish()
end

local function init(args)
    love.filesystem.setIdentity("map-editor")

    local world = JM.Physics:newWorld()
    JM.GameObject:init_state(State, world)

    data.map = GameMap:new()
    -- data.map.camera:set_viewport(64 * 3, 64, 64 * 10, 64 * 9)
    data.map.camera:set_viewport(State.screen_w * 0.1, State.screen_h * 0.1, State.screen_w * 0.8, State.screen_h * 0.8)
end

local function textinput(t)

end

local function keypressed(key)
    if key == 'o' then
        State.camera:toggle_grid()
        State.camera:toggle_world_bounds()
    end

    if love.keyboard.isDown("lctrl") and key == 's' then
        return data:save()
    end

    if key == 'l' then
        return data:load()
    end

    data.map:keypressed(key)
end

local function keyreleased(key)
    data.map:keyreleased(key)
end

local function mousepressed(x, y, button, istouch, presses)
    data.map:mousepressed(x, y, button, istouch, presses)
end

local function mousereleased(x, y, button, istouch, presses)
    data.map:mousereleased(x, y, button, istouch, presses)
end

local function mousemoved(x, y, dx, dy, istouch)
    data.map:mousemoved(x, y, dx, dy, istouch)
end

local function wheelmoved(x, y)
    data.map:wheelmoved(x, y)
end

local function touchpressed(id, x, y, dx, dy, pressure)

end

local function touchreleased(id, x, y, dx, dy, pressure)

end

local function gamepadpressed(joystick, button)

end

local function gamepadreleased(joystick, button)

end

local function update(dt)
    data.map:update(dt)
end

local layer_main = {
    ---@param cam JM.Camera.Camera
    draw = function(self, cam)
        data.map:draw()
    end
}

local layers = {
    --
    layer_main,
    --
    --
}
--============================================================================
State:implements {
    load = load,
    init = init,
    finish = finish,
    textinput = textinput,
    keypressed = keypressed,
    keyreleased = keyreleased,
    mousepressed = mousepressed,
    mousereleased = mousereleased,
    mousemoved = mousemoved,
    wheelmoved = wheelmoved,
    touchpressed = touchpressed,
    touchreleased = touchreleased,
    gamepadpressed = gamepadpressed,
    gamepadreleased = gamepadreleased,
    update = update,
    layers = layers,
}

return State
