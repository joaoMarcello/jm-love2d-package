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
    timer = {},
    n_timer = 0,
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

function Sound:is_locked()
    return self.lock__
end

function Sound:init()
    self.__fade_in = false
    self.__fade_out = false
    love_set_volume(1)
    -- self:stop_all()
end

function Sound:flush()
    _G.JM_Utils.clear_table(self.timer)
    self.n_timer = 0
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

    if self.n_timer > 0 then
        for k, _ in next, self.timer do
            ---@type JM.Sound.Timed
            k = k
            k.delay = k.delay - dt

            if k.delay <= 0.0 then
                self:play_sfx(k.name, k.force)
                self.timer[k] = nil
                self.n_timer = self.n_timer - 1
            end
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

---@alias JM.Sound.Timed {delay:number, name:string, force:boolean}

function Sound:play_sfx(name, force, delay)
    if Sound.lock__ then return end

    ---@type JM.Sound.Audio|nil
    local audio = list_sfx[name]
    if not audio then return end

    if delay then
        self.timer[{ delay = delay, name = name, force = force }] = true
        self.n_timer = self.n_timer + 1
        return audio.source
    end

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

            if source then
                local ok, is_playing = pcall(source.isPlaying, source)

                if ok and is_playing then
                    if pcall(source.pause, source) then
                        paused_sfx[audio.name] = true
                    end
                end
            end
        end

        for _, audio in next, list_song do
            ---@type JM.Sound.Audio
            audio = audio

            local source = audio.source

            if source then
                local ok, is_playing = pcall(source.isPlaying, source)

                if ok and is_playing then
                    if pcall(source.pause, source) then
                        paused_song[audio.name] = true
                    end
                end
            end
        end
        ---
    else
        if paused_song then
            for name, _ in next, paused_song do
                local audio = self:get_song(name)
                local source = audio and audio.source
                if source then
                    pcall(source.play, source)
                end
            end
        end

        if paused_sfx then
            for name, _ in next, paused_sfx do
                local audio = self:get_sfx(name)
                local source = audio and audio.source
                if source then pcall(source.play, source) end
            end
        end
        paused_song = nil
        paused_sfx = nil
    end
end

---@param value  "stream"|"static"
function Sound:set_song_mode(value)
    song_mode = value
end

return Sound
