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
    extern vec3 factors;
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _) {
      return vec4(factors, 1.0f) * Texel(texture, tc) * color;
    }]]

  local setters = {}

  return moonshine.Effect{
    name = "colorgradesimple",
    shader = shader,
    setters = {factors = function(v) shader:send("factors", v) end},
    defaults = {factors = {1,1,1}}
  }
end
