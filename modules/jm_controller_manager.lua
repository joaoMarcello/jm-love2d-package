local Controller = JM.Controller

---@class JM.ControllerManager
local Manager = {
    P1 = Controller:new(),
    P2 = Controller:new(),
    State = Controller.State,
    n = 2,
    joy_to_controller = {},
}
Manager.keyboard_owner = Manager.P1
Manager.P2.is_keyboard_owner = true
Manager[1] = Manager.P1
Manager[2] = Manager.P2

---@param controller JM.Controller
function Manager:switch_keyboard_owner(controller)
    if not controller then return end

    for i = 1, self.n do
        ---@type JM.Controller
        local c = self[i]
        c.is_keyboard_owner = false
    end

    self.keyboard_owner = controller
    controller.is_keyboard_owner = true
end

return Manager
