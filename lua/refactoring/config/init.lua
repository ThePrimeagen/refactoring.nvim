local default_code_generation = require("refactoring.code_generation")

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

local default_visibility = {
    php = "public",
    default = false,
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
---@field pack? fun(names: string|table):string This is for returning multiple arguments from a function
---@field unpack? fun(names: string|table):string This is for consuming one or more arguments from a function call.
---@field return fun(code: string[]|string):string
---@field function fun(opts: function_opts):string
---@field function_return fun(opts: function_opts): string
---@field call_function fun(opts: call_function_opts):string
---@field terminate fun(code: string): string
---@field class_function? fun(opts: call_function_opts):string
---@field class_function_return? fun(opts: {body: string, classname: string, name: string, return_type: string}): string
---@field call_class_function? fun(opts: {args: string[], class_type: string|nil, name: string}): string
---@field special_var? fun(var: string, opts: special_var_opts): string
---@field var_declaration? fun(opts: constant_opts): string

---@alias ft
---| "ts"
---| "js"
---| "typescriptreact"
---| "javascriptreact"
---| "typescript"
---| "javascript"
---| "java"
---| "lua"
---| "go"
---| "php"
---| "cpp"
---| "c"
---| "h"
---| "hpp"
---| "cxx"
---| "python"
---| "ruby"
---| "cs"

---@class ConfigOpts
---@field code_generation? table<ft, code_generation>|{new_line: fun(): string}
---@field prompt_func_return_type? table<ft, boolean>
---@field prompt_func_param_type? table<ft, boolean>
---@field printf_statements? table<ft, string[]>
---@field print_var_statements? table<ft, string[]>
---@field extract_var_statements? table<ft, string>
---@field visibility? table<ft, string>
---@field below? boolean
---@field show_success_message? boolean
---@field _end? boolean

---@class c: ConfigOpts
---@field _automation {bufnr: number, inputs: string[], inputs_idx: integer}
---@field _preview_namespace integer

---@class Config
---@field config c
local Config = {}
Config.__index = Config

---@vararg ConfigOpts
---@return Config
function Config:new(...)
    local c = vim.tbl_deep_extend("force", {
        _automation = {
            bufnr = nil,
        },
    }, {
        code_generation = vim.deepcopy(default_code_generation),
        prompt_func_return_type = vim.deepcopy(default_prompt_func_return_type),
        prompt_func_param_type = vim.deepcopy(default_prompt_func_param_type),
        printf_statements = vim.deepcopy(default_printf_statements),
        print_var_statements = vim.deepcopy(default_print_var_statements),
        extract_var_statements = vim.deepcopy(default_extract_var_statements),
        visibility = vim.deepcopy(default_visibility),
        show_success_message = false,
    })

    for idx = 1, select("#", ...) do
        c = vim.tbl_deep_extend("force", {}, c, select(idx, ...))
    end

    return setmetatable({
        config = c,
    }, self)
end

---@return c
function Config:get()
    return self.config
end

---@param opts ConfigOpts
---@return Config
function Config:merge(opts)
    return Config:new(self.config, opts or {})
end

function Config:reset()
    local c = self.config
    c.code_generation = vim.deepcopy(default_code_generation)
    c.prompt_func_return_type = vim.deepcopy(default_prompt_func_return_type)
    c.prompt_func_param_type = vim.deepcopy(default_prompt_func_param_type)
    c.printf_statements = vim.deepcopy(default_printf_statements)
    c.print_var_statements = vim.deepcopy(default_print_var_statements)
    c.extract_var_statements = vim.deepcopy(default_extract_var_statements)
    c.visibility = vim.deepcopy(default_visibility)
end

---@param inputs string|string[]
function Config:automate_input(inputs)
    if type(inputs) ~= "table" then
        inputs = { inputs }
    end

    self.config._automation.inputs = inputs
    self.config._automation.inputs_idx = 0
end

---@param filetype ft
---@return boolean
function Config:get_prompt_func_param_type(filetype)
    if self.config.prompt_func_param_type[filetype] == nil then
        return false
    end
    return self.config.prompt_func_param_type[filetype]
end

---@param override_map table<ft, boolean>
function Config:set_prompt_func_param_type(override_map)
    self.config.prompt_func_param_type = override_map
end

---@param filetype ft
---@return boolean
function Config:get_prompt_func_return_type(filetype)
    if self.config.prompt_func_return_type[filetype] == nil then
        return false
    end
    return self.config.prompt_func_return_type[filetype]
end

---@param override_map table<ft, boolean>
function Config:set_prompt_func_return_type(override_map)
    self.config.prompt_func_return_type = override_map
end

---@param filetype ft
---@return string[]|false
function Config:get_printf_statements(filetype)
    if self.config.printf_statements[filetype] == nil then
        return false
    end
    return self.config.prompt_func_return_type[filetype]
end

---@param override_map table<ft, string[]>
function Config:set_printf_statements(override_map)
    self.config.printf_statements = override_map
end

---@param filetype ft
---@return string[]|false
function Config:get_print_var_statements(filetype)
    if self.config.print_var_statements[filetype] == nil then
        return false
    end
    return self.config.prompt_func_return_type[filetype]
end

function Config:set_print_var_statements(override_map)
    self.config.print_var_statements = override_map
end

---@param filetype ft: the filetype
---@return string|false
function Config:get_extract_var_statement(filetype)
    if self.config.extract_var_statements[filetype] == nil then
        return false
    end
    return self.config.extract_var_statements[filetype]
end

---@param override_statement string|nil extract_var_statement
---@param filetype ft filetype for which to override the extract_var_statement
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

---@return integer
function Config:get_test_bufnr()
    return self.config._automation.bufnr
end

---@param bufnr integer
function Config:set_test_bufnr(bufnr)
    self.config._automation.bufnr = bufnr
end

--- Get the code generation for the current filetype
---@param filetype ft
---@return code_generation
function Config:get_code_generation_for(filetype)
    filetype = filetype or vim.bo[0].ft
    return self.config.code_generation[filetype]
        or self.config.code_generation["default"]
end

---@param filetype ft
---@return string
function Config:get_visibility_for(filetype)
    filetype = filetype or vim.bo[0].ft
    return self.config.visibility[filetype] or self.config.visibility["default"]
end

local config = Config:new()
local M = {}

---@return Config
function M.get()
    return config
end

---@param c ConfigOpts
function M.setup(c)
    c = c or {}
    config = Config:new(c)
end

return M
