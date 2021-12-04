local code_utils = require("refactoring.code_generation.utils")

local function returnify(args)
    if type(args) == "string" then
        return args
    end

    if #args == 1 then
        return args[1]
    end

    local codes = {}
    for _, value in pairs(args) do
        table.insert(codes, code_utils.stringify_code(value))
    end

    return string.format("%s", table.concat(codes, ", "))
end

local lua = {
    ["print"] = function(print_string)
        return string.format('print("%s")', print_string)
    end,
    print_var = function(prefix, var)
        return string.format('print("%s", vim.inspect(%s))', prefix, var)
    end,
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
            code_utils.stringify_code(opts.body)
        )
    end,
    ["return"] = function(code)
        return string.format("return %s", code_utils.stringify_code(code))
    end,

    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
    terminate = function(code)
        return code .. "\n"
    end,
    pack = function(opts)
        return returnify(opts)
    end,
}
return lua
