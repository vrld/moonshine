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
description = "Separates red, green and blue components",

new = function(self)
	self.angle, self.radius = 0, 0
	self.canvas = love.graphics.newCanvas()
	self.shader = love.graphics.newShader[[
		extern vec2 direction;
		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
		{
			return color * vec4(
				Texel(texture, tc - direction).r,
				Texel(texture, tc).g,
				Texel(texture, tc + direction).b,
				1.0);
		}
	]]
	self.shader:send("direction",{0,0})
end,

draw = function(self, func, ...)
	local dx = math.cos(self.angle) * self.radius / love.graphics.getWidth()
	local dy = math.sin(self.angle) * self.radius / love.graphics.getHeight()
	self.shader:send("direction", {dx,dy})
	self:_apply_shader_to_scene(self.shader, self.canvas, func, ...)
end,

set = function(self, key, value)
	if key == "radius" or key == "angle" then
		self[key] = tonumber(value) or 0
	else
		error("Unknown property: " .. tostring(key))
	end

	return self
end
}
