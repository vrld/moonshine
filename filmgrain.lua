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
description = "Film grain overlay",

new = function(self)
	self.canvas = love.graphics.newCanvas()
	self.noisetex = love.image.newImageData(100,100)
	self.noisetex:mapPixel(function()
		local l = love.math.random() * 255
		return l,l,l,l
	end)
	self.noisetex = love.graphics.newImage(self.noisetex)
	self.shader = love.graphics.newShader[[
		extern number opacity;
		extern number grainsize;
		extern number noise;
		extern Image noisetex;
		extern vec2 tex_ratio;
		float rand(vec2 co)
		{
			return Texel(noisetex, mod(co * tex_ratio / vec2(grainsize), vec2(1.0))).r;
		}

		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
		{
			return color * Texel(texture, tc) * mix(1.0, rand(tc+vec2(noise)), opacity);
		}
	]]
	self.shader:send("opacity",.3)
	self.shader:send("grainsize",1)

	self.shader:send("noise",0)
	self.shader:send("noisetex", self.noisetex)
	self.shader:send("tex_ratio", {love.graphics.getWidth() / self.noisetex:getWidth(), love.graphics.getHeight() / self.noisetex:getHeight()})
end,

draw = function(self, func, ...)
	self.shader:send("noise", love.math.random())
	self:_apply_shader_to_scene(self.shader, self.canvas, func, ...)
end,

set = function(self, key, value)
	if key == "opacity" or key == "grainsize" then
		self.shader:send(key, math.max(0, tonumber(value) or 0))
	else
		error("Unknown property: " .. tostring(key))
	end

	return self
end
}
