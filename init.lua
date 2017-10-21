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

shine.draw_shader = function(buffer, shader)
  front, back = buffer()
  love.graphics.setCanvas(front)
  love.graphics.clear()
  if shader ~= love.graphics.getShader() then
    love.graphics.setShader(shader)
  end
  love.graphics.draw(back)
end

shine.chain = function(effect)
  local front, back = love.graphics.newCanvas(), love.graphics.newCanvas()
  local buffer = function()
    back, front = front, back
    return front, back
  end

  local chain = {}

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

  chain.next = function(e)
    if type(e) == "function" then
      e = e()
    end
    assert(e.shader or e.draw, "Invalid effect: must provide `shader' or `draw'.")
    table.insert(chain, e)
    return chain
  end
  chain.chain = chain.next

  setmetatable(chain, {
    __call = function(_, ...) return chain.draw(...) end,
    __newindex = function(_,k,v)
      -- if k == "parameters" and type(v) == "table" then for k,v in (v) do _[k]=v end end
      for _, e in ipairs(chain) do
        if e.setters[k] then return e.setters[k](v, k) end
      end
      error(("Unknown property: %q"):format(k), 2)
    end
  })

  return chain.next(effect)
end

shine.Effect = function(e)
  -- set defaults
  for k,v in pairs(e.defaults or {}) do
    assert(e.setters[k], ("No setter for parameter `%s'"):format(k))(v, k)
    e.setters[k](v,k)
  end

  -- expose setters
  return setmetatable(e, {
    __newindex = function(self,k,v)
      assert(self.setters[k], ("Unknown property: %q"):format(k))
      self.setters[k](v, k)
    end})
end

-- autoloading effects
shine.effects = setmetatable({}, {__index = function(self, key)
  local ok, effect = pcall(require, BASE .. "." .. key)
  if not ok then
    error("No such effect: "..key, 2)
  end

  -- expose shine to effect
  local con = function(...) return effect(shine, ...) end

  -- cache effect constructor
  self[key] = con
  return con
end})

return shine
