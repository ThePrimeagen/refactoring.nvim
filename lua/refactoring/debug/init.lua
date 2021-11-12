local printf = require("refactoring.debug.printf")

local M = {}

function M.printf(opts)
    return printf(vim.api.nvim_get_current_buf(), opts)
end

return M
