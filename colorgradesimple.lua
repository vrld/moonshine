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
description = "Simple linear color grading of red, green and blue channel",

new = function(self)
	self.canvas = love.graphics.newCanvas()
	self.shader = love.graphics.newShader[[
		extern vec3 grade;
		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
		{
			return vec4(grade, 1.0f) * Texel(texture, tc) * color;
		}
	]]
	self.shader:send("grade",{1.0,1.0,1.0})
end,

draw = function(self, func, ...)
	self:_apply_shader_to_scene(self.shader, self.canvas, func, ...)
end,

set = function(self, key, value)
	if key == "grade" then
		self.shader:send(key, value)
	else
		error("Unknown property: " .. tostring(key))
	end

	return self
end
}
