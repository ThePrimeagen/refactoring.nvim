local Config = require("refactoring.config")
local printf = require("refactoring.debug.printf")
local print_var = require("refactoring.debug.print_var")
local print_in_editor = require("refactoring.debug.print_in_editor")
local cleanup = require("refactoring.debug.cleanup")

local M = {}

function M.printf(opts)
    local config = Config.get():merge(opts)
    return printf(vim.api.nvim_get_current_buf(), config)
end

function M.print_var(opts)
    local config = Config.get():merge(opts)
    return print_var(vim.api.nvim_get_current_buf(), config)
end

function M.cleanup(opts)
    local config = Config.get():merge(opts)
    return cleanup(vim.api.nvim_get_current_buf(), config)
end

function M.print_in_editor(opts)
    local config = Config.get():merge(opts)
    return print_in_editor(vim.api.nvim_get_current_buf(), config)
end

return M
