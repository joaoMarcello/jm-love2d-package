local list_sfx = {}
local list_song = {}
local volume_sfx = 1
local volume_song = 1

---@type JM.Sound.Audio|nil
local current_song = nil

local song_mode = "stream"

--==========================================================================
local love_get_volume = love.audio.getVolume
local love_set_volume = love.audio.setVolume
local pairs = pairs

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
    function Audio:new(path, name, volume, type, is_song)
        local obj = setmetatable({}, self)
        Audio.__constructor__(obj, path, name, volume or 1, type or "static", is_song)
        return obj
    end

    ---@param path string
    ---@param name string
    ---@param volume number
    ---@param type "stream"|"static"|"queue"
    function Audio:__constructor__(path, name, volume, type, is_song)
        self.source = love.audio.newSource(path, type)
        self.name = name --name:lower()
        self.volume = volume
        self.init_volume = volume

        if type == "static" and not is_song then
            list_sfx[name] = self
        else
            list_song[name] = self
        end
    end

    function Audio:set_volume(value)
        value = value or self.init_volume
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
    fade_out_speed = 0.5,
    fade_in_speed = 0.5,
    lock__ = false,
}

function Sound:config(args)
    self.fade_in_speed = args.fade_in_speed or self.fade_in_speed
    self.fade_out_speed = args.fade_out_speed or self.fade_out_speed
end

function Sound:lock()
    Sound.lock__ = true
end

function Sound:unlock()
    Sound.lock__ = false
end

function Sound:init()
    self.__fade_in = false
    self.__fade_out = false
    love_set_volume(1)
    -- self:stop_all()
end

function Sound:update(dt)
    if self.__fade_out then
        local volume = love_get_volume() - 1.0 / self.fade_out_speed * dt
        volume = clamp(volume, 0, 1)

        love_set_volume(volume)

        if volume <= 0 then
            self.__fade_out = false
        end
        ---
    elseif self.__fade_in then
        local volume = love_get_volume() + 1.0 / self.fade_in_speed * dt
        love_set_volume(volume)
        if volume >= 1 then
            self.__fade_in = false
        end
    end
end

function Sound:fade_out(duration)
    if not self.__fade_out then
        self.fade_out_speed = duration or 0.5
        self.__fade_out = true
        self.__fade_in = false
    end
end

function Sound:fade_in(duration)
    if not self.__fade_in then
        self.__fade_in = true
        self.fade_in_speed = duration or 0.5
        love_set_volume(0)
    end
end

function Sound:add_sfx(path, name, volume)
    if self:get_sfx(name) then return false end
    local audio = Audio:new(path, name, volume, "static")
    audio.source:setLooping(false)
    audio.source:setVolume(audio.volume * volume_sfx)
    return true
end

---@param path string
---@param name string
---@param volume number|any
function Sound:add_song(path, name, volume)
    if self:get_song(name) then return false end
    local audio = Audio:new(path, name, volume, song_mode, true)
    audio.source:setLooping(true)
    audio.source:setVolume(audio.volume * volume_song)
    return true
end

function Sound:remove_sfx(name)
    ---@type JM.Sound.Audio
    local audio = list_sfx[name]
    if not audio then return end

    audio.source:stop()
    audio.source:release()
    list_sfx[name] = nil
    return true
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

    if audio == current_song then
        current_song = nil
    end

    audio.source:stop()
    audio.source:release()
    list_song[name] = nil
end

function Sound:get_current_song()
    return current_song
end

function Sound:play_song(name, reset)
    if Sound.lock__ then return end

    ---@type JM.Sound.Audio|nil
    local audio = list_song[name]
    if not audio then return false end

    if current_song and current_song.name == name and not reset then
        return
    end
    -- stopping all others songs
    for _, audio in pairs(list_song) do
        ---@type JM.Sound.Audio
        audio = audio
        audio.source:stop()
    end

    current_song = audio

    return audio.source:play()
end

function Sound:play_sfx(name, force)
    if Sound.lock__ then return end

    ---@type JM.Sound.Audio|nil
    local audio = list_sfx[name]
    if not audio then return end

    if not audio.source:isPlaying() then
        audio.source:play()
    end

    if force then
        audio.source:stop()
        audio.source:play()
    end
    return audio.source
end

function Sound:stop_sfx(name)
    ---@type JM.Sound.Audio|nil
    local audio = list_sfx[name]
    if not audio then return end

    return audio.source:stop()
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

local paused_sfx
local paused_song

function Sound:focus(f)
    if not f then
        paused_sfx = paused_sfx or {}
        paused_song = paused_song or {}


        for _, audio in next, list_sfx do
            ---@type JM.Sound.Audio
            audio = audio

            local source = audio.source
            if source:isPlaying() then
                source:pause()
                paused_sfx[audio.name] = true
            end
        end

        for _, audio in next, list_song do
            ---@type JM.Sound.Audio
            audio = audio

            local source = audio.source
            if source:isPlaying() then
                source:pause()
                paused_song[audio.name] = true
            end
        end
        ---
    else
        if paused_song then
            for name, _ in next, paused_song do
                local audio = self:get_song(name)
                if audio then
                    audio.source:play()
                end
            end
        end

        if paused_sfx then
            for name, _ in next, paused_sfx do
                local audio = self:get_sfx(name)
                if audio then audio.source:play() end
            end
        end
        -- self:play_song("HowToPlay", true)
        paused_song = nil
        paused_sfx = nil
    end
end

---@param value  "stream"|"static"
function Sound:set_song_mode(value)
    song_mode = value
end

return Sound
