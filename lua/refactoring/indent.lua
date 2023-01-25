local M = {}

--- return the indent width of a given buffer
---
--- If the buffer uses tabs ('noexpandtab'), the value uf 'tabstop' will be
-- returned, else the value of 'shiftwidth' will be returned
---@param bufnr number
---@return number
M.buf_indent_width = function(bufnr)
    return vim.bo[bufnr].expandtab and vim.bo[bufnr].shiftwidth
        or vim.bo[bufnr].tabstop
end

return M
