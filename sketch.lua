--[[
The MIT License (MIT)

Copyright (c) 2015 Martin Felis
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
description = "Sketched drawing style",

new = function(self)
	self.canvas = love.graphics.newCanvas()
	self.noisetex = love.image.newImageData(100,100)
	self.noisetex:mapPixel(function()
		local l = love.math.random() * 255
		return l,l,l,l
	end)
	self.noisetex = love.graphics.newImage(self.noisetex)
	self.noisetex:setWrap ("repeat", "repeat")
	self.noisetex:setFilter("nearest", "nearest")

	self.shader = love.graphics.newShader[[
		extern number amp;
		extern number screen_center_x;
		extern number screen_center_y;

		extern Image noisetex;

		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
		{
			vec2 screen_center = vec2 (screen_center_x, screen_center_y);
			vec4 noise;

			noise = Texel (noisetex, texture_coords + screen_center);
			noise = normalize (noise * 2.0 - vec4 (1.0, 1.0, 1.0, 1.0));
			noise *= amp;

			return Texel(texture, texture_coords + noise.xy);
		}
	]]
	self.shader:send("amp", 0.001 )

	-- Set the screen_center positions when the camera moves but the
	-- noise texture should stay fixed in world coordinates to reduce
	-- aliasing effects.
	self.shader:send("screen_center_x",love.graphics.getWidth() * 0.5)
	self.shader:send("screen_center_y",love.graphics.getHeight() * 0.5)

	self.shader:send("noisetex", self.noisetex)
end,

draw = function(self, func, ...)
	self:_apply_shader_to_scene(self.shader, self.canvas, func, ...)
end,

set = function(self, key, value)
	if key == "amp" or key == "screen_center_x" or key == "screen_center_y" then
		self.shader:send(key, math.max(0, tonumber(value) or 0))
	else
		error("Unknown property: " .. tostring(key))
	end

	return self
end
}
