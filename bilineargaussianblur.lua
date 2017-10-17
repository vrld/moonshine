--[[
The MIT License (MIT)

Copyright (c) 2017 Tim Moore

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

-- Bilinear Gaussian blur filter as detailed here: http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
-- Produces near identical results to a standard Gaussian blur by using sub-pixel sampling,
-- this allows us to do ~1/2 the number of pixel lookups.

-- unroll convolution loop
local function build_shader(taps, offset, sigma)
	taps = math.floor(taps)
	sigma = sigma >= 1 and sigma or (taps - 1) * offset / 6

	if taps < 3 or taps % 2 ~= 1 then
	    error(('Taps must be >=3 and odd. Was %d.'):format(taps))
	end

	local steps = (taps + 1) / 2

	-- Calculate gaussian function.
	local g_offsets = {}
	local g_weights = {}
	for i = 1, steps, 1 do
		local offset = i - 1
		g_offsets[i] = offset

		-- We don't need to include the constant part of the gaussian function as we normalize later.
		-- 1 / math.sqrt(2 * sigma ^ math.pi) * math.exp(-0.5 * ((offset - 0) / sigma) ^ 2 )
		g_weights[i] = math.exp(-0.5 * (offset - 0) ^ 2 * 1 / sigma ^ 2 )
	end

	-- Calculate offsets and weights for sub-pixel samples.
	local offsets = {}
	local weights = {}
	for i = #g_weights, 2, -2 do
		local oA, oB = g_offsets[i], g_offsets[i - 1]
		local wA, wB = g_weights[i], g_weights[i - 1]
		wB = i ~=2 and wB or wB / 2 -- On final tap the middle is getting sampled twice so half weight.
		local weight = wA + wB
		offsets[#offsets + 1] = (oA * wA + oB * wB) / weight
		weights[#weights + 1] = weight
	end

	local code = {[[
extern vec2 direction;
uniform sampler2D tex0;
vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {]]}

    local norm = 0
	if #g_weights % 2 == 0 then
		code[#code+1] =  'vec4 c = vec4( 0.0f );'
	else
		local weight = g_weights[1]
		norm = norm + weight
		code[#code+1] = ('vec4 c = %f * texture2D( tex0, tc ).xyzw;'):format(weight)
	end

	local tmpl = 'c += %f * ( texture2D( tex0, tc + %f * direction ).xyzw + texture2D( tex0, tc - %f * direction ).xyzw );\n'
	for i = 1, #offsets, 1 do
		local offset = offsets[i]
		local weight = weights[i]
		norm = norm + weight * 2
		code[#code+1] = tmpl:format(weight, offset, offset)
	end
	code[#code+1] = ('return c * vec4(%f) * color; }'):format(1 / norm)

	local shader = table.concat(code)
	return love.graphics.newShader(shader)
end

return {

description = "Bilinear Gaussian blur shader (http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/)",

new = function(self)
	self.canvas_h, self.canvas_v = love.graphics.newCanvas(), love.graphics.newCanvas()
	self.taps, self.offset, self.sigma = 7, 1, -1
	self.shader = build_shader(self.taps, self.offset, self.sigma)

	self.shader:send("direction", {1.0, 0.0} )
end,

draw = function(self, func, ...)
	local c = love.graphics.getCanvas()
	local s = love.graphics.getShader()
	local co = {love.graphics.getColor()}

	-- draw scene
	self:_render_to_canvas(self.canvas_h, func, ...)

	love.graphics.setColor(co)
	love.graphics.setShader(self.shader)

	local b = love.graphics.getBlendMode()
	love.graphics.setBlendMode('alpha', 'premultiplied')

	-- first pass (horizontal blur)
	self.shader:send('direction', {1 / love.graphics.getWidth(), 0})
	self:_render_to_canvas(self.canvas_v, love.graphics.draw, self.canvas_h, 0,0)

	-- second pass (vertical blur)
	self.shader:send('direction', {0, 1 / love.graphics.getHeight()})
	love.graphics.draw(self.canvas_v, 0,0)

	-- restore blendmode, shader and canvas
	love.graphics.setBlendMode(b)
	love.graphics.setShader(s)
	love.graphics.setCanvas(c)
end,

set = function(self, key, value)
	if key == "taps" then
		-- Number of effective samples to take per pass. e.g. 3-tap is the current pixel and the neighbors each side.
		-- More taps = larger blur, but slower.
		self.taps = tonumber(value)
	elseif key == "offset" then
		-- Offset of each tap.
		-- For highest quality this should be <=1 but if the image has low entropy we
		-- can approximate the blur with a number > 1 and less taps, for better performance.
		self.offset = tonumber(value)
	elseif key == "sigma" then
		-- Sigma value for gaussian distribution. You don't normally need to set this.
	    self.sigma = tonumber(value)
	else
		error("Unknown property: " .. tostring(key))
	end

	self.shader = build_shader(self.taps, self.offset, self.sigma)
	return self
end
}
