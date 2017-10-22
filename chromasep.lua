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
  local shader = love.graphics.newShader[[
    extern vec2 direction;
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
    {
      return color * vec4(
        Texel(texture, tc - direction).r,
        Texel(texture, tc).g,
        Texel(texture, tc + direction).b,
        1.0);
    }]]

  local angle, radius = 0, 0
  local setters = {
    angle  = function(v) angle  = tonumber(v) or 0 end,
    radius = function(v) radius = tonumber(v) or 0 end
  }

  local draw = function(buffer, effect)
    local dx = math.cos(angle) * radius / love.graphics.getWidth()
    local dy = math.sin(angle) * radius / love.graphics.getHeight()
    shader:send("direction", {dx,dy})
    moonshine.draw_shader(buffer, shader)
  end

  return moonshine.Effect{
    name = "chromasep",
    draw = draw,
    setters = setters,
    defaults = {angle = 0, radius = 0}
  }
end
