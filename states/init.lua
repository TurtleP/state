local path = (...):gsub('%.init$', '')

local module = {}

-- current is a table {name, cache, args}
module.data = {states = {}, current = {}}

local love_events =
{
    "update",
    "gamepadpressed",
    "gamepadaxis",
    "gamepadreleased",
    "keypressed",
    "keyreleased",
    "mousepressed",
    "mousereleased",
    "wheelmoved",
    "focus",
    "visible",
    "quit",
    "touchpressed",
    "touchmoved",
    "touchreleased",
    "textinput"
}

-- functions based on batteries.lua
-- see https://github.com/1bardesign/batteries
local function table_find_in(t, find)
    for index, value in ipairs(t) do
        if value == find then
            return index
        end
    end
    return false
end

local function table_remove_value(t, find)
    local index = table_find_in(t, find)
    if index then
        table.remove(t, index)
        return true
    end
    return false
end

local function table_splat(t, f)
    local result = {}
    for index = 1, #t do
        local v, pos = f(t[index], index)
        if v ~= nil then
            pos = (pos and pos) or #result + 1
            result[pos] = v
        end
    end
end
---

if not love._console_name then
    table.insert(love_events, "draw")
else
    local function getDepth(screen)
        if love.graphics.get3DDepth then
            return screen ~= "bottom" and love.graphics.get3DDepth() or nil
        end
        return 0
    end

    local screens = {"top", "left", "right"}

    function module.draw(screen)
        local depth = getDepth(screen)

        if screen == "right" then
            depth = -depth
        end

        if module._has_method("drawTop") and module._has_method("drawBottom") then
            if table_find_in(screens, screen) then
                return module._call_method("drawTop", depth)
            end
            return module._call_method("drawBottom")
        end
        return module._call_method("draw", screen, depth)
    end
end

local Error = {}
Error.STATE_NOT_A_TABLE    = "target state '%s' is not a table."
Error.STATE_DOES_NOT_EXIST = "target state '%s' does not exist."
Error.FUNC_DOES_NOT_EXIST  = "current state function '%s' does not exist."

local function fail(errno, ...)
    local str = nil
    if errno == -1 then
        str = Error.STATE_NOT_A_TABLE
    elseif errno == -2 then
        str = Error.STATE_DOES_NOT_EXIST
    elseif errno == -3 then
        str = Error.FUNC_DOES_NOT_EXIST
    end
    return string.format(str, ...)
end

-- Initialize the state module
function module.init(exclusions)
    assert(type(exclusions) == "table" or not exclusions, "exclusions must be a table or nil, got " .. type(exclusions))

    local states = love.filesystem.getDirectoryItems(path)
    table_remove_value(states, "init.lua")

    module.data.states = table_splat(states, function(value)
        local name = value:gsub(".lua", "")
        local success, error_or_state_table = pcall(require, path .. "." .. name)

        if success then
            return error_or_state_table, name
        end
        return error(error_or_state_table)
    end)

    -- remove exclusions
    if exclusions then
        for _, callback in ipairs(exclusions) do
            table_remove_value(love_events, callback)
        end
    end

    -- hook love events we want into the states
    for _, callback in ipairs(love_events) do
        print(callback)
        module[callback] = function(...)
            if module._has_method(callback) then
                module._call_method(callback, ...)
            end
        end
    end

    return module
end

-- public methods

--[[
Switch to a new state with a given name and args
 - @param name Name of the state to change to
 - @param ... Variadic args to pass to the `enter` function
--]]
function module.switch(name, ...)
    local target = module.data.states[name]

    assert:some(target, fail(-2, name))
    assert:type(target, "table", fail(-1, name))

    if module._current() then
        module._call_method("exit")
    end

    module.data.current = {name = name, table = target, args = ...}

    module._call_method("enter", ...)
end

-- Resets the state to the beginning
function module.reset()
    assert(module._current() ~= nil)
    module.switch(module.data.current.name, module.data.current.args)
end

-- private methods

-- Gets the current state
function module._current()
    return module.data.current.name ~= "" and module.data.current.table
end

--[[
Check if the current state has a method
 - @param name Name of the method as a string
--]]
function module._has_method(name)
    local current_state = assert(module._current() ~= nil)
    return current_state[name] and current_state
end

--[[
Calls a method for the current state
 - @param name Name of the method to call
 - @param ... Variadic args to pass to the method
--]]
function module._call_method(name, ...)
    local target = module._has_method(name)
    assert(target ~= nil, fail(-3, name))

    target[name](target, ...)
end

return module
