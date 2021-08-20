local javascript = require("refactoring.code_generation.javascript")
local typescript = require("refactoring.code_generation.typescript")
local lua = require("refactoring.code_generation.lua")
local go = require("refactoring.code_generation.go")
local python = require("refactoring.code_generation.python")

local M = {
    javascript = javascript,
    typescript = typescript,
    lua = lua,
    go = go,
    python = python,
}

return M
