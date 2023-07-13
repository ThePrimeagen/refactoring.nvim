local get_input = require("refactoring.get_input")

local M = {}

---@param refactor Refactor
---@return boolean, Refactor|string
function M.from_input(refactor)
    local file_name = get_input("Create File: Name > ", vim.fn.expand("%:h"))
    if not file_name or file_name == "" then
        return false, "Error: Must provide a file name"
    end

    local bufnr = vim.fn.bufnr(vim.fn.expand(file_name))
    local winnr = vim.fn.bufwinnr(bufnr)
    if winnr == -1 then
        -- OPTIONS? We should probably configure this
        -- extract on second method added
        vim.cmd.vsplit(file_name)
        vim.opt_local.filetype = refactor.filetype
    else
        vim.cmd.wincmd({ args = { "w" }, count = winnr })
    end
    table.insert(refactor.buffers, vim.api.nvim_get_current_buf())

    --TODO (TheLeoP): add text_edits for when extracting file (?) tsx exclusive (?)

    return true, refactor
end

return M
