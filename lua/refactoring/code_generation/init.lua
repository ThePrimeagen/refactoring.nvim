local javascript = require("refactoring.code_generation.langs.javascript")
local typescript = require("refactoring.code_generation.langs.typescript")
local typescriptreact =
    require("refactoring.code_generation.langs.typescriptreact")
local vue = require("refactoring.code_generation.langs.vue")
local lua = require("refactoring.code_generation.langs.lua")
local go = require("refactoring.code_generation.langs.go")
local cpp = require("refactoring.code_generation.langs.cpp")
local c = require("refactoring.code_generation.langs.c")
local python = require("refactoring.code_generation.langs.python")
local php = require("refactoring.code_generation.langs.php")
local java = require("refactoring.code_generation.langs.java")
local cs = require("refactoring.code_generation.langs.cs")
local ruby = require("refactoring.code_generation.langs.ruby")

---@type table<ft, code_generation>|{new_line: fun(): string}
local M = {
    javascript = javascript, -- includes jsx because they share parser
    typescript = typescript,
    tsx = typescriptreact,

    vue = vue,
    lua = lua,
    go = go,
    cpp = cpp,
    c = c,
    python = python,
    php = php,
    java = java,
    c_sharp = cs,
    ruby = ruby,
    default = {},

    -- TODO: Take this and make all code generation subclassed.
    -- This should just be a function of code generation.
    new_line = function()
        return "\n"
    end,
}

return M
