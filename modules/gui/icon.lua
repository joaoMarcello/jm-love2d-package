local Affectable = _G.JM_Affectable

local function desired_size(width, height, ref_width, ref_height, keep_proportions)
    local dw, dh

    dw = width and width / ref_width or nil
    dh = height and height / ref_height or nil

    if keep_proportions then
        if not dw then
            dw = dh
        elseif not dh then
            dh = dw
        end
    end

    return dw, dh
end


---@class JM.GUI.Icon: JM.Template.Affectable
local Icon = setmetatable({}, Affectable)
Icon.__index = Icon

---@return JM.GUI.Icon
function Icon:new(args)
    local obj = Affectable:new()
    setmetatable(obj, self)
    Icon.__constructor__(obj, args)
    return obj
end

function Icon:__constructor__(args)
    self.img = type(args.img) == "string" and love.graphics.newImage(args.img) or args.img

    self.scale_x = 1
    self.scale_y = 1
    self.flip_x = 1
    self.flip_y = 1

    self.color = { 1, 1, 1, 1 }

    local w, h = self.img:getDimensions()
    self.ox = w / 2
    self.oy = h / 2
end

function Icon:set_scale(x, y)
    if not x and not y then return end

    self.scale_x = x or self.scale_x
    self.scale_y = y or self.scale_y
end

function Icon:set_size(width, height, ref_width, ref_height)
    if width or height then
        local w, h = self.img:getDimensions()

        local dw, dh = desired_size(
                width, height,
                ref_width or w,
                ref_height or h,
                true
            )

        if dw then
            self:set_scale(dw, dh)
        end
    end
end

function Icon:my_draw()
    love.graphics.setColor(self.color)
    love.graphics.draw(self.img, self.x, self.y, 0, self.scale_x * self.flip_x, self.scale_y * self.flip_y, 0,
        0)
end

function Icon:draw(x, y)
    x = x - self.ox
    y = y - self.oy
    self.x, self.y = x, y

    Affectable.draw(self, self.my_draw)
end

function Icon:draw_center(x, y)

end

return Icon
