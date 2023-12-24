local dir = ...

---@class JM.ShaderManager
local M = {}

---@param w number|any
---@param h number|any
---@return love.Image
function M:noise_generator(w, h, seed)
    w = w or 1024
    h = h or 768

    ---@type love.ImageData
    local noisetex = love.image.newImageData(w, h)

    if seed then
        math.randomseed(seed)
    end
    noisetex:mapPixel(function()
        local l = math.random() * 255
        return l, l, l, l
    end)

    if seed then
        math.randomseed(os.time())
    end

    return love.graphics.newImage(noisetex)
end

local shaders = setmetatable({}, { __mode = "v" })

---@param conf table
---@param state JM.Scene|nil
---@return love.Shader|any
function M:get_shader(shader, conf, state)
    local lgx = love.graphics
    local lfs = love.filesystem
    local code

    if shader == "vignette" then
        local vignette = shaders[shader]
        if not vignette then
            code = lfs.read("/jm-love2d-package/data/shader/vignette.glsl")
            vignette = lgx.newShader(code)
            shaders[shader] = vignette
        end

        vignette:send("radius", conf.radius or 1.45)
        vignette:send("softness", conf.softness or 1)
        vignette:send("opacity", conf.opacity or 0.4)
        vignette:sendColor("color", conf.color or { 0, 0, 0, 1 })
        return vignette
        ---
    elseif shader == "crt" then
        local crt = shaders[shader]
        if not crt then
            code = lfs.read("/jm-love2d-package/data/shader/crt.glsl")
            crt = lgx.newShader(code)
            shaders[shader] = crt
        end

        crt:send("feather", conf.feather or 0.02)
        crt:send("distortionFactor", conf.distortionFactor or { 1.04, 1.04 })
        crt:send("scaleFactor", conf.scaleFactor or { 1, 1 })
        return crt
        ---
    elseif shader == "scanline" then
        local scan = shaders[shader]
        if not scan then
            code = lfs.read("/jm-love2d-package/data/shader/scanline.glsl")
            scan = lgx.newShader(code)
            shaders[shader] = scan
        end

        scan:send("width", conf.width or 2)
        scan:send("phase", conf.phase or 1)
        scan:send("thickness", conf.thickness or 0.5)
        scan:send("opacity", conf.opacity or 0.3)
        scan:send("color", conf.color or { 0.3, 0.3, 0.3 })
        scan:send("screen_h", conf.screen_h or 768)
        return scan
        ---
    elseif shader == "filmgrain" then
        local noisetex = conf.noisetex or self:noise_generator(1024, 768)

        local filmgrain = shaders[shader]
        if not filmgrain then
            code = lfs.read("/jm-love2d-package/data/shader/filmgrain.glsl")
            filmgrain = lgx.newShader(code)
            shaders[shader] = filmgrain
        end

        filmgrain:send("opacity", conf.opacity or 0.6)
        filmgrain:send("size", conf.size or 1)
        filmgrain:send("noisetex", noisetex)
        filmgrain:send("tex_ratio", conf.text_ratio or {
            (state and state.screen_w or lgx.getWidth()) / noisetex:getWidth(),
            (state and state.screen_h or lgx.getHeight()) / noisetex:getHeight()
        })
        filmgrain:send("noise", { 0.5, 0.5 })
        return filmgrain
        ---
    elseif shader == "crt_scanline" then
        local crt_scan = shaders[shader]
        if not crt_scan then
            code = lfs.read("/jm-love2d-package/data/shader/crt_scan.glsl")
            crt_scan = lgx.newShader(code)
            shaders[shader] = crt_scan
        end

        crt_scan:send("width", conf.width or 2)
        crt_scan:send("phase", conf.phase or 1)
        crt_scan:send("thickness", conf.thickness or 1)
        crt_scan:send("opacity", conf.opacity or 0.3)
        crt_scan:send("color_ex", conf.color_ex or { 0, 0, 0 })
        crt_scan:send("screen_h", conf.screen_h or (224 * 3.5))

        crt_scan:send("feather", conf.feather or 0.02)
        crt_scan:send("distortionFactor", conf.distortionFactor
            or { 1.03, 1.04 })
        crt_scan:send("scaleFactor", conf.scaleFactor or { 1, 1 })
        return crt_scan
        ---
    elseif shader == "aberration" then
        local ab = shaders[shader]
        if not ab then
            code = lfs.read("/jm-love2d-package/data/shader/chromatic_aberration.glsl")
            ab = lgx.newShader(code)
            shaders[shader] = ab
        end

        ab:send("aberration_x", conf.aberration_x or 0.5)
        ab:send("aberration_y", conf.aberration_y or 0.25)
        ab:send("screen_width", conf.width or (state and state.screen_w)
            or lgx.getWidth())
        ab:send("screen_height", conf.height or (state and state.screen_h)
            or lgx.getHeight())
        return ab
        ---
    elseif shader == "boxblur" then
        local boxblur = shaders[shader]
        if not boxblur then
            code = lfs.read("/jm-love2d-package/data/shader/boxblur.glsl")
            boxblur = lgx.newShader(code)
            shaders[shader] = boxblur
        end

        local radius_x = conf.radius or 3
        local direction = { 1.0 / (conf.width or (state and state.screen_w)
            or lgx.getWidth()), 0 }

        boxblur:send('direction', direction)
        boxblur:send('radius', math.floor(radius_x + .5))
        return boxblur
        ---
    elseif shader == "chromasep" then
        local chromasep = shaders[shader]
        if not chromasep then
            code = lfs.read("/jm-love2d-package/data/shader/chromasep.glsl")
            chromasep = lgx.newShader(code)
            shaders[shader] = chromasep
        end

        local angle, radius = conf.angle or math.pi, conf.radius or 2.5
        local direction = {}

        direction[1] = (math.cos(angle) * radius)
            / lgx.getWidth()

        direction[2] = (math.sin(angle) * radius)
            / lgx.getHeight()

        shader:send('direction', direction)
        chromasep:send("direction", direction)
        return chromasep
        ---
    elseif shader == "desaturate" then
        local desaturate = shaders[shader]
        if not desaturate then
            code = lfs.read("/jm-love2d-package/data/shader/desaturate.glsl")
            desaturate = lgx.newShader(code)
            shaders[shader] = desaturate
        end

        desaturate:send("tint", conf.tint or { 1, 1, 1, 1 })
        desaturate:send("strength", conf.strength or 0.25)
        return desaturate
        ---
    elseif shader == "dmg" or "palette" then
        local dmg = shaders["dmg"] or shaders["palette"]
        if not dmg then
            code = lfs.read("/jm-love2d-package/data/shader/dmg.glsl")
            dmg = lgx.newShader(code)
            shaders["dmg"] = dmg
            shaders["palette"] = dmg
        end

        local pallette = conf.palette or {
            { 33 / 255,  32 / 255,  16 / 255 },
            { 107 / 255, 105 / 255, 49 / 255 },
            { 181 / 255, 174 / 255, 74 / 255 },
            { 255 / 255, 247 / 255, 123 / 255 }
        }

        dmg:send('palette', unpack(pallette))
        return dmg
        ---
    elseif shader == "fog" then
        local fog = shaders[shader]
        if not fog then
            code = lfs.read("/jm-love2d-package/data/shader/fog.glsl")
            fog = lgx.newShader(code)
            shaders[shader] = fog
        end

        fog:send('fog_color', conf.color or { 1, 1, 0.95 })
        fog:send('octaves', conf.octaves or 4)
        fog:send('speed', conf.speed or { 0.5, 0.5 })
        fog:send('time', 0)
        return fog
        ---
    elseif shader == "pixelate" then
        local pixelate = shaders[shader]
        if not pixelate then
            code = lfs.read("/jm-love2d-package/data/shader/pixelate.glsl")
            pixelate = lgx.newShader(code)
            shaders[shader] = pixelate
        end

        local size = conf.size or { 1, 1 }
        pixelate:send('size', size)
        pixelate:send('feedback', conf.feedback or 0)
        pixelate:send('screen_size', { conf.width
        or (state and state.screen_w) or lgx.getWidth(),
            conf.height or (state and state.screen_h) or lgx.getHeight()
        })
        return pixelate
        ---
    elseif shader == "posterize" then
        local posterize = shaders[shader]
        if not posterize then
            code = lfs.read("/jm-love2d-package/data/shader/posterize.glsl")
            posterize = lgx.newShader(code)
            shaders[shader] = posterize
        end

        posterize:send('num_bands', conf.band or 3)
        return posterize
        ---
    elseif shader == "water" then
        local water = shaders[shader]
        if not water then
            code = lfs.read("/jm-love2d-package/data/shader/water.glsl")
            water = lgx.newShader(code)
            shaders[shader] = water
        end

        local noise_water = conf.noise or self:noise_generator(64, 64, 42)

        water:send("simplex", noise_water)
        water:send("canvas_width", conf.width or (state and state.screen_w)
            or lgx.getWidth())
        water:send("time", 0.0)
        return water
        ---
    elseif shader == "mix" or shader == "crt_scan_vignette" then
        local mix = shaders["mix"] or shaders["crt_scan_vignette"]
        if not mix then
            code = lfs.read("/jm-love2d-package/data/shader/crt_scan_vignette.glsl")
            mix = lgx.newShader(code)
            shaders["mix"] = mix
            shaders["crt_scan_vignette"] = mix
        end

        mix:send("width", conf.width or 0.75)
        mix:send("phase", conf.phase or 1)
        mix:send("thickness", conf.thickness or 1)
        mix:send("opacity", conf.opacity or 0.2)
        mix:send("color_ex", conf.color_ex or { 0, 0, 0 })
        mix:send("screen_h", conf.screen_h or 224)
        --=========================================
        mix:send("feather", conf.feather or 0.03)
        mix:send("distortionFactor", conf.distortionFactor or { 1.03, 1.03 })
        mix:send("scaleFactor", conf.scaleFactor or { 1, 1 })
        --=========================================
        mix:send("vig_radius", conf.radius or 1.45)
        mix:send("vig_softness", conf.softness or 1)
        mix:send("vig_opacity", conf.vig_opacity or 0.5)
        mix:sendColor("vig_color", conf.vig_color or { 0, 0, 0, 1 })
        mix:send("screen_width", conf.screen_width or (state and state.screen_w) or lgx.getWidth())
        mix:send("screen_height", conf.screen_height or (state and state.screen_h) or lgx.getHeight())
        return mix
    end
end

return M
