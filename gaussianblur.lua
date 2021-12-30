--[[
Public domain:

Copyright (C) 2017 by Matthias Richter <vrld@vrld.org>

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
]]--
local function resetShader(sigma)
  local support = math.max(1, math.floor(3*sigma + .5))
  local one_by_sigma_sq = sigma > 0 and 1 / (sigma * sigma) or 1
  local norm = 0

  local code = {[[
    extern vec2 direction;
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
    { vec4 c = vec4(0.0);
  ]]}
  local blur_line = "c += vec4(%f) * Texel(texture, tc + vec2(%f) * direction);"

  for i = -support,support do
    local coeff = math.exp(-.5 * i*i * one_by_sigma_sq)
    norm = norm + coeff
    code[#code+1] = blur_line:format(coeff, i)
  end

  code[#code+1] = ("return c * vec4(%f) * color;}"):format(norm > 0 and 1/norm or 1)

  return love.graphics.newShader(table.concat(code))
end

return function(moonshine)
  local shader

  local setters = {}
  setters.sigma = function(v)
    shader = resetShader(math.max(0,tonumber(v) or 1))
  end

  local draw = function(buffer)
    shader:send('direction', {1 / love.graphics.getWidth(), 0})
    moonshine.draw_shader(buffer, shader)

    shader:send('direction', {0, 1 / love.graphics.getHeight()})
    moonshine.draw_shader(buffer, shader)
  end

  return moonshine.Effect{
    name = "gaussianblur",
    draw = draw,
    setters = setters,
    defaults = {sigma = 1},
  }
end
