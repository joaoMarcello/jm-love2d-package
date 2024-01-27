do
    local jit = require "jit"
    jit.off(true, true)
end

require "love.data"
require "love.image"

local folder_name = ...

local channel_finish = love.thread.getChannel('finish')
local channel_item = love.thread.getChannel('item')

local frame_number = 1

while true do
    if channel_finish:pop() then
        return
    end

    ---@type love.ImageData
    local item = channel_item:pop()
    if item then
        local data = item
        data:encode("png", string.format("%s/shot_%04d.png", folder_name, frame_number))
        frame_number = frame_number + 1
    end
end
