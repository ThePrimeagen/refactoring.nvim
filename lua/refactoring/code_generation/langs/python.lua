local code_utils = require("refactoring.code_generation.utils")

---@param args string[]
---@param arg_types string[]
---@return string[]
local function build_args(args, arg_types)
    local final_args = {} ---@type string[]
    for i, arg in pairs(args) do
        if arg_types[arg] ~= code_utils.default_func_param_type() then
            final_args[i] = arg .. ": " .. arg_types[arg]
        else
            final_args[i] = arg
        end
    end
    return final_args
end

local function python_function(opts)
    local args = build_args(opts.args, opts.args_types)
    if opts.func_header == nil then
        opts.func_header = ""
    end
    return string.format(
        [[
%sdef %s(%s):
%s

]],
        opts.func_header,
        opts.name,
        table.concat(args, ", "),
        code_utils.stringify_code(opts.body)
    )
end

local function python_function_return(opts)
    local args = build_args(opts.args, opts.args_types)
    if opts.func_header == nil then
        opts.func_header = ""
    end
    if opts.return_type == nil then
        opts.return_type = "None"
    end
    return string.format(
        [[
%sdef %s(%s) -> %s:
%s

]],
        opts.func_header,
        opts.name,
        table.concat(args, ", "),
        opts.return_type,
        code_utils.stringify_code(opts.body)
    )
end

local function python_class_function(opts)
    local args = build_args(opts.args, opts.args_types)
    args = vim.list_extend({ "self" }, args)
    if opts.func_header == nil then
        opts.func_header = ""
    end
    return string.format(
        [[
%sdef %s(%s):
%s

]],
        opts.func_header,
        opts.name,
        table.concat(args, ", "),
        code_utils.stringify_code(opts.body)
    )
end

local function python_class_function_return(opts)
    local args = build_args(opts.args, opts.args_types)
    args = vim.list_extend({ "self" }, args)
    if opts.func_header == nil then
        opts.func_header = ""
    end
    if opts.return_type == nil then
        opts.return_type = "None"
    end
    return string.format(
        [[
%sdef %s(%s) -> %s:
%s

]],
        opts.func_header,
        opts.name,
        table.concat(args, ", "),
        opts.return_type,
        code_utils.stringify_code(opts.body)
    )
end

local function python_constant(opts)
    local constant_string_pattern

    if opts.multiple then
        constant_string_pattern = string.format(
            "%s = %s\n",
            table.concat(opts.identifiers, ", "),
            table.concat(opts.values, ", ")
        )
    else
        local name
        if opts.name[1] ~= nil then
            name = opts.name[1]
        else
            name = opts.name
        end

        if not opts.statement then
            opts.statement = "%s = %s"
        end

        constant_string_pattern =
            string.format(opts.statement .. "\n", name, opts.value)
    end

    return constant_string_pattern
end

---@type code_generation
local python = {
    constant = function(opts)
        return python_constant(opts)
    end,
    ["return"] = function(code)
        return string.format("return %s", code_utils.stringify_code(code))
    end,
    ["function"] = function(opts)
        return python_function(opts)
    end,
    function_return = function(opts)
        return python_function_return(opts)
    end,
    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
    class_function = function(opts)
        return python_class_function(opts)
    end,
    class_function_return = function(opts)
        return python_class_function_return(opts)
    end,
    call_class_function = function(opts)
        return string.format(
            "self.%s(%s)",
            opts.name,
            table.concat(opts.args, ", ")
        )
    end,
    terminate = function(code)
        return code
    end,
    pack = function(opts)
        return code_utils.returnify(opts, "%s")
    end,
    comment = function(statement)
        return string.format("# %s", statement)
    end,
    default_printf_statement = function()
        return { 'print("%s")' }
    end,
    print = function(opts)
        return string.format(opts.statement, opts.content)
    end,
    default_print_var_statement = function()
        return { 'print(f"%s {str(%s)}")' }
    end,
    print_var = function(opts)
        return string.format(opts.statement, opts.prefix, opts.var)
    end,
}

return python
