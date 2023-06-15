local default_code_generation = require("refactoring.code_generation")

-- There is no formatting that we should do
local default_formatting = {
    -- TODO: should we change default to be nothing?
    -- I realize this is almost never a good idea.
    ts = {},
    js = {},
    typescriptreact = {},

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

    ruby = {},

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
local default_extract_var_statements = {}

---@alias constant_opts {multiple: boolean?, identifiers: string[]?, values: string[]?, statement: string|nil|boolean, name: string|nil|string[], value: string?}
---@alias call_function_opts func_params
---@alias function_opts func_params
---@alias special_var_opts {region_node_type: string}
---@alias print_opts {statement:string, content:string}

---@class code_generation
---@field default_printf_statement fun(): string[]
---@field print fun(opts: print_opts): string
---@field default_print_var_statement fun(): string[]
---@field print_var fun(opts: {statement:string, prefix:string , var:string}): string
---@field comment fun(statement: string): string
---@field constant fun(opts: constant_opts): string
---@field var_declaration fun(opts: code_generation): string
---@field pack fun(names: string|table):string This is for returning multiple arguments from a function
---@field unpack fun(names: string|table):string This is for consuming one or more arguments from a function call.
---@field return fun(code: string[]|string):string
---@field function fun(opts: function_opts):string
---@field function_return fun(opts: {args: string, body:string, name: string}): string
---@field call_function fun(opts: call_function_opts):string
---@field terminate fun(code: string): string
---@field class_function fun(opts: call_function_opts):string
---@field class_function_return fun(opts: {body: string, classname: string, name: string, return_type: string}): string
---@field call_class_function fun(opts: {args: string[], class_type: string, name: string}): string
---@field special_var fun(var: string, opts: special_var_opts): string

---@class c
---@field _automation table
---@field formatting table
---@field code_generation table
---@field prompt_func_return_type table
---@field prompt_func_param_type table
---@field printf_statements table
---@field print_var_statements table
---@field extract_var_statements table

---@class Config
---@field config c
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
        extract_var_statements = default_extract_var_statements,
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
    self.config.extract_var_statements = default_extract_var_statements
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

---@param filetype string: the filetype
---@return string|false
function Config:get_extract_var_statement(filetype)
    if self.config.extract_var_statements[filetype] == nil then
        return false
    end
    return self.config.extract_var_statements[filetype]
end

---@param override_statement string: map with statements to any current extract_var_statements
---@param filetype string: map with statements to any current extract_var_statements
function Config:set_extract_var_statement(filetype, override_statement)
    self.config.extract_var_statements[filetype] = override_statement
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

---@return number
function Config:get_test_bufnr()
    return self.config._automation.bufnr
end

function Config:set_test_bufnr(bufnr)
    self.config._automation.bufnr = bufnr
end

--- Get the code generation for the current filetype
---@param filetype string
---@return code_generation
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

---@return Config
function M.get()
    return config
end

function M.setup(c)
    c = c or {}
    config = Config:new(c)
end

return M
