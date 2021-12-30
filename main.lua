--[[
Public domain:

Copyright (C) 2017 by Matthias Richter <vrld@vrld.org>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
]]--

local suit = require 'suit'

-- normally, you'd require 'moonshine', but here init.lua is in the same directory as main.lua
local moonshine = require '.'

local ParamInfo = {
  number = function(default, min, max)
    return {
      state = {value = default, min = min, max = max},
      widget = suit.Slider,
      val = function(s) return s.value end
    }
  end,
  vec2 = function(x,y, xmin,ymin, xmax,ymax)
    return {
      widget = function(state, ...)
        local x,y,w,h = ...
        w = w/2 - 2
        local c = suit.Slider(state[1], x,y,w,h).changed
        c = suit.Slider(state[2], x+w+4,y,w,h).changed or c
        return {changed = c}
      end,
      state = {
        {value = x, min = xmin, max = xmax},
        {value = y, min = ymin, max = ymax}
      },
      val = function(s) return {s[1].value, s[2].value} end
    }
  end,
  rgb = function(r,g,b)
    return {
      widget = function(state, ...)
        local x,y,w,h = ...
        w = w/3 - 2
        local c = suit.Slider(state[1], x,y,w,h).changed
        c = suit.Slider(state[2], x+w+4,y,w,h).changed or c
        c = suit.Slider(state[3], x+2*w+8,y,w,h).changed or c
        return {changed = c}
      end,
      state = {
        {value = r, min = 0, max = 2},
        {value = g, min = 0, max = 2},
        {value = b, min = 0, max = 2}
      },
      val = function(s) return {s[1].value, s[2].value, s[3].value} end
    }
  end,
  RGB = function(r,g,b)
    return {
      widget = function(state, ...)
        local x,y,w,h = ...
        w = w/3 - 2
        local c = suit.Slider(state[1], x,y,w,h).changed
        c = suit.Slider(state[2], x+w+4,y,w,h).changed or c
        c = suit.Slider(state[3], x+2*w+8,y,w,h).changed or c
        return {changed = c}
      end,
      state = {
        {value = r, min = 0, max = 1},
        {value = g, min = 0, max = 1},
        {value = b, min = 0, max = 1}
      },
      val = function(s) return {s[1].value, s[2].value, s[3].value} end
    }
  end,
  int = function(default, min, max)
    return {
      widget = function(state, ...)
        local ret = suit.Slider(state, ...)
        state.value = math.floor(state.value+.5)
        return ret
      end,
      state = {value = default, min = min, max = max, step = 1},
      val = function(s) return s.value end
    }
  end,
  oddint = function(default, min, max)
    return {
      widget = function(state, ...)
        local ret = suit.Slider(state, ...)
        state.value = math.floor(state.value+.5)
        if state.value % 2 == 0 then state.value = state.value + 1 end
        return ret
      end,
      state = {value = default, min = min, max = max, step = 1},
      val = function(s) return s.value end
    }
  end,
}

local function EffectInfo(name)
  return function(p) return {text = name, params = p} end
end

local effects = {
  EffectInfo'boxblur'{
    radius = ParamInfo.number(3, 0, 15),
  },
  EffectInfo'chromasep'{
    angle = ParamInfo.number(0, 0, 2*math.pi),
    radius = ParamInfo.number(0, 0, 50)
  },
  EffectInfo'colorgradesimple'{
    factors = ParamInfo.rgb(1,1,1)
  },
  EffectInfo'crt'{
    distortionFactor = ParamInfo.vec2(1.06,1.065, .95,.95, 1.2,1.2),
    scaleFactor = ParamInfo.vec2(1,1, .5,.5, 1.5,1.5),
    feather = ParamInfo.number(0.02, 0, .2)
  },
  EffectInfo'desaturate'{
    tint = ParamInfo.RGB(1,1,1),
    strength = ParamInfo.number(0.5, 0, 1)
  },
  EffectInfo'dmg'{
    palette = ParamInfo.int(1, 1, 7)
  },
  EffectInfo'fastgaussianblur'{
    taps = ParamInfo.oddint(7, 3, 35),
    offset = ParamInfo.number(1, 1, 5)
  },
  EffectInfo'filmgrain'{
    opacity = ParamInfo.number(.3, 0, 1),
    size = ParamInfo.number(1, 0, 5)
  },
  EffectInfo'gaussianblur'{
    sigma = ParamInfo.number(1, .1, 12),
  },
  EffectInfo'glow'{
    strength = ParamInfo.number(5, .1, 12),
    min_luma = ParamInfo.number(.7, 0, 1),
  },
  EffectInfo'godsray'{
    exposure = ParamInfo.number(.25, 0, 1),
    decay = ParamInfo.number(.95, 0, 1),
    density = ParamInfo.number(.15, 0, 1),
    weight = ParamInfo.number(.5, 0, 1),
    light_position = ParamInfo.vec2(.5,.5, 0,0, 1,1),
    samples = ParamInfo.int(70, 1, 150),
  },
  EffectInfo'pixelate'{
    size = ParamInfo.vec2(5,5, 0,0, 25,25),
    feedback = ParamInfo.number(0, 0, 1)
  },
  EffectInfo'posterize'{
    num_bands = ParamInfo.int(3, 1, 25)
  },
  EffectInfo'scanlines'{
    width = ParamInfo.number(1, 1, 10),
    phase = ParamInfo.number(0, 0, 2*math.pi),
    thickness = ParamInfo.number(1, 0, 5),
    opacity = ParamInfo.number(1, 0, 1),
    color = ParamInfo.RGB(0,0,0),
  },
  EffectInfo'sketch'{
    amp = ParamInfo.number(0.0007, 0, .007),
    center = ParamInfo.vec2(0,0, -25,-25, 25,25),
  },
  EffectInfo'vignette'{
    radius = ParamInfo.number(0.8, 0, 2),
    softness = ParamInfo.number(0.5, 0, 2),
    opacity = ParamInfo.number(0.5, 0, 1),
    color = ParamInfo.RGB(0,0,0),
  },
}

local effect, img
local function passthrough()
  return moonshine.Effect{
    name = 'Passthrough',
    draw = function(buffer)
      front, back = buffer()
      love.graphics.setCanvas(front)
      love.graphics.clear()
      love.graphics.draw(back)
    end
  }
end

function love.load()
  effect = moonshine(passthrough)
  img = love.graphics.newImage('haddaway.jpg')
  love.graphics.setFont(love.graphics.newFont('DejaVuSans.ttf', 12))
end

function build_chain()
  effect = moonshine(passthrough)
  for _, e in ipairs(effects) do
    if e.checked then
      effect.chain(moonshine.effects[e.text])
      for name, info in pairs(e.params) do
        effect[e.text][name] = info.val(info.state)
      end
    end
  end
end

local function gui_edit_chain()
  local update = false
  local switch = nil

  for i, e in ipairs(effects) do
    suit.layout:push(suit.layout:row(180,20))

    update = update or suit.Checkbox(e, suit.layout:col(140,20)).hit

    if i == 1 then
      suit.layout:col(20,20)
    elseif suit.Button('▲', {id = 'up-'..e.text}, suit.layout:col(20,20)).hit then
      switch = {i,i-1}
    end
    if i == #effects then
      suit.layout:col(20,20)
    elseif suit.Button('▼', {id = 'down-'..e.text}, suit.layout:col(20,20)).hit then
      switch = {i,i+1}
    end

    suit.layout:pop()
  end

  return update, switch
end

local function _tostring(x)
  if type(x) == 'table' then
    local t = {}
    for i,v in ipairs(t) do
      print(i,v)
      t[i] = _tostring(v)
    end
    return '{'..table.concat(t, ', ')..'}'
  end
  if x == nil then
    return ''
  end
  return tostring(x)
end
local function gui_edit_params()
  for i, e in ipairs(effects) do
    if e.checked then
      suit.Label(e.text..':', {align='left'}, suit.layout:row())
      for name, info in pairs(e.params) do
        suit.layout:push(suit.layout:row(195,20,2,3))
        suit.layout:col(10,16) -- padding
        suit.Label(name, {align='left'}, suit.layout:col(100))
        if info.widget(info.state, suit.layout:col(175)).changed then
          effect[e.text][name] = info.val(info.state)
        end
        suit.layout:pop()
      end
    end
  end
end

local show_edit_chain = {text = 'Edit chain', checked = true}
local show_edit_params = {text = 'Edit parameters', checked = true}
function love.update(dt)
  suit.layout:reset(10,10, 2,2)
  suit.Checkbox(show_edit_chain, suit.layout:row(180,20))

  if show_edit_chain.checked then
    local update, switch = gui_edit_chain()

    if switch then
      local i,k = unpack(switch)
      effects[i], effects[k] = effects[k], effects[i]
      update = true
    end

    if update then
      build_chain()
    end
  end

  suit.layout:reset(love.graphics.getWidth()-305,10, 2,2)
  suit.Checkbox(show_edit_params, suit.layout:row(300,20))
  if show_edit_params.checked then
    gui_edit_params()
  end
end

function love.draw()
  love.graphics.setColor(1,1,1)
  effect(function()
    love.graphics.draw(img)

    local t = love.timer.getTime()
    love.graphics.rectangle('fill', 300+math.sin(t)*300,200,100,100)
    love.graphics.push()
    love.graphics.translate(550,200)
    love.graphics.rotate(t)
    love.graphics.setColor(0.4,0.4,0.8)
    love.graphics.rectangle('fill', -100,-50,200,100)
    love.graphics.pop()
  end)

  love.graphics.setColor(0,0,0,0.8)
  -- background for chain editor
  local h = ((show_edit_chain.checked and #effects or 0) + 1) * 22 + 8
  love.graphics.rectangle('fill', 5,5, 195, h)

  -- background for parameter editor
  _,h = suit.layout:row()
  love.graphics.rectangle('fill', love.graphics.getWidth()-310,5, 305, h)

  suit.draw()
end

function love.textinput(t)
  suit.textinput(t)
end

function love.keypressed(key)
  suit.keypressed(key)
end
