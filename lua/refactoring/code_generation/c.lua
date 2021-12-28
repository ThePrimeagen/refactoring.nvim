-- c mostly == cpp
local code_utils = require("refactoring.code_generation.utils")
local cpp = require("refactoring.code_generation.cpp")

local c = {
    comment = cpp.comment,
    print = cpp.print,
    print_var = cpp.print_var,
    ["return"] = cpp["return"],
    ["function"] = cpp["function"],
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
    call_function = cpp.call_function,
    pack = cpp.pack,
    terminate = cpp.terminate,
}

return c
