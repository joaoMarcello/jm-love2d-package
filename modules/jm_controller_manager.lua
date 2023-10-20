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
Manager.P2.is_keyboard_owner = false
Manager[1] = Manager.P1
Manager[2] = Manager.P2


return Manager
