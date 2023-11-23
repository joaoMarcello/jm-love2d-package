local lfs             = require "love.filesystem"
local Loader          = require "jm-love2d-package.modules.jm_loader"

local data, name, dir = ...

Loader.save(data, dir)

lfs.write(name .. ".txt", data)

os.execute("mkdir data\\gamemap")

os.execute(string.format("copy /y %s %s",
    lfs.getSaveDirectory():gsub("/", "\\") .. "\\" .. dir,
    lfs.getWorkingDirectory():gsub("/", "\\") .. "\\data\\gamemap\\" .. dir
))

os.execute(string.format("copy /y %s %s",
    lfs.getSaveDirectory():gsub("/", "\\") .. "\\" .. name .. ".txt",
    lfs.getWorkingDirectory():gsub("/", "\\") .. "\\data\\gamemap\\" .. name .. ".txt"
))

lfs = nil
---@diagnostic disable-next-line: cast-local-type
Loader = nil
data, name, dir = nil, nil, nil
collectgarbage()
