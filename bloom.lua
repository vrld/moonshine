return {
requires = {'canvas', 'shader'},
description = "Bloom effect",

new = function(self)
    self.canvas = love.graphics.newCanvas()
    self.shader = love.graphics.newShader[[
        extern vec2 size;
        extern number samples = 5;
        extern number quality = 2.5;
         
        vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
        {
            vec4 source = Texel(tex, tc);
            vec4 sum = vec4(0);
            number diff = (samples - 1) / 2;
            vec2 sizeFactor = vec2(1) / size * quality;
          
            for (number x = -diff; x <= diff; x++)
            {
                for (number y = -diff; y <= diff; y++)
                {
                    vec2 offset = vec2(x, y) * sizeFactor;
                    sum += Texel(tex, tc + offset);
                }
            }
          
            return ((sum / (samples * samples)) + source) * color;
        }

    ]]
    self.shader:send("size", {love.graphics.getWidth(), love.graphics.getHeight()})
    self.shader:send("samples", 5)
    self.shader:send("quality", 2.5)
end,

draw = function(self, func)
    self:_apply_shader_to_scene(self.shader, self.canvas, func)
end,

set = function(self, key, value)
    if key == "samples" then
        self.shader:send("samples", value)
    elseif key == "quality" then
        self.shader:send("quality", math.max(0, math.min(10, tonumber(value) or 0)))
    elseif key == "size" then
        assert(type(value) == "table")
        self.shader:send("size", value)
    else
        error("Unknown property: " .. tostring(key))
    end

    return self
end
}
