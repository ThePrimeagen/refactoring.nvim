local default_code_generation = require("refactoring.code_generation")

local default_prompt_func_param_type = {
    go = false,
    java = false,

    cpp = false,
    c = false,
}

local default_prompt_func_return_type = {
    go = false,
    java = false,

    cpp = false,
    c = false,
}

local default_visibility = {
    php = "public",
    default = false,
}

local default_printf_statements = {}
local default_print_var_statements = {}
local default_extract_var_statements = {}

---@alias refactor.code_gen.constant.Opts {multiple: boolean?, identifiers: string[]?, values: string[]?, statement: string|nil|boolean, name: string|nil|string[], value: string?}
---@alias refactor.code_gen.call_function.Opts refactor.FuncParams
---@alias refactor.code_gen.class_function_return.Opts {body: string, classname: string, name: string, return_type: string}
---@alias refactor.code_gen.call_class_function.Opts {args: string[], class_type: string|nil, name: string}
---@alias refactor.code_gen.function.Opts refactor.FuncParams
---@alias refactor.code_gen.special_var.Opts {region_node_type: string}
---@alias refactor.code_gen.print.Opts {statement:string, content:string}
---@alias refactor.code_gen.print_var.Opts {statement:string, prefix:string , var:string}

---@class refactor.CodeGeneration
---@field default_printf_statement fun(): string[]
---@field print fun(opts: refactor.code_gen.print.Opts): string
---@field default_print_var_statement fun(): string[]
---@field print_var fun(opts: refactor.code_gen.print_var.Opts): string
---@field comment fun(statement: string): string
---@field constant fun(opts: refactor.code_gen.constant.Opts): string
---@field pack? fun(names: string|table):string This is for returning multiple arguments from a function
---@field unpack? fun(names: string|table):string This is for consuming one or more arguments from a function call.
---@field return fun(code: string[]|string):string
---@field function fun(opts: refactor.code_gen.function.Opts):string
---@field function_return fun(opts: refactor.code_gen.function.Opts): string
---@field call_function fun(opts: refactor.code_gen.call_function.Opts):string
---@field terminate fun(code: string): string
---@field class_function? fun(opts: refactor.code_gen.call_function.Opts):string
---@field class_function_return? fun(opts: refactor.code_gen.class_function_return.Opts): string
---@field call_class_function? fun(opts: refactor.code_gen.call_class_function.Opts): string
---@field special_var? fun(var: string, opts: refactor.code_gen.special_var.Opts): string
---@field var_declaration? fun(opts: refactor.code_gen.constant.Opts): string

---@alias refactor.ft
---| "ts"
---| "js"
---| "typescriptreact"
---| "javascriptreact"
---| "vue"
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

---@class refactor.ConfigOpts
---@field code_generation? table<string, refactor.CodeGeneration>|{new_line: fun(): string}
---@field prompt_func_return_type? table<refactor.ft, boolean>
---@field prompt_func_param_type? table<refactor.ft, boolean>
---@field printf_statements? table<refactor.ft, string[]>
---@field print_var_statements? table<refactor.ft, string[]>
---@field extract_var_statements? table<refactor.ft, string>
---@field visibility? table<refactor.ft, string>
---@field below? boolean
---@field show_success_message? boolean
---@field _end? boolean

---@class refactor.c: refactor.ConfigOpts
---@field _automation {bufnr: number, inputs: string[], inputs_idx: integer}
---@field _preview_namespace integer

---@class refactor.Config
---@field config refactor.c
local Config = {}
Config.__index = Config

---@vararg refactor.ConfigOpts
---@return refactor.Config
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

---@return refactor.c
function Config:get()
    return self.config
end

---@param opts refactor.ConfigOpts
---@return refactor.Config
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

---@param filetype refactor.ft
---@return boolean
function Config:get_prompt_func_param_type(filetype)
    if self.config.prompt_func_param_type[filetype] == nil then
        return false
    end
    return self.config.prompt_func_param_type[filetype]
end

---@param override_map table<refactor.ft, boolean>
function Config:set_prompt_func_param_type(override_map)
    self.config.prompt_func_param_type = override_map
end

---@param filetype refactor.ft
---@return boolean
function Config:get_prompt_func_return_type(filetype)
    if self.config.prompt_func_return_type[filetype] == nil then
        return false
    end
    return self.config.prompt_func_return_type[filetype]
end

---@param override_map table<refactor.ft, boolean>
function Config:set_prompt_func_return_type(override_map)
    self.config.prompt_func_return_type = override_map
end

---@param filetype refactor.ft
---@return string[]|false
function Config:get_printf_statements(filetype)
    if self.config.printf_statements[filetype] == nil then
        return false
    end
    return self.config.prompt_func_return_type[filetype]
end

---@param override_map table<refactor.ft, string[]>
function Config:set_printf_statements(override_map)
    self.config.printf_statements = override_map
end

---@param filetype refactor.ft
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

---@param filetype refactor.ft: the filetype
---@return string|false
function Config:get_extract_var_statement(filetype)
    if self.config.extract_var_statements[filetype] == nil then
        return false
    end
    return self.config.extract_var_statements[filetype]
end

---@param override_statement string|nil extract_var_statement
---@param filetype refactor.ft filetype for which to override the extract_var_statement
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
---@param lang string
function Config:get_code_generation_for(lang)
    return self.config.code_generation[lang]
        or self.config.code_generation["default"]
end

---@param filetype refactor.ft
---@return string
function Config:get_visibility_for(filetype)
    filetype = filetype or vim.bo[0].ft
    return self.config.visibility[filetype] or self.config.visibility["default"]
end

local config = Config:new()
local M = {}

---@return refactor.Config
function M.get()
    return config
end

---@param c refactor.ConfigOpts
function M.setup(c)
    c = c or {}
    config = Config:new(c)
end

return M
