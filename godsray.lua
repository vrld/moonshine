--[[
The MIT License (MIT)

Copyright (c) 2015 Josef Patoprsty

Based on work by: ioxu

https://www.love2d.org/forums/viewtopic.php?f=4&t=3733&start=120#p71099

Based on work by: Fabien Sanglard

http://fabiensanglard.net/lightScattering/index.php

Based on work from: 

[Mitchell]: Kenny Mitchell "Volumetric Light Scattering as a Post-Process" GPU Gems 3 (2005). 
[Mitchell2]: Jason Mitchell "Light Shaft Rendering" ShadersX3 (2004). 

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

local x,y

return {
	description = "Realtime Light Scattering",

	new = function(self)
		self.canvas = love.graphics.newCanvas()
		self.shader = love.graphics.newShader[[
			extern number exposure = 0.3;
			extern number decay = .95;
			extern number density = .4;
			extern number weight = .3;
			extern vec2 light_position= vec2(0.5,0.5);
			extern number samples = 70.0 ;

			vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
				vec2 deltaTextCoord = vec2( texture_coords - light_position.xy );
				vec2 textCoo = texture_coords.xy;
				deltaTextCoord *= 1.0 / float(samples) * density;
				float illuminationDecay = 1.0;
				vec4 cc = vec4(0.0, 0.0, 0.0, 1.0);

				for(int i=0; i < samples ; i++) {
					textCoo -= deltaTextCoord;
					vec4 sample = Texel( texture, textCoo );
					sample *= illuminationDecay * weight;
					cc += sample;
					illuminationDecay *= decay;
				}
				cc *= exposure;
				return cc;
			}
		]]
	end,

	draw = function(self, func, ...)
		self.shader:send("light_position",{x or 0.5,y or 0.5})
		self:_apply_shader_to_scene(self.shader, self.canvas, func, ...)
	end,

	set = function(self, key, value)
		if key == "exposure" or key == "decay" or key == "density" or key == "weight" then
			self.shader:send(key,math.min(1,math.max(0,tonumber(value) or 0)))
		elseif key == "positionx" then
			x = math.min(1,math.max(0,tonumber(value) or 0.5))
		elseif key == "positiony" then
			y = math.min(1,math.max(0,tonumber(value) or 0.5))
		elseif key == "samples" then
			self.shader:send(key,math.max(1,tonumber(value) or 1))
		else
			error("Unknown property: " .. tostring(key))
		end

		return self
	end
}
