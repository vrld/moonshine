--[[
Public domain:

Copyright (C) 2017 by Matthias Richter <vrld@vrld.org>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
]]--


-- unroll convolution loop for gaussian blur shader
local function make_blur_shader(sigma)
  local support = math.max(1, math.floor(3*sigma + .5))
  local one_by_sigma_sq = sigma > 0 and 1 / (sigma * sigma) or 1
  local norm = 0

  local code = {[[
    extern vec2 direction;
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _) {
      vec4 c = vec4(0.0);
  ]]}
  local blur_line = "c += vec4(%f) * Texel(texture, tc + vec2(%f) * direction);"

  for i = -support,support do
    local coeff = math.exp(-.5 * i*i * one_by_sigma_sq)
    norm = norm + coeff
    code[#code+1] = blur_line:format(coeff, i)
  end

  code[#code+1] = ("return c * vec4(%f) * color;}"):format(1 / norm)

  return love.graphics.newShader(table.concat(code))
end

return function(moonshine)
  local blurshader -- set in setters.glow_strength
  local threshold = love.graphics.newShader[[
    extern number min_luma;
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _) {
      vec4 c = Texel(texture, tc);
      number luma = dot(vec3(0.299, 0.587, 0.114), c.rgb);
      return c * step(min_luma, luma) * color;
    }]]

  local w = 1280/4
  local h = 720/4
  local scene = love.graphics.newCanvas(w, h)

  local dir = {1/w, 0}
  local strength = 5

  local setters = {}
  setters.strength = function(v)
    blurshader = make_blur_shader(math.max(0,tonumber(v) or 1))
    strength = v
  end
  setters.min_luma = function(v)
    threshold:send("min_luma", math.max(0, math.min(1, tonumber(v) or 0.5)))
  end
  setters.dir = function(v)
      dir[1] = v[1]/w
      dir[2] = v[2]/h
      blurshader:send("direction", {dir[1], dir[2]})
  end
  setters.size = function(v)
      w = v[1]
      h = v[2]
      scene = love.graphics.newCanvas(w, h)
  end

  local draw = function(buffer, shader, tx, ty)
    local front, back = buffer() -- scene so far is in `back'
    scene, back = back, scene    -- save it for second draw below

    -- 1st pass: draw scene with brightness threshold
    love.graphics.setCanvas(front)
    love.graphics.clear()
    love.graphics.setShader(threshold)
    love.graphics.draw(scene)

    -- 2nd pass: apply blur shader in dir
    blurshader:send('direction', dir)
    love.graphics.setCanvas(back)
    love.graphics.clear()
    love.graphics.setShader(blurshader)
    love.graphics.draw(front)

    -- 3nd pass: apply blur shader in y and draw original and blurred scene
    love.graphics.setCanvas(front)
    love.graphics.clear()

    -- original scene without blur shader
    love.graphics.setShader()
    love.graphics.setBlendMode("add", "premultiplied")
    love.graphics.push()
    love.graphics.translate(tx or 0, ty or 0)
    love.graphics.draw(scene) -- original scene

    -- second pass of light blurring
    blurshader:send('direction', {0, 1 / h})
    love.graphics.setShader(blurshader)

    love.graphics.draw(back)
    love.graphics.pop()

    -- restore things as they were before entering draw()
    love.graphics.setBlendMode("alpha", "premultiplied")
    scene = back
  end

  return moonshine.Effect{
    name = "glow",
    draw = draw,
    setters = setters,
    defaults = {
        min_luma=.7,
        strength = 5,
        dir = {1/w, 0},
        size = {w, h},
    }
  }
end
