---@type table<integer, JS.Request>
local __requestQueue = {}

local _requestCount = 0

local _INTERVAL = 0.15

_Request =
{
    command = "",
    currentTime = 0,
    timeOut = 2,
    id = '0'
}
local os = love.system.getOS()
local __defaultErrorFunction = function(...) end
local isDebugActive = false

---@type function
local clear_table
do
    local next, rawset = next, rawset

    local sucess, _ = pcall(function()
        require "table.clear"
        return true
    end)

    ---@diagnostic disable-next-line: undefined-field
    if sucess then
        ---@diagnostic disable-next-line: undefined-field
        clear_table = table.clear
    else
        clear_table = function(t)
            for k, _ in next, t do
                rawset(t, k, nil)
            end
        end
    end
end

---@class JM.Foreign.JS
local JS = {}

function JS.callJS(funcToCall)
    if (os == "Web") then
        print("callJavascriptFunction " .. funcToCall)
    end
end

--You can pass a set of commands here and, it is a syntactic sugar for executing many commands inside callJS, as it only calls a function
--If you pass arguments to the func beyond the string, it will perform automatically string.format
--Return statement is possible inside this structure
--This will return a string containing a function to be called by JS.callJS
local _unpack
if (_VERSION == "Lua 5.1" or _VERSION == "LuaJIT") then
    _unpack = unpack
else
    _unpack = table.unpack
end

function JS.stringFunc(str, ...)
    local arg = (...) and { ... }
    str = "(function(){" .. str .. "})()"
    if (arg and #arg > 0) then
        str = str:format(_unpack(arg))
    end
    str = str:gsub("[\n\t]", "")
    return str
end

--The call will store in the webDB the return value from the function passed
--it timeouts
local function retrieveJS(funcToCall, id)
    --Used for retrieveData function
    JS.callJS("FS.writeFile('" .. love.filesystem.getSaveDirectory() .. "/__temp" .. id .. "', " .. funcToCall .. ");")
end

local lfs = love.filesystem

local read_file = function(__id)
    local dir = "__temp" .. __id
    if not lfs.getInfo(dir) then return end
    return lfs.read(dir)
end

local remove_file = function(__id)
    local dir = "__temp" .. __id
    if not lfs.getInfo(dir) then return end
    return lfs.remove(dir)
end

--Call JS.newRequest instead
function _Request:new(isPromise, command, onDataLoaded, onError, timeout, id)
    ---@class JS.Request
    local obj = {}
    setmetatable(obj, self)
    obj.command = command
    obj.onError = onError or __defaultErrorFunction
    if not isPromise then
        retrieveJS(command, id)
    else
        JS.callJS(command)
    end
    obj.onDataLoaded = onDataLoaded or __defaultErrorFunction
    obj.timeOut = timeout or 5
    obj.interval = 0.0
    obj.id = id

    function obj:getData()
        --Try to read from webdb
        -- return love.filesystem.read("__temp" .. self.id)

        local success, result = pcall(read_file, self.id)
        return success and result or nil
    end

    function obj:purgeData()
        --Data must be purged for not allowing old data to be retrieved
        -- love.filesystem.remove("__temp" .. self.id)
        pcall(remove_file, self.id)
    end

    local lim = 1 / 30
    function obj:update(dt)
        dt = dt < lim and dt or lim

        self.timeOut = self.timeOut - dt

        local retData

        self.interval = self.interval + dt
        if self.interval > _INTERVAL then
            self.interval = self.interval - _INTERVAL
            retData = self:getData()
        end


        if ((retData ~= nil and retData ~= "nil") or self.timeOut <= 0) then
            if (retData ~= nil and retData:match("ERROR") == nil) then
                if isDebugActive then
                    print("Data has been retrieved " .. retData)
                end
                self.onDataLoaded(retData)
            else
                self.onError(self.id, retData)
            end
            self:purgeData()
            return false
        else
            return true
        end
    end

    return obj
end

local deadReq = {}

--Place this function on love.update and set it to return if it returns false (This API is synchronous)
function JS.retrieveData(dt)
    local isRetrieving = #__requestQueue ~= 0
    local deadRequests = deadReq
    clear_table(deadRequests)

    for i = 1, #__requestQueue do
        local isUpdating = __requestQueue[i]:update(dt)
        if not isUpdating then
            table.insert(deadRequests, i)
        end
    end
    for i = 1, #deadRequests do
        if (isDebugActive) then
            print("Request died: " .. deadRequests[i])
        end
        local req_index = deadRequests[i]
        -- clear_table(req)
        table.remove(__requestQueue, req_index)
    end
    return isRetrieving
end

function JS.isRetrievingData()
    return (#__requestQueue) ~= 0
end

--May only be used for functions that don't return a promise
function JS.newRequest(funcToCall, onDataLoaded, onError, timeout, optionalId)
    if (os ~= "Web") then
        return
    end
    table.insert(__requestQueue,
        _Request:new(false, funcToCall, onDataLoaded, onError, timeout or 5, optionalId or _requestCount))
    _requestCount = _requestCount + 1
end

--This function can be handled manually (in JS code)
--How to: add the function call when your events resolve: FS.writeFile("Put love.filesystem.getSaveDirectory here", "Pass a string here (NUMBER DONT WORK"))
--Or it can be handled by Lua, it auto sets your data if you write the following command:
-- _$_(yourStringOrFunctionHere)
function JS.newPromiseRequest(funcToCall, onDataLoaded, onError, timeout, optionalId)
    if (os ~= "Web") then
        return
    end

    optionalId = optionalId or _requestCount

    funcToCall = funcToCall:gsub("_$_%(",
        "FS.writeFile('" .. love.filesystem.getSaveDirectory() .. "/__temp" .. optionalId .. "', ")

    table.insert(__requestQueue, _Request:new(true, funcToCall, onDataLoaded, onError, timeout or 5, optionalId))

    _requestCount = _requestCount + 1
end

--It receives the ID from ther request
--Don't try printing the request.command, as it will execute the javascript command
function JS.setDefaultErrorFunction(func)
    __defaultErrorFunction = func
end

JS.setDefaultErrorFunction(function(id, error)
    if (isDebugActive) then
        local msg = "Data could not be loaded for id:'" .. id .. "'"
        if (error) then
            msg = msg .. "\nError: " .. error
        end
        print(msg)
    end
end)
-- JS.callJS(JS.stringFunc(
--     [[
--         __getWebDB("%s");
--     ]]
--     , "__LuaJSDB"))
return JS
