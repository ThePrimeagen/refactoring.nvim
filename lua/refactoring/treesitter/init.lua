local TreeSitter = require("refactoring.treesitter.treesitter")
local Typescript = require("refactoring.treesitter.langs.typescript")
local Cpp = require("refactoring.treesitter.langs.cpp")
local C = require("refactoring.treesitter.langs.c")
local go = require("refactoring.treesitter.langs.go")
local Lua = require("refactoring.treesitter.langs.lua")
local Python = require("refactoring.treesitter.langs.python")
local JavaScript = require("refactoring.treesitter.langs.javascript")
local php = require("refactoring.treesitter.langs.php")
local java = require("refactoring.treesitter.langs.java")
local ruby = require("refactoring.treesitter.langs.ruby")

local M = {
    TreeSitter = TreeSitter,
    javascript = JavaScript,
    typescript = Typescript,
    python = Python,
    go = go,
    lua = Lua,
    php = php,
    java = java,
    ruby = ruby,

    -- Why so many...
    cc = Cpp,
    cxx = Cpp,
    cpp = Cpp,
    h = Cpp,
    hpp = Cpp,
    c = C,
}

local DefaultSitter = {}

function DefaultSitter.new(bufnr, ft)
    return TreeSitter:new({
        filetype = ft,
        bufnr = bufnr,
    }, bufnr)
end

local function get_bufrn(bufnr)
    return bufnr or vim.api.nvim_get_current_buf()
end

function M.get_treesitter(bufnr)
    bufnr = get_bufrn(bufnr)

    local ft = vim.bo[bufnr].ft
    return M[ft] and M[ft].new(bufnr, ft) or DefaultSitter.new(bufnr, ft)
end

return M
