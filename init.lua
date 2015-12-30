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

local BASE = ...

local shine = {}
shine.__index = shine

-- commonly used utility function
function shine._render_to_canvas(_, canvas, func, ...)
	local old_canvas = love.graphics.getCanvas()

	love.graphics.setCanvas(canvas)
	love.graphics.clear()
	func(...)

	love.graphics.setCanvas(old_canvas)
end

function shine._apply_shader_to_scene(_, shader, canvas, func, ...)
	local s = love.graphics.getShader()
	local co = {love.graphics.getColor()}

	-- draw scene to canvas
	shine._render_to_canvas(_, canvas, func, ...)

	-- apply shader to canvas
	love.graphics.setColor(co)
	love.graphics.setShader(shader)
	local b = love.graphics.getBlendMode()
	love.graphics.setBlendMode('alpha', 'premultiplied')
	love.graphics.draw(canvas, 0,0)
	love.graphics.setBlendMode(b)

	-- reset shader and canvas
	love.graphics.setShader(s)
end

-- effect chaining
function shine.chain(first, second)
	local effect = {}
	function effect:set(k, v)
		local ok = pcall(first.set, first, k, v)
		ok = pcall(second.set, second, k, v) or ok
		if not ok then
			error("Unknown property: " .. tostring(k))
		end
	end
	function effect:draw(func, ...)
		local args = {n = select('#',...), ...}
		second(function() first(func, unpack(args, 1, args.n)) end)
	end

	return setmetatable(effect, {__newindex = shine.__newindex, __index = shine, __call = effect.draw})
end

-- guards
function shine.draw()
	error("Incomplete effect: draw(func) not implemented", 2)
end
function shine.set()
	error("Incomplete effect: set(key, value) not implemented", 2)
end

function shine.__newindex(self, k, v)
	if k == "parameters" then
		assert(type(v) == "table")
		for k,v in pairs(v) do
			self:set(k,v)
		end
	else
		self:set(k, v)
	end
end

return setmetatable({}, {__index = function(self, key)
	local ok, effect = pcall(require, BASE .. "." .. key)
	if not ok then
		error("No such effect: "..key, 2)
	end

	setmetatable(effect, shine)

	local constructor = function(t)
		local instance = {}
		effect.new(instance)
		setmetatable(instance, {__newindex = shine.__newindex, __index = effect, __call = effect.draw})
		if t and type(t) == "table" then
			instance.parameters = t
		end
		return instance
	end

	self[key] = constructor
	return constructor
end})
