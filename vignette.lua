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

return function(shine)
  local shader = love.graphics.newShader[[
    extern number vignette_radius;
    extern number vignette_softness;
    extern number vignette_opacity;
    extern vec4 vignette_color;

    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 _)
    {
      color = Texel(tex, tc);

      number aspect = love_ScreenSize.x / love_ScreenSize.y;
      number v = 1.0 - smoothstep(vignette_radius, vignette_radius-vignette_softness,
                                  length((tc - vec2(0.5f)) * aspect));
      return mix(color, vignette_color, v*vignette_opacity);
    }]]

  local setters = {}
  for _,k in ipairs{"radius", "softness", "opacity"} do
    k = "vignette_"..k
    setters[k] = function(v) shader:send(k, math.max(0, tonumber(v) or 0)) end
  end
  setters.vignette_color = function(c)
    assert(type(c) == "table" and #c == 3, "Invalid value for `vignette_color'")
    shader:send("vignette_color", {
      (tonumber(c[1]) or 0) / 255,
      (tonumber(c[2]) or 0) / 255,
      (tonumber(c[3]) or 0) / 255,
      1
    })
  end

  return shine.Effect{
    shader = shader,
    setters = setters,
    defaults = {
      vignette_radius = .8,
      vignette_softness = .5,
      vignette_opacity = .5,
      vignette_color = {0,0,0}
    }
  }
end
