## States

A simple state management system for LÖVE games.

## Installation

### Simple

1. Copy the contents of `states/init.lua`.
2. Create a `states` folder in your project.
3. Create a new file,  `init.lua` and paste the contents of the file from step 1.

### Alternative

1. Clone (or download the repository as a zip) to a directory of your choosing.
2. Copy the `states` folder to your project root directory.

### Usage

Once this is installed, simply `require` the `states` folder and call `init` :

```lua
local states = require("states").init()
```

You can also pass an table of strings for callbacks to exclude. By default, most callbacks that LÖVE provides will be hooked into.

The `draw` method can be split if running LÖVE Potion on Nintendo 3DS between `drawTop` and `drawBottom` . The first will render the top screen and pass the current 3D depth (aka the stereoscopic 3D slider value, 0 ~ 1). This is always zero on LÖVE, since it's not possible to emulate this behavior. If neither of those methods exist, however, it will result in calling `draw` with the `screen` and `depth` parameters. The `screen` parameter points to `left` , `right` , or `bottom` when 3D is enabled, `top` and `bottom` when disabled.

Once the table is returned, simply call the function from your `main.lua` 's LÖVE callbacks.

```lua
function love.update(dt)
    states.update(dt)
end

function love.draw()
    states.draw()
end
```

States must be tables that are returned from their respective Lua files. Entering a new state will call its `enter` method, changing states calls its `exit` method. You can use these to allocate and free resources dedicated to state.

### API

#### `states.switch(name, ...)`

_Switch to a new state, `name` with varargs `...`_

 - @param `name` : `string` - Name of the state to switch to, which is also the filename (without the lua extension)
 - @param `...` : `varargs` - Any arguments you wish to pass to the new state

#### `states.reset()`

_Resets the state to its beginning values_
