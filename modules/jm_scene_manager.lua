---@alias JM.GameState.Config {skip_finish:boolean, skip_load:boolean, save_prev:boolean, skip_collect:boolean, skip_init:boolean, skip_transition:boolean, transition:string, transition_conf:table, unload:string, skip_prev_state_finish:boolean, trans_end_action:function}

-- ---@type JM.Scene
-- local scene

---@class JM.SceneManager
---@field scene JM.Scene|any
local Manager = {}

-- ---@return JM.Scene | any
-- function Manager:get_scene()
--     return self.scene
-- end

---@param new_state JM.Scene
---@param conf JM.GameState.Config|any
function Manager:change_gamestate(new_state, conf)
    local scene = self.scene
    JM.Sound:init()

    conf = conf or {}
    conf.transition = conf.transition or (not conf.skip_transition and "fade")
    conf.transition_conf = conf.transition_conf
        or (conf.transition == "fade" and { duration = 0.3 })

    ---@type any
    local r = scene and not conf.skip_finish and scene:finish()

    if not conf.keep_canvas and scene then
        if scene.canvas then
            scene.canvas:release()
            scene.canvas = nil
        end

        if scene.canvas_layer then
            scene.canvas_layer:release()
            scene.canvas_layer = nil
        end
    end

    if scene and scene.prev_state and not conf.skip_prev_state_finish
        and new_state ~= scene.prev_state
    then
        scene.prev_state:finish()
        scene.prev_state = nil
    end

    -- if scene then
    --     scene.trans_action = nil
    --     scene.trans_end_action = nil
    -- end

    new_state.prev_state = conf.save_prev and scene or nil

    self.scene = new_state

    JM.Vpad:flush()

    r = (not conf.skip_load) and new_state:load()
    r = (not conf.skip_init) and new_state:init()

    if conf.unload then
        package.loaded[conf.unload] = nil
        _G[conf.unload] = nil
    end

    scene = new_state
    scene:restaure_canvas()
    if conf.skip_init then scene.default_config(scene) end

    r = (not conf.skip_collect) and collectgarbage()

    r = conf.transition and scene:add_transition(conf.transition, "in", conf.transition_conf, nil, conf.trans_end_action) or
        nil

    self.scene = scene
    scene:resize(love.graphics.getDimensions())
    scene:update(0.0)

    return r
end

---@param state JM.Scene
function Manager:restart_gamestate(state)
    return self:change_gamestate(state, {
        skip_finish = true,
        skip_load = true,
    })
end

---@param state JM.Scene
function Manager:pause_gamestate(state)
    self:change_gamestate(state, {
        skip_finish = true,
        save_prev = true,
        skip_collect = true,
        skip_transition = true
    })
end

function Manager:unpause_gamestate(state)
    if not state then return end
    self:change_gamestate(state.prev_state, {
        skip_finish = true,
        skip_load = true,
        skip_init = true,
        skip_transition = true
    })
end

return Manager
