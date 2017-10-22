--[[
The MIT License (MIT)

Copyright (c) 2015 Martin Felis
Copyright (c) 2017 Matthias Richter

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
  local noisetex = love.image.newImageData(256,256)
  noisetex:mapPixel(function()
    return love.math.random() * 255,love.math.random() * 255, 0, 0
  end)
  noisetex = love.graphics.newImage(noisetex)
  noisetex:setWrap ("repeat", "repeat")
  noisetex:setFilter("nearest", "nearest")

  local shader = love.graphics.newShader[[
    extern Image noisetex;
    extern number amp;
    extern vec2 center;

    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _) {
      vec2 displacement = Texel(noisetex, tc + center).rg;
      tc += normalize(displacement * 2.0 - vec2(1.0)) * amp;

      return Texel(texture, tc);
    }]]

  shader:send("noisetex", noisetex)

  local setters = {}
  setters.amp = function(v)
    shader:send("amp", math.max(0, tonumber(v) or 0))
  end
  setters.center = function(v)
    assert(type(v) == "table" and #v == 2, "Invalid value for `center'")
    shader:send("center", v)
  end

  return moonshine.Effect{
    name = "sketch",
    shader = shader,
    setters = setters,
    defaults = {amp = .0007, center = {0,0}}
  }
end
