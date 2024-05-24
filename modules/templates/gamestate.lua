local path = ...
local JM = _G.JM

do
    _G.SUBPIXEL = _G.SUBPIXEL or 3
    _G.CANVAS_FILTER = _G.CANVAS_FILTER or 'linear'
    _G.TILE = _G.TILE or 16
end

---@class GenericState : JM.Scene
local State = JM.Scene:new {
    x = nil,
    y = nil,
    w = nil,
    h = nil,
    game_width = _G.SCREEN_WIDTH or 320,
    game_height = _G.SCREEN_HEIGHT or 180,
    tile = _G.TILE,
    subpixel = _G.SUBPIXEL or 3,
    canvas_filter = _G.CANVAS_FILTER or 'linear',
    bound_top = 0,
    bound_left = 0,
    bound_right = 1366,
    bound_bottom = 1366,
    cam_scale = 1,
}
--============================================================================
---@class GenericState.Data
local data = {}
State.props = data
--============================================================================

function State:__get_data__()
    return data
end

local function load()

end

local function finish()

end

local function init(args)

end

local function textinput(t)

end

local function keypressed(key)
    if key == 'o' then
        State.camera:toggle_grid()
        State.camera:toggle_world_bounds()
    end
end

local function keyreleased(key)

end

local function mousepressed(x, y, button, istouch, presses)

end

local function mousereleased(x, y, button, istouch, presses)

end

local function mousemoved(x, y, dx, dy, istouch)

end

local function touchpressed(id, x, y, dx, dy, pressure)

end

local function touchreleased(id, x, y, dx, dy, pressure)

end

local function touchmoved(id, x, y, dx, dy, pressure)

end

local function gamepadpressed(joystick, button)

end

local function gamepadreleased(joystick, button)

end

local function gamepadaxis(joystick, axis, value)
end

local function update(dt)

end

---@param cam JM.Camera.Camera
local function draw(cam)

end

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
    touchpressed = touchpressed,
    touchreleased = touchreleased,
    touchmoved = touchmoved,
    gamepadpressed = gamepadpressed,
    gamepadreleased = gamepadreleased,
    gamepadaxis = gamepadaxis,
    update = update,
    draw = draw,
}

return State
