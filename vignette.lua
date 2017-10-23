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
    extern number radius;
    extern number softness;
    extern number opacity;
    extern vec4 color;

    vec4 effect(vec4 c, Image tex, vec2 tc, vec2 _)
    {
      number aspect = love_ScreenSize.x / love_ScreenSize.y;
      aspect = max(aspect, 1.0 / aspect); // use different aspect when in portrait mode
      number v = 1.0 - smoothstep(radius, radius-softness,
                                  length((tc - vec2(0.5f)) * aspect));
      return mix(Texel(tex, tc), color, v*opacity);
    }]]

  local setters = {}
  for _,k in ipairs{"radius", "softness", "opacity"} do
    setters[k] = function(v) shader:send(k, math.max(0, tonumber(v) or 0)) end
  end
  setters.color = function(c)
    assert(type(c) == "table" and #c == 3, "Invalid value for `color'")
    shader:send("color", {
      (tonumber(c[1]) or 0) / 255,
      (tonumber(c[2]) or 0) / 255,
      (tonumber(c[3]) or 0) / 255,
      1
    })
  end

  return moonshine.Effect{
    name = "vignette",
    shader = shader,
    setters = setters,
    defaults = {
      radius = .8,
      softness = .5,
      opacity = .5,
      color = {0,0,0}
    }
  }
end
