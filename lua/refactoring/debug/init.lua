local Config = require("refactoring.config")
local printf = require("refactoring.debug.printf")
local print_var = require("refactoring.debug.print_var")
local print_var_norm = require("refactoring.debug.print_var_norm")
local get_path = require("refactoring.debug.get_path")
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

function M.print_var_norm(opts)
    local config = Config.get():merge(opts)
    return print_var_norm(vim.api.nvim_get_current_buf(), config)
end

function M.cleanup(opts)
    local config = Config.get():merge(opts)
    return cleanup(vim.api.nvim_get_current_buf(), config)
end

function M.get_path(opts)
    local config = Config.get():merge(opts)
    return get_path(vim.api.nvim_get_current_buf(), config)
end

return M
