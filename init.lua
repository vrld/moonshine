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

local moonshine = {}

moonshine.draw_shader = function(buffer, shader)
  local front, back = buffer()
  love.graphics.setCanvas(front)
  love.graphics.clear()
  if shader ~= love.graphics.getShader() then
    love.graphics.setShader(shader)
  end
  love.graphics.draw(back)
end

moonshine.chain = function(w,h,effect)
  -- called as moonshine.chain(effect)'
  if h == nil then
    effect, w,h = w, love.window.getMode()
  end
  assert(effect ~= nil, "No effect")

  local front, back = love.graphics.newCanvas(w,h), love.graphics.newCanvas(w,h)
  local buffer = function()
    back, front = front, back
    return front, back
  end

  local disabled = {} -- set of disabled effects
  local chain = {}
  chain.resize = function(w, h)
    front, back = love.graphics.newCanvas(w,h), love.graphics.newCanvas(w,h)
    return chain
  end

  chain.draw = function(func, ...)
    -- save state
    local canvas = love.graphics.getCanvas()
    local shader = love.graphics.getShader()
    local fg_r, fg_g, fg_b, fg_a = love.graphics.getColor()

    -- draw scene to front buffer
    love.graphics.setCanvas((buffer())) -- parens are needed: take only front buffer
    love.graphics.clear(love.graphics.getBackgroundColor())
    func(...)

    -- save more state
    local blendmode = love.graphics.getBlendMode()

    -- process all shaders
    love.graphics.setColor(fg_r, fg_g, fg_b, fg_a)
    love.graphics.setBlendMode("alpha", "premultiplied")
    for _,e in ipairs(chain) do
      if not disabled[e.name] then
        (e.draw or moonshine.draw_shader)(buffer, e.shader)
      end
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
    assert(e.name, "Invalid effect: must provide `name'.")
    assert(e.shader or e.draw, "Invalid effect: must provide `shader' or `draw'.")
    table.insert(chain, e)
    return chain
  end
  chain.chain = chain.next

  chain.disable = function(name, ...)
    if name then
      disabled[name] = name
      return chain.disable(...)
    end
  end

  chain.enable = function(name, ...)
    if name then
      disabled[name] = nil
      return chain.enable(...)
    end
  end

  setmetatable(chain, {
    __call = function(_, ...) return chain.draw(...) end,
    __index = function(_,k)
      for _, e in ipairs(chain) do
        if e.name == k then return e end
      end
      error(("Effect `%s' not in chain"):format(k), 2)
    end,
    __newindex = function(_, k, v)
      if k == "parameters" or k == "params" or k == "settings" then
        for e,par in pairs(v) do
          for k,v in pairs(par) do
            chain[e][k] = v
          end
        end
      else
        rawset(chain, k, v)
      end
    end
  })

  return chain.next(effect)
end

moonshine.Effect = function(e)
  -- set defaults
  for k,v in pairs(e.defaults or {}) do
    assert(e.setters[k], ("No setter for parameter `%s'"):format(k))(v, k)
    e.setters[k](v,k)
  end

  -- expose setters
  return setmetatable(e, {
    __newindex = function(self,k,v)
      assert(self.setters[k], ("Unknown property: `%s.%s'"):format(e.name, k))
      self.setters[k](v, k)
    end})
end

-- autoloading effects
moonshine.effects = setmetatable({}, {__index = function(self, key)
  local ok, effect = pcall(require, BASE .. "." .. key)
  if not ok then
    error("No such effect: "..key, 2)
  end

  -- expose moonshine to effect
  local con = function(...) return effect(moonshine, ...) end

  -- cache effect constructor
  self[key] = con
  return con
end})

return setmetatable(moonshine, {__call = function(_, ...) return moonshine.chain(...) end})
