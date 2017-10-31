--[[
Public domain:

Copyright (C) 2017 by Matthias Richter <vrld@vrld.org>

shader based on code by sam hocevar, see
https://gamedev.stackexchange.com/questions/59797/glsl-shader-change-hue-saturation-brightness

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
    extern number num_bands;
    vec3 rgb2hsv(vec3 c)
    {
      vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
      vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
      vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

      float d = q.x - min(q.w, q.y);
      float e = 1.0e-10;
      return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
    }

    vec3 hsv2rgb(vec3 c)
    {
      vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
      vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
      return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }

    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
    {
      color = Texel(texture, tc);
      vec3 hsv = floor((rgb2hsv(color.rgb) * num_bands) + vec3(0.5)) / num_bands;
      return vec4(hsv2rgb(hsv), color.a);
    }]]

  return moonshine.Effect{
    name = "posterize",
    shader = shader,
    setters = {
      num_bands = function(v)
        shader:send("num_bands", math.max(1, tonumber(v) or 1))
      end
    },
    defaults = {num_bands = 3}
  }
end
