-- -- local love = _G.love
-- local lgx = love.graphics
-- local JM = require "jm-love2d-package.init"
-- local SceneManager = JM.SceneManager

-- function love.load()
--     math.randomseed(os.time())
--     lgx.setBackgroundColor(0, 0, 0, 1)
--     lgx.setDefaultFilter("nearest", "nearest")
--     lgx.setLineStyle("rough")
--     love.mouse.setVisible(false)

--     SCREEN_WIDTH = JM.Utils:round(320)
--     SCREEN_HEIGHT = JM.Utils:round(180)
--     SUBPIXEL = 3
--     TILE = 16
--     CANVAS_FILTER = "linear"
--     TARGET = "pc"

--     Controller = JM.Controllers.P1

--     JM_Utils:set_alpha_range(32)

--     -- local state = require(JM.SplashScreenPath)
--     local state = require("lib.gamestate.game")

--     SceneManager:change_gamestate(state)
--     _G.PLAY_SFX = function(name, force)
--         JM.Sound:play_sfx(name, force)
--     end

--     _G.PLAY_SONG = function(name)
--         JM.Sound:play_song(name)
--     end
-- end

-- function love.textinput(t)
--     return JM:textinput(t)
-- end

-- function love.keypressed(key, scancode, isrepeat)
--     if key == 'p' and love.keyboard.isDown('lctrl') then
--         return love.graphics.captureScreenshot("img_" .. os.time() .. ".png")
--     end

--     return JM:keypressed(key, scancode, isrepeat)
-- end

-- function love.keyreleased(key, scancode)
--     return JM:keyreleased(key, scancode)
-- end

-- function love.mousepressed(x, y, button, istouch, presses)
--     return JM:mousepressed(x, y, button, istouch, presses)
-- end

-- function love.mousereleased(x, y, button, istouch, presses)
--     return JM:mousereleased(x, y, button, istouch, presses)
-- end

-- function love.mousemoved(x, y, dx, dy, istouch)
--     return JM:mousemoved(x, y, dx, dy, istouch)
-- end

-- function love.focus(f)
--     return JM:focus(f)
-- end

-- function love.visible(v)
--     return JM:visible(v)
-- end

-- function love.wheelmoved(x, y)
--     return JM:wheelmoved(x, y)
-- end

-- function love.touchpressed(id, x, y, dx, dy, pressure)
--     if not _G.USE_VPAD then
--         do
--             local scene = JM.SceneManager.scene
--             if scene and not scene.is_splash_screen then
--                 scene.use_vpad = true
--             end
--             JM.ControllerManager.P1:set_vpad(JM.Vpad)
--         end
--         _G.USE_VPAD = true
--         JM:to_fullscreen()
--         return JM.Vpad:resize(love.graphics.getDimensions())
--     end
--     return JM:touchpressed(id, x, y, dx, dy, pressure)
-- end

-- function love.touchreleased(id, x, y, dx, dy, pressure)
--     return JM:touchreleased(id, x, y, dx, dy, pressure)
-- end

-- function love.touchmoved(id, x, y, dx, dy, pressure)
--     return JM:touchmoved(id, x, y, dx, dy, pressure)
-- end

-- function love.joystickpressed(joystick, button)
--     return JM:joystickpressed(joystick, button)
-- end

-- function love.joystickreleased(joystick, button)
--     return JM:joystickreleased(joystick, button)
-- end

-- function love.joystickaxis(joystick, axis, value)
--     return JM:joystickaxis(joystick, axis, value)
-- end

-- function love.joystickadded(joystick)
--     return JM:joystickadded(joystick)
-- end

-- function love.joystickremoved(joystick)
--     return JM:joystickremoved(joystick)
-- end

-- function love.gamepadpressed(joy, button)
--     return JM:gamepadpressed(joy, button)
-- end

-- function love.gamepadreleased(joy, button)
--     return JM:gamepadreleased(joy, button)
-- end

-- function love.gamepadaxis(joy, axis, value)
--     return JM:gamepadaxis(joy, axis, value)
-- end

-- function love.resize(w, h)
--     return JM:resize(w, h)
-- end

-- local km = 0
-- function love.update(dt)
--     km = collectgarbage("count") / 1024.0
--     JM:update(dt)
--     SceneManager.scene:update(dt)
-- end

-- function love.draw()
--     SceneManager.scene:draw()

--     lgx.setColor(0, 0, 0, 0.7)
--     lgx.rectangle("fill", 0, 0, 80, 120)
--     lgx.setColor(1, 1, 0, 1)
--     lgx.print(string.format("Memory:\n\t%.2f Mb", km), 5, 10)
--     lgx.print("FPS: " .. tostring(love.timer.getFPS()), 5, 50)
--     local maj, min, rev, code = love.getVersion()
--     lgx.print(string.format("Version:\n\t%d.%d.%d", maj, min, rev), 5, 75)

--     -- local stats = love.graphics.getStats()
--     -- local font = _G.JM_Font
--     -- -- font:print(stats.texturememory / (10 ^ 6), 100, 96)
--     -- font:print(stats.drawcalls, 200, 96 + 32)
--     -- font:print(stats.canvasswitches, 200, 96 + 32 + 22)
-- end
