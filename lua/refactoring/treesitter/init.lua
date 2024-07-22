local TreeSitter = require("refactoring.treesitter.treesitter")
local Typescript = require("refactoring.treesitter.langs.typescript")
local TypescriptReact = require("refactoring.treesitter.langs.typescriptreact")
local JavascriptReact = require("refactoring.treesitter.langs.javascriptreact")
local Cpp = require("refactoring.treesitter.langs.cpp")
local C = require("refactoring.treesitter.langs.c")
local go = require("refactoring.treesitter.langs.go")
local Lua = require("refactoring.treesitter.langs.lua")
local Python = require("refactoring.treesitter.langs.python")
local JavaScript = require("refactoring.treesitter.langs.javascript")
local php = require("refactoring.treesitter.langs.php")
local java = require("refactoring.treesitter.langs.java")
local cs = require("refactoring.treesitter.langs.cs")
local ruby = require("refactoring.treesitter.langs.ruby")

---@class TreeSitterInstance: TreeSitter
---@field new fun(bufnr: integer, ft: string): TreeSitter

---@type table<string, TreeSitter|TreeSitterInstance|fun(bufnr: integer|nil): TreeSitter>
local M = {
    TreeSitter = TreeSitter,
    javascript = JavaScript,
    typescript = Typescript,
    typescriptreact = TypescriptReact,
    javascriptreact = JavascriptReact,
    python = Python,
    go = go,
    lua = Lua,
    php = php,
    java = java,
    cs = cs,
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

---@param bufnr integer
---@param ft string
---@return TreeSitter
function DefaultSitter.new(bufnr, ft)
    return TreeSitter:new({
        filetype = ft,
        bufnr = bufnr,
    }, bufnr)
end

function M.get_treesitter(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local ft = vim.bo[bufnr].ft
    return M[ft] and M[ft].new(bufnr, ft) or DefaultSitter.new(bufnr, ft)
end

return M
