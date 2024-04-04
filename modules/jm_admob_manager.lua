local admob = false
do
    local sucess, r = pcall(function(...)
        return require "admob"
    end)
    admob = sucess and r or admob
end

---@enum JM.AdmobManager.CallbackType
local CallbackType = {
    interstitialFailedToLoad = 1,
    interstitialClosed = 2,
    rewardedAdFailedToLoad = 3,
    rewardUserWithReward = 4,
    rewardedAdDidStop = 5,
}

---@alias JM.AdmobManager.Callbacks "interstitialFailedToLoad"|"interstitialClosed"|"rewardedAdFailedToLoad"|"rewardUserWithReward"|"rewardedAdDidStop"

---@class JM.AdmobManager
local Ad = {}

local time = 0.0
local id_banner_test = "ca-app-pub-3940256099942544/6300978111"
local id_inter_test = "ca-app-pub-3940256099942544/1033173712"
local id_reward_test = "ca-app-pub-3940256099942544/5224354917"

local id_banner, id_inter, id_reward

---@type table|nil
local callbacks

---@type table|nil
local callbacks_args

---@param type JM.AdmobManager.CallbackType
local function dispatch_callback(type, ...)
    if not callbacks then return false end

    local func = callbacks[type]

    if func then
        local args = (...) and { ... }

        if args then
            local temp = callbacks_args and callbacks_args[type]

            if temp then
                func(temp, unpack(args))
            else
                func(unpack(args))
            end
        else
            func(callbacks_args and callbacks_args[type])
        end

        return true
    end

    return false
end

---@overload fun(self:any, args:{banner:string, inter:string, reward:string})
---@param banner any
---@param inter any
---@param reward any
function Ad:setIds(banner, inter, reward)
    if type(banner) == "table" then
        return self:setIds(banner.banner, banner.inter, banner.reward)
    end
    id_banner = banner
    id_inter = inter
    id_reward = reward
end

---@param type JM.AdmobManager.Callbacks
---@param func function
function Ad:setCallback(type, func, args)
    local temp = CallbackType[type]
    if not temp then return false end

    callbacks = callbacks or {}
    callbacks_args = callbacks_args or {}

    callbacks[temp] = func
    callbacks_args[temp] = args
end

function Ad:clearCallbacks()
    if callbacks then
        for k, v in next, callbacks do
            callbacks[k] = nil
        end
    end

    if callbacks_args then
        for k, v in next, callbacks_args do
            callbacks_args[k] = nil
        end
    end
end

if admob then
    ---

    function Ad:changeEUConsent()
        return admob.changeEUConsent()
    end

    function Ad:checkForAdsCallbacks()
        if admob.coreInterstitialError() then
            -- local r = admob.interstitialFailedToLoad
            -- if r then r() end
            dispatch_callback(CallbackType.interstitialFailedToLoad)
        end

        if admob.coreInterstitialClosed() then
            -- local r = admob.interstitialClosed
            -- if r then r() end
            dispatch_callback(CallbackType.interstitialClosed)
        end

        if admob.coreRewardedAdError() then
            -- local r = admob.rewardedAdFailedToLoad
            -- if r then r() end
            dispatch_callback(CallbackType.rewardedAdFailedToLoad)
        end

        if admob.coreRewardedAdDidFinish() then
            local reward_type = "???"
            local reward_quant = 1
            reward_type = admob.coreGetRewardType() or reward_type
            reward_quant = admob.coreGetRewardQuantity() or 1

            -- local r = admob.rewardUserWithReward
            -- if r then r(reward_type, reward_quant) end
            dispatch_callback(CallbackType.rewardUserWithReward, reward_type, reward_quant)
        end

        if admob.coreRewardedAdDidStop() then
            -- local r = admob.rewardedAdDidStop
            -- if r then r() end
            dispatch_callback(CallbackType.rewardedAdDidStop)
        end
    end

    ---@param id string|nil
    ---@param position "bottom"|"top"
    function Ad:createBanner(id, position, show_on_creation)
        admob.createBanner(id or id_banner or id_banner_test, position)

        if show_on_creation then
            return admob.showBanner()
        end
    end

    function Ad:hideBanner()
        return admob.hideBanner()
    end

    function Ad:showBanner()
        return admob.showBanner()
    end

    function Ad:requestInterstitial(id)
        return admob.requestInterstitial(id or id_inter or id_inter_test)
    end

    function Ad:showInterstitial()
        if admob.isInterstitialLoaded() then
            admob.showInterstitial()
            return true
        end
        return false
    end

    function Ad:requestRewardedAd(id)
        return admob.requestRewardedAd(id or id_reward or id_reward_test)
    end

    function Ad:showRewardedAd()
        if admob.isRewardedAdLoaded() then
            admob.showRewardedAd()
            return true
        end
        return false
    end

    ---@return string locale
    function Ad:getDeviceLanguage()
        return admob.getDeviceLanguage()
    end

    function Ad:update(dt)
        if time >= 0.1 then
            self:checkForAdsCallbacks()
            time = 0.0
        end
        time = time + dt
    end

    function Ad:tryShowInterstitial(onSuccess, onCloseAfterSuccess, onFail)
        self:setCallback("interstitialClosed",
            function()
                self:requestInterstitial()
                if onCloseAfterSuccess then onCloseAfterSuccess() end
            end)

        self:setCallback("interstitialFailedToLoad", onFail)
        if self:showInterstitial() then
            if onSuccess then onSuccess() end
        else
            onFail()
        end
    end

    function Ad:tryShowRewardedAd(onSuccess, onCloseAfterSuccess, onFail)
        self:setCallback("rewardedAdDidStop",
            function()
                self:requestRewardedAd()
                if onCloseAfterSuccess then onCloseAfterSuccess() end
            end)

        self:setCallback("rewardedAdFailedToLoad", onFail)

        if self:showRewardedAd() then
            if onSuccess then onSuccess() end
        else
            if onFail then onFail() end
        end
    end

    ---
else
    ---
    local func = function() end
    Ad.changeEUConsent = func
    Ad.createBanner = func
    Ad.hideBanner = func
    Ad.requestInterstitial = func
    Ad.requestRewardedAd = func
    Ad.showBanner = func
    Ad.showInterstitial = func
    Ad.showRewardedAd = func
    Ad.checkForAdsCallbacks = func
    Ad.getDeviceLanguage = function() return "EN" end
    Ad.update = func
end

return Ad
