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
description = "Vignette overlay",

new = function(self)
	self.canvas = love.graphics.newCanvas()
	self.shader = love.graphics.newShader[[
		extern number radius;
		extern number softness;
		extern number opacity;
		extern number aspect;
		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
		{
			color = Texel(texture, tc);
			number v = smoothstep(radius, radius-softness, length((tc - vec2(0.5f)) * aspect));
			return mix(color, color * v, opacity);
		}
	]]
	self.shader:send("radius",1)
	self.shader:send("softness",.45)
	self.shader:send("opacity",.5)
	self.shader:send("aspect", love.graphics.getWidth() / love.graphics.getHeight())
end,

draw = function(self, func, ...)
	self:_apply_shader_to_scene(self.shader, self.canvas, func, ...)
end,

set = function(self, key, value)
	if key == "radius" or key == "softness" or key == "opacity" then
		self.shader:send(key, math.max(0, tonumber(value) or 0))
	else
		error("Unknown property: " .. tostring(key))
	end

	return self
end
}
