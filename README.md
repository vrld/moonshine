# shine

Postprocessing in LÖVE made easy as pi.


## Usage:

```lua
local shine = require 'shine'

function love.load()
    -- load the effects you want
    local grain = shine.filmgrain()
    
    -- many effects can be parametrized
    grain.opacity = 0.2
    
    -- multiple parameters can be set at once
    local vignette = shine.vignette()
    vignette.parameters = {radius = 0.9, opacity = 0.7}
    
    -- you can also provide parameters on effect construction
    local desaturate = shine.desaturate{strength = 0.6, tint = {255,250,200}}
    
    -- you can chain multiple effects
    post_effect = desaturate:chain(grain):chain(vignette)

    -- warning - setting parameters affects all chained effects:
    post_effect.opacity = 0.5 -- affects both vignette and film grain

    -- more code here
end
    
function love.draw()
    -- wrap what you want to be post-processed in a function:
    post_effect:draw(function()
        draw()
        my()
        stuff()
    end)
    
    -- alternative syntax:
    -- post_effect(function()
    --     draw()
    --     my()
    --     stuff()
    -- end)
    
    -- everything you draw here will not be affected by the effect
end
```

## Documentation:

A full documentation including all included effects can be found in the [wiki](https://github.com/vrld/shine/wiki).


## Add your own effects:

Easy: create a new file that returns a table with:

 * a table `requires` that names the required graphics capabilities (shader, canvas, ...),
 * a function  `new(self)` that initialized the effect (creates canvas, shaders, ...),
 * a function `draw(self, func)` that applies the effect, and
 * a function `set(self, key, value)` to set parameters of the effect.

See the [wiki](https://github.com/vrld/shine/wiki) for more information.
