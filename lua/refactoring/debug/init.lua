local Config = require("refactoring.config")
local printf = require("refactoring.debug.printf")
local print_var = require("refactoring.debug.print_var")
local get_path = require("refactoring.debug.get_path")
local cleanup = require("refactoring.debug.cleanup")

local M = {}

---@param opts ConfigOpts
function M.printf(opts)
    local config = Config.get():merge(opts)
    printf(vim.api.nvim_get_current_buf(), config)
end

---@param opts ConfigOpts
function M.print_var(opts)
    local config = Config.get():merge(opts)
    print_var(vim.api.nvim_get_current_buf(), config)
end

---@param opts ConfigOpts
function M.cleanup(opts)
    local config = Config.get():merge(opts)
    cleanup(vim.api.nvim_get_current_buf(), config)
end

---@param opts ConfigOpts
---@return string
function M.get_path(opts)
    local config = Config.get():merge(opts)
    return get_path(vim.api.nvim_get_current_buf(), config)
end

return M
