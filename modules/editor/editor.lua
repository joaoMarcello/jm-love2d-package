local path = ...
local JM = _G.JM
local Loader = JM.Ldr

local GameMap = JM.GameMap
local MapLayer = GameMap.MapLayer

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
    canvas_w = 1366,
    canvas_h = 768,
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

function data:save(name)
    name = name or "gamemap2"
    local dir = name .. ".dat"

    ---@type any
    local d = self.map:get_save_data()

    d = Loader.ser.pack(d)

    if not data.thread_save:isRunning() then
        data.thread_save:start(d, name, dir)
    end

    -- os.rename(lfs.getSaveDirectory() .. "/" .. dir .. ".dat",
    --     lfs.getWorkingDirectory() .. "/data/gamemap/" .. dir .. ".dat")
end

function data:load(dir)
    local dir = dir or 'data/gamemap/gamemap2.dat'
    ---@type any
    local d = Loader.load(dir)

    -- d.layers[3].tilemap_number = 2

    self.map:init(d)
    -- self.map.layers[2].factor_x = 1.6
    -- self.map.layers[2].factor_y = 0.8

    -- self.map.layers[1], self.map.layers[3] = self.map.layers[3], self.map.layers[1]
    -- self.map.layers[2].type = GameMap.MapLayer.Types.static
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

    JM.GameObject:init_state(State)

    data.map = GameMap:new(State)
    data.map.camera:set_viewport(State.screen_w * 0.1,
        State.screen_h * 0.075,
        State.screen_w * 0.8,
        State.screen_h * 0.775
    )

    data.thread_save = data.thread_save
        or love.thread.newThread('/jm-love2d-package/modules/editor/thread_save.lua')



    data.debug = true
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

    if love.keyboard.isDown("lshift") then
        if key == 'w' then
            return data.map:prev_layer()
        elseif key == 's' then
            return data.map:next_layer()
        end
    end

    if love.keyboard.isDown("lctrl") and key == 'a' then
        data.map:keypressed('v')
        data.map.show_world = false
        return data.map:auto_tile()
    end

    if key == 'j' then
        data.map.layers[1], data.map.layers[3] = data.map.layers[3], data.map.layers[1]
        data.map:change_layer(3)
    end

    if love.keyboard.isDown("lalt") and key == 'b' then
        data.map:new_layer(nil, MapLayer.Types.only_fall)
        return
    end

    if key == 'd' then
        data.debug = not data.debug
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
    data.map:update_debug(dt)
end

local layer_main = {
    ---@param cam JM.Camera.Camera
    draw = function(self, cam)
        if data.debug then
            data.map:debbug_draw()
        else
            data.map:draw()
        end

        local font = JM:get_font()

        if data.thread_save:isRunning() then
            local camera = data.map.camera
            font:printf("Saving...", camera.viewport_x, camera.viewport_y + camera.viewport_h - 22, "right",
                camera.viewport_w - 10)
        end
        -- font:print(love.filesystem.getSaveDirectory(), 0, 0)
        -- font:print(love.filesystem.getWorkingDirectory(), 0, 40)
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
