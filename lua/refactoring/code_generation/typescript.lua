local code_utils = require("refactoring.code_generation.utils")

local string_pattern = "{%s}"

local typescript = {
    print = function(statement)
        return string.format('console.log("%s");', statement)
    end,

    -- The constant can be destructured
    constant = function(opts)
        return string.format(
            "const %s = %s;\n",
            code_utils.returnify(opts.name, string_pattern),
            opts.value
        )
    end,

    -- This is for returing multiple arguments from a function
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
        return string.format(
            [[
function %s(%s) {
    %s
}

]],
            opts.name,
            table.concat(opts.args, ", "),
            code_utils.stringify_code(opts.body)
        )
    end,

    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
    terminate = function(code)
        return code .. ";\n"
    end,
}

return typescript
