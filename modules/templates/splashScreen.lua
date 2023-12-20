local path = ...
local JM = _G.JM_Package
local Utils = JM.Utils

---@class JM.GameState.Splash : JM.Scene
local State = JM.Scene:new {
    x = nil,
    w = nil,
    y = nil,
    h = nil,
    canvas_w = 1366,          --SCREEN_WIDTH,
    canvas_h = 768,           --SCREEN_HEIGHT,
    subpixel = 1.0,           --SUBPIXEL,
    canvas_filter = 'linear', --CANVAS_FILTER,
    tile = TILE,
    cam_tile = TILE,
    show_border = false,
    -- use_stencil = true,
}

---@enum JM.Splash.States
local States = {
    love = 1,
    jm = 2,
}

local E = 2.718281828459

---@class JM.GameState.Splash.Data
---@field affect JM.Template.Affectable
local data = {
    --
    light_blue = { 233 / 255, 245 / 255, 255 / 255, 1 },
    blue = { 39 / 255, 170 / 255, 255 / 255, 1 },
    pink = { 231 / 255, 74 / 255, 153 / 255, 1 },
    --
    state = States.love,
    --
    x_rect = math.pi,
    speed_rect = 0.8,
    --
    result_rect = 0,
    --
    x_rot = 0,       --math.pi,
    speed_rot = 1.8, --0.85 * 2,
    domain_rot = math.pi * 1.72,
    result_rot = 0,  -- value from 0 to 1
    ------------------------------------------------------------------
    x_mask = 0,
    speed_mask = 1,
    domain_mask = State.screen_w / 2 + State.screen_w * 0.1 * 0,
    result_mask = 1,
    --
    next_state = 'lib.gamestate.howToPlay',
    --
    skip_state = function(self)
        if not State.transition then
            State:add_transition("fade", "out", { duration = 0.8 }, nil,
                function()
                    if self.state == States.jm then
                        State:change_gamestate(require(self.next_state), {
                            unload = path,
                            transition = "fade",
                            transition_conf = { delay = 0.2, duration = 0.25 }
                        })
                    else
                        State:add_transition("fade", "in", { delay = 0.25, duration = 0.8 })
                        State:init(States.jm)
                    end
                end)

            -- if self.state == States.jm then
            --     State:change_gamestate(require(self.next_state), {
            --         unload = path,
            --         skip_transition = true,
            --     })
            -- else
            --     State:init(States.jm)
            -- end
        end
    end,
    ---
    set_next_state_string = function(self, value)
        self.next_state = value
    end
}


---@return JM.GameState.Splash.Data
function State:__get_data__()
    return data
end

local function sigmoid(x)
    return 1.0 / (1.0 + (E ^ (-x)))
end

local function tanh(x)
    local E_2x = E ^ (2 * x)
    return (E_2x - 1) / (E_2x + 1)
end


--==========================================================================
local lgx = love.graphics

local mask_shader = lgx.newShader [[
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){vec4 pixel = Texel(texture, texture_coords );
if(pixel.r == 1.0 && pixel.b == 1.0){return vec4(0.0,0.0,0.0,0.0);}return vec4(0.0,0.0,0.0,1.0);}]]

local SCREEN_WIDTH = State.screen_w
local RECT_HEIGHT = State.screen_h / 2
local EXTRA_VALUE = State.screen_h / 2

local function draw_rects()
    local full = data.result_rect >= 1
    local slope_w = State.screen_w * 0.3 --200

    lgx.setColor(data.pink)
    lgx.rectangle("fill", -EXTRA_VALUE, -EXTRA_VALUE, EXTRA_VALUE, EXTRA_VALUE + RECT_HEIGHT)

    if full then
        lgx.rectangle("fill", SCREEN_WIDTH, -EXTRA_VALUE, SCREEN_WIDTH, RECT_HEIGHT + EXTRA_VALUE)
    end
    local w = SCREEN_WIDTH * data.result_rect
    lgx.rectangle("fill", 0, -EXTRA_VALUE,
        w,
        RECT_HEIGHT + EXTRA_VALUE
    )
    --========================================================================

    lgx.polygon("fill", w, -EXTRA_VALUE, w + slope_w, -EXTRA_VALUE, w, RECT_HEIGHT)
    --========================================================================
    lgx.setColor(data.blue)
    lgx.rectangle("fill", SCREEN_WIDTH, RECT_HEIGHT, EXTRA_VALUE, RECT_HEIGHT + EXTRA_VALUE)

    if full then
        lgx.rectangle("fill", -EXTRA_VALUE, RECT_HEIGHT, EXTRA_VALUE, RECT_HEIGHT + EXTRA_VALUE)
    end

    local px = SCREEN_WIDTH * (1.0 - data.result_rect)
    lgx.rectangle("fill", px,
        RECT_HEIGHT,
        SCREEN_WIDTH,
        RECT_HEIGHT + EXTRA_VALUE
    )
    --=======================================================
    -- lgx.setColor(1, 0, 0)
    lgx.polygon("fill", px, RECT_HEIGHT, px, RECT_HEIGHT + RECT_HEIGHT + EXTRA_VALUE, px - slope_w,
        RECT_HEIGHT + RECT_HEIGHT + EXTRA_VALUE)
    --=======================================================
end

local draw_main = {
    [States.love] = function(self, camera)
        State:draw_game_object(camera)

        data.affect:draw(draw_rects)

        -- local font = JM_Font.current
        -- font:print(tostring(data.result_rect), 32, 32)
        -- font:print(tostring(data.offset_x), 32, 32 + 16)

        local px = data.logo_x + data.logo_w * 0.5
        local px2 = data.logo_x + data.logo_w * 0.51
        local py = data.logo_y + data.logo_h * 0.525 + data.offset
        local py2 = data.logo_y + data.logo_h * 0.55 + data.offset
        data.heart:set_color2(0, 0, 0, 0.3)
        data.heart:draw(px2, py2)
        data.heart:set_color2(1, 1, 1, 1)
        data.heart:draw(px, py)
    end,
    ---
    [States.jm] = function(self, cam)
        lgx.setColor(1, 0, 0)
        local x = State.screen_w * 0.5
        local y = State.screen_h * 0.5
        local diag = math.sqrt(State.screen_h ^ 2 + State.screen_w ^ 2)
        local r = diag * 0.5 * 0.15

        -- lgx.circle("fill", x, y, r)

        data.jm_logo:set_size(r * 2)
        data.jm_logo:draw(x, y)
    end
}

local draw_mask = {
    [States.love] = function(self, cam)
        lgx.setColor(1, 0, 1)
        lgx.circle("fill", data.logo_x + data.logo_w * 0.5,
            data.logo_y + data.logo_h * 0.5 + data.offset,
            data.mask_min_raio + (data.domain_mask * data.result_mask)
        )
    end,
    ---
    [States.jm] = function(self, cam)

    end
}

local draw_text = {
    [States.love] = function(self, cam)
        -- local font = JM_Font.current
        -- font:print("<color, 1, 1, 1>tostring(data.result_rect)", 90, 32)

        data.made_with:draw(State.screen_w * 0.5,
            data.logo_y + data.logo_h * 1.2 + data.offset
        )

        data.love_text:draw(State.screen_w * 0.5,
            data.logo_y + data.logo_h * 1.5 + data.offset
        )
    end,
    ---
    [States.jm] = function(self, cam)

    end
}
--===========================================================================

local function load()
    data.img = data.img or {}
    data.img["heart"] = data.img["heart"]
        or lgx.newImage("jm-love2d-package/data/img/love-heart.png")

    data.img["made-with"] = data.img["made-with"]
        or lgx.newImage("jm-love2d-package/data/img/made-with.png")

    data.img["love-text"] = data.img["love-text"]
        -- or lgx.newImage("/data/img/love-logo-512x256.png")
        or lgx.newImage("jm-love2d-package/data/img/love-text.png")

    data.img["jm-logo"] = data.img["jm-logo"]
        or lgx.newImage("/jm-love2d-package/data/img/jm_icone_game.png")

    data.sound = data.sound
        or (love.filesystem.getInfo('/data/sfx/simple-clean-logo.ogg')
            and love.audio.newSource('data/sfx/simple-clean-logo.ogg', 'static'))
end

local function init(state)
    SCREEN_WIDTH = State.screen_w
    RECT_HEIGHT = State.screen_h * 0.5
    EXTRA_VALUE = State.screen_h * 0.5

    state = state or States.love

    if not state or state == States.love then
        data.state = States.love

        data.affect = JM.Affectable:new()
        data.affect.ox = State.screen_w / 2
        data.affect.oy = State.screen_h / 2
        -- data.affect:set_effect_transform("oy", -30)

        data.x_rect = 0 --E + 0.5
        data.result_rect = 0
        -- data.domain_rect = math.pi
        data.speed_rect = 1.1

        data.x_rot = 0 ---E --math.pi
        data.result_rot = 0

        data.logo_w = State.screen_h * 0.3
        data.logo_h = data.logo_w

        data.logo_x = State.screen_w / 2 - data.logo_w / 2
        data.logo_y = State.screen_h / 2 - data.logo_h / 2

        local diagonal = math.sqrt(State.screen_w ^ 2 + State.screen_h ^ 2)

        data.mask_max_raio = diagonal * 0.5 --State.screen_w * 0.6
        data.mask_min_raio = data.logo_w / 2
        data.domain_mask = data.mask_max_raio - data.mask_min_raio
        data.x_mask = 0
        data.speed_mask = 0.9

        data.offset_max = data.logo_h * 0.4
        data.offset_x = 0
        data.offset_speed = 1.5
        data.offset_result = 0
        data.offset = 0

        data.heart = JM.Anima:new { img = data.img["heart"],
            min_filter = 'linear', max_filter = 'linear'
        }
        data.heart:set_size(data.logo_w * 0.6)
        local eff = data.heart:apply_effect("pulse",
            { speed = 0.3, duration = 0.3 }
        )
        data.heart:set_visible(false)

        data.made_with = JM.Anima:new { img = data.img["made-with"],
            min_filter = 'nearest', max_filter = 'nearest'
        }
        data.made_with:set_size(data.logo_w * 0.5)
        data.made_with:set_visible(false)
        data.made_with:apply_effect("fadein", { speed = 0.8, delay = 0.1 })

        data.love_text = JM.Anima:new { img = data.img["love-text"],
            min_filter = 'linear', max_filter = 'linear'
        }
        data.love_text:set_size(data.logo_w * 1.2)
        data.love_text:set_visible(false)
        data.love_text:apply_effect("fadein", { speed = 1.3, delay = 0.1 })

        eff:set_final_action(function()
            data.made_with:set_visible(true)
            data.love_text:set_visible(true)
        end)

        State:set_color(unpack(data.light_blue))
        data.played_sound = false

        State.__layers[2].use_canvas = true
        State.__layers[2].shader = mask_shader
        --
    elseif state == States.jm then
        data.state = state
        data.px = 100
        data.py = 20
        data.width = 50
        data.time_state = 0
        data.duration = 2.5
        data.scale = 1.0

        data.jm_logo = JM.Anima:new { img = data.img["jm-logo"], min_filter = 'linear', max_filter = 'linear' }

        State:set_color(0, 0, 0, 1)
        State.__layers[2].use_canvas = false
        State.__layers[2].shader = nil
    end

    State.__layers[1].draw = draw_main[data.state]
    State.__layers[2].draw = draw_mask[data.state]
    State.__layers[3].draw = draw_text[data.state]
end

local function finish()
    if data.img then
        data.img["heart"]:release()
        data.img["made-with"]:release()
        data.img["love-text"]:release()
    end

    if data.sound then
        data.sound:stop()
        data.sound:release()
    end

    mask_shader:release()
end

local function keypressed(key)
    if key == "o" then
        State.camera:toggle_grid()
        State.camera:toggle_debug()
        State.camera:toggle_world_bounds()
    end

    if key == "s" then
        State:init()
    end

    if key == "return" or key == "space" then
        data:skip_state()
    end
end

local function keyreleased(key)

end

local function mousepressed(x, y, bt, istouch)
    data:skip_state()
end

local function gamepadpressed(joy, bt)
    if bt == 'a' or bt == 'start' then
        data:skip_state()
    end
end

local function love_logo_update(dt)
    if not data.played_sound and data.sound then
        if data.sound:isPlaying() then data.sound:stop() end
        data.sound:play()
        data.played_sound = true
    end

    data.x_rect = data.x_rect + (math.pi / data.speed_rect) * dt
    data.x_rect = Utils:clamp(data.x_rect, 0, math.pi)
    data.result_rect = 1.0 - (math.cos(data.x_rect) + 1) * 0.5

    --======================================================================

    if data.result_rect >= 0.6 then
        data.x_rot = data.x_rot + (E / data.speed_rot) * dt
    end

    data.result_rot = (tanh(data.x_rot))
    if data.result_rot > 0.9999 then
        data.result_rot = 1
    end
    data.affect:set_effect_transform("rot", data.result_rot * data.domain_rot)

    --=========================================================================

    if data.result_rect >= 0.7 then
        data.x_mask = data.x_mask + (E / data.speed_mask) * dt
    end
    data.result_mask = 1 - tanh(data.x_mask)
    if data.result_mask <= 0.001 then
        data.result_mask = 0.0
    end
    data.result_mask = Utils:clamp(data.result_mask, 0, 1)
    --=========================================================================
    local domain = (math.pi)

    if data.result_mask <= 0.7 then
        data.offset_x = data.offset_x +
            (domain / data.offset_speed) * dt
    end
    data.offset_x = Utils:clamp(data.offset_x, 0, 1)
    data.offset_result = (math.sin(data.offset_x))
    data.offset = -data.offset_max * data.offset_result

    data.affect:set_effect_transform("oy", data.offset)
    --========================================================================
    if data.x_mask >= (E * 0.9) then
        data.heart:update(dt)
        data.heart:set_visible(true)
    end

    if data.made_with.is_visible then
        data.made_with:update(dt)
        data.love_text:update(dt)

        if not State.transition and data.result_rot >= 1 then
            State:add_transition("fade", "out", { duration = 1.1 }, nil, function()
                -- State:init(States.jm)
                -- State:add_transition("fade", "in", { duration = 0.8, delay = 0.25 })

                State:change_gamestate(require(data.next_state), {
                    unload = path,
                    skip_transition = true,
                    transition = "fade",
                    transition_conf = { delay = 0.2, duration = 0.25 },
                })

                if data.sound then
                    data.sound:stop()
                end
            end)
        end
    end
end

local jm_update = function(dt)
    data.time_state = data.time_state + dt

    data.scale = data.scale + (0.2 / 3.5) * dt
    data.jm_logo:set_effect_transform("sx", data.scale)
    data.jm_logo:set_effect_transform("sy", data.scale)

    data.jm_logo:update(dt)

    if not State.transition and data.time_state >= data.duration then
        State:add_transition("fade", "out", { duration = 1.1 }, nil,
            function()
                State:change_gamestate(require(data.next_state), {
                    unload = path,
                    skip_transition = true,
                    transition = "fade",
                    transition_conf = { delay = 0.2, duration = 0.25 }
                })
            end)
    end
end

local function update(dt)
    dt = dt > 1 / 30 and 1 / 60 or dt

    if data.state == States.love then
        love_logo_update(dt)
    else
        jm_update(dt)
    end
end
--===========================================================================

local layer_main = {
    name = 'main',
    --
    draw = draw_main[States.love]
}

local layer_mask = {
    name = 'mask',
    use_canvas = true,
    shader = mask_shader,
    --
    draw = draw_mask[States.love]
}

local layer_text = {
    name = 'text',
    use_canvas = false,
    ---
    draw = draw_text[States.love]
}
--========================================================
State:implements {
    load = load,
    init = init,
    finish = finish,
    keypressed = keypressed,
    keyreleased = keyreleased,
    mousepressed = mousepressed,
    gamepadpressed = gamepadpressed,
    update = update,

    layers = {
        layer_main,
        layer_mask,
        layer_text,
    }
}
-- Sound Effect by Muzaproduction from Pixabay

return State
