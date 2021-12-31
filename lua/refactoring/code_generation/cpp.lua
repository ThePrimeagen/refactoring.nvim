local code_utils = require("refactoring.code_generation.utils")

local function cpp_func_args(args)
    local new_args = {}
    for _, arg in ipairs(args) do
        table.insert(new_args, string.format("INSERT_VAR_TYPE %s", arg))
    end
    return new_args
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
            table.concat(cpp_func_args(opts.args), ", "),
            code_utils.stringify_code(opts.body)
        )
    end,
    function_return = function(opts)
        return string.format(
            [[
auto %s(%s) {
    %s
}

]],
            opts.name,
            table.concat(opts.args, ", "),
            code_utils.stringify_code(opts.body)
        )
    end,
    constant = function(opts)
        return string.format("auto %s = %s;\n", opts.name, opts.value)
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
