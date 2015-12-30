--[[
The MIT License (MIT)

Copyright (c) 2015 Daniel Oaks

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
description = "CRT-like barrel distortion",

new = function(self)
	self._x_distortion, self._y_distortion = 0.06, 0.065
	self._outline = {25, 25, 26}
	self._draw_outline = true

	self.canvas = love.graphics.newCanvas()
	self.shader = love.graphics.newShader[[
	// How much we distort on the x and y axis.
	//   from 0 to 1
	extern float x_distortion;
	extern float y_distortion;

	vec2 distort_coords(vec2 point)
	{
		// convert to coords we use for barrel distort function
		//   turn 0 -> 1 into -1 -> 1
		point.x = ((point.x * 2.0) - 1.0);
		point.y = ((point.y * -2.0) + 1.0);

		// distort
		point.x = point.x + (point.y * point.y) * point.x * x_distortion;
		point.y = point.y + (point.x * point.x) * point.y * y_distortion;

		// convert back to coords glsl uses
		//   turn -1 -> 1 into 0 -> 1
		point.x = ((point.x + 1.0) / 2.0);
		point.y = ((point.y - 1.0) / -2.0);

		return point;
	}

	vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
	{
		vec2 working_coords = distort_coords(tc);
		return Texel(texture, working_coords);
	}
	]]
	self.shader:send("x_distortion", self._x_distortion)
	self.shader:send("y_distortion", self._y_distortion)
end,

distort = function(self, x, y)
	local w = love.graphics.getWidth()
	local h = love.graphics.getHeight()

	-- turn 0 -> w/h into -1 -> 1
	local distorted_x = (x / (w / 2)) - 1
	local distorted_y = (y / (h / 2)) - 1

	distorted_x = distorted_x + (distorted_y * distorted_y) * distorted_x * self._x_distortion
	distorted_y = distorted_y + (distorted_x * distorted_x) * distorted_y * self._y_distortion

	-- turn -1 -> 1 into 0 -> w/h
	distorted_x = (distorted_x + 1) * (w / 2)
	distorted_y = (distorted_y + 1) * (h / 2)

	return distorted_x, distorted_y
end,

draw = function(self, func, ...)
	local s = love.graphics.getShader()
	local co = {love.graphics.getColor()}
	local b = love.graphics.getBlendMode()

	-- draw scene to canvas
	self:_render_to_canvas(self.canvas, func, ...)

	-- draw outline if required
	if self._draw_outline then
		love.graphics.setBlendMode('replace')
		local width = love.graphics.getLineWidth()
		love.graphics.setLineWidth(1)
		self.canvas:renderTo(function()
			local w = love.graphics.getWidth()
			local h = love.graphics.getHeight()
			love.graphics.setColor(self._outline)
			love.graphics.line(0,0, w,0, w,h, 0,h, 0,0)
		end)
		love.graphics.setLineWidth(width)
	end

	-- apply shader to canvas
	love.graphics.setColor(co)
	love.graphics.setShader(self.shader)
	love.graphics.setBlendMode('alpha', 'premultiplied')
	love.graphics.draw(self.canvas, 0,0)
	love.graphics.setBlendMode(b)

	-- reset shader and canvas
	love.graphics.setShader(s)
end,

set = function(self, key, value)
	if key == "x" then
		assert(type(value) == "number")
		self._x_distortion = value
		self.shader:send("x_distortion", value)
	elseif key == "y" then
		assert(type(value) == "number")
		self._y_distortion = value
		self.shader:send("y_distortion", value)
	elseif key == "draw_outline" then
		assert(type(value) == "boolean")
		self._draw_outline = value
	elseif key == "outline" then
		assert(type(value) == "table")
		self._outline = value
	else
		error("Unknown property: " .. tostring(key))
	end

	return self
end
}
