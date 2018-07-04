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
    extern vec4 tint;
    extern number strength;
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _) {
      color = Texel(texture, tc);
      number luma = dot(vec3(0.299, 0.587, 0.114), color.rgb);
      return mix(color, tint * luma, strength);
    }]]

  local setters = {}

  setters.tint = function(c)
    assert(type(c) == "table" and #c == 3, "Invalid value for `tint'")
    shader:send("tint", {
      (tonumber(c[1]) or 0) / 255,
      (tonumber(c[2]) or 0) / 255,
      (tonumber(c[3]) or 0) / 255,
      1
    })
  end

  setters.strength = function(v)
    shader:send("strength", math.max(0, math.min(1, tonumber(v) or 0)))
  end

  local defaults = {tint = {255,255,255}, strength = 0.5}

  return moonshine.Effect{
    name = "desaturate",
    shader = shader,
    setters = setters,
    defaults = defaults
  }
end
