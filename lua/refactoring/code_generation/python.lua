local code_utils = require("refactoring.code_generation.utils")

local python = {
    constant = function(opts)
        return string.format("%s = %s\n", opts.name, opts.value)
    end,
    ["return"] = function(code)
        return string.format("return %s", code_utils.stringify_code(code))
    end,

    ["function"] = function(opts)
        return string.format(
            [[
def %s(%s):
    %s


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
        return code .. "\n"
    end,
    pack = function(opts)
        return code_utils.returnify(opts, "%s")
    end,
}
return python
