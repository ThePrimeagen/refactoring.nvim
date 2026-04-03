local TreeSitter = require("refactoring.treesitter.treesitter")
local typescript = require("refactoring.treesitter.langs.typescript")
local typescriptReact = require("refactoring.treesitter.langs.typescriptreact")
local cpp = require("refactoring.treesitter.langs.cpp")
local c = require("refactoring.treesitter.langs.c")
local vue = require("refactoring.treesitter.langs.vue")
local go = require("refactoring.treesitter.langs.go")
local lua = require("refactoring.treesitter.langs.lua")
local python = require("refactoring.treesitter.langs.python")
local javaScript = require("refactoring.treesitter.langs.javascript")
local php = require("refactoring.treesitter.langs.php")
local java = require("refactoring.treesitter.langs.java")
local cs = require("refactoring.treesitter.langs.cs")
local ruby = require("refactoring.treesitter.langs.ruby")
local powershell = require("refactoring.treesitter.langs.powershell")
local vimscript = require("refactoring.treesitter.langs.vimscript")
local dart = require("refactoring.treesitter.langs.dart")
local api = vim.api
local ts = vim.treesitter

---@class refactor.TreeSitterInstance: refactor.TreeSitter
---@field new fun(bufnr: integer, ft: string): refactor.TreeSitter

---@type table<string, refactor.TreeSitter|refactor.TreeSitterInstance|fun(bufnr: integer|nil): refactor.TreeSitter, string>
local M = {
    TreeSitter = TreeSitter,
    javascript = javaScript, -- includes jsx because they use the same parser
    typescript = typescript,
    tsx = typescriptReact,
    vue = vue,
    python = python,
    go = go,
    lua = lua,
    php = php,
    java = java,
    c_sharp = cs,
    ruby = ruby,
    dart = dart,

    cpp = cpp,
    c = c,

    powershell = powershell,
    vim = vimscript,
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
