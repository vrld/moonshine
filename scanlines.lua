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
    extern number width;
    extern number phase;
    extern number thickness;
    extern number opacity;
    extern vec3 color;
    vec4 effect(vec4 c, Image tex, vec2 tc, vec2 _) {
      number v = .5*(sin(tc.y * 3.14159 / width * love_ScreenSize.y + phase) + 1.);
      c = Texel(tex,tc);
      //c.rgb = mix(color, c.rgb, mix(1, pow(v, thickness), opacity));
      c.rgb -= (color - c.rgb) * (pow(v,thickness) - 1.0) * opacity;
      return c;
    }]]


  local defaults = {
    width = 2,
    phase = 0,
    thickness = 1,
    opacity = 1,
    color = {0,0,0},
  }

  local setters = {}
  setters.width = function(v)
    shader:send("width", tonumber(v) or defaults.width)
  end
  setters.frequency = function(v)
    shader:send("width", love.graphics.getHeight()/(tonumber(v) or love.graphics.getHeight()))
  end
  setters.phase = function(v)
    shader:send("phase", tonumber(v) or defaults.phase)
  end
  setters.thickness = function(v)
    shader:send("thickness", math.max(0, tonumber(v) or defaults.thickness))
  end
  setters.opacity = function(v)
    shader:send("opacity", math.min(1, math.max(0, tonumber(v) or defaults.opacity)))
  end
  setters.color = function(c)
    assert(type(c) == "table" and #c == 3, "Invalid value for `color'")
    shader:send("color", {
      (tonumber(c[1]) or defaults.color[0]) / 255,
      (tonumber(c[2]) or defaults.color[1]) / 255,
      (tonumber(c[3]) or defaults.color[2]) / 255
    })
  end

  return moonshine.Effect{
    name = "scanlines",
    shader = shader,
    setters = setters,
    defaults = defaults,
  }
end
