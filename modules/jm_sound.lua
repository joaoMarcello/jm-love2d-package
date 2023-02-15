local list_sfx = {}
local list_song = {}
local volume_sfx = 1
local volume_song = 1

---@type JM.Sound.Audio|nil
local current_song = nil

--==========================================================================

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
local Sound = {}

function Sound:add_sfx(path, name, volume)
    local audio = Audio:new(path, name, volume, "static")
    audio.source:setLooping(false)
    audio.source:setVolume(volume * volume_sfx)
end

function Sound:add_song(path, name, volume)
    local audio = Audio:new(path, name, volume, "stream")
    audio.source:setLooping(true)
    audio.source:setVolume(volume * volume_song)
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

return Sound
