local Config = require("refactoring.config")
local printf = require("refactoring.debug.printf")

local M = {}

function M.printf(opts)
    local config = Config.get():merge(opts)
    return printf(vim.api.nvim_get_current_buf(), config)
end

return M
