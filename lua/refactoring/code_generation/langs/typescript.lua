local code_utils = require("refactoring.code_generation.utils")
local code_gen_indent = require("refactoring.code_generation.indent")

local string_pattern = "{%s}"

local function build_args(args, arg_types)
    local final_args = {}
    for i, arg in pairs(args) do
        local arg_key = arg .. ":"
        if arg_types[arg_key] ~= code_utils.default_func_param_type() then
            final_args[i] = arg .. ": " .. arg_types[arg_key]
        else
            final_args[i] = arg
        end
    end
    return final_args
end

local function typescript_class_function(opts)
    -- Need this for javascript
    local args
    if opts.args_types ~= nil then
        args = build_args(opts.args, opts.args_types)
    else
        args = opts.args
    end

    if opts.func_header == nil then
        opts.func_header = ""
    end

    return string.format(
        [[
%s%s(%s) {
%s
%s}
]],
        opts.func_header,
        opts.name,
        table.concat(args, ", "),
        code_utils.stringify_code(opts.body),
        opts.func_header
    )
end

local function typescript_function(opts)
    -- Need this for javascript
    local args
    if opts.args_types ~= nil then
        args = build_args(opts.args, opts.args_types)
    else
        args = opts.args
    end

    return string.format(
        [[
%sfunction %s(%s) {
%s
%s}

]],
        opts.func_header,
        opts.name,
        table.concat(args, ", "),
        code_utils.stringify_code(opts.body),
        opts.func_header
    )
end

local function typescript_constant(opts)
    local constant_string_pattern

    if opts.multiple then
        constant_string_pattern = "const "

        for idx, identifier in pairs(opts.identifiers) do
            if idx == #opts.identifiers then
                constant_string_pattern = constant_string_pattern
                    .. string.format("%s = %s", identifier, opts.values[idx])
            else
                constant_string_pattern = constant_string_pattern
                    .. string.format("%s = %s,", identifier, opts.values[idx])
            end
        end

        constant_string_pattern = constant_string_pattern .. ";\n"
    else
        constant_string_pattern = string.format(
            "const %s = %s;\n",
            code_utils.returnify(opts.name, string_pattern),
            opts.value
        )
    end

    return constant_string_pattern
end

local indent_char = " "

local typescript = {
    default_printf_statement = function()
        return { 'console.log("%s");' }
    end,
    print = function(opts)
        return string.format(opts.statement, opts.content)
    end,
    default_print_var_statement = function()
        return { 'console.log("%s %%s", %s);' }
    end,
    print_var = function(opts)
        return string.format(opts.statement, opts.prefix, opts.var)
    end,
    comment = function(statement)
        return string.format("// %s", statement)
    end,
    -- The constant can be destructured
    constant = function(opts)
        return typescript_constant(opts)
    end,

    -- This is for returning multiple arguments from a function
    -- @param names string|table
    pack = function(names)
        return code_utils.returnify(names, string_pattern)
    end,

    -- this is for consuming one or more arguments from a function call.
    -- @param names string|table
    unpack = function(names)
        return code_utils.returnify(names, string_pattern)
    end,

    ["return"] = function(code)
        return string.format("return %s;", code)
    end,
    ["function"] = function(opts)
        return typescript_function(opts)
    end,
    function_return = function(opts)
        return typescript_function(opts)
    end,
    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
    terminate = function(code)
        return code .. ";"
    end,
    indent_char_length = function(first_line)
        return code_gen_indent.indent_char_length(first_line, indent_char)
    end,
    indent_char = function()
        return indent_char
    end,
    indent = function(opts)
        return code_gen_indent.indent(opts, indent_char)
    end,

    class_function = function(opts)
        return typescript_class_function(opts)
    end,

    class_function_return = function(opts)
        return typescript_class_function(opts)
    end,

    call_class_function = function(opts)
        return string.format(
            "this.%s(%s)",
            opts.name,
            table.concat(opts.args, ", ")
        )
    end,
}

return typescript
