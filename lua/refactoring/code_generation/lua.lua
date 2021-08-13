local utils = require("refactoring.code_generation.utils")

local lua = {
    constant = function(opts)
        return string.format("local %s = %s\n", opts.name, opts.value)
    end,
    ["function"] = function(opts)
        return string.format(
            [[
local function %s(%s)
    %s
end

]],
            opts.name,
            table.concat(opts.args, ", "),
            utils.stringify_code(opts.body)
        )
    end,
    ["return"] = function(code)
        return string.format("return %s", utils.stringify_code(code))
    end,

    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
}
return lua
