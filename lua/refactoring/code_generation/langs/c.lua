-- c mostly == cpp
local code_utils = require("refactoring.code_generation.utils")
local cpp = require("refactoring.code_generation.langs.cpp")

local string_pattern = "%s"

local function c_func_args_default_types(args)
    local new_args = {}
    for _, arg in ipairs(args) do
        table.insert(
            new_args,
            string.format("%s %s", code_utils.default_func_param_type(), arg)
        )
    end
    return new_args
end

local function c_func_args_with_types(args, args_types)
    local args_with_types = {}
    for _, arg in ipairs(args) do
        table.insert(
            args_with_types,
            string.format("%s %s", args_types[arg], arg)
        )
    end
    return table.concat(args_with_types, ", ")
end

local function c_func_args(opts)
    if opts.args_types ~= nil then
        return c_func_args_with_types(opts.args, opts.args_types)
    else
        return table.concat(c_func_args_default_types(opts.args), ", ")
    end
end

local function c_constant(opts)
    local constant_string_pattern

    if opts.multiple then
        constant_string_pattern = "INSERT_TYPE_HERE "

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
        if not opts.statement then
            opts.statement = "INSERT_TYPE_HERE %s = %s;"
        end

        constant_string_pattern = string.format(
            opts.statement .. "\n",
            code_utils.returnify(opts.name, string_pattern),
            opts.value
        )
    end

    return constant_string_pattern
end

---@type code_generation
local c = {
    comment = cpp.comment,
    default_printf_statement = cpp.default_printf_statement,
    print = cpp.print,
    default_print_var_statement = cpp.default_print_var_statement,
    print_var = cpp.print_var,
    ["return"] = cpp["return"],
    ["function"] = cpp["function"],
    function_return = function(opts)
        return string.format(
            [[
%s %s(%s) {
%s
}

]],
            opts.return_type,
            opts.name,
            c_func_args(opts),
            code_utils.stringify_code(opts.body)
        )
    end,
    constant = function(opts)
        return c_constant(opts)
    end,
    call_function = cpp.call_function,
    pack = cpp.pack,
    terminate = cpp.terminate,
}

return c
