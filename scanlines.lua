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
description = "Horizontal Scanlines",

new = function(self)
	self._pixel_size = 3
	self._opacity = 0.3
	self._center_fade = 0.44
	self._line_height = 0.35

	self.canvas = love.graphics.newCanvas()
	self.shader = love.graphics.newShader[[
	#define PI (3.14159265)

	extern float pixel_size;

	// Opacity of the scanlines, 0 to 1.
	extern float opacity;
	// How much scanlines 'fade out' in the center of the screen
	extern float center_fade;
	// How much of each pixel is scanline, 0 to 1.
	extern float scanline_height;

	// input coords 0 -> 1,
	//   return coords -1 -> 1
	vec2 coords_glsl_to_neg1_1(vec2 point) {
		point.x = ((point.x * 2.0) - 1.0);
		point.y = ((point.y * -2.0) + 1.0);

		return point;
	}

	vec4 desaturate(vec4 color, float amount)
	{
		vec4 gray = vec4(dot(vec4(0.2126,0.7152,0.0722,0.2), color));
		return vec4(mix(color, gray, amount));
	}

	vec4 effect(vec4 vcolor, Image texture, vec2 texture_coords, vec2 pixel_coords)
	{
		vec4 working_rgb = Texel(texture, texture_coords);

		// horizontal scanlines
		float current_pixel_v = pixel_coords.y / pixel_size;
		float scanline_is_active = cos(current_pixel_v * 2.0 * PI) - 1.0 + scanline_height * 3.0;

		// clamp
		if (scanline_is_active > 1.0) {
			scanline_is_active = 1.0;
		}

		// fading towards the center, looks much better
		vec2 fade_coords = coords_glsl_to_neg1_1(texture_coords);
		float fade_value = ((1.0 - abs(fade_coords.x)) + (1.0 - abs(fade_coords.y))) / 2.0;

		scanline_is_active -= fade_value * center_fade;

		// clamp
		if (scanline_is_active < 0.0) {
			scanline_is_active = 0.0;
		}

		// eh, just implement as lowering alpha for now
		// see if we should be modifying rgb values instead
		// possibly by making it darker and less saturated in the scanlines?
		working_rgb = desaturate(working_rgb, scanline_is_active * 0.07);
		working_rgb.r = working_rgb.r - (scanline_is_active * opacity);
		working_rgb.g = working_rgb.g - (scanline_is_active * opacity);
		working_rgb.b = working_rgb.b - (scanline_is_active * opacity);

		return working_rgb;
	}
	]]
	self.shader:send("pixel_size", self._pixel_size)
	self.shader:send("opacity", self._opacity)
	self.shader:send("center_fade", self._center_fade)
	self.shader:send("scanline_height", self._line_height)
end,

draw = function(self, func, ...)
	self:_apply_shader_to_scene(self.shader, self.canvas, func, ...)
end,

set = function(self, key, value)
	if key == "pixel_size" then
		assert(type(value) == "number")
		self._pixel_size = value
		self.shader:send("pixel_size", value)
	elseif key == "opacity" then
		assert(type(value) == "number")
		self._opacity = value
		self.shader:send("opacity", value)
	elseif key == "center_fade" then
		assert(type(value) == "number")
		self._center_fade = value
		self.shader:send("center_fade", value)
	elseif key == "line_height" then
		assert(type(value) == "number")
		self._line_height = value
		self.shader:send("line_height", value)
	else
		error("Unknown property: " .. tostring(key))
	end

	return self
end
}
