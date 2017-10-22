--[[
The MIT License (MIT)

Original code: Copyright (c) 2015 Josef Patoprsty
Port to moonshine: Copyright (c) 2017 Matthias Richter <vrld@vrld.org>

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

local palettes = {
  -- Default color palette. Source:
  -- http://en.wikipedia.org/wiki/List_of_video_game_console_palettes#Original_Game_Boy
  {
    name = "default",
    colors = {
      { 15/255, 56/255, 15/255},
      { 48/255, 98/255, 48/255},
      {139/255,172/255, 15/255},
      {155/255,188/255, 15/255}
    }
  },
  -- Hardcore color profiles. Source:
  -- http://www.hardcoregaming101.net/gbdebate/gbcolours.htm
  {
    name = "dark_yellow",
    colors = {
      {33/255,32/255,16/255},
      {107/255,105/255,49/255},
      {181/255,174/255,74/255},
      {255/255,247/255,123/255}
    }
  },
  {
    name = "light_yellow",
    colors = {
      {102/255,102/255,37/255},
      {148/255,148/255,64/255},
      {208/255,208/255,102/255},
      {255/255,255/255,148/255}
    }
  },
  {
    name = "green",
    colors = {
      {8/255,56/255,8/255},
      {48/255,96/255,48/255},
      {136/255,168/255,8/255},
      {183/255,220/255,17/255}
    }
  },
  {
    name = "greyscale",
    colors = {
      {56/255,56/255,56/255},
      {117/255,117/255,117/255},
      {178/255,178/255,178/255},
      {239/255,239/255,239/255}
    }
  },
  {
    name = "stark_bw",
    colors = {
      {0/255,0/255,0/255},
      {117/255,117/255,117/255},
      {178/255,178/255,178/255},
      {255/255,255/255,255/255}
    }
  },
  {
    name = "pocket",
    colors = {
      {108/255,108/255,78/255},
      {142/255,139/255,87/255},
      {195/255,196/255,165/255},
      {227/255,230/255,201/255}
    }
  }
}

local lookup_palette = function(name)
  for _,palette in pairs(palettes) do
    if palette.name == name then
      return palette
    end
  end
end

local is_valid_palette = function(v)
  -- Needs to match: {{R,G,B},{R,G,B},{R,G,B},{R,G,B}}
  if #v ~= 4 then return false end

  for i = 1,4 do
    if type(v[i]) ~= "table" or #v[i] ~= 3 then return false end
    for c = 1,3 do
      if type(v[i][c]) ~= "number" then return false end
      local x = v[i][c]
      if x > 1 then x = x / 255 end
      if x < 0 or x > 1 then return false end
      v[i][c] = x
    end
  end
  return true
end

return function(moonshine)
  local shader = love.graphics.newShader[[
    extern vec3 palette[ 4 ];

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
      vec4 pixel = Texel(texture, texture_coords);
      float avg = min(0.9999,max(0.0001,(pixel.r + pixel.g + pixel.b)/3));
      int index = int(avg*4);
      return vec4(palette[index], pixel.a);
    }]]

  local setters = {}
  setters.palette = function(v)
    if type(v) == "number" and palettes[math.floor(v)] then -- indexed palette
      palette = palettes[math.floor(v)]
    elseif type(v) == "string" then -- named palette
      palette = lookup_palette(v)
    elseif type(v) == "table" and is_valid_palette(v) then -- custom palette
      palette = {colors=v}
    else -- Fall back to default
      palette = palettes[1]
    end
    shader:send("palette", palette.colors[1], palette.colors[2],
                           palette.colors[3], palette.colors[4], {})
  end

  return moonshine.Effect{
    name = "dmg",
    shader = shader,
    setters = setters,
    defaults = {palette = "default"}
  }
end
