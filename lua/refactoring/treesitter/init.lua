local TreeSitter = require("refactoring.treesitter.treesitter")
local Typescript = require("refactoring.treesitter.typescript")
local Golang = require("refactoring.treesitter.golang")
local Lua = require("refactoring.treesitter.lua")
local Python = require("refactoring.treesitter.python")
local JavaScript = require("refactoring.treesitter.javascript")
local Ruby = require("refactoring.treesitter.ruby")

local M = {
    TreeSitter = TreeSitter,
    javascript = JavaScript,
    typescript = Typescript,
    python = Python,
    go = Golang,
    lua = Lua,
    ruby = Ruby,
}

local DefaultSitter = {}

function DefaultSitter.new(bufnr, ft)
    return TreeSitter:new({
        version = 0,
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
