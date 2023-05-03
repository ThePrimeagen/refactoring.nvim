local get_input = require("refactoring.get_input")

local M = {}

---@param refactor Refactor
---@return boolean, Refactor|string
function M.from_input(refactor)
    local file_name = get_input("Create File: Name > ", vim.fn.expand("%:h"))
    if not file_name then
        return false, "Error: Must provide a file name"
    end
    -- OPTIONS? We should probably configure this
    -- extract on second method added
    vim.cmd(":vnew")
    vim.cmd(string.format(":w! %s", file_name))
    vim.cmd(string.format(":set filetype=%s", refactor.filetype))
    table.insert(refactor.buffers, vim.api.nvim_get_current_buf())

    --TODO (TheLeoP): add text_edits for when extracting file (?) tsx exclusive (?)

    return true, refactor
end

return M
