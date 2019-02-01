# moonshine

Chainable post-processing shaders for LÖVE.

## Overview

* [Getting started](#getting-started)
* [General usage](#general-usage)
* [List of effects](#list-of-effects)
* [Writing effects](#writing-effects)
* [License](#license)

<a name="getting-started"></a>
## Getting started

Clone this repository into your game folder:

    git clone https://github.com/vrld/moonshine.git

This will create the folder `moonshine`.

In your `main.lua`, or wherever you load your libraries, add the following:

```lua
local moonshine = require 'moonshine'
```

Create and parametrize the post-processing effect in `love.load()`, for example:

```lua
function love.load()
  effect = moonshine(moonshine.effects.filmgrain)
                    .chain(moonshine.effects.vignette)
  effect.filmgrain.size = 2
end
```

Lastly, wrap the things you want to be drawn with the effect inside a function:

```lua
function love.draw()
    effect(function()
      love.graphics.rectangle("fill", 300,200, 200,200)
    end)
end
```

When you package your game for release, you might want consider deleting the
(hidden) `.git` folder in the moonshine directory.


<a name="general-usage"></a>
## General usage

The main concept behind moonshine are chains. A chain consists of one or more
effects. Effects that come later in the chain will be applied to the result of
the effects that come before. In the example above, the vignette is drawn on
top of the filmgrain.

### Chains

Chains are created using the `moonshine.chain` function:

```lua
chain = moonshine.chain(effect)
```

For convenience, `moonshine(effect)` is an alias to `moonshine.chain(effect)`.
You can add new effects to a chain using

```lua
chain = chain.chain(another_effect)
```

or using `chain.next()`, which is an alias to `chain.chain()`.
As the function returns the chain, you can specify your whole chain in one go,
as shown in the example above.

### Effects and effect parameters

The effects that come bundled with moonshine (see [List of effects](#list-of-effects))
are accessed by `chain.effects.<effect-name>`, e.g.,

```lua
moonshine.effects.glow
```

Most effects are parametrized to change how they look. In the example above,
the size of the grains was set to 2 pixels (the default is 1 pixel).
Effect parameters are set by first specifying the name of the effect and then
the name of the parameter:

```lua
chain.<effect>.<parameter> = <value>
```

For example, if `chain` contained the `glow` and `crt` effects, you can set the
glow `strength` parameter and crt `distortionFactor` parameter as such:

```lua
chain.glow.strength = 10
chain.crt.distortionFactor = {1.06, 1.065}
```

Because you likely initialize a bunch of parameters at once, you can set all
parameters with the special key `parameters` (or `params` or `settings`). This
is equivalent to the above:

```lua
chain.parameters = {
  glow = {strength = 10},
  crt = {distortionFactor = {1.06, 1.065}},
}
```

Note that this will only set the parameters specified in the table. The crt
parameter `feather`, for example, will be left untouched.

### Drawing effects

Creating effects and setting parameters is fine, but not very useful on its
own. You also need to apply it to something. This is done using `chain.draw()`:

```lua
chain.draw(func, ...)
```

This will apply the effect to everything that is drawn inside `func(...)`.
Everything that is drawn outside of `func(...)` will not be affected. For
example,

```lua
love.graphics.draw(img1, 0,0)
chain.draw(function()
  love.graphics.draw(img2, 200,0)
end)
love.graphics.draw(img3, 400,0)
```

will apply the effect to `img2`, but not to `img1` and `img3`. Note that some
effects (like filmgrain) draw on the whole screen. So if in this example `chain`
would consist of a gaussianblur and filmgrain effect, `img1` will be covered
with grain, but will not be blurred, `img2` will get both effects, and `img3`
will be left untouched.

Similar to chain creation, `chain(func, ...)` is an alias to the more verbose
`chain.draw(func, ...)`.

### Temporarily disabling effects

You can disable effects in a chain by using `chain.disable(names...)` and
`chain.enable(names...)`.
For example,

```lua
effect = moonshine(moonshine.effects.boxblur)
                  .chain(moonshine.effects.filmgrain)
                  .chain(moonshine.effects.vignette)
effect.disable("boxblur", "filmgrain")
effect.enable("filmgrain")
```

would first disable the boxblur and filmgrain effect, and then enable the
filmgrain again.
Note that the effects are still in the chain, they are only not drawn.

### Canvas size

You can change the size of the internal canvas, for example when the window was
resized, by calling `chain.resize(width, height)`.
Do this anytime you want, but best not during `chain.draw()`.

You can also specify the initial canvas size by starting the chain like this:

```lua
effect = moonshine(400,300, moonshine.effects.vignette)
```

That is, you specify the width and height before the first effect in the chain.

### Is this efficient?

Of course, using moonshine is not as efficient as writing your own shader that
does all the effects you want in the least amount of passes, but moonshine
tries to minimize the overhead.

On the other hand, you don't waste time writing the same shader over and over
again when using moonshine: You're trading a small amount of computation time
for a large amount of development time.


<a name="list-of-effects"></a>
## List of effects

Currently, moonshine contains the following effects (in alphabetical order):

* [boxblur](#effect-boxblur): simple blurring
* [chromasep](#effect-chromasep): cheap/fake chromatic aberration
* [colorgradesimple](#effect-colorgradesimple): weighting of color channels
* [crt](#effect-crt): crt/barrel distortion
* [desaturate](#effect-desaturate): desaturation and tinting
* [dmg](#effect-dmg): Gameboy and other four color palettes
* [fastgaussianblur](#effect-fastgaussianblur): faster Gaussian blurring
* [filmgrain](#effect-filmgrain): image noise
* [gaussianblur](#effect-gaussianblur): Gaussian blurring
* [glow](#effect-glow): aka (light bloom
* [godsray](#effect-godsray): aka light scattering
* [pixelate](#effect-pixelate): sub-sampling (for that indie look)
* [posterize](#effect-posterize): restrict number of colors
* [scanlines](#effect-scanlines): horizontal lines
* [sketch](#effect-sketch): simulate pencil drawings
* [vignette](#effect-vignette): shadow in the corners


<a name="effect-boxblur"></a>
### boxblur

```lua
moonshine.effects.boxblur
```

**Parameters:**

Name | Type | Default
-----|------|--------
radius | number or table of numbers | {3,3}
radius_x | number | 3
radius_y | number | 3


<a name="effect-chromasep"></a>
### chromasep

```lua
moonshine.effects.chromasep
```

**Parameters:**

Name | Type | Default
-----|------|--------
angle | number (in radians) | 0
radius | number | 0


<a name="effect-colorgradesimple"></a>
### colorgradesimple

```lua
moonshine.effects.colorgradesimple
```

**Parameters:**

Name | Type | Default
-----|------|--------
factors | table of numbers | {1,1,1}


<a name="effect-crt"></a>
### crt

```lua
moonshine.effects.crt
```

**Parameters:**

Name | Type | Default
-----|------|--------
distortionFactor | table of numbers | {1.06, 1.065}
x | number | 1.06
y | number | 1.065
scaleFactor | number or table of numbers | {1,1}
feather | number | 0.02


<a name="effect-desaturate"></a>
### desaturate

```lua
moonshine.effects.desaturate
```

**Parameters:**

Name | Type | Default
-----|------|--------
tint | color / table of numbers | {255,255,255}
strength | number between 0 and 1 | 0.5


<a name="effect-dmg"></a>
### dmg

```lua
moonshine.effects.dmg
```

Name | Type | Default
-----|------|--------
palette | number or string or table of table of numbers | "default"

DMG ships with 7 palettes:

1. `default`
2. `dark_yellow`
3. `light_yellow`
4. `green`
5. `greyscale`
6. `stark_bw`
7. `pocket`

Custom palettes must be in the format `{{R,G,B}, {R,G,B}, {R,G,B}, {R,G,B}}`,
where `R`, `G`, and `B` are numbers between `0` and `255`.


<a name="effect-fastgaussianblur"></a>
### fastgaussianblur

```lua
moonshine.effects.fastgaussianblur
```

**Parameters:**

Name | Type | Default
-----|------|--------
taps | odd number >= 3 | 7 | (amount of blur)
offset | number | 1
sigma | number | -1


<a name="effect-filmgrain"></a>
### filmgrain

```lua
moonshine.effects.filmgrain
```

**Parameters:**

Name | Type | Default
-----|------|--------
opacity | number | 0.3
size | number | 1


<a name="effect-gaussianblur"></a>
### gaussianblur

```lua
moonshine.effects.gaussianblur
```

**Parameters:**

Name | Type | Default
-----|------|--------
sigma | number | 1 | (amount of blur)


<a name="effect-glow"></a>
### glow

```lua
moonshine.effects.glow
```

**Parameters:**

Name | Type | Default
-----|------|--------
min_luma | number between 0 and 1 | 0.7
strength | number >= 0 | 5


<a name="effect-godsray"></a>
### godsray

```lua
moonshine.effects.godsray
```

**Parameters:**

Name | Type | Default
-----|------|--------
exposire | number between 0 and 1 | 0.5
decay | number between 0 and 1 | 0.95
density | number between 0 and 1 | 0.05
weight | number between 0 and 1 | 0.5
light_position | table of two numbers | {0.5, 0.5}
light_x | number | 0.5
light_y | number | 0.5
samples | number >= 1 | 70


<a name="effect-pixelate"></a>
### pixelate

```lua
moonshine.effects.pixelate
```

**Parameters:**

Name | Type | Default
-----|------|--------
size | number or table of two numbers | {5,5}
feedback | number between 0 and 1 | 0


<a name="effect-posterize"></a>
### posterize

```lua
moonshine.effects.posterize
```

**Parameters:**

Name | Type | Default
-----|------|--------
num_bands | number >= 1 | 3


<a name="effect-scanlines"></a>
### scanlines

```lua
moonshine.effects.scanlines
```

**Parameters:**

Name | Type | Default
-----|------|--------
width | number | 2
frequency | number | screen-height
phase | number | 0
thickness | number | 1
opacity | number | 1
color | color / table of numbers | {0,0,0}


<a name="effect-sketch"></a>
### sketch

```lua
moonshine.effects.sketch
```

**Parameters:**

Name | Type | Default
-----|------|--------
amp | number | 0.0007
center | table of numbers | {0,0}


<a name="effect-vignette"></a>
### vignette

```lua
moonshine.effects.vignette
```

**Parameters:**

Name | Type | Default
-----|------|--------
radius | number > 0 | 0.8
softness | number > 0 | 0.5
opacity | number > 0 | 0.5
color | color / table of numbers | {0,0,0}

<a name="effect-fog"></a>
### fog

```lua
moonshine.effects.fog
```

**Parameters:**

Name | Type | Default
-----|------|--------
fog_color | color/table of numbers | {0.35, 0.48, 0.95}
octaves | number > 0 | 4
speed | vec2/table of numbers | {0.5, 0.5}


<a name="writing-effects"></a>
## Writing effects

An effect is essentially a function that returns a `moonshine.Effect{}`, which
must specify at least a `name` and a `shader` or a `draw` function.

It may also specify a `setters` table that contains functions that set the
effect parameters and a `defaults` table with the corresponding default values.
The default values will be set when the effect is instantiated.

A good starting point to see how to write effects is the `colorgradesimple`
effect, which uses the `shader`, `setters` and `defaults` fields.

Moonshine uses double buffering to draw the effects. A function to swap and
access the buffers is provided to the `draw(buffer)` function of your effect:

```lua
front, back = buffer() -- swaps front and back buffer and returns both
```

You don't have to care about canvases or restoring defaults, moonshine handles
all that for you.

If you only need a custom draw function because your effect needs multiple
shader passes, moonshine provides the `draw_shader(buffer, shader)` function.
As you might have guessed, this function uses `shader` to draw the front buffer
to the back buffer. The `boxblur` effect gives a simple example how to use this
function.

If for some reason you need more than two buffer, you are more or less on your
own. You can do everything, but make sure that the blend mode and the order of
back and front buffer is the same before and after your custom `draw` function.
The `glow` effect gives an example of a more complicated `draw` function.


<a name="license"></a>
## License

See [here](https://github.com/vrld/moonshine/graphs/contributors) for a list of
contributors.

The main library can freely be used under the following conditions:

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

Most of the effects are public domain (see comments inside the files):

* boxblur.lua
* chromasep.lua
* colorgradesimple.lua
* crt.lua
* desaturate.lua
* filmgrain.lua
* gaussianblur.lua
* glow.lua
* pixelate.lua
* posterize.lua
* scanlines.lua
* vignette.lua

These effects are MIT-licensed with multiple authors:

* dmg.lua: Joseph Patoprsty, Matthias Richter
* fastgaussianblur.lua: Tim Moore, Matthias Richter
* godsray.lua: Joseph Patoprsty, Matthias Richter. Based on work by ioxu, Fabien Sanglard, Kenny Mitchell and Jason Mitchell.
* sketch.lua: Martin Felis, Matthias Richter
* fog.lua: Brandon Blanker Lim-it. Based on work by Gonkee.
