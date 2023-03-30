---@alias JM.GameState.Config {skip_finish:boolean, skip_load:boolean, save_prev:boolean, skip_collect:boolean, skip_init:boolean, skip_transition:boolean, transition:string, transition_conf:table}

---@type JM.Scene
local scene

---@class JM.SceneManager
local Manager = {}
Manager.__index = Manager

function Manager:get_scene()
    return scene
end

---@param conf JM.GameState.Config|any
function Manager:change_gamestate(new_state, conf)
    conf = conf or {}
    conf.transition = conf.transition or (not conf.skip_transition and "fade")
    conf.transition_conf = conf.transition_conf
        or (conf.transition == "fade" and { duration = 0.3 })

    ---@type any
    local r = scene and not conf.skip_finish and scene:finish()
    new_state.prev_state = conf.save_prev and scene or nil

    r = (not conf.skip_load) and new_state:load()
    r = (not conf.skip_init) and new_state:init()
    r = (not conf.skip_collect) and collectgarbage()

    scene = new_state

    r = conf.transition and scene:add_transition(conf.transition, "in", conf.transition_conf) or nil

    scene:update(love.timer.getDelta())

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
