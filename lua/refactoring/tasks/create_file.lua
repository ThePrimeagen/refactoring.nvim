local get_input = require("refactoring.get_input")

local M = {}

---@param refactor Refactor
---@return boolean, Refactor|string
function M.from_input(refactor)
    local file_name = get_input("Create File: Name > ", vim.fn.expand("%:h"))
    if not file_name or file_name == "" then
        return false, "Error: Must provide a file name"
    end

    local starting_win = vim.api.nvim_get_current_win()

    local new_bufnr = vim.fn.bufnr(vim.fn.expand(file_name))
    local new_winnr = vim.fn.bufwinnr(new_bufnr)
    if new_winnr == -1 then
        -- OPTIONS? We should probably configure this
        -- extract on second method added
        vim.cmd.vsplit(file_name)
        vim.opt_local.filetype = refactor.filetype
    else
        vim.cmd.wincmd({ args = { "w" }, count = new_winnr })
    end
    table.insert(refactor.buffers, vim.api.nvim_get_current_buf())

    vim.api.nvim_set_current_win(starting_win)
    return true, refactor
end

return M
