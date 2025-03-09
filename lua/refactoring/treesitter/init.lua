local TreeSitter = require("refactoring.treesitter.treesitter")
local Typescript = require("refactoring.treesitter.langs.typescript")
local TypescriptReact = require("refactoring.treesitter.langs.typescriptreact")
local Cpp = require("refactoring.treesitter.langs.cpp")
local C = require("refactoring.treesitter.langs.c")
local vue = require("refactoring.treesitter.langs.vue")
local go = require("refactoring.treesitter.langs.go")
local Lua = require("refactoring.treesitter.langs.lua")
local Python = require("refactoring.treesitter.langs.python")
local JavaScript = require("refactoring.treesitter.langs.javascript")
local php = require("refactoring.treesitter.langs.php")
local java = require("refactoring.treesitter.langs.java")
local cs = require("refactoring.treesitter.langs.cs")
local ruby = require("refactoring.treesitter.langs.ruby")

local api = vim.api
local ts = vim.treesitter

---@class refactor.TreeSitterInstance: refactor.TreeSitter
---@field new fun(bufnr: integer, ft: string): refactor.TreeSitter

---@type table<string, refactor.TreeSitter|refactor.TreeSitterInstance|fun(bufnr: integer|nil): refactor.TreeSitter, string>
local M = {
    TreeSitter = TreeSitter,
    javascript = JavaScript, -- includes jsx because they use the same parser
    typescript = Typescript,
    tsx = TypescriptReact,
    vue = vue,
    python = Python,
    go = go,
    lua = Lua,
    php = php,
    java = java,
    c_sharp = cs,
    ruby = ruby,

    -- Why so many...
    cpp = Cpp,
    c = C,
}

local DefaultSitter = {}

---@param bufnr integer
---@param ft string
---@return refactor.TreeSitter
function DefaultSitter.new(bufnr, ft)
    return TreeSitter:new({
        filetype = ft,
        bufnr = bufnr,
    }, bufnr)
end

function M.get_treesitter(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()

    local cursor = api.nvim_win_get_cursor(0)
    local range = {
        cursor[1] - 1,
        cursor[2],
        cursor[1] - 1,
        cursor[2] + 1,
    }
    local language_tree = ts.get_parser(bufnr)
    language_tree:parse(true)

    local nested_tree = language_tree:language_for_range(range)
    local lang = nested_tree:lang()

    local treesitter = M[lang] and M[lang].new(bufnr, lang)
        or DefaultSitter.new(bufnr, lang)

    treesitter.language_tree = nested_tree
    return treesitter, lang
end

return M
