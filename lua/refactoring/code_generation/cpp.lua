local code_utils = require("refactoring.code_generation.utils")

local cpp = {
    print = function(statement)
        return string.format('printf("%s(%%d): \\n", __LINE__);', statement)
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
            table.concat(opts.args, ", "),
            code_utils.stringify_code(opts.body)
        )
    end,
    function_return = function(opts)
        return string.format(
            [[
INPUT_RETURN_TYPE %s(%s) {
    %s
}

]],
            opts.name,
            table.concat(opts.args, ", "),
            code_utils.stringify_code(opts.body)
        )
    end,
    constant = function(opts)
        return string.format(
            "INSERT_TYPE_HERE %s = %s;\n",
            opts.name,
            opts.value
        )
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
