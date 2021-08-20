local utils = require("refactoring.code_generation.utils")

local javascript = {
    constant = function(opts)
        return string.format("const %s = %s;\n", opts.name, opts.value)
    end,

    ["return"] = function(code)
        return string.format("return %s", utils.stringify_code(code))
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
            utils.stringify_code(opts.body)
        )
    end,

    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
}

return javascript
