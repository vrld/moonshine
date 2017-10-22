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

return function(moonshine)
  local radius_x, radius_y = 3, 3
  local shader = love.graphics.newShader[[
    extern vec2 direction;
    extern number radius;
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _) {
      vec4 c = vec4(0.0f);

      for (float i = -radius; i <= radius; i += 1.0f)
      {
        c += Texel(texture, tc + i * direction);
      }
      return c / (2.0f * radius + 1.0f) * color;
    }]]

  local setters = {}
  setters.radius = function(v)
    if type(v) == "number" then
      radius_x, radius_y = v, v
    elseif type(v) == "table" and #v >= 2 then
      radius_x, radius_y = tonumber(v[1] or v.h or v.x), tonumber(v[2] or v.v or v.y)
    else
      error("Invalid argument `radius'")
    end
  end
  setters.radius_x = function(v) radius_x = tonumber(v) end
  setters.radius_y = function(v) radius_y = tonumber(v) end

  local draw = function(buffer)
    shader:send('direction', {1 / love.graphics.getWidth(), 0})
    shader:send('radius', math.floor(radius_x + .5))
    moonshine.draw_shader(buffer, shader)

    shader:send('direction', {0, 1 / love.graphics.getHeight()})
    shader:send('radius', math.floor(radius_y + .5))
    moonshine.draw_shader(buffer, shader)
  end

  return moonshine.Effect{
    name = "boxblur",
    draw = draw,
    setters = setters,
    defaults = {radius = 3}
  }
end
