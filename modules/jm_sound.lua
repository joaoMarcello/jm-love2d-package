local list_sfx = {}
local list_song = {}
local volume_sfx = 1
local volume_song = 1

---@type JM.Sound.Audio|nil
local current_song = nil

--==========================================================================
local love_get_volume = love.audio.getVolume
local love_set_volume = love.audio.setVolume

local function clamp(value, min, max)
    return math.min(math.max(value, min), max)
end
--==========================================================================

---@class JM.Sound.Audio
local Audio = {}
do
    Audio.__index = Audio

    ---@param path string
    ---@param name string
    ---@param volume number|nil
    ---@param type "stream"|"static"|"queue"
    function Audio:new(path, name, volume, type)
        local obj = setmetatable({}, self)
        Audio.__constructor__(obj, path, name, volume or 1, type or "static")
        return obj
    end

    ---@param path string
    ---@param name string
    ---@param volume number
    ---@param type "stream"|"static"|"queue"
    function Audio:__constructor__(path, name, volume, type)
        self.source = love.audio.newSource(path, type)
        self.name = name:lower()
        self.volume = volume

        if type == "static" then
            list_sfx[name] = self
        else
            list_song[name] = self
        end
    end

    function Audio:set_volume(value)
        value = clamp(value, 0, 1)
        local type_ = self.source:getType()

        self.volume = value

        local global_volume = type_ == "static" and volume_sfx or volume_song

        self.source:setVolume(value * global_volume)
    end
end
--==========================================================================

---@class JM.Sound
local Sound = {
    __fade_in = false,
    __fade_out = false,
    fade_out_speed = 1.5,
    fade_in_speed = 0.5
}

function Sound:init()
    self.__fade_in = false
    self.__fade_out = false
    love_set_volume(1)
    self:stop_all()
end

function Sound:update(dt)
    if self.__fade_out then
        local volume = love_get_volume() - 1 / self.fade_out_speed * dt
        volume = clamp(volume, 0, 1)

        love_set_volume(volume)

        if volume <= 0 then
            self.__fade_out = false
        end
        ---
    elseif self.__fade_in then
        local volume = love_get_volume() + 1 / self.fade_in_speed * dt
        love_set_volume(volume)
        if volume >= 1 then
            self.__fade_in = false
        end
    end
end

function Sound:fade_out()
    self.__fade_out = true
end

function Sound:fade_in()
    if not self.__fade_in then
        self.__fade_in = true
        love_set_volume(0)
    end
end

function Sound:add_sfx(path, name, volume)
    local audio = Audio:new(path, name, volume, "static")
    audio.source:setLooping(false)
    audio.source:setVolume(audio.volume * volume_sfx)
end

function Sound:add_song(path, name, volume)
    local audio = Audio:new(path, name, volume, "stream")
    audio.source:setLooping(true)
    audio.source:setVolume(audio.volume * volume_song)
end

function Sound:set_volume_sfx(value)
    volume_sfx = clamp(value, 0.0, 1.0)

    for _, audio in pairs(list_sfx) do
        ---@type JM.Sound.Audio
        audio = audio

        audio.source:setVolume(audio.volume * volume_sfx)
    end
end

function Sound:set_volume_song(value)
    volume_song = clamp(value, 0.0, 1.0)

    for _, audio in pairs(list_song) do
        ---@type JM.Sound.Audio
        audio = audio

        audio.source:setVolume(audio.volume * volume_song)
    end
end

---@return JM.Sound.Audio|nil
function Sound:get_sfx(name)
    return list_sfx[name]
end

---@return JM.Sound.Audio|nil
function Sound:get_song(name)
    return list_song[name]
end

function Sound:remove_song(name)
    ---@type JM.Sound.Audio
    local audio = list_song[name]
    if not audio then return false end
    audio.source:stop()
    audio.source:release()
    list_song[name] = nil
end

function Sound:get_current_song()
    return current_song
end

function Sound:play_song(name)
    ---@type JM.Sound.Audio|nil
    local audio = list_song[name]
    if not audio then return false end

    -- stopping all others songs
    for _, audio in pairs(list_song) do
        ---@type JM.Sound.Audio
        audio = audio
        audio.source:stop()
    end

    current_song = audio
    return audio.source:play()
end

function Sound:play_sfx(name)
    ---@type JM.Sound.Audio|nil
    local audio = list_sfx[name]
    if not audio then return false end

    if not audio.source:isPlaying() then
        audio.source:play()
    end
end

function Sound:pause()
    for _, audio in pairs(list_sfx) do
        ---@type JM.Sound.Audio
        audio = audio

        audio.source:pause()
    end
end

function Sound:stop_all()
    for _, audio in pairs(list_song) do
        audio.source:stop()
    end

    for _, audio in pairs(list_sfx) do
        audio.source:stop()
    end
end

return Sound
