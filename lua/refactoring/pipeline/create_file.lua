local get_input = require("refactoring.get_input")

local M = {}

function M.from_input(refactor)
    local file_name = get_input("106: File Name > ", vim.fn.expand("%:h"))
    -- OPTIONS? We should probably configure this
    -- extract on second method added
    vim.cmd(":vnew")
    vim.cmd(string.format(":set filetype=%s", refactor.filetype))
    vim.cmd(string.format(":w! %s", file_name))
    table.insert(refactor.buffers, vim.fn.bufnr())

    return true, refactor
end

return M
