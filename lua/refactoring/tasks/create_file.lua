local get_input = require("refactoring.get_input")

local M = {}

---@param refactor Refactor
function M.from_input(refactor)
    local file_name = get_input("Create File: Name > ", vim.fn.expand("%:h"))
    assert(file_name ~= "", "Error: Must provide a file name")
    -- OPTIONS? We should probably configure this
    -- extract on second method added
    vim.cmd(":vnew")
    vim.cmd(string.format(":w! %s", file_name))
    vim.cmd(string.format(":set filetype=%s", refactor.filetype))
    table.insert(refactor.buffers, vim.fn.bufnr())

    --TODO (TheLeoP): add text_edits for when extracting file (?)

    return true, refactor
end

return M
