local default_code_generation = require("refactoring.code_generation")

-- There is no formatting that we should do
local default_formatting = {
    lua = {},
    go = {},

    -- All of the cs
    cpp = {},
    c = {},
    h = {},
    hpp = {},
    cxx = {},

    -- Python needs tons of work to become correct.
    python = {},

    default = {
        cmd = [[ :silent norm! mzgg=G`z ]],
    },
}

local default_prompt_func_param_type = {
    go = false,

    -- All of the cs
    cpp = false,
    c = false,
    h = false,
    hpp = false,
    cxx = false,
}

local default_prompt_func_return_type = {
    go = false,
}

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
