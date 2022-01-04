local javascript = require("refactoring.code_generation.javascript")
local typescript = require("refactoring.code_generation.typescript")
local lua = require("refactoring.code_generation.lua")
local go = require("refactoring.code_generation.go")
local cpp = require("refactoring.code_generation.cpp")
local c = require("refactoring.code_generation.c")
local python = require("refactoring.code_generation.python")
local php = require("refactoring.code_generation.php")

local M = {
    javascript = javascript,
    typescript = typescript,
    lua = lua,
    go = go,
    cpp = cpp,
    c = c,
    python = python,
    php = php,

    -- TODO: Take this and make all code generation subclassed.
    -- This should just be a function of code generation.
    new_line = function()
        return "\n"
    end,
}

return M
