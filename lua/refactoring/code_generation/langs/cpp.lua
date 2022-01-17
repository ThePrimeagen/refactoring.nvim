local code_utils = require("refactoring.code_generation.utils")

local function cpp_func_args_default_types(args)
    local new_args = {}
    for _, arg in ipairs(args) do
        table.insert(
            new_args,
            string.format("%s %s", code_utils.default_func_param_type(), arg)
        )
    end
    return new_args
end

local function cpp_func_args_with_types(args, args_types)
    local args_with_types = {}
    for _, arg in ipairs(args) do
        table.insert(
            args_with_types,
            string.format("%s %s", args_types[arg], arg)
        )
    end
    return table.concat(args_with_types, ", ")
end

local function cpp_func_args(opts)
    if opts.args_types ~= nil then
        return cpp_func_args_with_types(opts.args, opts.args_types)
    else
        return table.concat(cpp_func_args_default_types(opts.args), ", ")
    end
end

local function cpp_constant(opts)
    local constant_string_pattern

    if opts.multiple then
        constant_string_pattern = "auto "

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
            "auto %s = %s;\n",
            opts.name,
            opts.value
        )
    end

    return constant_string_pattern
end

local cpp = {
    comment = function(statement)
        return string.format("// %s", statement)
    end,
    print = function(statement)
        return string.format('printf("%s(%%d): \\n", __LINE__);', statement)
    end,
    print_var = function(prefix, var)
        return string.format('printf("%s %%s \\n", %s);', prefix, var)
    end,
    ["return"] = function(code)
        return string.format("return %s;", code)
    end,
    ["function"] = function(opts)
        return string.format(
            [[
void %s(%s) {
    %s
}

]],
            opts.name,
            cpp_func_args(opts),
            code_utils.stringify_code(opts.body)
        )
    end,
    function_return = function(opts)
        return string.format(
            [[
%s %s(%s) {
    %s
}

]],
            opts.return_type,
            opts.name,
            cpp_func_args(opts),
            code_utils.stringify_code(opts.body)
        )
    end,
    constant = function(opts)
        return cpp_constant(opts)
    end,
    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
    pack = function(opts)
        return code_utils.returnify(opts, "%s")
    end,
    terminate = function(code)
        return code .. ";\n"
    end,
}

return cpp
