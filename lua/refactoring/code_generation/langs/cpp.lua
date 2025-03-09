local code_utils = require("refactoring.code_generation.utils")

local string_pattern = "%s"

local function cpp_func_args_default_types(args)
    local new_args = {}
    for _, arg in ipairs(args) do
        table.insert(
            new_args,
            ("%s %s"):format(code_utils.default_func_param_type(), arg)
        )
    end
    return new_args
end

local function cpp_func_args_with_types(args, args_types)
    local args_with_types = {}
    for _, arg in ipairs(args) do
        table.insert(args_with_types, ("%s %s"):format(args_types[arg], arg))
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
                    .. ("%s = %s"):format(identifier, opts.values[idx])
            else
                constant_string_pattern = constant_string_pattern
                    .. ("%s = %s,"):format(identifier, opts.values[idx])
            end
        end

        constant_string_pattern = constant_string_pattern .. ";\n"
    else
        if not opts.statement then
            opts.statement = "auto %s = %s;"
        end

        constant_string_pattern = (opts.statement .. "\n"):format(
            code_utils.returnify(opts.name, string_pattern),
            opts.value
        )
    end

    return constant_string_pattern
end

---@type refactor.CodeGeneration
local cpp = {
    comment = function(statement)
        return ("// %s"):format(statement)
    end,
    default_printf_statement = function()
        return { 'printf("%s(%%d): \\n", __LINE__);' }
    end,
    print = function(opts)
        return opts.statement:format(opts.content)
    end,
    default_print_var_statement = function()
        return { 'printf("%s %%s \\n", %s);' }
    end,
    print_var = function(opts)
        return opts.statement:format(opts.prefix, opts.var)
    end,
    ["return"] = function(code)
        return ("return %s;"):format(code)
    end,
    ["function"] = function(opts)
        return ([[
void %s(%s) {
%s
}

]]):format(
            opts.name,
            cpp_func_args(opts),
            code_utils.stringify_code(opts.body)
        )
    end,
    function_return = function(opts)
        return ([[
%s %s(%s) {
%s
}

]]):format(
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
        return ("%s(%s)"):format(opts.name, table.concat(opts.args, ", "))
    end,
    pack = function(opts)
        return code_utils.returnify(opts, "%s")
    end,
    terminate = function(code)
        return code .. ";"
    end,
}

return cpp
