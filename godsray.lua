--[[
The MIT License (MIT)

Original code: Copyright (c) 2015 Josef Patoprsty
Port to moonshine: Copyright (c) 2017 Matthias Richter <vrld@vrld.org>

Based on work by: ioxu

https://www.love2d.org/forums/viewtopic.php?f=4&t=3733&start=120#p71099

Based on work by: Fabien Sanglard

http://fabiensanglard.net/lightScattering/index.php

Based on work from:

[Mitchell]: Kenny Mitchell "Volumetric Light Scattering as a Post-Process" GPU Gems 3 (2005).
[Mitchell2]: Jason Mitchell "Light Shaft Rendering" ShadersX3 (2004).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

return function(moonshine)
  local shader = love.graphics.newShader[[
    extern number exposure;
    extern number decay;
    extern number density;
    extern number weight;
    extern vec2 light_position;
    extern number samples;

    vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px) {
      color = Texel(tex, uv);

      vec2 offset = (uv - light_position) * density / samples;
      number illumination = decay;
      vec4 c = vec4(.0, .0, .0, 1.0);

      for (int i = 0; i < int(samples); ++i) {
        uv -= offset;
        c += Texel(tex, uv) * illumination * weight;
        illumination *= decay;
      }

      return vec4(c.rgb * exposure + color.rgb, color.a);
    }]]


  local setters, light_position = {}

  for _,k in ipairs{"exposure", "decay", "density", "weight"} do
    setters[k] = function(v)
      shader:send(k, math.min(1, math.max(0, tonumber(v) or 0)))
    end
  end

  setters.light_position = function(v)
    light_position = {unpack(v)}
    shader:send("light_position", v)
  end

  setters.light_x = function(v)
    assert(type(v) == "number", "Invalid value for `light_x'")
    setters.light_position{v, light_position[2]}
  end

  setters.light_y = function(v)
    assert(type(v) == "number", "Invalid value for `light_y'")
    setters.light_position{light_position[1], v}
  end

  setters.samples = function(v)
    shader:send("samples", math.max(1,tonumber(v) or 1))
  end

  local defaults = {
    exposure = 0.25,
    decay = 0.95,
    density = 0.15,
    weight = 0.5,
    light_position = {0.5,0.5},
    samples = 70
  }

  return moonshine.Effect{
    name = "godsray",
    shader = shader,
    setters = setters,
    defaults = defaults
  }
end
