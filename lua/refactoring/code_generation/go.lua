local code_utils = require("refactoring.code_generation.utils")

local string_pattern = "%s"

local function go_function(opts)
    return string.format(
        [[
func %s(%s) {
%s
}
]],
        opts.name,
        table.concat(opts.args, ", "),
        code_utils.stringify_code(opts.body)
    )
end

local function go_class_function(opts)
    return string.format(
        [[
func %s %s(%s) {
%s
}
]],
        opts.className,
        opts.name,
        table.concat(opts.args, ", "),
        code_utils.stringify_code(opts.body)
    )
end

local function go_class_function_return(opts)
    return string.format(
        [[
func %s %s(%s) INPUT_RETURN_TYPE {
%s
}
]],
        opts.className,
        opts.name,
        table.concat(opts.args, ", "),
        code_utils.stringify_code(opts.body)
    )
end

local function go_call_class_func(opts)
    return string.format(
        "%s.%s(%s)",
        opts.class_type,
        opts.name,
        table.concat(opts.args, ", ")
    )
end

local function constant(opts)
    return string.format(
        "%s := %s\n",
        code_utils.returnify(opts.name, string_pattern),
        opts.value
    )
end

local go = {
    print_var = function(prefix, var)
        return string.format(
            'fmt.Println(fmt.Sprintf("%s %%v", %s))',
            prefix,
            var
        )
    end,
    print = function(statement)
        return string.format('fmt.Println("%s")', statement)
    end,
    constant = function(opts)
        return constant(opts)
    end,
    ["return"] = function(code)
        return string.format("return %s", code_utils.stringify_code(code))
    end,
    ["function"] = function(opts)
        return go_function(opts)
    end,
    class_function = function(opts)
        return go_class_function(opts)
    end,
    class_function_return = function(opts)
        return go_class_function_return(opts)
    end,
    pack = function(names)
        return code_utils.returnify(names, string_pattern)
    end,
    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
    call_class_function = function(opts)
        return go_call_class_func(opts)
    end,
    terminate = function(code)
        return code .. "\n"
    end,
}
return go
