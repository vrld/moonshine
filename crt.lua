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
  -- Barrel distortion adapted from Daniel Oaks (see commit cef01b67fd)
  -- Added feather to mask out outside of distorted texture
  local distortionFactor
  local shader = love.graphics.newShader[[
    extern vec2 distortionFactor;
    extern vec2 scaleFactor;
    extern number feather;

    vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px) {
      // to barrel coordinates
      uv = uv * 2.0 - vec2(1.0);

      // distort
      uv *= scaleFactor;
      uv += (uv.yx*uv.yx) * uv * (distortionFactor - 1.0);
      number mask = (1.0 - smoothstep(1.0-feather,1.0,abs(uv.x)))
                  * (1.0 - smoothstep(1.0-feather,1.0,abs(uv.y)));

      // to cartesian coordinates
      uv = (uv + vec2(1.0)) / 2.0;

      return color * Texel(tex, uv) * mask;
    }
  ]]

  local setters = {}

  setters.distortionFactor = function(v)
    assert(type(v) == "table" and #v == 2, "Invalid value for `distortionFactor'")
    distortionFactor = {unpack(v)}
    shader:send("distortionFactor", v)
  end

  setters.x = function(v) setters.distortionFactor{v, distortionFactor[2]} end
  setters.y = function(v) setters.distortionFactor{distortionFactor[1], v} end

  setters.scaleFactor = function(v)
    if type(v) == "table" and #v == 2 then
      shader:send("scaleFactor", v)
    elseif type(v) == "number" then
      shader:send("scaleFactor", {v,v})
    else
      error("Invalid value for `scaleFactor'")
    end
  end

  setters.feather = function(v) shader:send("feather", v) end

  local defaults = {
    distortionFactor = {1.06, 1.065},
    feather = 0.02,
    scaleFactor = 1,
  }

  return moonshine.Effect{
    name = "crt",
    shader = shader,
    setters = setters,
    defaults = defaults
  }
end
