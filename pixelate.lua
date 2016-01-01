--[[
The MIT License (MIT)

Copyright (c) 2015 Daniel Oaks, Matthias Richter

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

local function build_shader(add_original, samples)
	local code = {[[
	extern float pixel_size;

	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
	{
	]]}

	if add_original then
		code[#code+1] = [[color = Texel(texture, texture_coords);]]
	else
		code[#code+1] = [[color = vec4(.0);]]
	end

	code[#code+1] = [[
		vec2 pixel_pos = floor(pixel_coords / pixel_size);
		vec2 upper_left = (pixel_pos + vec2(.2)) * pixel_size / love_ScreenSize.xy;
		vec2 lower_right   = (pixel_pos + vec2(.8)) * pixel_size / love_ScreenSize.xy;
		vec2 center   = (upper_left + lower_right) / 2.;
	]]

	-- sample color at different positions in the pixel
	if samples >= 1 then -- center
		code[#code+1] = [[color += Texel(texture, center);]]
	end
	if samples >= 2 then -- upper left
		code[#code+1] = [[color += Texel(texture, upper_left);]]
	end
	if samples >= 3 then -- lower right
		code[#code+1] = [[color += Texel(texture, lower_right);]]
	end
	if samples >= 4 then -- upper right
		code[#code+1] = [[color += Texel(texture, vec2(lower_right.x, upper_left.y));]]
	end
	if samples >= 5 then -- lower left
		code[#code+1] = [[color += Texel(texture, vec2(upper_left.x, lower_right.y));]]
	end
	if samples >= 6 then -- center left
		code[#code+1] = [[color += Texel(texture, vec2(upper_left.x, center.y));]]
	end
	if samples >= 7 then -- center right
		code[#code+1] = [[color += Texel(texture, vec2(lower_right.x, center.y));]]
	end
	if samples >= 8 then -- upper center
		code[#code+1] = [[color += Texel(texture, vec2(center.x, upper_left.y));]]
	end
	if samples >= 9 then -- lower center
		code[#code+1] = [[color += Texel(texture, vec2(center.x, lower_right.y));]]
	end

	-- average out
	code[#code+1] = ([[
		return color / float(%d);
	}]]):format(math.max(1, math.min(9, samples)) + (add_original and 1 or 0))

	print(table.concat(code,"\n"))
	return love.graphics.newShader(table.concat(code))
end

return {
description = "Pixelation",

new = function(self)
	self._pixel_size = 3
	self._add_original = false
	self._samples = 5

	self.canvas = love.graphics.newCanvas()
	self.shader = build_shader(self._add_original, self._samples)

	self.shader:send("pixel_size", self._pixel_size)
end,

draw = function(self, func, ...)
	self:_apply_shader_to_scene(self.shader, self.canvas, func, ...)
end,

set = function(self, key, value)
	if key == "pixel_size" then
		assert(type(value) == "number")
		self._pixel_size = value
		self.shader:send("pixel_size", value)
	elseif key == "samples" then
		assert(type(value) == "number")
		self._samples = value
		self.shader = build_shader(self._add_original, self._samples)
		self.shader:send("pixel_size", self._pixel_size)
	elseif key == "add_original" then
		assert(type(value) == "boolean")
		self._add_original = value
		self.shader = build_shader(self._add_original, self._samples)
		self.shader:send("pixel_size", self._pixel_size)
	else
		error("Unknown property: " .. tostring(key))
	end

	return self
end
}
