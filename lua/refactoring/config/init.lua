local default_code_generation = require("refactoring.code_generation")

-- There is no formatting that we should do
local default_formatting = {
    -- TODO: should we change default to be nothing?
    -- I realize this is almost never a good idea.
    ts = {},
    js = {},

    lua = {},
    go = {},
    php = {},

    -- All of the cs
    cpp = {},
    c = {},
    h = {},
    hpp = {},
    cxx = {},

    -- Python needs tons of work to become correct.
    python = {},

    default = {
        cmd = nil, -- format.lua checks to see if the command is nil or not
    },
}

local default_prompt_func_param_type = {
    go = false,
    java = false,

    cpp = false,
    c = false,
    h = false,
    hpp = false,
    cxx = false,
}

local default_prompt_func_return_type = {
    go = false,
    java = false,

    cpp = false,
    c = false,
    h = false,
    hpp = false,
    cxx = false,
}

local default_printf_statements = {}

local default_print_var_statements = {}

---@class Config
---@field config table
local Config = {}
Config.__index = Config

function Config:new(...)
    local c = vim.tbl_deep_extend("force", {
        _automation = {
            bufnr = nil,
        },
    }, {
        formatting = default_formatting,
        code_generation = default_code_generation,
        prompt_func_return_type = default_prompt_func_return_type,
        prompt_func_param_type = default_prompt_func_param_type,
        printf_statements = default_printf_statements,
        print_var_statements = default_print_var_statements,
    })

    for idx = 1, select("#", ...) do
        c = vim.tbl_deep_extend("force", {}, c, select(idx, ...))
    end

    return setmetatable({
        config = c,
    }, self)
end

function Config:get()
    return self.config
end

function Config:merge(opts)
    return Config:new(self.config, opts or {})
end

function Config:reset()
    self.config.formatting = default_formatting
    self.config.code_generation = default_code_generation
    self.config.prompt_func_return_type = default_prompt_func_return_type
    self.config.prompt_func_param_type = default_prompt_func_param_type
    self.config.printf_statements = default_printf_statements
    self.config.print_var_statements = default_print_var_statements
end

function Config:automate_input(inputs)
    if type(inputs) ~= "table" then
        inputs = { inputs }
    end

    self.config._automation.inputs = inputs
    self.config._automation.inputs_idx = 0
end

function Config:get_prompt_func_param_type(filetype)
    if self.config.prompt_func_param_type[filetype] == nil then
        return false
    end
    return self.config.prompt_func_param_type[filetype]
end

function Config:set_prompt_func_param_type(override_map)
    self.config.prompt_func_param_type = override_map
end

function Config:get_prompt_func_return_type(filetype)
    if self.config.prompt_func_return_type[filetype] == nil then
        return false
    end
    return self.config.prompt_func_return_type[filetype]
end

function Config:set_prompt_func_return_type(override_map)
    self.config.prompt_func_return_type = override_map
end

function Config:get_printf_statements(filetype)
    if self.config.printf_statements[filetype] == nil then
        return false
    end
    return self.config.prompt_func_return_type[filetype]
end

function Config:set_printf_statements(override_map)
    self.config.printf_statements = override_map
end

function Config:get_print_var_statements(filetype)
    if self.config.print_var_statements[filetype] == nil then
        return false
    end
    return self.config.prompt_func_return_type[filetype]
end

function Config:set_print_var_statements(override_map)
    self.config.print_var_statements = override_map
end

function Config:get_automated_input()
    local a = self.config._automation
    if a.inputs then
        local inputs = a.inputs
        if #inputs > a.inputs_idx then
            a.inputs_idx = a.inputs_idx + 1
            return a.inputs[a.inputs_idx]
        end
    end

    return nil
end

function Config:get_test_bufnr()
    return self.config._automation.bufnr
end

function Config:set_test_bufnr(bufnr)
    self.config._automation.bufnr = bufnr
end

function Config:get_code_generation_for(filetype)
    filetype = filetype or vim.bo[0].ft
    return self.config.code_generation[filetype]
end

function Config:get_formatting_for(filetype)
    filetype = filetype or vim.bo[0].ft
    return self.config.formatting[filetype] or self.config.formatting["default"]
end

local config = Config:new()
local M = {}

function M.get()
    return config
end

function M.setup(c)
    c = c or {}
    config = Config:new(c)
end

return M
