--[[
The MIT License (MIT)

Copyright (c) 2015 Matthias Richter

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

return {
requires = {'canvas', 'shader'},
description = "Bloom effect",

new = function(self)
    self._size = {love.graphics.getWidth(), love.graphics.getHeight()}
    self._samples = 5
    self._quality = 2.5

    self.canvas = love.graphics.newCanvas()
    self.shader = love.graphics.newShader[[
        extern vec2 size;
        extern number samples = 5;
        extern number quality = 2.5;
         
        vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
        {
            vec4 source = Texel(tex, tc);
            vec4 sum = vec4(0);
            number diff = (samples - 1) / 2;
            vec2 sizeFactor = vec2(1) / size * quality;
          
            for (number x = -diff; x <= diff; x++)
            {
                for (number y = -diff; y <= diff; y++)
                {
                    vec2 offset = vec2(x, y) * sizeFactor;
                    sum += Texel(tex, tc + offset);
                }
            }
          
            return ((sum / (samples * samples)) + source) * color;
        }

    ]]
    self.shader:send("size", self._size)
    self.shader:send("samples", self._samples)
    self.shader:send("quality", self._quality)
end,

draw = function(self, func, ...)
    self:_apply_shader_to_scene(self.shader, self.canvas, func, ...)
end,

set = function(self, key, value)
    if key == "samples" then
        assert(type(value) == "number")
        self._samples = value
        self.shader:send(key, value)
    elseif key == "quality" then
        assert(type(value) == "number")
        self._quality = value
        self.shader:send(key, math.max(0, math.min(10, tonumber(value) or 0)))
    elseif key == "size" then
        assert(type(value) == "table")
        self.shader:send(key, value)
    else
        error("Unknown property: " .. tostring(key))
    end

    return self
end
}
