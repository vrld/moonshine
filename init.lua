--[[
The MIT License (MIT)

Copyright (c) 2017 Matthias Richter

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

local Chain = {}
Chain.__call = function(_, ...) return chain.next(...) end,
Chain.__newindex = function(_,k,v)
  -- if k == "parameters" and type(v) == "table" then for k,v in (v) do _[k]=v end end
  for _, e in ipairs(chain) do
    if e.setters[k] then return e.setters[k](v, k) end
  end
  error(("Unknown property: %q"):format(k), 2)
end

shine.draw_shader = function(buffer, shader)
  front, back = buffer()
  love.graphics.setCanvas(front)
  love.graphics.clear()
  love.graphics.setShader(shader)
  love.graphics.draw(back)
end

shine.chain = function(effect)
  local chain = setmetatable({}, Chain)

  chain.next = function(next_effect)
    chain[#chain+1] = next_effect
    for k,v in pairs(next_effect.defaults or {}) do
      next_effect.settes[k](v,k)
    end
    return chain
  end
  chain.next(next_effect)

  local front, back = love.graphics.newCanvas(), love.graphics.newCanvas()
  local buffer = function()
    back, front = front, back
    return front, back
  end

  chain.draw = function(func, ...)
    -- save state
    local canvas = love.graphics.getCanvas()
    local shader = love.graphics.getShader()
    local color = {love.graphics.getColor()}

    -- draw scene to front buffer
    love.graphics.setCanvas(buffer())
    love.graphics.clear()
    func(...)

    -- save more state
    local blendmode = love.graphics.getBlendMode()

    -- process all shaders
    love.graphics.setColor(color)
    love.graphics.setBlendMode("alpha", "premultiplied")
    for _,e in ipairs(chain) do
      (e.draw or shine.draw_shader)(buffer, e.shader)
    end

    -- present result
    love.graphics.setShader()
    love.graphics.setCanvas(canvas)
    love.graphics.draw(front,0,0)

    -- restore state
    love.graphics.setBlendMode(blendmode)
    love.graphics.setShader(shader)
  end

  return chain
end

-- autoloading effects
shine.effects = setmetatable({}, {__index = function(self, key)
  local ok, effect = pcall(require, BASE .. "." .. key)
  if not ok then
    error("No such effect: "..key, 2)
  end

  -- call effect with reference to shine and expose setters
  effect = function(...)
    return setmetatable(effect(shine, ...), {
      __newindex = function(self,k,v)
        assert(self.setters[k], ("Unknown property: %q"):format(k))
        self.setters[k](v, k)
      end})
    end

  self[key] = effect
  return effect
end})

return shine
