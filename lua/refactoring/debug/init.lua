local Config = require("refactoring.config")
local printf = require("refactoring.debug.printf").printDebug
local print_var = require("refactoring.debug.print_var").printDebug
local get_path = require("refactoring.debug.get_path")
local cleanup = require("refactoring.debug.cleanup")

local api = vim.api

local M = {}

---@type Config
local last_config

function M.printf_operatorfunc()
    printf(api.nvim_get_current_buf(), last_config)
end

---@param opts ConfigOpts
function M.printf(opts)
    last_config = Config.get():merge(opts)
    vim.o.operatorfunc = "v:lua.require'refactoring'.debug.printf_operatorfunc"
    vim.cmd([[normal! g@iw]])
end

function M.print_var_operatorfunc()
    print_var(api.nvim_get_current_buf(), last_config)
end

---@param opts ConfigOpts
function M.print_var(opts)
    last_config = Config.get():merge(opts)
    vim.o.operatorfunc =
        "v:lua.require'refactoring'.debug.print_var_operatorfunc"
    local mode = api.nvim_get_mode().mode
    if mode == "v" or mode == "V" or mode == "\22" then -- 
        vim.cmd([[normal! g@]])
    else
        --TODO (TheLeoP): allow more than simply iw? maybe as a config option
        vim.cmd([[normal! g@iw]])
    end
end

---@param opts ConfigOpts
function M.cleanup(opts)
    local config = Config.get():merge(opts)
    cleanup(api.nvim_get_current_buf(), config)
end

---@param opts ConfigOpts
---@return string
function M.get_path(opts)
    local config = Config.get():merge(opts)
    return get_path(api.nvim_get_current_buf(), config)
end

return M
