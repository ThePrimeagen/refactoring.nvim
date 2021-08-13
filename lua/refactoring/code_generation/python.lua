local utils = require("refactoring.code_generation.utils")

local python = {
    constant = function(opts)
        return string.format("%s = %s\n", opts.name, opts.value)
    end,
    ["return"] = function(code)
        return string.format("return %s", utils.stringify_code(code))
    end,

    ["function"] = function(opts)
        return string.format(
            [[
def %s(%s):
    %s


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
return python
