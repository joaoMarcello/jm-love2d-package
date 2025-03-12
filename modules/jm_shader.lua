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

    return love.graphics.newImage(noisetex, { dpiscale = 1 })
end

local shaders = setmetatable({}, { __mode = "v" })

---@param conf table|any
---@param state JM.Scene|nil
---@return love.Shader|any
function M:get_shader(shader, state, conf)
    state = state or JM.SceneManager.scene
    conf = conf or {}
    local lgx = love.graphics
    local lfs = love.filesystem
    local code

    if shader == "vignette" then
        local vignette = shaders[shader]
        if not vignette then
            code = lfs.read("/jm-love2d-package/data/shader/vignette.glsl")
            vignette = lgx.newShader(code)
            shaders[shader] = vignette

            vignette:send("radius", conf.radius or 1.45)
            vignette:send("softness", conf.softness or 1)
            vignette:send("opacity", conf.opacity or 0.4)
            vignette:sendColor("color", conf.color or { 0, 0, 0, 1 })
        end

        return vignette
        ---
    elseif shader == "grayscale" then
        local gray = shaders[shader]
        if not gray then
            code = lfs.read("/jm-love2d-package/data/shader/grayscale.glsl")
            gray = lgx.newShader(code)
            shaders[shader] = gray
        end

        return gray
    elseif shader == "crt" then
        local crt = shaders[shader]
        if not crt then
            code = lfs.read("/jm-love2d-package/data/shader/crt.glsl")
            crt = lgx.newShader(code)
            shaders[shader] = crt

            crt:send("feather", conf.feather or 0.02)
            crt:send("distortionFactor", conf.distortionFactor or { 1.03, 1.04 })
            crt:send("scaleFactor", conf.scaleFactor or { 1, 1 })
        end

        return crt
        ---
    elseif shader == "scanline" then
        local scan = shaders[shader]
        if not scan then
            code = lfs.read("/jm-love2d-package/data/shader/scanline.glsl")
            scan = lgx.newShader(code)
            shaders[shader] = scan

            scan:send("width", conf.width or 1)
            scan:send("phase", conf.phase or 1)
            scan:send("thickness", conf.thickness or 1)
            scan:send("opacity", conf.opacity or 0.15)
            scan:send("color", conf.color or { 0, 0, 0 })
            -- scan:send("screen_h", conf.screen_h or 270)
            scan:send("screen_h", conf.screen_h or
                (state and state.screen_h)
                or lgx.getHeight())
        end

        return scan
        ---
    elseif shader == "filmgrain" then
        local noisetex = conf.noisetex or self:noise_generator(1024, 768)

        local filmgrain = shaders[shader]
        if not filmgrain then
            code = lfs.read("/jm-love2d-package/data/shader/filmgrain.glsl")
            filmgrain = lgx.newShader(code)
            shaders[shader] = filmgrain

            filmgrain:send("opacity", conf.opacity or 0.6)
            filmgrain:send("size", conf.size or 1)
            filmgrain:send("noisetex", noisetex)
            filmgrain:send("tex_ratio", conf.text_ratio or {
                (state and state.screen_w or lgx.getWidth()) / noisetex:getWidth(),
                (state and state.screen_h or lgx.getHeight()) / noisetex:getHeight()
            })
            filmgrain:send("noise", { 0.5, 0.5 })
        end

        return filmgrain
        ---
    elseif shader == "crt_scanline" then
        local crt_scan = shaders[shader]
        if not crt_scan then
            code = lfs.read("/jm-love2d-package/data/shader/crt_scan.glsl")
            crt_scan = lgx.newShader(code)
            shaders[shader] = crt_scan

            crt_scan:send("width", conf.width or 1)
            crt_scan:send("phase", conf.phase or 1)
            crt_scan:send("thickness", conf.thickness or 1)
            crt_scan:send("opacity", conf.opacity or 0.15)
            crt_scan:send("scan_color", conf.scan_color or { 0, 0, 0 })
            -- crt_scan:send("screen_h", conf.screen_h or
            --     (state and 288)
            --     or lgx.getHeight())
            crt_scan:send("screen_h", conf.screen_h or 270)

            crt_scan:send("feather", conf.feather or 0.02)
            crt_scan:send("distortionFactor", conf.distortionFactor
                or { 1.03, 1.04 })
            crt_scan:send("scaleFactor", conf.scaleFactor or { 1, 1 })
        end

        return crt_scan
        ---
    elseif shader == "aberration" then
        local ab = shaders[shader]
        if not ab then
            code = lfs.read("/jm-love2d-package/data/shader/chromatic_aberration.glsl")
            ab = lgx.newShader(code)
            shaders[shader] = ab

            ab:send("aberration_x", conf.aberration_x or 0.5)
            ab:send("aberration_y", conf.aberration_y or 0.25)
            ab:send("screen_width", conf.width or (state and state.screen_w)
                or lgx.getWidth())
            ab:send("screen_height", conf.height or (state and state.screen_h)
                or lgx.getHeight())
        end

        return ab
        ---
    elseif shader == "boxblur" then
        local boxblur = shaders[shader]
        if not boxblur then
            code = lfs.read("/jm-love2d-package/data/shader/boxblur.glsl")
            boxblur = lgx.newShader(code)
            shaders[shader] = boxblur

            local radius_x = conf.radius or 3
            local direction = { 1.0 / (conf.width or (state and state.screen_w)
                or lgx.getWidth()), 0.0 }

            boxblur:send('direction', direction)
            boxblur:send('radius', math.floor(radius_x + .5))
        end

        return boxblur
        ---
    elseif shader == "chromasep" then
        local chromasep = shaders[shader]
        if not chromasep then
            code = lfs.read("/jm-love2d-package/data/shader/chromasep.glsl")
            chromasep = lgx.newShader(code)
            shaders[shader] = chromasep

            local angle, radius = conf.angle or math.pi, conf.radius or 2.5
            local direction = {}

            direction[1] = (math.cos(angle) * radius)
                / lgx.getWidth()

            direction[2] = (math.sin(angle) * radius)
                / lgx.getHeight()

            shader:send('direction', direction)
            chromasep:send("direction", direction)
        end

        return chromasep
        ---
    elseif shader == "desaturate" then
        local desaturate = shaders[shader]
        if not desaturate then
            code = lfs.read("/jm-love2d-package/data/shader/desaturate.glsl")
            desaturate = lgx.newShader(code)
            shaders[shader] = desaturate

            desaturate:send("tint", conf.tint or { 1, 1, 1, 1 })
            desaturate:send("strength", conf.strength or 0.25)
        end

        return desaturate
        ---
    elseif shader == "dmg" then
        local dmg = shaders[shader]
        if not dmg then
            code = lfs.read("/jm-love2d-package/data/shader/dmg.glsl")
            dmg = lgx.newShader(code)
            shaders[shader] = dmg

            local pallette = conf.palette or {
                { 15 / 255,  56 / 255,  15 / 255 },
                { 48 / 255,  98 / 255,  48 / 255 },
                { 139 / 255, 172 / 255, 15 / 255 },
                { 155 / 255, 188 / 255, 15 / 255 }
            }

            dmg:send('palette', unpack(pallette))
        end

        return dmg
        ---
    elseif shader == "fog" then
        local fog = shaders[shader]
        if not fog then
            code = lfs.read("/jm-love2d-package/data/shader/fog.glsl")
            fog = lgx.newShader(code)
            shaders[shader] = fog

            fog:send('fog_color', conf.color or { 1, 1, 0.95 })
            fog:send('octaves', conf.octaves or 4)
            fog:send('speed', conf.speed or { 0.5, 0.5 })
            fog:send('time', 0)
        end

        return fog
        ---
    elseif shader == "pixelate" then
        local pixelate = shaders[shader]
        if not pixelate then
            code = lfs.read("/jm-love2d-package/data/shader/pixelate.glsl")
            pixelate = lgx.newShader(code)
            shaders[shader] = pixelate

            local size = conf.size or { 1, 1 }
            pixelate:send('size', size)
            pixelate:send('feedback', conf.feedback or 0)
            pixelate:send('screen_size', { conf.width
            or (state and state.screen_w) or lgx.getWidth(),
                conf.height or (state and state.screen_h) or lgx.getHeight()
            })
        end

        return pixelate
        ---
    elseif shader == "posterize" then
        local posterize = shaders[shader]
        if not posterize then
            code = lfs.read("/jm-love2d-package/data/shader/posterize.glsl")
            posterize = lgx.newShader(code)
            shaders[shader] = posterize

            posterize:send('num_bands', conf.band or 3)
        end

        return posterize
        ---
    elseif shader == "water" then
        local water = shaders[shader]
        if not water then
            code = lfs.read("/jm-love2d-package/data/shader/water.glsl")
            water = lgx.newShader(code)
            shaders[shader] = water

            -- local noise_water = conf.noise or self:noise_generator(64, 64, 42)
            local noise_water = lgx.newImage("/jm-love2d-package/data/img/3-simplex-noise-64.png")
            water:send("simplex", noise_water)

            water:send("canvas_width", conf.width
                or (state and (state.screen_w * state.subpixel))
                or lgx.getWidth())
            water:send("time", 0.0)
        end

        return water
        ---
    elseif shader == "mix" or shader == "crt_scan_vignette" then
        local mix = shaders["mix"] or shaders["crt_scan_vignette"]
        if not mix then
            code = lfs.read("/jm-love2d-package/data/shader/crt_scan_vignette.glsl")
            mix = lgx.newShader(code)
            shaders["mix"] = mix
            shaders["crt_scan_vignette"] = mix

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
        end

        return mix
        ---
    elseif shader == "mask" then
        local m = shaders[shader]
        if not m then
            code = lfs.read("/jm-love2d-package/data/shader/mask.glsl")
            m = lgx.newShader(code)
            shaders[shader] = m
        end
        return m
        ---
    elseif shader == "pico8" then
        --[[
            // uniform vec3 palette[] = vec3[](
            // vec3(0.0, 0.0, 0.0),
            // vec3(29.0/255.0, 43.0/255.0, 83.0/255.0),
            // vec3(126.0/255.0, 37.0/255.0, 83.0/255.0),
            // vec3(0.0, 135.0/255.0, 81.0/255.0),
            // vec3(171.0/255.0, 82.0/255.0, 54.0/255.0),
            // vec3(95.0/255.0, 87.0/255.0, 79.0/255.0),
            // vec3(194.0/255.0, 195.0/255.0, 199.0/255.0),
            // vec3(1.0, 241.0/255.0, 232.0/255.0),
            // vec3(1.0, 0.0, 77.0/255.0),
            // vec3(1.0, 163.0/255.0, 0.0),
            // vec3(1.0, 236.0/255.0, 39.0/255.0),
            // vec3(0.0, 228.0/255.0, 54.0/255.0),
            // vec3(41.0/255.0, 173.0/255.0, 1.0),
            // vec3(131.0/255.0, 118.0/255.0, 156.0/255.0),
            // vec3(1.0, 119.0/255.0, 168.0/255.0),
            // vec3(1.0, 204.0/255.0, 170.0/255.0));
        ]]
        local pico8 = shaders[shader]
        if not pico8 then
            code = lfs.read("/jm-love2d-package/data/shader/pico8_copilot.glsl")
            pico8 = lgx.newShader(code)
            shaders[shader] = pico8

            local palette = {
                { 0.0,           0.0,           0.0 },
                { 29.0 / 255.0,  43.0 / 255.0,  83.0 / 255.0 },
                { 126.0 / 255.0, 37.0 / 255.0,  83.0 / 255.0 },
                { 0.0,           135.0 / 255.0, 81.0 / 255.0 },
                { 171.0 / 255.0, 82.0 / 255.0,  54.0 / 255.0 },
                { 95.0 / 255.0,  87.0 / 255.0,  79.0 / 255.0 },
                { 194.0 / 255.0, 195.0 / 255.0, 199.0 / 255.0 },
                { 255.0 / 255.0, 241.0 / 255.0, 232.0 / 255.0 },
                { 255.0 / 255.0, 0.0,           77.0 / 255.0 },
                { 255.0 / 255.0, 163.0 / 255.0, 0.0 },
                { 255.0 / 255.0, 236.0 / 255.0, 39.0 / 255.0 },
                { 0.0,           228.0 / 255.0, 54.0 / 255.0 },
                { 41.0 / 255.0,  173.0 / 255.0, 255.0 / 255.0 },
                { 131.0 / 255.0, 118.0 / 255.0, 156.0 / 255.0 },
                { 255.0 / 255.0, 119.0 / 255.0, 168.0 / 255.0 },
                { 255.0 / 255.0, 204.0 / 255.0, 170.0 / 255.0 },
            }
            pico8:send("size", 16)
            pico8:send("palette", unpack(palette))
            pico8:send("weights_dark", { 2.0, 4.0, 3.0 })
            pico8:send("weights_light", { 3.0, 4.0, 2.0 })
            pico8:send("threshold", 128 / 255)
        end
        return pico8
    elseif shader == "godsray" then
        local god = shaders[shader]
        if not god then
            code = lfs.read("/jm-love2d-package/data/shader/godsray.glsl")
            god = lgx.newShader(code)
            shaders[shader] = god

            god:send("exposure", 0.25)
            god:send("decay", 0.95)
            god:send("density", 0.15)
            god:send("weight", 0.5)
            god:send("light_position", { 0.5, 0.5 })
            god:send("samples", 70)
        end
        return god
        ---
    elseif shader == "phosphor" then
        local ph = shaders[shader]
        if not ph then
            code = lfs.read("/jm-love2d-package/data/shader/phosphor.frag")
            ph = lgx.newShader(code)
            shaders[shader] = ph

            ph:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })
        end
        return ph
        ---
    elseif shader == "hq4x" then
        local hq = shaders[shader]
        if not hq then
            code = lfs.read("/jm-love2d-package/data/shader/hq4x.frag")
            hq = lgx.newShader(code)
            shaders[shader] = hq

            hq:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })
        end
        return hq
        ---
    elseif shader == "hq2x" then
        local hq = shaders[shader]
        if not hq then
            code = lfs.read("/jm-love2d-package/data/shader/hq2x.frag")
            hq = lgx.newShader(code)
            shaders[shader] = hq

            hq:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })
        end
        return hq
        ---
    elseif string.lower(shader) == "hdr-tv" then
        shader = string.lower(shader)
        local hd = shaders[shader]
        if not hd then
            code = lfs.read("/jm-love2d-package/data/shader/HDR-TV.frag")
            hd = lgx.newShader(code)
            shaders[shader] = hd
        end
        return hd
        ---
    elseif shader == "dotnbloom" or shader == "dotbloom" then
        local dot = shaders["dotnbloom"] or shaders["dotbloom"]
        if not dot then
            code = lfs.read("/jm-love2d-package/data/shader/dotnbloom.frag")
            dot = lgx.newShader(code)
            shaders["dotnbloom"] = dot
            shaders["dotbloom"] = dot

            dot:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })
        end
        return dot
        ---
    elseif shader == "curvature" then
        local curv = shaders[shader]
        if not curv then
            code = lfs.read("/jm-love2d-package/data/shader/curvature.frag")
            curv = lgx.newShader(code)
            shaders[shader] = curv

            curv:send("inputSize", {
                (conf.inputSize and conf.inputSize[1])
                or (state and state.screen_w)
                or lgx.getWidth(),

                (conf.inputSize and conf.inputSize[2])
                or (state and state.screen_h)
                or lgx.getHeight()
            })

            curv:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })
        end
        return curv
        ---
    elseif shader == "phosporish" then
        local ph = shaders[shader]
        if not ph then
            code = lfs.read("/jm-love2d-package/data/shader/phosphorish.frag")
            ph = lgx.newShader(code)
            shaders[shader] = ph

            ph:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })
        end
        return ph
        ---
    elseif shader == "blknwht" or shader == "blkwht" or shader == "black_white"
        or shader == "blackwhite"
    then
        local blk = shaders["blknwht"] or shaders["blkwht"] or shaders["black_white"] or shaders["blackwhite"]
        if not blk then
            code = lfs.read("/jm-love2d-package/data/shader/blcknwht.frag")
            blk = lgx.newShader(code)
            shaders["blknwht"] = blk
            shaders["blkwht"] = blk
            shaders["black_white"] = blk
            shaders["blackwhite"] = blk

            blk:send("brightness", 0.75)
        end
        return blk
        ---
    elseif shader == "scanline-4x" then
        local scan = shaders[shader]
        if not scan then
            code = lfs.read("/jm-love2d-package/data/shader/scanline-4x.frag")
            scan = lgx.newShader(code)
            shaders[shader] = scan
        end
        return scan
        ---
    elseif shader == "scanline-3x" then
        local scan = shaders[shader]
        if not scan then
            code = lfs.read("/jm-love2d-package/data/shader/scanline-3x.frag")
            scan = lgx.newShader(code)
            shaders[shader] = scan
        end
        return scan
        ---
    elseif shader == "scanline2" then
        local scan = shaders[shader]
        if not scan then
            code = lfs.read("/jm-love2d-package/data/shader/scanlines2.frag")
            scan = lgx.newShader(code)
            shaders[shader] = scan

            scan:send("inputSize", {
                (conf.inputSize and conf.inputSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.inputSize and conf.inputSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })

            scan:send("outputSize", {
                (conf.outputSize and conf.outputSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.outputSize and conf.outputSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })

            scan:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })
        end
        return scan
        ---
    elseif shader == "pixellate" then
        local pix = shaders[shader]
        if not pix then
            code = lfs.read("/jm-love2d-package/data/shader/pixellate.frag")
            pix = lgx.newShader(code)
            shaders[shader] = pix

            pix:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })
        end
        return pix
        ---
    elseif shader == "pixellate2" then
        local pix = shaders[shader]
        if not pix then
            code = lfs.read("/jm-love2d-package/data/shader/pixellate2.frag")
            pix = lgx.newShader(code)
            shaders[shader] = pix

            pix:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })
        end
        return pix
        ---
    elseif shader == "radialblur" then
        local rad = shaders[shader]
        if not rad then
            code = lfs.read("/jm-love2d-package/data/shader/radialblur.frag")
            rad = lgx.newShader(code)
            shaders[shader] = rad
        end
        return rad
        ---
    elseif shader == "simplebloom" then
        local bloom = shaders[shader]
        if not bloom then
            code = lfs.read("/jm-love2d-package/data/shader/simplebloom.frag")
            bloom = lgx.newShader(code)
            shaders[shader] = bloom

            bloom:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })
        end
        return bloom
        ---
    elseif shader == "technicolor1" then
        local tech = shaders[shader]
        if not tech then
            code = lfs.read("/jm-love2d-package/data/shader/technicolor1.frag")
            tech = lgx.newShader(code)
            shaders[shader] = tech
        end
        return tech
        ---
    elseif shader == "technicolor2" then
        local tech = shaders[shader]
        if not tech then
            code = lfs.read("/jm-love2d-package/data/shader/technicolor2.frag")
            tech = lgx.newShader(code)
            shaders[shader] = tech
        end
        return tech
        ---
    elseif shader == "pip" then
        local pip = shaders[shader]
        if not pip then
            code = lfs.read("/jm-love2d-package/data/shader/pip.frag")
            pip = lgx.newShader(code)
            shaders[shader] = pip

            pip:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })

            pip:send("outputSize", {
                (conf.outputSize and conf.outputSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.outputSize and conf.outputSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })

            pip:send("time", 0.0)
        end
        return pip
        ---
    elseif shader:lower() == "4xbr" then
        shader = string.lower(shader)
        local br = shaders[shader]
        if not br then
            code = lfs.read("/jm-love2d-package/data/shader/4xBR.frag")
            br = lgx.newShader(code)
            shaders[shader] = br

            br:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })
        end
        return br
        ---
    elseif shader == "waterpaint" then
        local water = shaders[shader]
        if not water then
            code = lfs.read("/jm-love2d-package/data/shader/waterpaint.frag")
            water = lgx.newShader(code)
            shaders[shader] = water

            water:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })
        end
        return water
        ---
    elseif shader:lower() == "crt-simple" then
        shader = string.lower(shader)
        local crt = shaders[shader]
        if not crt then
            code = lfs.read("/jm-love2d-package/data/shader/CRT-Simple.frag")
            crt = lgx.newShader(code)
            shaders[shader] = crt

            crt:send("inputSize", {
                (conf.inputSize and conf.inputSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.inputSize and conf.inputSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })

            crt:send("outputSize", {
                (conf.outputSize and conf.outputSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.outputSize and conf.outputSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })

            crt:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })
        end
        return crt
        ---
    elseif shader == "heavybloom" then
        local bloom = shaders[shader]
        if not bloom then
            code = lfs.read("/jm-love2d-package/data/shader/heavybloom.frag")
            bloom = lgx.newShader(code)
            shaders[shader] = bloom

            bloom:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })
        end
        return bloom
        ---
    elseif shader == "scanline3" then
        local scan = shaders[shader]
        if not scan then
            code = lfs.read("/jm-love2d-package/data/shader/scanline3.frag")
            scan = lgx.newShader(code)
            shaders[shader] = scan

            scan:send("inputSize", {
                (conf.inputSize and conf.inputSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.inputSize and conf.inputSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })

            scan:send("outputSize", {
                (conf.outputSize and conf.outputSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.outputSize and conf.outputSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })

            scan:send("textureSize", {
                (conf.textureSize and conf.textureSize[1])
                or (state and state.screen_w) or lgx.getWidth(),

                (conf.textureSize and conf.textureSize[2]) or
                (state and state.screen_h) or lgx.getHeight(),
            })
        end
        return scan
        ---
    elseif shader == "glitch_1" then
        local gl = shaders[shader]
        if not gl then
            code = lfs.read("/jm-love2d-package/data/shader/glitch_transform_tdhooper.glsl")
            gl = lgx.newShader(code)
            shaders[shader] = gl

            gl:send("iTime", 0.0)
            gl:send("glitchScale", conf.glitchScale or 0.25)
            gl:send("glitchSwapSpeed", conf.glitchSwapSpeed or 30)
            gl:send("glitchSeedProb", conf.glitchSeedProb or 0.75)
        end
        return gl
        ---
    elseif shader == "glitch_2" then
        local gl = shaders[shader]
        if not gl then
            code = lfs.read("/jm-love2d-package/data/shader/glitch_shampain.glsl")
            gl = lgx.newShader(code)
            shaders[shader] = gl
            gl:send("glitch", 0.1)
        end
        return gl
        ---
    elseif shader == "glitch_3" then
        local gl = shaders[shader]
        if not gl then
            code = lfs.read("/jm-love2d-package/data/shader/glitch_3.glsl")
            gl = lgx.newShader(code)
            shaders[shader] = gl
        end
        return gl
        ---
    elseif shader == "wiggle" then
        local wig = shaders[shader]
        if not wig then
            code = lfs.read("/jm-love2d-package/data/shader/wiggle.glsl")
            wig = lgx.newShader(code)
            shaders[shader] = wig

            local noise = lgx.newImage("/jm-love2d-package/data/img/blue_noise.png")

            wig:send("NOISE_TEXTURE", noise)
        end
        return wig
        ---
    elseif shader == "outline" then
        local out = shaders[shader]
        if not out then
            code = lfs.read("/jm-love2d-package/data/shader/outline.glsl")
            out = lgx.newShader(code)
            shaders[shader] = out
        end
        return out
        ---
    elseif shader == "water2" then
        local water = shaders[shader]
        if not water then
            code = lfs.read("/jm-love2d-package/data/shader/water2.glsl")
            water = lgx.newShader(code)
            shaders[shader] = water
        end
        return water
        ---
    elseif shader == "shockwave_1" then
        local shock = shaders[shader]
        if not shock then
            code = lfs.read("/jm-love2d-package/data/shader/shockwave_1.glsl")
            shock = lgx.newShader(code)
            shaders[shader] = shock
        end
        return shock
        ---
    elseif shader == "shockwave_2" then
        local shock = shaders[shader]
        if not shock then
            code = lfs.read("/jm-love2d-package/data/shader/shockwave_2.glsl")
            shock = lgx.newShader(code)
            shaders[shader] = shock

            shock:send("iResolution",
                conf.iResolution or (state
                    and { state.screen_w, state.screen_h }
                    or { lgx:getDimensions() }))

            shock:send("iTime", 0.0)
            shock:send("duration", conf.duration or 0.4)
            shock:send("center", conf.center or { 0.5, 0.5 })
            local dpi = love.window.getDPIScale()
            dpi = dpi <= 0 and 1 or dpi
            shock:send("scaling", conf.scaling or dpi)
        end
        return shock
        ---
    elseif shader == "water_gbc" then
        local water = shaders[shader]
        if not water then
            code = lfs.read("/jm-love2d-package/data/shader/wave_gbc.glsl")
            water = lgx.newShader(code)
            shaders[shader] = water

            local w = conf.width or (state and state.screen_w)
                or lgx.getWidth()
            local h = conf.height or (state and state.screen_h)
                or lgx.getHeight()
            water:send("scaling", { 1.0 / w, 1.0 / h })
        end
        return water
        ---
    elseif shader == "water3" then
        local water = shaders[shader]
        if not water then
            code = lfs.read("/jm-love2d-package/data/shader/my_water.glsl")
            water = lgx.newShader(code)
            shaders[shader] = water

            local noise = lgx.newImage("/jm-love2d-package/data/img/3-simplex-noise-64.png")
            water:send("NOISE", noise)
        end
        return water
    elseif shader == "fastgaussianblur" then
        local blur = shaders[shader]
        if not blur then
            local function build_shader(taps, offset, offset_type, sigma)
                taps = math.floor(taps)
                sigma = sigma >= 1 and sigma or (taps - 1) * offset / 6
                sigma = math.max(sigma, 1)

                local steps = (taps + 1) / 2

                -- Calculate gaussian function.
                local g_offsets = {}
                local g_weights = {}
                for i = 1, steps, 1 do
                    g_offsets[i] = offset * (i - 1)

                    -- We don't need to include the constant part of the gaussian function as we normalize later.
                    -- 1 / math.sqrt(2 * sigma ^ math.pi) * math.exp(-0.5 * ((offset - 0) / sigma) ^ 2 )
                    g_weights[i] = math.exp(-0.5 * (g_offsets[i] - 0) ^ 2 * 1 / sigma ^ 2)
                end

                -- Calculate offsets and weights for sub-pixel samples.
                local offsets = {}
                local weights = {}
                for i = #g_weights, 2, -2 do
                    local oA, oB = g_offsets[i], g_offsets[i - 1]
                    local wA, wB = g_weights[i], g_weights[i - 1]
                    wB = oB == 0 and wB / 2 or wB -- On center tap the middle is getting sampled twice so half weight.
                    local weight = wA + wB
                    offsets[#offsets + 1] = offset_type == 'center' and (oA + oB) / 2 or (oA * wA + oB * wB) / weight
                    weights[#weights + 1] = weight
                end

                local code = { [[
                  uniform vec2 direction;
                  vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {]] }

                local norm = 0
                if #g_weights % 2 == 0 then
                    code[#code + 1] = 'vec4 c = vec4( 0.0 );'
                else
                    local weight = g_weights[1]
                    norm = norm + weight
                    code[#code + 1] = ('vec4 c = %f * Texel(tex, tc);'):format(weight)
                end

                local tmpl = 'c += %f * ( Texel(tex, tc + %f * direction)+ Texel(tex, tc - %f * direction));\n'
                for i = 1, #offsets, 1 do
                    local offset = offsets[i]
                    local weight = weights[i]
                    norm = norm + weight * 2
                    code[#code + 1] = tmpl:format(weight, offset, offset)
                end
                code[#code + 1] = ('return c * vec4(%f) * color; }'):format(1 / norm)

                local shader = table.concat(code)
                return love.graphics.newShader(shader)
            end
            blur = build_shader(conf.taps or 8, conf.offset or 1, conf.offset_type or 'weighted', conf.sigma or -1)
            shaders[shader] = blur
        end
        return blur
    end
end

function M:get_exclusive_shader(shader, state, conf)
    local temp = shaders[shader]
    shaders[shader] = nil
    local ex_shader = self:get_shader(shader, state, conf)
    shaders[shader] = temp
    return ex_shader
end

function M:finish()
    for id, shader in next, shaders do
        ---@type love.Shader
        local shader = shader

        shader:release()
        shaders[id] = nil
    end
end

return M
