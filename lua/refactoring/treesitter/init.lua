local TreeSitter = require("refactoring.treesitter.treesitter")
local Typescript = require("refactoring.treesitter.typescript")

local M = {
    TreeSitter = TreeSitter,
    typescript = Typescript,
}

local function get_bufrn(bufnr)
    return bufnr or vim.api.nvim_get_current_buf()
end

function M.get_treesitter(bufnr)
    local ft = vim.bo[get_bufrn(bufnr)].ft
    return M[ft] and M[ft].new(bufnr, ft) or nil
end

return M
