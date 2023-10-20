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
--     local scene = SceneManager.scene
--     scene:textinput(t)
-- end

-- local getKeyFromScancode = love.keyboard.getKeyFromScancode
-- function love.keypressed(key)
--     local scene = SceneManager.scene
--     key = getKeyFromScancode(key)

--     if key == "escape" then
--         scene:finish()
--         scene = nil
--         collectgarbage()
--         love.event.quit()
--         return
--     end

--     if scene then
--         scene:keypressed(key)
--     end
-- end

-- function love.keyreleased(key)
--     local scene = SceneManager.scene
--     key = getKeyFromScancode(key)

--     if scene then
--         scene:keyreleased(key)
--     end
-- end

-- function love.mousepressed(x, y, button, istouch, presses)
--     local scene = SceneManager.scene
--     if scene then scene:mousepressed(x, y, button, istouch, presses) end
-- end

-- function love.mousereleased(x, y, button, istouch, presses)
--     local scene = SceneManager.scene
--     if scene then scene:mousereleased(x, y, button, istouch, presses) end
-- end

-- function love.mousemoved(x, y, dx, dy, istouch)
--     local scene = SceneManager.scene
--     if scene then scene:mousemoved(x, y, dx, dy, istouch) end
-- end

-- function love.touchpressed(id, x, y, dx, dy, pressure)
--     local scene = SceneManager.scene
--     if scene then scene:touchpressed(id, x, y, dx, dy, pressure) end
-- end

-- function love.touchreleased(id, x, y, dx, dy, pressure)
--     local scene = SceneManager.scene
--     if scene then scene:touchreleased(id, x, y, dx, dy, pressure) end
-- end

-- function love.touchmoved(id, x, y, dx, dy, pressure)
--     local scene = SceneManager.scene
--     if scene then scene:touchmoved(id, x, y, dx, dy, pressure) end
-- end

-- function love.joystickpressed(joystick, button)
--     local scene = SceneManager.scene
--     if scene then scene:joystickpressed(joystick, button) end
-- end

-- function love.joystickreleased(joystick, button)
--     local scene = SceneManager.scene
--     if scene then scene:joystickreleased(joystick, button) end
-- end

-- function love.joystickaxis(joystick, axis, value)
--     local scene = SceneManager.scene
--     if scene then scene:joystickaxis(joystick, axis, value) end
-- end

-- function love.joystickadded(joystick)
--     local scene = SceneManager.scene
--     if scene then scene:joystickadded(joystick) end
-- end

-- function love.joystickremoved(joystick)
--     local scene = SceneManager.scene
--     if scene then scene:joystickremoved(joystick) end
-- end

-- function love.gamepadpressed(joy, button)
--     local scene = SceneManager.scene
--     if scene then scene:gamepadpressed(joy, button) end
-- end

-- function love.gamepadreleased(joy, button)
--     local scene = SceneManager.scene
--     if scene then scene:gamepadreleased(joy, button) end
-- end

-- function love.gamepadaxis(joy, axis, value)
--     local scene = SceneManager.scene
--     if scene then scene:gamepadaxis(joy, axis, value) end
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
