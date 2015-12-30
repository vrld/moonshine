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
description = "Desaturation/tint effect",

new = function(self)
	self.canvas = love.graphics.newCanvas()
	self.shader = love.graphics.newShader[[
		extern vec4 tint;
		extern number strength;
		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
		{
			color = Texel(texture, tc);
			number luma = dot(vec3(0.299f, 0.587f, 0.114f), color.rgb);
			return mix(color, tint * luma, strength);
		}
	]]
	self.shader:send("tint",{1.0,1.0,1.0,1.0})
	self.shader:send("strength",0.5)
end,

draw = function(self, func, ...)
	self:_apply_shader_to_scene(self.shader, self.canvas, func, ...)
end,

set = function(self, key, value)
	if key == "tint" then
		assert(type(value) == "table")
		self.shader:send("tint", {value[1]/255, value[2]/255, value[3]/255, 1})
	elseif key == "strength" then
		self.shader:send("strength", math.max(0, math.min(1, tonumber(value) or 0)))
	else
		error("Unknown property: " .. tostring(key))
	end

	return self
end
}
